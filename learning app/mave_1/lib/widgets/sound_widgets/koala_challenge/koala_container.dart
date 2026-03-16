import '../../../utils/common_imports/common_imports.dart';

class KoalaContainer extends StatelessWidget {
  final String animationPath;
  final bool isFaded;

  KoalaContainer({Key? key, required this.animationPath, required this.isFaded})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    return AnimatedOpacity(
      opacity: isFaded ? 0.3 : 1.0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: Container(
        width: 150,
        height: screenHeight * 0.3,
        decoration: BoxDecoration(
          color: Color(0xFFD9D9D9).withAlpha(217),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Color(0xFFCCA7DA), width: 6),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
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
              return Center(
                child: Text(
                  isFaded ? '😢' : '😊',
                  style: TextStyle(fontSize: 60),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
