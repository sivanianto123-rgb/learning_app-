import 'dart:async';
import '../../utils/common_imports/common_imports.dart';
import '../../widgets/sound_widgets/animated_word.dart';
import '../../widgets/sound_widgets/sound_lottie.dart';
import '../../widgets/sound_widgets/koala_challenge/koala_challenge.dart';
import '../../widgets/back_button.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

const _kBubbleDecoration = BoxDecoration(
  color: Color(0xDFD9D9D9),
  borderRadius: BorderRadius.all(Radius.circular(50)),
  border: Border.fromBorderSide(BorderSide(color: Color(0xFFCCA7DA), width: 6)),
);

const _kAlternatives = <String, List<String>>{
  'mama': ['ma', 'mom', 'mum', 'mommy', 'mamma'],
  'papa': ['pa', 'pop', 'pap', 'poppy', 'daddy'],
  'dada': ['da', 'dad', 'daddy', 'dah'],
  'baba': ['ba', 'bob', 'bab', 'baby'],
  'ooo': ['o', 'oh', 'ooh', 'oo', 'who'],
  'eee': ['e', 'ee', 'eh', 'he', 'hee', 'yeah'],
  'aaaa': ['a', 'aa', 'ah', 'aah', 'ha'],
  'moo': ['mu', 'muu', 'mooo', 'mow'],
  'woof': ['wuf', 'wof', 'oof', 'ruff'],
  'coo': ['cu', 'co', 'coup'],
  'quack': ['quak', 'kwak', 'quac', 'kwack'],
  'hiss': ['his', 'hisss', 'iss'],
};

const _kListenDuration = Duration(seconds: 5);

// Lenient threshold for toddler voices — any genuine phonetic attempt passes.
const _kAccuracyThreshold = 0.40;

class SoundScreen extends StatefulWidget {
  final SoundData soundData;

  const SoundScreen({super.key, required this.soundData});

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  int _currentSyllableIndex = 0;
  bool _isAnimating = false;
  bool _showKoalaChallenge = false;
  bool _isCorrect = false;
  bool _isDisposed = false;
  bool _isNavigating = false;

  // Whether the mic toggle is currently active (baby is speaking).
  bool _isMicActive = false;

  Soundpool? _soundpool;
  int? _soundId;
  int? _streamId;

  final SpeechToText _stt = SpeechToText();
  bool _sttAvailable = false;
  bool _isListening = false;

  // Completed to interrupt _listenForMatch immediately (toggle-off or back).
  Completer<void>? _listenCancelCompleter;

  String _transcript = '';

  double? _cachedScreenHeight;

