import '../../../Utils/Common_imports/common_imports.dart';

class KoalaTitle extends StatelessWidget {
  final String title;

  KoalaTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppFonts.homeScreenTextStroke(),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppFonts.homeScreenText(),
        ),
      ],
    );
  }
}
