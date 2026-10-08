import 'package:flutter/material.dart';

class LoadingSkeletonWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeletonWidget({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<LoadingSkeletonWidget> createState() => _LoadingSkeletonWidgetState();
}

class _LoadingSkeletonWidgetState extends State<LoadingSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFEEEEEE),
                Color(0xFFF5F5F5),
                Color(0xFFEEEEEE),
              ],
              stops: [
                (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PgCardSkeletonWidget extends StatelessWidget {
  const PgCardSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoadingSkeletonWidget(
            width: double.infinity,
            height: 180,
            borderRadius: 16,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const LoadingSkeletonWidget(
                      width: 80,
                      height: 22,
                      borderRadius: 4,
                    ),
                    const LoadingSkeletonWidget(
                      width: 60,
                      height: 18,
                      borderRadius: 4,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const LoadingSkeletonWidget(
                  width: 160,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 6),
                const LoadingSkeletonWidget(
                  width: 100,
                  height: 13,
                  borderRadius: 4,
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: LoadingSkeletonWidget(
                        width: 70,
                        height: 28,
                        borderRadius: 8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
