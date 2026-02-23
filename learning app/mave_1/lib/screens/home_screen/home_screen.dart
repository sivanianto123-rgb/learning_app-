import '../../Utils/Common_imports/common_imports.dart';
import '../../widgets/home_screen_widgets/home_animaton.dart';
import '../../widgets/home_screen_widgets/home_background.dart';
import '../../widgets/home_screen_widgets/home_header.dart';
import '../../widgets/home_screen_widgets/home_title.dart';
import '../../widgets/module_template_widget/corusel_widget.dart';
import '../module_screen/basic_sound/basic_sounds.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isMuted = false;

  List<bool> _firstSoundsCompleted = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

  double get _firstSoundsProgress {
    int completed = _firstSoundsCompleted.where((c) => c).length;
    return completed / _firstSoundsCompleted.length;
  }

  List<Map<String, dynamic>> get _modules => [
    {'title': 'First Sounds', 'progress': _firstSoundsProgress},
    {'title': 'Long Sounds', 'progress': 0.0},
    {'title': 'Combinations', 'progress': 0.0},
    {'title': 'Words', 'progress': 0.0},
  ];

  void _onModuleTap(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, animation, secondaryAnimation) =>
                BasicSoundScreen(
                  initialCompletedSounds: _firstSoundsCompleted,
                  onProgressUpdate: (completedSounds) {
                    setState(() {
                      _firstSoundsCompleted = completedSounds;
                    });
                  },
                ),
            transitionDuration: Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
          ),
        );
        break;
      case 1:
        break;
      case 2:
        break;
      case 3:
        break;
    }
  }

  void _onSettingsTap() {}

  void _onSoundTap() {
    setState(() => _isMuted = !_isMuted);
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: HomeBackground(
          child: SafeArea(
            child: Stack(
              children: [
                HomeHeader(
                  onSettingsTap: _onSettingsTap,
                  onSoundTap: _onSoundTap,
                  isMuted: _isMuted,
                ),
                Positioned(
                  left: 20,
                  top: screenHeight * 0.35,
                  child: HomeTitle(),
                ),
                Positioned(
                  left: screenWidth * 0.25,
                  bottom: 0,
                  child: HomeAnimation(),
                ),
                Positioned(
                  right: 20,
                  top: screenHeight * 0.1,
                  bottom: screenHeight * 0.1,
                  child: CarouselWidget(
                    modules: _modules,
                    onModuleTap: _onModuleTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
