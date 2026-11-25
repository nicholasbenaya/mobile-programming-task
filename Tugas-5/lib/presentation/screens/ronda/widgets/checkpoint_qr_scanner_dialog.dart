import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/ronda/models/ronda_models.dart';

/// Memindai payload QR checkpoint dinamis menggunakan kamera perangkat.
class CheckpointQrScannerDialog extends StatefulWidget {
  const CheckpointQrScannerDialog({super.key, required this.checkpoint});

  final Checkpoint checkpoint;

  static Future<String?> scan(BuildContext context, Checkpoint checkpoint) {
    return showDialog<String>(
      context: context,
      builder: (_) => CheckpointQrScannerDialog(checkpoint: checkpoint),
    );
  }

  @override
  State<CheckpointQrScannerDialog> createState() =>
      _CheckpointQrScannerDialogState();
}

class _CheckpointQrScannerDialogState extends State<CheckpointQrScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final TextEditingController _payloadController = TextEditingController();
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    _payloadController.dispose();
    super.dispose();
  }

  void _returnPayload(String payload) {
    final value = payload.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: AppColors.secondary),
          const SizedBox(width: 8),
          Expanded(child: Text('Pindai QR ${widget.checkpoint.kodeTitik}')),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.checkpoint.namaLokasi,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _controller,
                        onDetect: (capture) {
                          final payload = capture.barcodes
                              .map((barcode) => barcode.rawValue)
                              .whereType<String>()
                              .firstWhere((value) => value.isNotEmpty,
                                  orElse: () => '');
                          _returnPayload(payload);
                        },
                        errorBuilder: (context, error, child) =>
                            const ColoredBox(
                          color: Colors.black87,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Kamera tidak tersedia. Masukkan payload QR pos secara manual.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 210,
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.patrolAccent, width: 3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: IconButton.filledTonal(
                          tooltip: 'Senter',
                          onPressed: () async {
                            await _controller.toggleTorch();
                            if (mounted) setState(() => _torchOn = !_torchOn);
                          },
                          icon:
                              Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _payloadController,
                decoration: const InputDecoration(
                  labelText: 'Payload QR (opsional)',
                  hintText: 'RONDA|v1|…',
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        FilledButton.icon(
          onPressed: () => _returnPayload(_payloadController.text),
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Gunakan QR'),
        ),
      ],
    );
  }
}
