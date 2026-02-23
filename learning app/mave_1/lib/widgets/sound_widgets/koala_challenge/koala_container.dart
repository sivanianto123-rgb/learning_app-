import '../../../Utils/Common_imports/common_imports.dart';

class KoalaContainer extends StatelessWidget {
  final String animationPath;
  final bool isFaded;
  final String label;

  KoalaContainer({
    required this.animationPath,
    required this.isFaded,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;

    return AnimatedOpacity(
      opacity: isFaded ? 0.3 : 1.0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 250,
            height: screenHeight * 0.35,
            decoration: BoxDecoration(
              color: Color(0xFFD9D9D9).withOpacity(0.85),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Color(0xFFCCA7DA), width: 6),
            ),
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
          ),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
