import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/ronda/models/ronda_models.dart';
import '../../../../providers/ronda_provider.dart';

/// Pemindai QR kamera untuk memverifikasi penyelesaian insiden SOS.
class SosQrScannerDialog extends StatefulWidget {
  const SosQrScannerDialog({
    super.key,
    required this.ronda,
    required this.event,
  });

  final RondaProvider ronda;
  final EmergencyEvent event;

  static Future<bool?> show(
      BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SosQrScannerDialog(ronda: ronda, event: event),
    );
  }

  @override
  State<SosQrScannerDialog> createState() => _SosQrScannerDialogState();
}

class _SosQrScannerDialogState extends State<SosQrScannerDialog> {
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _tokenInputController = TextEditingController();
  bool _isProcessing = false;
  bool _isTorchOn = false;
  String? _errorMessage;

  @override
  void dispose() {
    _scannerController.dispose();
    _tokenInputController.dispose();
    super.dispose();
  }

  void _processScannedPayload(String payload) {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final success = widget.ronda.resolveEmergencyWithQr(
      eventId: widget.event.id,
      scannedQrPayload: payload.trim(),
    );

    if (success) {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _isProcessing = false;
      _errorMessage =
          widget.ronda.lastErrorMessage ?? 'QR tidak valid untuk insiden ini.';
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final payload = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (payload.isNotEmpty) _processScannedPayload(payload);
  }

  Future<void> _toggleTorch() async {
    try {
      await _scannerController.toggleTorch();
      if (mounted) {
        setState(() => _isTorchOn = !_isTorchOn);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Senter kamera tidak tersedia.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: theme.colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
              child: Row(
                children: [
                  const Icon(Icons.qr_code_scanner,
                      color: AppColors.patrolAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Pindai QR Warga Pelapor',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    tooltip: 'Senter kamera',
                    onPressed: _toggleTorch,
                    icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 250,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                    errorBuilder: (context, error, child) => ColoredBox(
                      color: Colors.black87,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Kamera tidak dapat dibuka. Periksa izin kamera atau masukkan token QR secara manual.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: theme.colorScheme.onInverseSurface),
                          ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        width: 210,
                        height: 170,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: AppColors.patrolAccent, width: 3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Text(
                      'Arahkan kamera ke QR pada perangkat warga',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 4)]),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Insiden ${widget.event.userName}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(_errorMessage!,
                          style: const TextStyle(
                              color: AppColors.emergency, fontSize: 12)),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _tokenInputController,
                      enabled: !_isProcessing,
                      decoration: const InputDecoration(
                        labelText: 'Masukkan token QR',
                        hintText: 'Pindai QR atau tempel token di sini',
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: _isProcessing
                          ? null
                          : () => _processScannedPayload(
                              _tokenInputController.text),
                      icon: _isProcessing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.verified_outlined),
                      label: Text(_isProcessing
                          ? 'Memverifikasi…'
                          : 'Verifikasi Token'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
