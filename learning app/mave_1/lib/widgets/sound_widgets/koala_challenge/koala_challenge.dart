import '../../../Utils/Common_imports/common_imports.dart';
import 'koala_title.dart';
import 'koala_container.dart';
import 'koala_challenge_data.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class KoalaChallenge extends StatefulWidget {
  final String sound;
  final bool isCorrect;
  final Function(String) onVoiceResult;
  final VoidCallback onReplay;
  final VoidCallback onBack;

  KoalaChallenge({
    Key? key,
    required this.sound,
    required this.isCorrect,
    required this.onVoiceResult,
    required this.onReplay,
    required this.onBack,
  }) : super(key: key);

  @override
  State<KoalaChallenge> createState() => _KoalaChallengeState();
}

class _KoalaChallengeState extends State<KoalaChallenge> {
  bool _isListening = false;
  stt.SpeechToText? _speech;
  bool _speechAvailable = false;
  String _spokenText = '';
  bool _isDisposed = false;
  late KoalaChallengeData _challengeData;

  @override
  void initState() {
    super.initState();
    _challengeData = KoalaChallengeData.getRandomChallenge();
    _initSpeech();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech!.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _safeSetState(() => _isListening = false);
        }
      },
      onError: (error) {
        _safeSetState(() => _isListening = false);
      },
    );
    _safeSetState(() {});
  }

  void _startListening() async {
    if (!_speechAvailable || _speech == null) return;

    _safeSetState(() {
      _isListening = true;
      _spokenText = '';
    });

    await _speech!.listen(
      onResult: (result) {
        _safeSetState(() {
          _spokenText = result.recognizedWords;
        });
        if (result.finalResult) {
          _checkResult(result.recognizedWords);
        }
      },
      listenFor: Duration(seconds: 5),
      pauseFor: Duration(seconds: 2),
    );
  }

  void _stopListening() async {
    if (_speech != null) {
      await _speech!.stop();
    }
    _safeSetState(() => _isListening = false);
  }

  void _checkResult(String spokenWords) {
    widget.onVoiceResult(spokenWords);
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
        KoalaTitle(title: _challengeData.title),
        SizedBox(height: screenHeight * 0.03),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              KoalaContainer(
                animationPath: _challengeData.sadAnimation,
                isFaded: widget.isCorrect,
                label: _challengeData.sadLabel,
              ),
              SizedBox(width: screenWidth * 0.08),
              KoalaContainer(
                animationPath: _challengeData.happyAnimation,
                isFaded: !widget.isCorrect,
                label: _challengeData.happyLabel,
              ),
            ],
          ),
        ),
        if (_spokenText.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'You said: $_spokenText',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        _buildButtons(),
        SizedBox(height: screenHeight * 0.05),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Icon(Icons.arrow_back, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_buildReplayButton(), SizedBox(width: 20), _buildMicButton()],
    );
  }

  Widget _buildReplayButton() {
    return GestureDetector(
      onTap: widget.onReplay,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFF6B7A99),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Color(0xFFCCA7DA), width: 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.replay, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text('Replay', style: AppFonts.primaryText()),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return GestureDetector(
      onTap: _isListening ? _stopListening : _startListening,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
        decoration: BoxDecoration(
          color: _isListening ? Colors.red : Color(0xFF6B7A99),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Color(0xFFCCA7DA), width: 4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              _isListening ? 'Listening...' : 'Speak',
              style: AppFonts.primaryText(),
            ),
          ],
        ),
      ),
    );
  }
}
