import '../../../Utils/Common_imports/common_imports.dart';
import '../../../widgets/sound_widgets/sound_grid.dart';
import '../../../widgets/sound_widgets/sound_title.dart';
import '../sound_screen.dart';

class BasicSoundScreen extends StatefulWidget {
  final List<bool> initialCompletedSounds;
  final Function(List<bool>) onProgressUpdate;

  BasicSoundScreen({
    required this.initialCompletedSounds,
    required this.onProgressUpdate,
  });

  @override
  State<BasicSoundScreen> createState() => _BasicSoundScreenState();
}

class _BasicSoundScreenState extends State<BasicSoundScreen> {
  final List<String> _sounds = [
    'mama',
    'papa',
    'dada',
    'baba',
    'aaaa',
    'ooo',
    'eee',
  ];

  late List<bool> _completedSounds;

  @override
  void initState() {
    super.initState();
    _completedSounds = List.from(widget.initialCompletedSounds);
  }

  void _onSoundTap(int index) async {
    if (_completedSounds[index]) return;

    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) =>
            SoundScreen(sound: _sounds[index]),
        transitionDuration: Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (result == true) {
      setState(() {
        _completedSounds[index] = true;
      });
      widget.onProgressUpdate(_completedSounds);
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'lib/assets/images/sound_bg.jpg',
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: screenHeight * 0.03),
                  SoundTitle(title: 'First Sounds'),
                  SizedBox(height: screenHeight * 0.06),
                  Expanded(
                    child: Center(
                      child: SoundGrid(
                        sounds: _sounds,
                        completedSounds: _completedSounds,
                        onSoundTap: _onSoundTap,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back, color: Colors.black, size: 24),
          ),
        ],
      ),
    );
  }
}
