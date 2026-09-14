import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/game_controller.dart';
import 'game_screen.dart';

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
      appBar: AppBar(title: const Text('Setting Pertandingan')),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_main_menu.png'),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Nama Pemain',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _player1Controller,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Pemain 1',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _player2Controller,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Pemain 2',
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Skor Maksimum',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pemain yang lebih dulu mencapai angka ini akan menang.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _maxScoreController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  errorText: _errorText,
                  hintText: 'mis. 11, 21, 100',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Aktifkan Deuce'),
                subtitle: const Text(
                  'Jika skor imbang di angka (maks-1), harus menang selisih 2 poin.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _useDeuce,
                onChanged: (val) => setState(() => _useDeuce = val),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Mulai Pertandingan',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}