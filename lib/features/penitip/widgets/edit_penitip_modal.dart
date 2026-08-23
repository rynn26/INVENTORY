import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../models/penitip_item.dart';

class EditPenitipModal extends StatefulWidget {
  final PenitipItem penitip;
  final Function(PenitipItem) onPenitipUpdated;

  const EditPenitipModal({
    super.key,
    required this.penitip,
    required this.onPenitipUpdated,
  });

  @override
  State<EditPenitipModal> createState() => _EditPenitipModalState();
}

class _EditPenitipModalState extends State<EditPenitipModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _commissionController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.penitip.name);
    _phoneController =
        TextEditingController(text: widget.penitip.phoneNumber ?? '');
    _commissionController = TextEditingController(
        text: widget.penitip.commissionRate.toString());
    _addressController =
        TextEditingController(text: widget.penitip.address ?? '');
    _notesController = TextEditingController(text: widget.penitip.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _commissionController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final updated = widget.penitip.copyWith(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        commissionRate:
            int.tryParse(_commissionController.text.trim()) ?? 10,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      widget.onPenitipUpdated(updated);
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
                      'Edit Profil Mitra Penitip',
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

                // Nama Mitra
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Mitra Penitip',
                    hintText: 'Contoh: Bu Siti (Dapur Rasa)',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.person_rounded, size: 20),
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
                      val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                // Nomor WhatsApp & Komisi
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'No. WhatsApp / HP',
                          hintText: '081234567890',
                          filled: true,
                          fillColor: AppColors.background,
                          prefixIcon: const Icon(Icons.phone_rounded, size: 20),
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
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _commissionController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Fee Toko (%)',
                          hintText: '10',
                          filled: true,
                          fillColor: AppColors.background,
                          prefixIcon: const Icon(Icons.percent_rounded, size: 18),
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
                const SizedBox(height: 12),

                // Alamat / Asal Dapur
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Alamat / Lokasi Dapur (Opsional)',
                    hintText: 'Contoh: Jl. Kenanga No. 12, RT 02/05',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
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

                // Catatan Khusus
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Catatan Titipan (Opsional)',
                    hintText: 'Misal: Titipan diantar setiap jam 06.30 pagi',
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.notes_rounded, size: 20),
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
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: const Text('Simpan Perubahan Mitra'),
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
