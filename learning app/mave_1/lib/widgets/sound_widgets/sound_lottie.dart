import '../../utils/common_imports/common_imports.dart';

class SoundLottie extends StatelessWidget {
  final String animationPath;

  SoundLottie({Key? key, required this.animationPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    if (animationPath.isEmpty) {
      return SizedBox(
        height: screenHeight * 0.35,
        child: Center(
          child: Icon(
            Icons.pets,
            size: 100,
            color: Colors.white.withAlpha(150),
          ),
        ),
      );
    }

    return SizedBox(
      height: screenHeight * 0.35,
      child: DotLottieLoader.fromAsset(
        animationPath,
        frameBuilder: (context, dotlottie) {
          if (dotlottie != null) {
            return Lottie.memory(
              dotlottie.animations.values.single,
              fit: BoxFit.contain,
              repeat: true,
            );
          }
          return SizedBox();
        },
      ),
    );
  }
}
