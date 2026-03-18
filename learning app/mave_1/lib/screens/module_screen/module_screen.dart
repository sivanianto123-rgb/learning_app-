import '../../utils/common_imports/common_imports.dart';
import '../../widgets/sound_widgets/sound_grid.dart';
import '../../widgets/sound_widgets/sound_title.dart';
import '../../widgets/back_button.dart';
import 'sound_screen.dart';

class ModuleScreen extends StatefulWidget {
  final ModuleData moduleData;
  final List<bool> initialCompletedSounds;
  final Function(List<bool>) onProgressUpdate;

  ModuleScreen({
    Key? key,
    required this.moduleData,
    required this.initialCompletedSounds,
    required this.onProgressUpdate,
  }) : super(key: key);

  @override
  State<ModuleScreen> createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  late List<bool> _completedSounds;

  @override
  void initState() {
    super.initState();
    _completedSounds = List.from(widget.initialCompletedSounds);
  }

  void _onSoundTap(int index) async {
    final soundData = widget.moduleData.sounds[index];

    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            SoundScreen(soundData: soundData),
        transitionDuration: Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    if (result == true && !_completedSounds[index]) {
      setState(() {
        _completedSounds[index] = true;
      });
      widget.onProgressUpdate(_completedSounds);
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
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
                child: Column(
                  children: [
                    _buildHeader(),
                    SizedBox(height: screenHeight * 0.03),
                    SoundTitle(title: widget.moduleData.title),
                    SizedBox(height: screenHeight * 0.06),
                    Expanded(
                      child: Center(
                        child: SoundGrid(
                          sounds: widget.moduleData.sounds
                              .map((s) => s.name)
                              .toList(),
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
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [AppBackButton(onPressed: () => Navigator.pop(context))],
      ),
    );
  }
}
