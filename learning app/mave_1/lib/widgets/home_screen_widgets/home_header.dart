import '../../../Utils/Common_imports/common_imports.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback onSettingsTap;
  final VoidCallback onSoundTap;
  final bool isMuted;

  HomeHeader({
    required this.onSettingsTap,
    required this.onSoundTap,
    required this.isMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: Row(
        children: [
          _buildIconButton(Icons.settings, onSettingsTap),
          SizedBox(width: 10),
          _buildIconButton(
            isMuted ? Icons.volume_off : Icons.volume_up,
            onSoundTap,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF7DD3FC), Color(0xFFC4B5FD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
