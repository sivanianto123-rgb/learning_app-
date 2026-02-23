import '../../../Utils/Common_imports/common_imports.dart';

class SoundLottie extends StatelessWidget {
  final String sound;

  SoundLottie({required this.sound});

  String _getLottiePath() {
    switch (sound.toLowerCase()) {
      case 'mama':
        return 'lib/assets/animations/mama.lottie';
      case 'dada':
        return 'lib/assets/animations/dada.lottie';
      default:
        return 'lib/assets/animations/mama.lottie';
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.35,
      child: DotLottieLoader.fromAsset(
        _getLottiePath(),
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