  int get _audioDurationMs => widget.soundData.syllables.length * 500 + 500;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('lib/assets/images/sound_bg.jpg'), context);
    _cachedScreenHeight = MediaQuery.sizeOf(context).height;
  }

  // ─── Initialisation ──────────────────────────────────────────────────────

  Future<void> _initAll() async {
    await Future.wait([_initAudio(), _initStt()]);
    if (mounted && !_isDisposed) {
      await Future.delayed(const Duration(milliseconds: 300));
      _startSession();
    }
  }

  Future<void> _initAudio() async {
    if (widget.soundData.audioPath.isEmpty) return;
    try {
      _soundpool = Soundpool.fromOptions(
        options: const SoundpoolOptions(streamType: StreamType.music),
      );
      final data = await rootBundle.load(widget.soundData.audioPath);
      _soundId = await _soundpool!.load(data);
    } catch (_) {}
  }

  Future<void> _initStt() async {
    try {
      _sttAvailable = await _stt.initialize(
        onError: (_) {},
        onStatus: (status) {
          if (!mounted || _isDisposed) return;
          if (status == 'listening') {
            _safeSetState(() => _isListening = true);
          } else if (status == 'done' || status == 'notListening') {
            _safeSetState(() => _isListening = false);
          }
        },
      );
    } catch (_) {
      _sttAvailable = false;
    }
  }

  // ─── Session ──────────────────────────────────────────────────────────────

  // Plays the word audio once when the screen opens.
  // Listening is manual — the baby taps the mic button to speak.
  void _startSession() {
    _playAudioAndAnimate();
  }

  // ─── Mic toggle ───────────────────────────────────────────────────────────

  Future<void> _onMicTap() async {
    if (_showKoalaChallenge) return;

    if (_isMicActive) {
      // Toggle OFF — stop listening immediately.
      _stopListening();
      _safeSetState(() => _isMicActive = false);
      return;
    }

    // Toggle ON — stop any currently playing audio first so audio and mic
    // never run simultaneously (AVAudioSession conflict on iOS).
    if (_streamId != null && _streamId! > 0) {
      _soundpool?.stop(_streamId!);
      _streamId = null;
    }
    _safeSetState(() {
      _isMicActive = true;
      _isAnimating = false; // freeze syllable animation while listening
    });

    await _listenForMatch();

    // Listen window expired without a successful match.
    if (!_isDisposed && !_showKoalaChallenge) {
      _safeSetState(() => _isMicActive = false);
    }
  }

  // ─── Speech recognition ──────────────────────────────────────────────────

  Future<void> _listenForMatch() async {
    if (_isDisposed) return;

    _listenCancelCompleter = Completer<void>();

    if (!_sttAvailable) {
      await Future.any([
        Future.delayed(_kListenDuration),
        _listenCancelCompleter!.future,
      ]);
      _listenCancelCompleter = null;
      return;
    }

    final matchCompleter = Completer<void>();

    _stt.listen(
      onResult: (result) {
        if (_isDisposed || _showKoalaChallenge || matchCompleter.isCompleted) {
          return;
        }

        final words = result.recognizedWords;
        final accuracy = _computeAccuracy(result);

        _safeSetState(() => _transcript = words);

        if (accuracy >= _kAccuracyThreshold) {
          _safeSetState(() => _isListening = false);
          try {
            _stt.stop();
          } catch (_) {}
          if (!_isDisposed && !_showKoalaChallenge) {
            _goToKoalaChallenge(correct: true);
          }
          if (!matchCompleter.isCompleted) matchCompleter.complete();
        }
      },
      listenFor: _kListenDuration,
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );

    await Future.any([
      matchCompleter.future,
      _listenCancelCompleter!.future,
      Future.delayed(_kListenDuration),
    ]);

    if (!matchCompleter.isCompleted) matchCompleter.complete();
    _listenCancelCompleter = null;

    if (_isListening) {
      _safeSetState(() => _isListening = false);
      try {
        _stt.stop();
      } catch (_) {}
    }
  }

  void _stopListening() {
    if (_listenCancelCompleter != null &&
        !_listenCancelCompleter!.isCompleted) {
      _listenCancelCompleter!.complete();
    }
    _listenCancelCompleter = null;
    _isListening = false;
    try {
      _stt.stop();
    } catch (_) {}
  }

  // Lenient accuracy for toddlers — any genuine phonetic attempt passes.
  // Reported confidence is clamped to min 0.50; absent confidence defaults
  // to 0.80 because toddler voices frequently get low or null scores.
  double _computeAccuracy(SpeechRecognitionResult result) {
    final recognized = result.recognizedWords.toLowerCase().trim();
    if (recognized.isEmpty) return 0.0;

    final target = widget.soundData.name.toLowerCase();
    final rawConf = result.confidence;
    final confidence = rawConf > 0 ? rawConf.clamp(0.5, 1.0) : 0.8;

    if (recognized.contains(target)) return confidence;

    for (final alt in (_kAlternatives[target] ?? [])) {
      if (recognized.contains(alt)) return confidence * 0.95;
    }

    for (final syl in widget.soundData.syllables) {
      if (recognized.contains(syl.toLowerCase())) return confidence * 0.85;
    }

    return 0.0;
  }

  // ─── Audio playback ───────────────────────────────────────────────────────

  void _playAudioAndAnimate() {
    if (_isDisposed) return;
    if (_streamId != null && _streamId! > 0) {
      _soundpool?.stop(_streamId!);
      _streamId = null;
    }
    _safeSetState(() {
      _isAnimating = true;
      _currentSyllableIndex = 0;
      _transcript = '';
      _isMicActive = false;
    });
    _playAudio();
  }

  Future<void> _playAudio() async {
    if (_isDisposed || _soundpool == null || _soundId == null) return;
    try {
      _streamId = await _soundpool!.play(_soundId!);
    } catch (_) {}
  }

  // ─── UI callbacks ─────────────────────────────────────────────────────────

  void _onSyllableComplete() {
    if (_isDisposed) return;
    if (_currentSyllableIndex < widget.soundData.syllables.length - 1) {
      _safeSetState(() => _currentSyllableIndex++);
    } else {
      _safeSetState(() => _isAnimating = false);
    }
  }

  // Tapping anywhere (outside the mic button) replays the audio.
  // Ignored while mic is active to avoid audio/mic overlap.
  Future<void> _onScreenTap() async {
    if (_showKoalaChallenge || _isMicActive) return;
    _playAudioAndAnimate();
  }

  void _goToKoalaChallenge({required bool correct}) {
    if (_isDisposed || _showKoalaChallenge) return;
    _stopListening();
    _safeSetState(() {
      _showKoalaChallenge = true;
      _isCorrect = correct;
      _isMicActive = false;
    });
  }

  void _onKoalaComplete() {
    _safeSetState(() => _isCorrect = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isDisposed && !_isNavigating) {
        _onBack(completed: true);
      }
    });
  }

  Future<void> _onBack({bool completed = false}) async {
    if (_isNavigating || _isDisposed) return;
    _isNavigating = true;
    _stopListening();
    try {
      if (_streamId != null && _streamId! > 0) {
        await _soundpool?.stop(_streamId!);
      }
    } catch (_) {}
    if (mounted) Navigator.pop(context, completed);
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) setState(fn);
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _isDisposed = true;
    _stopListening();
    _soundpool?.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isNavigating) _onBack(completed: false);
      },
      child: Scaffold(
        body: GestureDetector(
          onTap: _onScreenTap,
          child: SizedBox.expand(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const RepaintBoundary(child: _BackgroundImage()),
                SafeArea(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _showKoalaChallenge
                        ? KoalaChallenge(
                            key: const ValueKey('koala'),
                            sound: widget.soundData.name,
                            isCorrect: _isCorrect,
                            onComplete: _onKoalaComplete,
                            onBack: () => _onBack(completed: false),
                          )
                        : _buildWordAnimation(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordAnimation() {
    final screenHeight =
        _cachedScreenHeight ?? MediaQuery.sizeOf(context).height;

    return Column(
      key: const ValueKey('word'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppBackButton(onPressed: () => _onBack(completed: false)),
            ],
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
        Container(
          width: 400,
          height: 120,
          decoration: _kBubbleDecoration,
          child: Center(
            child: AnimatedWord(
              syllables: widget.soundData.syllables,
              currentIndex: _currentSyllableIndex,
              isAnimating: _isAnimating,
              onSyllableComplete: _onSyllableComplete,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: RepaintBoundary(
              child: SoundLottie(
                animationPath: widget.soundData.animationPath,
              ),
            ),
          ),
        ),
        _buildMicSection(),
        SizedBox(height: screenHeight * 0.03),
      ],
    );
  }

  Widget _buildMicSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hand tap hint — bounces to show the baby where to tap.
        // Fades out while mic is active.
        AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _isMicActive ? 0.0 : 1.0,
          child: const SizedBox(
            height: 48,
            child: _HandTapHint(),
          ),
        ),
        const SizedBox(height: 4),
        // Mic toggle button.
        GestureDetector(
          onTap: _onMicTap,
          child: _MicButton(isActive: _isMicActive),
        ),
        const SizedBox(height: 10),
        // Live transcript bubble.
        _buildTranscript(),
      ],
    );
  }

  Widget _buildTranscript() {
    final visible = _isListening || _transcript.isNotEmpty;
    if (!visible) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFCCA7DA), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isListening)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.mic, color: Colors.green, size: 18),
            ),
          Flexible(
            child: Text(
              _transcript.isEmpty ? 'Listening...' : '"$_transcript"',
              style: GoogleFonts.outfit(
                fontSize: 18,
                color: _transcript.isEmpty
                    ? Colors.grey
                    : const Color(0xFF4A4A4A),
                fontStyle: _transcript.isEmpty
                    ? FontStyle.normal
                    : FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hand tap hint ────────────────────────────────────────────────────────────
//
// Animated pointing-hand icon that bounces downward to hint the baby to tap
// the mic button below it.

class _HandTapHint extends StatefulWidget {
  const _HandTapHint();

  @override
  State<_HandTapHint> createState() => _HandTapHintState();
}

class _HandTapHintState extends State<_HandTapHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _translateY;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    // Bounces 10 px downward to "point" at the mic below.
    _translateY = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    // Slight scale-down on the downstroke to mimic a press motion.
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateY.value),
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: const Text('👇', style: TextStyle(fontSize: 34)),
    );
  }
}

// ─── Mic toggle button ────────────────────────────────────────────────────────
//
// Circular button that pulses green while recording.

class _MicButton extends StatefulWidget {
  final bool isActive;

  const _MicButton({required this.isActive});

  @override
  State<_MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<_MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulse = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isActive) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _ctrl.stop();
      _ctrl.reset();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isActive ? _pulse.value : 1.0,
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isActive
              ? const Color(0xFF34A853)
              : Colors.white,
          border: Border.all(
            color: widget.isActive
                ? const Color(0xFF57C97A)
                : const Color(0xFFCCA7DA),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.isActive
                  ? const Color(0xFF34A853).withAlpha(100)
                  : Colors.black.withAlpha(25),
              blurRadius: widget.isActive ? 22 : 8,
              spreadRadius: widget.isActive ? 4 : 0,
            ),
          ],
        ),
        child: Icon(
          widget.isActive ? Icons.mic : Icons.mic_none,
          color: widget.isActive
              ? Colors.white
              : const Color(0xFFCCA7DA),
          size: 34,
        ),
      ),
    );
  }
}

// ─── Background ───────────────────────────────────────────────────────────────

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/assets/images/sound_bg.jpg',
      fit: BoxFit.cover,
      gaplessPlayback: true,
    );
  }
}
