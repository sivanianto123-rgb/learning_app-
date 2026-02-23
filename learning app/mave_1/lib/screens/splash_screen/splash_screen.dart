import '../../Utils/Common_imports/common_imports.dart';
import '../../Utils/image_preloader.dart';
import '../Home_screen/Home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAndNavigate();
  }

  void _setupAnimation() {
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadAndNavigate() async {
    if (_isNavigating) return;
    _isNavigating = true;

    await ImagePreloader().preloadImages(context);
    await Future.delayed(Duration(seconds: 2));

    if (!mounted) return;

    await _fadeController.forward();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
        transitionDuration: Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: screenHeight * 0.1),
                Expanded(
                  child: Center(
                    child: DotLottieLoader.fromAsset(
                      'lib/assets/animations/splash.lottie',
                      frameBuilder: (context, dotlottie) {
                        if (dotlottie != null) {
                          return Lottie.memory(
                            dotlottie.animations.values.single,
                            width: screenWidth * 0.8,
                            fit: BoxFit.contain,
                            repeat: false,
                          );
                        }
                        return SizedBox();
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: screenHeight * 0.08),
                  child: Text(
                    'Start Your Journey With Mave',
                    style: AppFonts.splashText(),
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
