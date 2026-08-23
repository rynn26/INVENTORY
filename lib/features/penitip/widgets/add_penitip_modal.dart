import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/penitip_item.dart';

class AddPenitipModal extends StatefulWidget {
  final Function(PenitipItem) onPenitipAdded;

  const AddPenitipModal({
    super.key,
    required this.onPenitipAdded,
  });

  @override
  State<AddPenitipModal> createState() => _AddPenitipModalState();
}

class _AddPenitipModalState extends State<AddPenitipModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _productCountController = TextEditingController();
  final _itemCountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _productCountController.dispose();
    _itemCountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newPenitip = PenitipItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        totalProducts: int.tryParse(_productCountController.text.trim()) ?? 1,
        totalItems: int.tryParse(_itemCountController.text.trim()) ?? 10,
        totalRevenue: 0,
      );

      widget.onPenitipAdded(newPenitip);
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
                const Text(
                  'Tambah Mitra Penitip',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Nama Penitip
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Penitip / Toko Mitra',
                    hintText: 'Contoh: Bu Siti',
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
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                // Nomor WhatsApp
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Nomor WhatsApp (Opsional)',
                    hintText: '08123456789',
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
                ),
                const SizedBox(height: 12),

                // Jumlah Produk & Item
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _productCountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jenis Produk',
                          hintText: 'Contoh: 2',
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
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _itemCountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Total Item',
                          hintText: 'Contoh: 20',
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Button Simpan
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: AppStyles.primaryButtonStyle(),
                    onPressed: _submit,
                    child: const Text('Simpan Penitip'),
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
