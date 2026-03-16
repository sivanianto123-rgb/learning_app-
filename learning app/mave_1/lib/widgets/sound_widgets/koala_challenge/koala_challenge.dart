import '../../../utils/common_imports/common_imports.dart';
import 'koala_title.dart';
import 'koala_container.dart';
import '../../../widgets/back_button.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class KoalaChallenge extends StatefulWidget {
  final String sound;
  final bool isCorrect;
  final Function(String) onVoiceResult;
  final VoidCallback onBack;

  KoalaChallenge({
    Key? key,
    required this.sound,
    required this.isCorrect,
    required this.onVoiceResult,
    required this.onBack,
  }) : super(key: key);

  @override
  State<KoalaChallenge> createState() => _KoalaChallengeState();
}

class _KoalaChallengeState extends State<KoalaChallenge> {
  bool _isListening = false;
  bool _isDisposed = false;
  bool _isSpeechReady = false;
  stt.SpeechToText? _speech;
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _initSpeechEarly();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) setState(fn);
  }

  Future<void> _initSpeechEarly() async {
    _speech = stt.SpeechToText();
    try {
      _isSpeechReady = await _speech!.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            _safeSetState(() => _isListening = false);
          }
        },
        onError: (error) {
          _safeSetState(() => _isListening = false);
        },
      );
    } catch (e) {
      _isSpeechReady = false;
    }
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_isSpeechReady || _speech == null || _isListening) return;

    _safeSetState(() {
      _isListening = true;
      _spokenText = '';
    });

    try {
      await _speech!.listen(
        onResult: (result) {
          _safeSetState(() => _spokenText = result.recognizedWords);
          if (result.finalResult) {
            widget.onVoiceResult(result.recognizedWords);
          }
        },
        listenFor: Duration(seconds: 5),
        pauseFor: Duration(seconds: 2),
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      _safeSetState(() => _isListening = false);
    }
  }

  Future<void> _stopListening() async {
    try {
      await _speech?.stop();
    } catch (e) {}
    _safeSetState(() => _isListening = false);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _speech?.stop();
    _speech?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        _buildHeader(),
        SizedBox(height: screenHeight * 0.02),
        KoalaTitle(),
        SizedBox(height: screenHeight * 0.03),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KoalaContainer(
                animationPath: 'lib/assets/animations/Koala_sad.lottie',
                isFaded: widget.isCorrect,
              ),
              SizedBox(width: screenWidth * 0.08),
              KoalaContainer(
                animationPath: 'lib/assets/animations/Koala_happy.lottie',
                isFaded: !widget.isCorrect,
              ),
            ],
          ),
        ),
        if (_spokenText.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'You said: $_spokenText',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        _buildMicButton(),
        SizedBox(height: screenHeight * 0.05),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(children: [AppBackButton(onPressed: widget.onBack)]),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: _isListening ? 80 : 70,
        height: _isListening ? 80 : 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isListening ? Colors.red : Color(0xFF6B7A99),
          border: Border.all(color: Color(0xFFCCA7DA), width: 4),
          boxShadow: [
            BoxShadow(
              color: _isListening
                  ? Colors.red.withAlpha(128)
                  : Colors.black.withAlpha(77),
              blurRadius: _isListening ? 20 : 10,
              spreadRadius: _isListening ? 2 : 0,
            ),
          ],
        ),
        child: Icon(
          _isListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: _isListening ? 40 : 35,
        ),
      ),
    );
  }
}
