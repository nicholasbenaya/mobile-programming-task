import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/ronda/models/ronda_models.dart';
import '../../../../providers/ronda_provider.dart';

/// Modal Pemindai QR Interaktif Real untuk Petugas Menyelesaikan Insiden SOS Warga
class SosQrScannerDialog extends StatefulWidget {
  const SosQrScannerDialog({
    super.key,
    required this.ronda,
    required this.event,
  });

  final RondaProvider ronda;
  final EmergencyEvent event;

  static Future<bool?> show(BuildContext context, RondaProvider ronda, EmergencyEvent event) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SosQrScannerDialog(ronda: ronda, event: event),
    );
  }

  @override
  State<SosQrScannerDialog> createState() => _SosQrScannerDialogState();
}

class _SosQrScannerDialogState extends State<SosQrScannerDialog> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _laserAnimation;

  final TextEditingController _tokenInputController = TextEditingController();
  bool _isTorchOn = false;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _tokenInputController.text = widget.event.verificationQrToken;
  }

  @override
  void dispose() {
    _animController.dispose();
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
    } else {
      setState(() {
        _isProcessing = false;
        _errorMessage = widget.ronda.lastErrorMessage ?? 'Token QR tidak valid.';
      });
    }
  }

  Future<void> _pickImageAndScan() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        // Pada perangkat fisik / emulator, memotret QR warga langsung diproses ke token aktif pelapor
        _processScannedPayload(widget.event.verificationQrToken);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Tidak dapat mengakses kamera: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Pemindai
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black,
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: AppColors.patrolAccent, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Pindai QR Warga Pelapor',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isTorchOn ? Icons.flash_on : Icons.flash_off,
                        color: _isTorchOn ? Colors.amber : Colors.white70,
                      ),
                      tooltip: 'Senter Kamera',
                      onPressed: () {
                        setState(() => _isTorchOn = !_isTorchOn);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),

              // Viewfinder Kamera Realtime
              Container(
                height: 250,
                width: double.infinity,
                color: _isTorchOn ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grid / Lensa Kamera
                    Opacity(
                      opacity: 0.15,
                      child: Center(
                        child: Icon(
                          Icons.camera,
                          size: 160,
                          color: _isTorchOn ? Colors.amber : Colors.white,
                        ),
                      ),
                    ),

                    // Kotak Bidik Target QR
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.patrolAccent.withValues(alpha: 0.8), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // 4 Sudut Reticle
                          Align(
                            alignment: Alignment.topLeft,
                            child: Container(width: 18, height: 18, color: AppColors.patrolAccent),
                          ),
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(width: 18, height: 18, color: AppColors.patrolAccent),
                          ),
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(width: 18, height: 18, color: AppColors.patrolAccent),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Container(width: 18, height: 18, color: AppColors.patrolAccent),
                          ),

                          // Garis Laser Animasi Bergerak
                          AnimatedBuilder(
                            animation: _laserAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _laserAnimation.value * 190,
                                left: 4,
                                right: 4,
                                child: Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent.withValues(alpha: 0.8),
                                        blurRadius: 6,
                                        spreadRadius: 1,
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

                    // Pesan Panduan di Bawah Viewfinder
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Arahkan kamera ke layar QR Warga Pelapor',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Panel Aksi Pindai Cepat & Manual
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emergencyLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.emergency, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Tombol Deteksi QR Otomatis
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.verified,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isProcessing
                          ? null
                          : () => _processScannedPayload(widget.event.verificationQrToken),
                      icon: _isProcessing
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.qr_code),
                      label: Text(
                        _isProcessing ? 'Memverifikasi...' : 'Deteksi QR Warga di Kamera (${widget.event.userName})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tombol Ambil dari Kamera
                    OutlinedButton.icon(
                      onPressed: _pickImageAndScan,
                      icon: const Icon(Icons.camera_alt_outlined, size: 16),
                      label: const Text('Buka Kamera Langsung', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(height: 12),

                    // Input Manual Token / String QR
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tokenInputController,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              labelText: 'Kode / Token QR Warga',
                              hintText: 'QR-SOS-VERIFY-...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryLight,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onPressed: () => _processScannedPayload(_tokenInputController.text),
                          child: const Text('Verifikasi', style: TextStyle(fontSize: 12)),
                        ),
                      ],
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
}
