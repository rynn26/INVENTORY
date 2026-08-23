import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/stock_item.dart';

class StockReturnModal extends StatefulWidget {
  final StockItem item;
  final Function(int returnQty, String reason) onStockReturned;

  const StockReturnModal({
    super.key,
    required this.item,
    required this.onStockReturned,
  });

  @override
  State<StockReturnModal> createState() => _StockReturnModalState();
}

class _StockReturnModalState extends State<StockReturnModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _returnQtyController;
  String _selectedReason = 'Sisa Tidak Terjual (Tutup Toko)';

  final List<String> _reasons = [
    'Sisa Tidak Terjual (Tutup Toko)',
    'Makanan Melewati Batas Konsumsi / Basi',
    'Bungkusan Rusak / Cacat',
    'Permintaan Penitip (Ditarik Kembali)',
  ];

  @override
  void initState() {
    super.initState();
    _returnQtyController =
        TextEditingController(text: widget.item.availableStock.toString());
  }

  @override
  void dispose() {
    _returnQtyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final qty = int.tryParse(_returnQtyController.text.trim()) ?? 0;
      if (qty <= 0) return;
      if (qty > widget.item.availableStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Jumlah retur tidak boleh melebihi stok yang ada!'),
          ),
        );
        return;
      }

      widget.onStockReturned(qty, _selectedReason);
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
                      'Retur Sisa Makanan Titipan',
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
                const SizedBox(height: 14),

                // Info Item Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_return_rounded,
                          color: AppColors.danger, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Penitip: ${widget.item.penitipName} • Sisa: ${widget.item.availableStock} pcs',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Jumlah Retur
                TextFormField(
                  controller: _returnQtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah yang Diretur / Dikembalikan (pcs)',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.undo_rounded, size: 20),
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

                // Alasan Retur
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Alasan Retur',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: _reasons.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text(
                        r,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedReason = val);
                  },
                ),
                const SizedBox(height: 22),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppStyles.radiusMedium),
                      ),
                    ),
                    onPressed: _submit,
                    icon: const Icon(Icons.assignment_return_rounded,
                        color: Colors.white),
                    label: const Text(
                      'Konfirmasi Retur ke Penitip',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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
