import 'package:flutter/material.dart';
import '../../../core/constants/app_categories.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/product_item.dart';

class EditProductModal extends StatefulWidget {
  final ProductItem product;
  final Function(ProductItem) onProductUpdated;

  const EditProductModal({
    super.key,
    required this.product,
    required this.onProductUpdated,
  });

  @override
  State<EditProductModal> createState() => _EditProductModalState();
}

class _EditProductModalState extends State<EditProductModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _penitipController;
  late TextEditingController _barcodeController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: CurrencyFormatter.format(widget.product.price, withSymbol: false),
    );
    _stockController =
        TextEditingController(text: widget.product.stock.toString());
    _penitipController =
        TextEditingController(text: widget.product.penitipName);
    _barcodeController =
        TextEditingController(text: widget.product.barcode ?? widget.product.id);
    _selectedCategory = AppCategories.all.contains(widget.product.category)
        ? widget.product.category
        : AppCategories.all.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _penitipController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updated = widget.product.copyWith(
        name: _nameController.text.trim(),
        price: CurrencyFormatter.parse(_priceController.text.trim()),
        stock: int.tryParse(_stockController.text.trim()) ?? widget.product.stock,
        penitipName: _penitipController.text.trim().isEmpty
            ? widget.product.penitipName
            : _penitipController.text.trim(),
        category: _selectedCategory,
        barcode: _barcodeController.text.trim().isEmpty
            ? widget.product.id
            : _barcodeController.text.trim(),
      );

      widget.onProductUpdated(updated);
      Navigator.pop(context);
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Data Produk',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Nama Produk
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Produk / Makanan',
                    hintText: 'Contoh: Risol Mayo Spesial',
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
                      val == null || val.isEmpty ? 'Nama produk wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                // Kategori Dropdown
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
                    return DropdownMenuItem(
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
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),

                // Harga & Stok
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

                // Nama Penitip
                TextFormField(
                  controller: _penitipController,
                  decoration: InputDecoration(
                    labelText: 'Mitra / Penitip',
                    hintText: 'Contoh: Bu Siti',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
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
                const SizedBox(height: 12),

                // Barcode Code
                TextFormField(
                  controller: _barcodeController,
                  decoration: InputDecoration(
                    labelText: 'Kode Barcode / SKU',
                    hintText: 'TK-2026-001',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
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
                const SizedBox(height: 22),

                // Button Simpan Perubahan
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: AppStyles.primaryButtonStyle(),
                    onPressed: _submit,
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: const Text('Simpan Perubahan'),
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
