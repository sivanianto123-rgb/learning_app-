import '../../../Utils/Common_imports/common_imports.dart';
import '../module_template_widget/threed_sound_card.dart';

class SoundGrid extends StatelessWidget {
  final List<String> sounds;
  final List<bool> completedSounds;
  final Function(int) onSoundTap;

  SoundGrid({
    required this.sounds,
    required this.completedSounds,
    required this.onSoundTap,
  });

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 25,
        runSpacing: 25,
        children: List.generate(sounds.length, (index) {
          return BulgedSoundCard(
            sound: sounds[index],
            isCompleted: completedSounds[index],
            onTap: () => onSoundTap(index),
          );
        }),
      ),
    );
  }
}
