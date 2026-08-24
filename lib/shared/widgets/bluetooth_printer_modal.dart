import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/services/bluetooth_printer_service.dart';

class BluetoothPrinterModal extends StatefulWidget {
  final VoidCallback? onConnected;

  const BluetoothPrinterModal({
    super.key,
    this.onConnected,
  });

  static Future<bool?> show(BuildContext context, {VoidCallback? onConnected}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BluetoothPrinterModal(onConnected: onConnected),
    );
  }

  @override
  State<BluetoothPrinterModal> createState() => _BluetoothPrinterModalState();
}

class _BluetoothPrinterModalState extends State<BluetoothPrinterModal> {
  bool _isLoading = true;
  bool _isScanning = false;
  bool _isConnecting = false;
  bool _isTesting = false;
  bool _isBtEnabled = true;
  String? _connectingMac;
  List<BluetoothInfo> _devices = [];
  String? _connectedMac;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await _checkBtStatus();
    await _loadDevices();
    await _checkCurrentConnection();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkBtStatus() async {
    final enabled = await BluetoothPrinterService.isBluetoothEnabled();
    if (mounted) {
      setState(() => _isBtEnabled = enabled);
    }
  }

  Future<void> _checkCurrentConnection() async {
    final isConn = await BluetoothPrinterService.checkConnection();
    if (mounted) {
      setState(() {
        if (isConn && BluetoothPrinterService.selectedDevice != null) {
          _connectedMac = BluetoothPrinterService.selectedDevice!.macAdress;
        } else {
          _connectedMac = null;
        }
      });
    }
  }

  Future<void> _loadDevices() async {
    setState(() => _isScanning = true);
    try {
      final devices = await BluetoothPrinterService.getPairedDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _connectToDevice(BluetoothInfo device) async {
    setState(() {
      _isConnecting = true;
      _connectingMac = device.macAdress;
    });

    final success = await BluetoothPrinterService.connect(device);

    if (mounted) {
      setState(() {
        _isConnecting = false;
        _connectingMac = null;
        if (success) {
          _connectedMac = device.macAdress;
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Berhasil terhubung ke ${device.name.isNotEmpty ? device.name : "Printer"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
        widget.onConnected?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(
              'Gagal menghubungkan ke printer. Pastikan printer menyala dan bluetooth aktif.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _disconnectDevice() async {
    setState(() => _isConnecting = true);
    await BluetoothPrinterService.disconnect();
    if (mounted) {
      setState(() {
        _isConnecting = false;
        _connectedMac = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.textSecondary,
          content: Text('Koneksi printer diputuskan.'),
        ),
      );
    }
  }

  Future<void> _runTestPrint() async {
    setState(() => _isTesting = true);
    final success = await BluetoothPrinterService.testPrint();
    if (mounted) {
      setState(() => _isTesting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Tes cetak berhasil terkirim ke printer thermal!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.danger,
            content: Text('Gagal tes cetak. Pastikan printer terhubung dan ada kertas.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Printer Bluetooth',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Hubungkan printer thermal kasir 58mm',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isScanning ? null : _loadDevices,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded, color: AppColors.primary),
                    tooltip: 'Cari Ulang Printer',
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.divider, height: 1),

            // Warning if Bluetooth is Off
            if (!_isBtEnabled)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bluetooth_disabled_rounded,
                        color: AppColors.danger, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bluetooth HP dalam keadaan Nonaktif. Harap nyalakan Bluetooth di pengaturan HP Anda.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Content List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _devices.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bluetooth_searching_rounded,
                                  size: 56,
                                  color: AppColors.textMuted.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tidak Ada Printer Terdeteksi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Pastikan printer thermal sudah dinyalakan dan dipasangkan (pair) lewat menu Bluetooth di HP Anda.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  style: AppStyles.primaryButtonStyle(),
                                  onPressed: _loadDevices,
                                  icon: const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text('Pindai Ulang'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          itemCount: _devices.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            final isConnected = _connectedMac == device.macAdress;
                            final isThisConnecting =
                                _connectingMac == device.macAdress;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? AppColors.success.withValues(alpha: 0.08)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isConnected
                                      ? AppColors.success
                                      : AppColors.border,
                                  width: isConnected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isConnected
                                          ? AppColors.success.withValues(alpha: 0.15)
                                          : AppColors.divider.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.print_rounded,
                                      color: isConnected
                                          ? AppColors.success
                                          : AppColors.textSecondary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                device.name.isNotEmpty
                                                    ? device.name
                                                    : 'Thermal Printer',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            if (isConnected)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.success,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'TERHUBUNG',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          device.macAdress,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  if (isConnected)
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.danger,
                                        side: const BorderSide(
                                            color: AppColors.danger),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                      ),
                                      onPressed: _isConnecting
                                          ? null
                                          : _disconnectDevice,
                                      child: const Text(
                                        'Putus',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    )
                                  else
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                      ),
                                      onPressed: _isConnecting
                                          ? null
                                          : () => _connectToDevice(device),
                                      child: isThisConnecting
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Sambung',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
            ),

            // Bottom Actions (Test Print & Tutup)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: (_connectedMac != null && !_isTesting)
                          ? _runTestPrint
                          : null,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('Tes Cetak Struk'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: AppStyles.primaryButtonStyle(),
                      onPressed: () => Navigator.pop(context, _connectedMac != null),
                      child: const Text('Selesai'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
