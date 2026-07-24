import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/attendance_provider.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  late AnimationController _successController;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);
    final notifier = ref.read(attendanceProvider.notifier);

    if (_showSuccess || state.scanSuccess == true) {
      return _buildSuccessView(context, state);
    }

    if (state.scanSuccess == false) {
      return _buildErrorView(context, state, notifier);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Absensi'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController ??
                MobileScannerController(
                  detectionSpeed: DetectionSpeed.noDuplicates,
                  returnImage: false,
                ),
            onDetect: (capture) {
              if (_isProcessing) return;
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue == null) return;

              _isProcessing = true;
              HapticFeedback.heavyImpact();

              final token = barcode!.rawValue!;
              notifier.scanQr(token);
            },
          ),
          _buildScanOverlay(context),
          if (state.isLoading)
            Container(color: Colors.black26, child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanSize = size.width * 0.7;

    return CustomPaint(
      size: size,
      painter: _ScanOverlayPainter(scanSize: scanSize),
      child: Center(
        child: Container(
          width: scanSize,
          height: scanSize,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Arahkan ke QR Code',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, AttendanceState state) {
    _successController.forward();
    if (!_showSuccess) {
      _showSuccess = true;
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          ref.read(attendanceProvider.notifier).resetScanSuccess();
          Navigator.of(context).pop();
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.success,
      body: Center(
        child: AnimatedBuilder(
          animation: _successController,
          builder: (context, _) {
            return Transform.scale(
              scale: 0.5 + _successController.value * 0.5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.success,
                      size: 56,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Absensi Tercatat!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.scanMessage ?? 'Selamat belajar!',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mengalihkan kembali...',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    AttendanceState state,
    AttendanceNotifier notifier,
  ) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Absensi'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text(
                'Gagal!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.scanMessage ?? 'QR tidak valid atau sudah kedaluwarsa',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  notifier.resetScanSuccess();
                  _isProcessing = false;
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  final double scanSize;

  _ScanOverlayPainter({required this.scanSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final dx = (size.width - scanSize) / 2;
    final dy = (size.height - scanSize) / 2 - 40;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, dy), paint);
    canvas.drawRect(
      Rect.fromLTWH(0, dy + scanSize, size.width, size.height - dy - scanSize),
      paint,
    );
    canvas.drawRect(Rect.fromLTWH(0, dy, dx, scanSize), paint);
    canvas.drawRect(
      Rect.fromLTWH(dx + scanSize, dy, size.width - dx - scanSize, scanSize),
      paint,
    );

    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.0;
    canvas.drawLine(
      Offset(dx, dy + cornerLength),
      Offset(dx, dy),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(dx, dy),
      Offset(dx + cornerLength, dy),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(dx + scanSize - cornerLength, dy),
      Offset(dx + scanSize, dy),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(dx + scanSize, dy),
      Offset(dx + scanSize, dy + cornerLength),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(dx, dy + scanSize - cornerLength),
      Offset(dx, dy + scanSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(dx, dy + scanSize),
      Offset(dx + cornerLength, dy + scanSize),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(dx + scanSize - cornerLength, dy + scanSize),
      Offset(dx + scanSize, dy + scanSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(dx + scanSize, dy + scanSize - cornerLength),
      Offset(dx + scanSize, dy + scanSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
