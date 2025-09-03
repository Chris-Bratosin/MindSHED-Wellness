import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// add this import so we can navigate explicitly to Activities
import 'activities_screen.dart';

class GuidedBreathingScreen extends StatefulWidget {
  const GuidedBreathingScreen({super.key});

  @override
  State<GuidedBreathingScreen> createState() => _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends State<GuidedBreathingScreen>
    with SingleTickerProviderStateMixin {
  // ---------- palette ----------
  static const cream = Color(0xFFFFF9DA);
  static const mint = Color(0xFFB6FFB1);
  static const panel = Color(0xFFE6F3FF);
  static const textBlack = Colors.black;

  // ---------- state ----------
  int meditationDuration = 60; // seconds
  int secondsLeft = 60;

  String? _selectedSound;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Timer? _timer;
  bool _sessionActive = false; // controls overlay + dimming

  // 4-4-4-4 box breathing
  final int _inhale = 4;
  final int _hold1 = 4;
  final int _exhale = 4;
  final int _hold2 = 4;
  int _phase = 0; // 0: inhale, 1: hold, 2: exhale, 3: hold
  int _phaseTick = 0;

  // simple scale pulse for the circle
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    secondsLeft = meditationDuration;

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _pulse.dispose();
    super.dispose();
  }

  // ---------- navigation/back handling ----------
  void _goBack() {
    // stop overlay + audio if running
    if (_sessionActive) _stop();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // if there is no previous route, go to Activities
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ActivitiesScreen()),
      );
    }
  }

  // ---------- logic ----------
  void _adjustTime(int delta) {
    setState(() {
      meditationDuration = (meditationDuration + delta).clamp(10, 3600);
      secondsLeft = meditationDuration;
    });
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _selectSound(String s) async {
    if (_selectedSound == s) return;
    setState(() => _selectedSound = s);
    if (_sessionActive) await _playAudio(); // if running, switch immediately
  }

  String _assetFor(String sound) {
    switch (sound) {
      case 'Light Rain':
        return 'ambient/lr.mp3';
      case 'Heavy Rain':
        return 'ambient/hr.mp3';
      case 'Warm Fireplace':
        return 'ambient/c.mp3';
      case 'White Noise':
        return 'ambient/w.mp3';
      case 'Ocean Waves':
        return 'ambient/o.mp3';
      default:
        return '';
    }
  }

  Future<void> _playAudio() async {
    if (_selectedSound == null) return;
    final path = _assetFor(_selectedSound!);
    if (path.isEmpty) return;
    await _audioPlayer.stop();
    await _audioPlayer.setSource(AssetSource(path));
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource(path));
  }

  void _start() {
    if (_selectedSound == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an ambient sound first')),
      );
      return;
    }
    setState(() {
      _sessionActive = true;
      secondsLeft = meditationDuration;
      _phase = 0;
      _phaseTick = 0;
    });
    _playAudio();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsLeft <= 0) {
        _stop();
        return;
      }
      setState(() {
        secondsLeft--;
        _phaseTick++;

        // 4-4-4-4 cycle
        if (_phase == 0 && _phaseTick >= _inhale) {
          _phase = 1;
          _phaseTick = 0;
        } else if (_phase == 1 && _phaseTick >= _hold1) {
          _phase = 2;
          _phaseTick = 0;
        } else if (_phase == 2 && _phaseTick >= _exhale) {
          _phase = 3;
          _phaseTick = 0;
        } else if (_phase == 3 && _phaseTick >= _hold2) {
          _phase = 0;
          _phaseTick = 0;
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    _audioPlayer.pause();
    setState(() {
      _sessionActive = false;
    });
  }

  String get _phaseLabel {
    switch (_phase) {
      case 0:
        return 'Inhale...';
      case 1:
        return 'Hold...';
      case 2:
        return 'Exhale...';
      case 3:
        return 'Hold...';
      default:
        return 'Inhale...';
    }
  }

  Color get _ringColor {
    switch (_phase) {
      case 0:
        return const Color(0xFF48A9F8); // inhale blue
      case 1:
        return const Color(0xFF60D394); // hold green
      case 2:
        return const Color(0xFF9B5DE5); // exhale purple
      case 3:
        return const Color(0xFFFFB6C1); // hold pink
      default:
        return const Color(0xFF48A9F8);
    }
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final baseText = Theme.of(context).textTheme.bodyMedium;

    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false; // we handled back
      },
      child: Scaffold(
        backgroundColor: cream,
        body: SafeArea(
          child: Stack(
            children: [
              // base content
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _sessionActive ? 0.25 : 1,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _pillHeader('Guided Breathing'),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'This is your moment to relax\nand recharge',
                        textAlign: TextAlign.center,
                        style: baseText?.copyWith(
                          fontFamily: 'HappyMonkey',
                          color: textBlack,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _timerCard(),
                    const SizedBox(height: 14),
                    _soundPanel(baseText),
                    const SizedBox(height: 16),

                    Center(child: _mintButton('Start', _start)),
                    const SizedBox(height: 16),
                    Center(child: _mintButton('Back', _goBack)),
                  ],
                ),
              ),

              // overlay (session)
              if (_sessionActive) _breathingOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pillHeader(String title) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: Text(
          title,
          style: const TextStyle(fontFamily: 'HappyMonkey', fontSize: 22, color: Colors.black),
        ),
      ),
    );
  }

  Widget _timerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF1EEDB),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Center(
              child: Text(
                _fmt(secondsLeft),
                style: const TextStyle(
                  fontFamily: 'HappyMonkey',
                  fontSize: 36,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _soundPanel(TextStyle? baseText) {
    final sounds = const [
      'Light Rain',
      'Heavy Rain',
      'Warm Fireplace',
      'White Noise',
      'Ocean Waves',
    ];

    return Container(
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          const Text(
            'Select Ambient Music',
            style: TextStyle(fontFamily: 'HappyMonkey', fontSize: 16, color: Colors.black),
          ),
          const SizedBox(height: 10),
          ...sounds.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _chipButton(
              label: s,
              selected: _selectedSound == s,
              onTap: () => _selectSound(s),
            ),
          )),
          const SizedBox(height: 10),

          // Seconds adjuster & selected sound label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconBadge(Icons.remove, onTap: () => _adjustTime(-10)),
              const SizedBox(width: 12),
              Text(
                _fmt(meditationDuration),
                style: const TextStyle(fontFamily: 'HappyMonkey', fontSize: 22, color: Colors.black),
              ),
              const SizedBox(width: 12),
              _iconBadge(Icons.add, onTap: () => _adjustTime(10)),
            ],
          ),
          const SizedBox(height: 10),
          if (_selectedSound != null) _chipLabel(label: _selectedSound!),
        ],
      ),
    );
  }

  // ---------- overlay ----------
  Widget _breathingOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          color: Colors.black38,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _ringColor, width: 10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _phaseLabel,
                      style: const TextStyle(
                        fontFamily: 'HappyMonkey',
                        fontSize: 22,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                // close
                Positioned(
                  right: 24,
                  top: 24,
                  child: Material(
                    shape: const CircleBorder(side: BorderSide(color: Colors.black, width: 2)),
                    color: Colors.white,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _stop,
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.close, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- small UI helpers ----------
  Widget _mintButton(String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _chipButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? mint : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: const Offset(0, 2))],
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'HappyMonkey',
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBadge(IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: Colors.black, width: 2)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.black),
        ),
      ),
    );
  }

  Widget _chipLabel({required String label}) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3, offset: const Offset(0, 2))],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'HappyMonkey',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
