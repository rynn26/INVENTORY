import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final _db = Supabase.instance.client;
  static const _bucket = 'product-images';

  /// Compress bytes gambar: resize ke maks 600×600px, encode PNG.
  static Future<Uint8List> _compressBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 600,
      targetHeight: 600,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    frame.image.dispose();
    return byteData!.buffer.asUint8List();
  }

  /// Upload gambar dari bytes (XFile.readAsBytes()) — aman di Android.
  /// Gambar dikompresi terlebih dahulu sebelum diupload.
  static Future<String> uploadProductImageBytes(Uint8List rawBytes) async {
    final compressed = await _compressBytes(rawBytes);
    final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.png';

    await _db.storage.from(_bucket).uploadBinary(
          fileName,
          compressed,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
            contentType: 'image/png',
          ),
        );

    return _db.storage.from(_bucket).getPublicUrl(fileName);
  }

  /// Upload file gambar produk ke Supabase Storage (legacy — pakai bytes lebih aman).
  static Future<String> uploadProductImage(File imageFile) async {
    final raw = await imageFile.readAsBytes();
    return uploadProductImageBytes(raw);
  }


  /// Hapus gambar dari Storage berdasarkan URL-nya.
  static Future<void> deleteProductImage(String imageUrl) async {
    try {
      // Ambil nama file dari URL
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      // path: /storage/v1/object/public/product-images/filename.jpg
      final bucketIdx = segments.indexOf(_bucket);
      if (bucketIdx != -1 && bucketIdx < segments.length - 1) {
        final fileName = segments.sublist(bucketIdx + 1).join('/');
        await _db.storage.from(_bucket).remove([fileName]);
      }
    } catch (_) {
      // Abaikan error hapus gambar
    }
  }

  /// Widget helper: tampilkan gambar dari URL dengan fallback.
  static Widget productImageWidget(
    String? imageUrl, {
    double height = 120,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final placeholder = Container(
      height: height,
      color: const Color(0xFFEDF2FF),
      child: const Center(
        child: Icon(Icons.fastfood_rounded, color: Color(0xFF4361EE), size: 36),
      ),
    );

    if (imageUrl == null || imageUrl.isEmpty) return placeholder;

    final img = Image.network(
      imageUrl,
      height: height,
      width: double.infinity,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => placeholder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          height: height,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: img);
    }
    return img;
  }
}
