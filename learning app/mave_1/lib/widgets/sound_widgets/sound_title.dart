import '../../utils/common_imports/common_imports.dart';

class SoundTitle extends StatelessWidget {
  final String title;

  SoundTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Color(0xFFCCA7DA), width: 5),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            offset: Offset(4, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withAlpha(128),
              offset: Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}
