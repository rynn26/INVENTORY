import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/stock_item.dart';

class StockInModal extends StatefulWidget {
  final List<StockItem> availableItems;
  final Function(String itemId, int addedStock, String notes) onStockIn;

  const StockInModal({
    super.key,
    required this.availableItems,
    required this.onStockIn,
  });

  @override
  State<StockInModal> createState() => _StockInModalState();
}

class _StockInModalState extends State<StockInModal> {
  final _formKey = GlobalKey<FormState>();
  late StockItem _selectedItem;
  final _quantityController = TextEditingController(text: '10');
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.availableItems.first;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
      if (qty <= 0) return;

      widget.onStockIn(
        _selectedItem.id,
        qty,
        _notesController.text.trim(),
      );
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
                      'Terima Titipan Masuk',
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

                // Pilih Produk
                const Text(
                  'Pilih Produk Makanan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StockItem>(
                      value: _selectedItem,
                      isExpanded: true,
                      items: widget.availableItems.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Row(
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '(Stok: ${item.availableStock} pcs)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedItem = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Jumlah Masuk
                TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Titipan Masuk (pcs)',
                    hintText: '10',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.add_shopping_cart_rounded,
                        size: 20, color: AppColors.primary),
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
                      val == null || val.isEmpty ? 'Jumlah wajib diisi' : null,
                ),
                const SizedBox(height: 14),

                // Catatan Titipan
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Catatan / Waktu Pengantaran (Opsional)',
                    hintText: 'Misal: Masuk jam 07.00 pagi dalam kondisi hangat',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
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

                // Button Submit
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: AppStyles.primaryButtonStyle(),
                    onPressed: _submit,
                    icon: const Icon(Icons.check_circle_rounded,
                        color: Colors.white),
                    label: const Text('Konfirmasi Penerimaan Titipan'),
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
