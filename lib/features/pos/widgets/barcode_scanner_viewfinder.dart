import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';

class BarcodeScannerViewfinder extends StatefulWidget {
  final VoidCallback onSimulateScan;
  final Function(String barcode)? onBarcodeScanned;

  const BarcodeScannerViewfinder({
    super.key,
    required this.onSimulateScan,
    this.onBarcodeScanned,
  });

  @override
  State<BarcodeScannerViewfinder> createState() =>
      _BarcodeScannerViewfinderState();
}

class _BarcodeScannerViewfinderState extends State<BarcodeScannerViewfinder>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  bool _isTorchOn = false;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    final now = DateTime.now();
    // Debounce scan events by 1.5 seconds
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < 1500) {
      return;
    }

    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final rawValue = barcodes.first.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        _lastScanTime = now;
        if (widget.onBarcodeScanned != null) {
          widget.onBarcodeScanned!(rawValue);
        } else {
          widget.onSimulateScan();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onSimulateScan,
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.border,
              width: 1.2,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Live Hardware Camera Viewfinder via MobileScanner
              MobileScanner(
                controller: _scannerController,
                onDetect: _handleBarcode,
                errorBuilder: (context, error) {
                  return Container(
                    color: const Color(0xFF1E293B),
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            size: 44,
                            color: Colors.white60,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kamera belum diizinkan atau tidak tersedia',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ketuk layar untuk simulasi pindai',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                placeholderBuilder: (context) {
                  return Container(
                    color: const Color(0xFF0F172A),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),

              // Dark Vignette Overlay for focus
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.45),
                    ],
                  ),
                ),
              ),

              // 2. Corner Bracket Scanner Frame Overlay
              Center(
                child: SizedBox(
                  width: 220,
                  height: 150,
                  child: Stack(
                    children: [
                      // Top-Left Corner Bracket
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _buildCorner(top: true, left: true),
                      ),
                      // Top-Right Corner Bracket
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildCorner(top: true, left: false),
                      ),
                      // Bottom-Left Corner Bracket
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _buildCorner(top: false, left: true),
                      ),
                      // Bottom-Right Corner Bracket
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _buildCorner(top: false, left: false),
                      ),

                      // Animated Laser Line
                      AnimatedBuilder(
                        animation: _laserAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 150 * _laserAnimation.value,
                            left: 10,
                            right: 10,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.9),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Top Controls (LIVE Indicator, Flash, Camera Switch)
              Positioned(
                top: 12,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // LIVE Camera Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'KAMERA AKTIF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [
                        // Flash / Senter Toggle
                        InkWell(
                          onTap: () async {
                            await _scannerController.toggleTorch();
                            setState(() {
                              _isTorchOn = !_isTorchOn;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _isTorchOn
                                  ? AppColors.primary
                                  : Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Icon(
                              _isTorchOn
                                  ? Icons.flash_on_rounded
                                  : Icons.flash_off_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Switch Front / Back Camera
                        InkWell(
                          onTap: () async {
                            await _scannerController.switchCamera();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Icon(
                              Icons.cameraswitch_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 4. Bottom Instruction Pill
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 13,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Arahkan kamera ke barcode makanan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    const double length = 24.0;
    const double thickness = 3.5;
    const radius = Radius.circular(8);

    return Container(
      width: length,
      height: length,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: AppColors.primary, width: thickness)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: AppColors.primary, width: thickness)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: AppColors.primary, width: thickness)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: AppColors.primary, width: thickness)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? radius : Radius.zero,
          topRight: top && !left ? radius : Radius.zero,
          bottomLeft: !top && left ? radius : Radius.zero,
          bottomRight: !top && !left ? radius : Radius.zero,
        ),
      ),
    );
  }
}


