import '../../../Utils/Common_imports/common_imports.dart';

class AnimatedWord extends StatefulWidget {
  final List<String> syllables;
  final int currentIndex;
  final bool isAnimating;
  final VoidCallback onSyllableComplete;

  AnimatedWord({
    required this.syllables,
    required this.currentIndex,
    required this.isAnimating,
    required this.onSyllableComplete,
  });

  @override
  State<AnimatedWord> createState() => _AnimatedWordState();
}

class _AnimatedWordState extends State<AnimatedWord>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    if (widget.isAnimating) {
      _controller.forward();
    }
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse().then((_) {
          _controller.reset();
          widget.onSyllableComplete();
        });
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedWord oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && widget.currentIndex != oldWidget.currentIndex) {
      _controller.forward();
    }
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.syllables.length, (index) {
            bool isActive = widget.isAnimating && index == widget.currentIndex;
            double scale = isActive ? _scaleAnimation.value : 1.0;
            Color textColor = isActive ? Colors.red : Colors.white;

            return Transform.scale(
              scale: scale,
              child: Text(
                widget.syllables[index],
                style: TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
