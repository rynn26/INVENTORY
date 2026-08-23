import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/services/product_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/product_item.dart';

class AddProductModal extends StatefulWidget {
  final Function(ProductItem) onProductAdded;

  const AddProductModal({
    super.key,
    required this.onProductAdded,
  });

  @override
  State<AddProductModal> createState() => _AddProductModalState();
}

class _AddProductModalState extends State<AddProductModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _penitipController = TextEditingController();
  String _selectedCategory = AppCategories.all.first;

  // Simpan bytes langsung dari XFile — tidak pakai File(path) agar aman di Android
  Uint8List? _imageBytes;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _penitipController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded,
                  color: AppColors.primary),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 800,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() => _imageBytes = bytes);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    String imageUrl = '';

    // 1. Upload gambar jika ada
    if (_imageBytes != null) {
      try {
        imageUrl = await StorageService.uploadProductImageBytes(_imageBytes!);
      } catch (uploadErr) {
        debugPrint('[AddProduct] Upload gambar gagal: $uploadErr');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
              content: Text('Foto gagal diupload — produk disimpan tanpa foto'),
            ),
          );
        }
      }
    }

    // 2. Simpan produk ke Supabase
    try {
      final priceVal = CurrencyFormatter.parse(_priceController.text.trim());
      final stockVal = int.tryParse(_stockController.text.trim()) ?? 0;

      final newProduct = await ProductService.createFromFields(
        name: _nameController.text.trim(),
        price: priceVal,
        stock: stockVal,
        penitipName: _penitipController.text.trim().isEmpty
            ? 'Mitra Umum'
            : _penitipController.text.trim(),
        category: _selectedCategory,
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      widget.onProductAdded(newProduct);
      Navigator.pop(context);
    } catch (e) {
      debugPrint('[AddProduct] ERROR simpan produk: $e');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Gagal Menyimpan'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tambah Produk Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Gambar Produk ──────────────────────────────
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.border,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded,
                                  size: 36, color: AppColors.textMuted),
                              SizedBox(height: 6),
                              Text(
                                'Ketuk untuk tambah foto',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Nama Produk ────────────────────────────────
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Produk / Makanan',
                    hintText: 'Contoh: Lemper Ayam Spesial',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.fastfood_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                // ── Kategori Produk ─────────────────────────────
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategori Produk',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: Icon(
                      AppCategories.getIcon(_selectedCategory),
                      size: 20,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  dropdownColor: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  items: AppCategories.all.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(
                            AppCategories.getIcon(cat),
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            cat,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // ── Harga & Stok ───────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [RupiahInputFormatter()],
                        decoration: InputDecoration(
                          labelText: 'Harga Jual',
                          hintText: '20.000',
                          prefixText: 'Rp ',
                          prefixStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jumlah Stok',
                          hintText: '20',
                          filled: true,
                          fillColor: AppColors.background,
                          prefixIcon: const Icon(Icons.inventory_2_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                        ),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Wajib diisi' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Nama Penitip ───────────────────────────────
                TextFormField(
                  controller: _penitipController,
                  decoration: InputDecoration(
                    labelText: 'Nama Mitra / Penitip',
                    hintText: 'Contoh: Bu Siti (Opsional)',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.person_pin_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Tombol Simpan ──────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: AppStyles.primaryButtonStyle(),
                    onPressed: _isUploading ? null : _submit,
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text('Simpan Produk'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
