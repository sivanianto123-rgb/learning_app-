import '../../Utils/Common_imports/common_imports.dart';
import '../../widgets/sound_widgets/animated_word.dart';
import '../../widgets/sound_widgets/koala_challenge/koala_challenge.dart';
import '../../widgets/sound_widgets/sound_lottie.dart';

import 'package:soundpool/soundpool.dart';
import 'package:flutter/services.dart';

class SoundScreen extends StatefulWidget {
  final String sound;

  SoundScreen({Key? key, required this.sound}) : super(key: key);

  @override
  State<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends State<SoundScreen> {
  List<String> _syllables = [];
  int _currentSyllableIndex = 0;
  bool _isAnimating = false;
  bool _showKoalaChallenge = false;
  bool _isCorrect = false;
  bool _isDisposed = false;
  Soundpool? _soundpool;
  int? _soundId;
  int? _streamId;

  @override
  void initState() {
    super.initState();
    _splitIntoSyllables();
    _startAnimation();
    _initAudio();
  }

  String _getAudioPath() {
    switch (widget.sound.toLowerCase()) {
      case 'mama':
        return 'audio/mama.wav';
      case 'papa':
        return 'audio/papa.wav';
      case 'dada':
        return 'audio/dada.wav';
      case 'baba':
        return 'audio/baba.wav';
      case 'aaaa':
        return 'audio/aaa.wav';
      case 'ooo':
        return 'audio/ooo.wav';
      case 'eee':
        return 'audio/eee.wav';
      default:
        return '';
    }
  }

  Future<void> _initAudio() async {
    String audioPath = _getAudioPath();
    if (audioPath.isEmpty) return;

    try {
      _soundpool = Soundpool.fromOptions(
        options: SoundpoolOptions(streamType: StreamType.music),
      );
      ByteData data = await rootBundle.load(audioPath);
      _soundId = await _soundpool!.load(data);
    } catch (e) {
      debugPrint('Audio init error: $e');
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) {
      setState(fn);
    }
  }

  void _splitIntoSyllables() {
    switch (widget.sound.toLowerCase()) {
      case 'mama':
        _syllables = ['ma', 'ma'];
        break;
      case 'papa':
        _syllables = ['pa', 'pa'];
        break;
      case 'dada':
        _syllables = ['da', 'da'];
        break;
      case 'baba':
        _syllables = ['ba', 'ba'];
        break;
      case 'aaaa':
        _syllables = ['aa', 'aa'];
        break;
      case 'ooo':
        _syllables = ['ooo'];
        break;
      case 'eee':
        _syllables = ['eee'];
        break;
      default:
        _syllables = [widget.sound];
    }
  }

  void _startAnimation() {
    _safeSetState(() {
      _isAnimating = true;
      _currentSyllableIndex = 0;
    });
  }

  Future<void> _playAudio() async {
    if (_isDisposed || _soundpool == null || _soundId == null) return;

    try {
      await _stopAudio();
      _streamId = await _soundpool!.play(_soundId!);
    } catch (e) {
      debugPrint('Audio play error: $e');
    }
  }

  Future<void> _stopAudio() async {
    if (_soundpool == null || _streamId == null || _streamId! <= 0) return;

    try {
      await _soundpool!.stop(_streamId!);
    } catch (e) {
      debugPrint('Stop audio error: $e');
    } finally {
      _streamId = null;
    }
  }

  void _onSyllableComplete() {
    if (_currentSyllableIndex < _syllables.length - 1) {
      _safeSetState(() => _currentSyllableIndex++);
    } else {
      _safeSetState(() => _isAnimating = false);
    }
  }

  void _goToKoalaChallenge() {
    _stopAudio();
    _safeSetState(() {
      _showKoalaChallenge = true;
      _isCorrect = false;
    });
  }

  void _onVoiceResult(String spokenWord) {
    String spoken = spokenWord.toLowerCase().replaceAll(' ', '');
    String target = widget.sound.toLowerCase().replaceAll(' ', '');

    if (spoken.contains(target)) {
      _safeSetState(() => _isCorrect = true);
      Future.delayed(Duration(seconds: 2), () {
        if (mounted && !_isDisposed) {
          _onBack(completed: true);
        }
      });
    }
  }

  void _replayAnimation() {
    _safeSetState(() {
      _showKoalaChallenge = false;
      _isCorrect = false;
    });
    _startAnimation();
    _playAudio();
  }

  void _onSwipeLeft() {
    if (!_showKoalaChallenge) {
      _goToKoalaChallenge();
    }
  }

  void _onScreenTap() {
    if (!_showKoalaChallenge) {
      _playAudio();
    }
  }

  void _onBack({bool completed = false}) {
    _stopAudio();
    Navigator.pop(context, completed);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _streamId = null;
    _soundpool?.dispose();
    _soundpool = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _stopAudio();
        return false;
      },
      child: Scaffold(
        body: GestureDetector(
          onTap: _onScreenTap,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -200) {
              _onSwipeLeft();
            }
          },
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
                  duration: Duration(milliseconds: 500),
                  child: _showKoalaChallenge
                      ? KoalaChallenge(
                          key: ValueKey('koala'),
                          sound: widget.sound,
                          isCorrect: _isCorrect,
                          onVoiceResult: _onVoiceResult,
                          onReplay: _replayAnimation,
                          onBack: () => _onBack(completed: false),
                        )
                      : _buildWordAnimation(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordAnimation() {
    var screenHeight = MediaQuery.of(context).size.height;

    return Column(
      key: ValueKey('word'),
      children: [
        _buildHeader(),
        SizedBox(height: screenHeight * 0.02),
        _buildWordContainer(),
        Expanded(
          child: Center(child: SoundLottie(sound: widget.sound)),
        ),
        _buildBottomButtons(),
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
            onTap: () => _onBack(completed: false),
            child: Icon(Icons.arrow_back, color: Colors.black, size: 30),
          ),
        ],
      ),
    );
  }

  Widget _buildWordContainer() {
    return GestureDetector(
      onTap: _playAudio,
      child: Container(
        width: 400,
        height: 120,
        decoration: BoxDecoration(
          color: Color(0xFFD9D9D9).withOpacity(0.9),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Color(0xFFCCA7DA), width: 6),
        ),
        child: Center(
          child: AnimatedWord(
            syllables: _syllables,
            currentIndex: _currentSyllableIndex,
            isAnimating: _isAnimating,
            onSyllableComplete: _onSyllableComplete,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [_buildReplayButton(), SizedBox(width: 20), _buildNextButton()],
    );
  }

  Widget _buildReplayButton() {
    return GestureDetector(
      onTap: () {
        _startAnimation();
        _playAudio();
      },
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

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: _goToKoalaChallenge,
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
            Text('Next', style: AppFonts.primaryText()),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}
