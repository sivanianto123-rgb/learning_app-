import '../../../utils/common_imports/common_imports.dart';

class KoalaTitle extends StatelessWidget {
  KoalaTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Text(
          'Lets make Mr Koala happy',
          textAlign: TextAlign.center,
          style: AppFonts.homeScreenTextStroke(),
        ),
        Text(
          'Lets make Mr Koala happy',
          textAlign: TextAlign.center,
          style: AppFonts.homeScreenText(),
        ),
      ],
    );
  }
}
