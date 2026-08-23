import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { kasir, admin }

class UserProfile {
  final String id;
  final String fullName;
  final UserRole role;
  final String? phoneNumber;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phoneNumber,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      role: (json['role'] as String?) == 'admin'
          ? UserRole.admin
          : UserRole.kasir,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  bool get isAdmin => role == UserRole.admin;
  String get roleName => role == UserRole.admin ? 'Administrator' : 'Kasir';
}

class AuthService {
  static final _client = Supabase.instance.client;

  /// User yang sedang login (null jika belum login)
  static User? get currentUser => _client.auth.currentUser;

  static bool get isLoggedIn => currentUser != null;

  /// Login dengan email & password, mengembalikan profil user
  static Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    if (response.user == null) {
      throw Exception('Login gagal: akun tidak ditemukan.');
    }

    return _fetchProfile(response.user!.id);
  }

  /// Ambil profil dari tabel profiles
  static Future<UserProfile> _fetchProfile(String userId) async {
    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) {
      // Profil belum ada → anggap kasir (fallback)
      return UserProfile(
        id: userId,
        fullName: currentUser?.email ?? 'User',
        role: UserRole.kasir,
      );
    }

    return UserProfile.fromJson(data);
  }

  /// Ambil profil user yang sedang login
  static Future<UserProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return _fetchProfile(user.id);
  }

  /// Logout
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Stream perubahan auth state (untuk auto-redirect)
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
