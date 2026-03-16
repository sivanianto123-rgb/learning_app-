import '../../utils/common_imports/common_imports.dart';
import '../../widgets/sound_widgets/animated_word.dart';
import '../../widgets/sound_widgets/sound_lottie.dart';
import '../../widgets/sound_widgets/koala_challenge/koala_challenge.dart';
import '../../widgets/sound_widgets/accuracy_bar.dart';
import '../../widgets/back_button.dart';
import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SoundScreen extends StatefulWidget {
  final SoundData soundData;

  SoundScreen({Key? key, required this.soundData}) : super(key: key);

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
  bool _isListening = false;
  double _accuracy = 0.0;
  String _lastWords = '';

  Soundpool? _soundpool;
  int? _soundId;
  int? _streamId;
  stt.SpeechToText? _speech;
  bool _isSpeechReady = false;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _requestMicPermission();
    await _initAudio();
    await _initSpeech();

    if (mounted && !_isDisposed) {
      await Future.delayed(Duration(milliseconds: 500));
      _playAudioAndAnimate();
      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted && !_isDisposed) {
        _startListening();
      }
    }
  }

  Future<void> _requestMicPermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      _isSpeechReady = await _speech!.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted &&
                !_isDisposed &&
                !_showKoalaChallenge &&
                _accuracy < 0.8) {
              Future.delayed(Duration(milliseconds: 500), () {
                if (mounted && !_isDisposed && !_showKoalaChallenge) {
                  _startListening();
                }
              });
            }
          }
        },
        onError: (error) {
          debugPrint('Speech error: ${error.errorMsg}');
        },
      );
      debugPrint('Speech ready: $_isSpeechReady');
    } catch (e) {
      debugPrint('Speech init error: $e');
      _isSpeechReady = false;
    }
  }

  Future<void> _initAudio() async {
    if (widget.soundData.audioPath.isEmpty) return;
    try {
      _soundpool = Soundpool.fromOptions(
        options: SoundpoolOptions(streamType: StreamType.music),
      );
      ByteData data = await rootBundle.load(widget.soundData.audioPath);
      _soundId = await _soundpool!.load(data);
    } catch (e) {
      debugPrint('Audio init error: $e');
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) setState(fn);
  }

  void _playAudioAndAnimate() {
    if (_isDisposed) return;
    _safeSetState(() {
      _isAnimating = true;
      _currentSyllableIndex = 0;
    });
    _playAudio();
  }

  Future<void> _startListening() async {
    if (!_isSpeechReady ||
        _speech == null ||
        _isDisposed ||
        _showKoalaChallenge ||
        _isListening) {
      debugPrint('Cannot start: ready=$_isSpeechReady listening=$_isListening');
      return;
    }

    _safeSetState(() => _isListening = true);
    debugPrint('Starting to listen...');

    try {
      await _speech!.listen(
        onResult: (result) {
          if (_isDisposed || _showKoalaChallenge) return;
          debugPrint('Heard: ${result.recognizedWords}');
          _safeSetState(() => _lastWords = result.recognizedWords);
          _processVoiceResult(result.recognizedWords);
        },
        listenFor: Duration(seconds: 20),
        pauseFor: Duration(seconds: 4),
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      );
    } catch (e) {
      debugPrint('Listen error: $e');
      _safeSetState(() => _isListening = false);
    }
  }

  void _processVoiceResult(String spokenWords) {
    if (_isDisposed || _showKoalaChallenge) return;

    String spoken = spokenWords.toLowerCase().replaceAll(' ', '');
    String target = widget.soundData.name.toLowerCase();

    double newAccuracy = 0.0;

    if (spoken.contains(target)) {
      newAccuracy = 1.0;
    } else {
      for (var syl in widget.soundData.syllables) {
        if (spoken.contains(syl.toLowerCase())) {
          newAccuracy = 0.5;
          break;
        }
      }
    }

    _safeSetState(() {
      if (newAccuracy > _accuracy) _accuracy = newAccuracy;
    });

    if (_accuracy >= 0.8) {
      _goToKoalaChallenge();
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech?.stop();
    } catch (e) {}
    _safeSetState(() => _isListening = false);
  }

  Future<void> _playAudio() async {
    if (_isDisposed || _soundpool == null || _soundId == null) return;
    try {
      _streamId = await _soundpool!.play(_soundId!);
    } catch (e) {}
  }

  void _onSyllableComplete() {
    if (_isDisposed) return;
    if (_currentSyllableIndex < widget.soundData.syllables.length - 1) {
      _safeSetState(() => _currentSyllableIndex++);
    } else {
      _safeSetState(() => _isAnimating = false);
    }
  }

  Future<void> _goToKoalaChallenge() async {
    if (_isDisposed || _showKoalaChallenge) return;
    await _stopListening();
    _safeSetState(() {
      _showKoalaChallenge = true;
      _isCorrect = false;
    });
  }

  void _onKoalaVoiceResult(String spokenWord) {
    if (_isDisposed) return;
    String spoken = spokenWord.toLowerCase().replaceAll(' ', '');
    String target = widget.soundData.name.toLowerCase();

    if (spoken.contains(target)) {
      _safeSetState(() => _isCorrect = true);
      Future.delayed(Duration(seconds: 2), () {
        if (mounted && !_isDisposed && !_isNavigating) {
          _onBack(completed: true);
        }
      });
    }
  }

  Future<void> _onScreenTap() async {
    if (_showKoalaChallenge) return;
    _playAudioAndAnimate();
  }

  Future<void> _onBack({bool completed = false}) async {
    if (_isNavigating || _isDisposed) return;
    _isNavigating = true;
    await _stopListening();
    try {
      if (_streamId != null && _streamId! > 0) {
        await _soundpool?.stop(_streamId!);
      }
    } catch (e) {}
    if (mounted) Navigator.pop(context, completed);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speech?.stop();
    _speech?.cancel();
    _soundpool?.dispose();
    super.dispose();
  }

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
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'lib/assets/images/sound_bg.jpg',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
                SafeArea(
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    child: _showKoalaChallenge
                        ? KoalaChallenge(
                            key: ValueKey('koala'),
                            sound: widget.soundData.name,
                            isCorrect: _isCorrect,
                            onVoiceResult: _onKoalaVoiceResult,
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
    var screenHeight = MediaQuery.of(context).size.height;

    return Row(
      key: ValueKey('word'),
      children: [
        Expanded(
          child: Column(
            children: [
              _buildHeader(),
              SizedBox(height: screenHeight * 0.02),
              _buildWordContainer(),
              Expanded(
                child: Center(
                  child: SoundLottie(
                    animationPath: widget.soundData.animationPath,
                  ),
                ),
              ),
              if (_lastWords.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Heard: $_lastWords',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
        AccuracyBar(accuracy: _accuracy),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [AppBackButton(onPressed: () => _onBack(completed: false))],
      ),
    );
  }

  Widget _buildWordContainer() {
    return Container(
      width: 400,
      height: 120,
      decoration: BoxDecoration(
        color: Color(0xFFD9D9D9).withAlpha(230),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Color(0xFFCCA7DA), width: 6),
      ),
      child: Center(
        child: AnimatedWord(
          syllables: widget.soundData.syllables,
          currentIndex: _currentSyllableIndex,
          isAnimating: _isAnimating,
          onSyllableComplete: _onSyllableComplete,
        ),
      ),
    );
  }
}
