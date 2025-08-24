import 'package:flutter/material.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class GuidedBreathingScreen extends StatefulWidget {
  const GuidedBreathingScreen({Key? key}) : super(key: key);

  @override
  _GuidedBreathingScreenState createState() => _GuidedBreathingScreenState();
}

class _GuidedBreathingScreenState extends State<GuidedBreathingScreen> {
  int seconds = 0;
  int meditationDuration = 60;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _selectedSound;
  bool _isPlaying = false;
  bool _isInhaling = true;
  int _breathingPhase = 0; // 0: inhale, 1: hold, 2: exhale, 3: hold
  int _phaseTimer = 0;

  // Proven Box Breathing pattern (4-4-4-4) - used by Navy SEALs and clinically proven
  // Inhale 4s, Hold 4s, Exhale 4s, Hold 4s - creates a smooth, balanced rhythm
  final int _inhaleTime = 4;
  final int _holdAfterInhale = 4;
  final int _exhaleTime = 4;
  final int _holdAfterExhale = 4;

  void _startTimer() {
    if (_selectedSound == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an ambient sound first!")),
      );
      return;
    }
    _timer?.cancel();
    _isPlaying = true;
    seconds = meditationDuration;
    _breathingPhase = 0;
    _isInhaling = true;
    _phaseTimer = 0;
    _playAudio();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds > 0) {
        setState(() {
          seconds--;
          _phaseTimer++;

          // Update breathing phase based on Box Breathing timing
          if (_breathingPhase == 0 && _phaseTimer >= _inhaleTime) {
            _breathingPhase = 1; // Hold after inhale
            _phaseTimer = 0;
            _isInhaling = false;
          } else if (_breathingPhase == 1 && _phaseTimer >= _holdAfterInhale) {
            _breathingPhase = 2; // Exhale
            _phaseTimer = 0;
            _isInhaling = false;
          } else if (_breathingPhase == 2 && _phaseTimer >= _exhaleTime) {
            _breathingPhase = 3; // Hold after exhale
            _phaseTimer = 0;
            _isInhaling = false;
          } else if (_breathingPhase == 3 && _phaseTimer >= _holdAfterExhale) {
            _breathingPhase = 0; // Back to inhale
            _phaseTimer = 0;
            _isInhaling = true;
          }
        });
      } else {
        _pauseTimer();
      }
    });
    setState(() {});
  }

  void _pauseTimer() {
    if (_isPlaying) {
      setState(() => _isPlaying = false);
      _timer?.cancel();
      _audioPlayer.pause();
    }
  }

  void _adjustMeditationTime(int adjustment) {
    setState(() {
      meditationDuration = (meditationDuration + adjustment).clamp(10, 3600);
      seconds = meditationDuration;
    });
  }

  Future<void> _playAudio() async {
    if (_selectedSound == null) return;
    String audioPath = _getAudioPath(_selectedSound!);
    if (audioPath.isEmpty) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSource(AssetSource(audioPath));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource(audioPath));
    } catch (e) {
      print("Error loading audio: $audioPath - $e");
    }
  }

  void _changeSound(String sound) async {
    if (_selectedSound != sound) {
      setState(() {
        _selectedSound = sound;
      });
      if (_isPlaying) {
        await _playAudio();
      }
    }
  }

  String _getAudioPath(String sound) {
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

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _getBreathingInstruction() {
    switch (_breathingPhase) {
      case 0:
        return "Inhale";
      case 1:
        return "Hold";
      case 2:
        return "Exhale";
      case 3:
        return "Hold";
      default:
        return "Inhale";
    }
  }

  Color _getCircleColor() {
    switch (_breathingPhase) {
      case 0:
        return const Color(0xFF87CEEB); // Light blue for inhale
      case 1:
        return const Color(0xFF98FB98); // Light green for hold
      case 2:
        return const Color(0xFFDDA0DD); // Light purple for exhale
      case 3:
        return const Color(0xFFFFB6C1); // Light pink for hold
      default:
        return const Color(0xFF87CEEB);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 18.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double containerWidth = MediaQuery.of(context).size.width * 0.85;

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            "This is your moment to relax\nand recharge",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'HappyMonkey',
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 15),

          // Play/Pause button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 50,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: _isPlaying ? _pauseTimer : _startTimer,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Timer display
          Container(
            width: containerWidth,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.black),
                  onPressed: () => _adjustMeditationTime(-10),
                ),
                Text(
                  _formatTime(seconds),
                  style: TextStyle(
                    fontSize: fontSize + 10,
                    fontFamily: 'Digital',
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.black),
                  onPressed: () => _adjustMeditationTime(10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main content area - either music selection or breathing circle
          if (!_isPlaying || _selectedSound == null) ...[
            // Ambient music selection
            Container(
              width: containerWidth,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade300,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    "Select Ambient Music",
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'HappyMonkey',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...[
                    "Light Rain",
                    "Heavy Rain",
                    "Warm Fireplace",
                    "White Noise",
                    "Ocean Waves"
                  ]
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? (_selectedSound == e
                                        ? Colors.blueGrey
                                        : const Color(0xFF1E1E1E))
                                    : (_selectedSound == e
                                        ? Colors.blueGrey
                                        : Colors.grey[300]),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                      color: Colors.black, width: 2),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _changeSound(e),
                              child: Text(
                                e,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'HappyMonkey',
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ] else ...[
            // Breathing circle when session is active
            Container(
              width: containerWidth,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade300,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                children: [
                  Text(
                    "Current Sound: $_selectedSound",
                    style: TextStyle(
                      fontSize: fontSize,
                      fontFamily: 'HappyMonkey',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Breathing circle
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: _getCircleColor(),
                        width: 8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getBreathingInstruction(),
                        style: TextStyle(
                          fontSize: fontSize + 8,
                          fontFamily: 'HappyMonkey',
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Follow the breathing pattern",
                    style: TextStyle(
                      fontSize: fontSize - 2,
                      fontFamily: 'HappyMonkey',
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
