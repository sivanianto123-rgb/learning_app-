import '../../../utils/common_imports/common_imports.dart';

class AnimatedWord extends StatefulWidget {
  final List<String> syllables;
  final int currentIndex;
  final bool isAnimating;
  final VoidCallback onSyllableComplete;

  AnimatedWord({
    Key? key,
    required this.syllables,
    required this.currentIndex,
    required this.isAnimating,
    required this.onSyllableComplete,
  }) : super(key: key);

  @override
  State<AnimatedWord> createState() => _AnimatedWordState();
}

class _AnimatedWordState extends State<AnimatedWord>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
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
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed && _hasStarted) {
        _hasStarted = false;
        widget.onSyllableComplete();
      }
    });
  }

  void _startAnimation() {
    if (_hasStarted || !mounted) return;
    _hasStarted = true;
    _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(AnimatedWord oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAnimating && !_hasStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAnimation();
      });
    } else if (widget.isAnimating &&
        widget.currentIndex != oldWidget.currentIndex &&
        !_hasStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAnimation();
      });
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
