import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/game_controller.dart';
import 'game_screen.dart';

/// Preset skor umum per cabang olahraga -- mengisi otomatis
/// maxScore & useDeuce saat dipilih, tapi user tetap bisa override
/// manual lewat TextField (pilihan chip akan otomatis ter-nonaktif
/// kalau nilainya sudah tidak cocok lagi dengan preset).
class _SportPreset {
  final String label;
  final IconData icon;
  final int maxScore;
  final bool useDeuce;
  final String? subtitle;

  const _SportPreset({
    required this.label,
    required this.icon,
    required this.maxScore,
    required this.useDeuce,
    this.subtitle,
  });
}

const List<_SportPreset> _sportPresets = [
  _SportPreset(
    label: 'Badminton',
    icon: Icons.sports_tennis,
    maxScore: 21,
    useDeuce: true,
    subtitle: '21 poin, deuce aktif',
  ),
  _SportPreset(
    label: 'Voli',
    icon: Icons.sports_volleyball,
    maxScore: 25,
    useDeuce: true,
    subtitle: '25 poin, deuce aktif',
  ),
  _SportPreset(
    label: 'Sepak Bola',
    icon: Icons.sports_soccer,
    maxScore: 9999,
    useDeuce: false,
    subtitle: 'Tanpa batas skor, tanpa deuce',
  ),
];

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _maxScoreController =
      TextEditingController(text: '11');
  final TextEditingController _player1Controller =
      TextEditingController(text: 'Pemain 1');
  final TextEditingController _player2Controller =
      TextEditingController(text: 'Pemain 2');

  bool _useDeuce = true;
  String? _errorText;

  @override
  void dispose() {
    _maxScoreController.dispose();
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  /// Cek apakah preset ini yang sedang aktif, dibandingkan dari nilai
  /// TextField & switch saat ini -- dipakai buat highlight chip tanpa
  /// perlu nyimpen state index terpisah.
  bool _isPresetActive(_SportPreset preset) {
    final current = int.tryParse(_maxScoreController.text.trim());
    return current == preset.maxScore && _useDeuce == preset.useDeuce;
  }

  void _applyPreset(_SportPreset preset) {
    setState(() {
      _maxScoreController.text = preset.maxScore.toString();
      _useDeuce = preset.useDeuce;
      _errorText = null;
    });
  }

  void _startGame() {
    final input = int.tryParse(_maxScoreController.text.trim());

    if (input == null || input <= 0) {
      setState(() => _errorText = 'Masukkan angka lebih besar dari 0');
      return;
    }

    final p1 = _player1Controller.text.trim().isEmpty
        ? 'Pemain 1'
        : _player1Controller.text.trim();
    final p2 = _player2Controller.text.trim().isEmpty
        ? 'Pemain 2'
        : _player2Controller.text.trim();

    setState(() => _errorText = null);

    context.read<GameController>().setMaxScoreAndStart(
          input,
          player1Name: p1,
          player2Name: p2,
          useDeuce: _useDeuce,
        );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Setting Pertandingan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background asli tetap dipakai.
          Image.asset(
            'assets/images/bg_main_menu.png',
            fit: BoxFit.cover,
          ),
          // Gradient overlay gelap -> supaya teks & card putih di
          // atasnya tetap kebaca jelas, tanpa mengganti gambarnya.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.25),
                  Colors.black.withOpacity(0.65),
                ],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 90, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel(
                          icon: Icons.emoji_events_outlined,
                          text: 'Pilih Jenis Olahraga',
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Isi otomatis skor target & deuce sesuai kebiasaan.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _sportPresets.map((preset) {
                            final active = _isPresetActive(preset);
                            return ChoiceChip(
                              selected: active,
                              onSelected: (_) => _applyPreset(preset),
                              avatar: Icon(
                                preset.icon,
                                size: 18,
                                color: active
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              label: Text(preset.label),
                              labelStyle: TextStyle(
                                color: active ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                              selectedColor: Theme.of(context).colorScheme.primary,
                              backgroundColor: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: active
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel(
                          icon: Icons.people_alt_outlined,
                          text: 'Nama Pemain',
                        ),
                        const SizedBox(height: 12),
                        _ModernTextField(
                          controller: _player1Controller,
                          label: 'Pemain 1',
                          icon: Icons.circle,
                          iconColor: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 12),
                        _ModernTextField(
                          controller: _player2Controller,
                          label: 'Pemain 2',
                          icon: Icons.circle,
                          iconColor: Colors.red.shade600,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel(
                          icon: Icons.flag_outlined,
                          text: 'Skor Maksimum',
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pemain yang lebih dulu mencapai angka ini akan menang.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _maxScoreController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (_) => setState(() {}), // refresh highlight chip
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            errorText: _errorText,
                            hintText: 'mis. 11, 21, 25',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Aktifkan Deuce',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Skor imbang di (maks-1) harus menang selisih 2 poin.',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: _useDeuce,
                          onChanged: (val) => setState(() => _useDeuce = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Mulai Pertandingan',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card "glass" putih semi-transparan dengan rounded corner besar,
/// dipakai berulang untuk tiap section form -- biar konten tetap
/// kebaca jelas di atas background image + gradient.
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SectionLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        labelText: label,
        prefixIcon: Icon(icon, size: 14, color: iconColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}