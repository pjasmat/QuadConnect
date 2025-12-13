import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[200]!,
                Colors.grey[300]!,
              ],
              stops: [
                0.0,
                _animation.value,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

// Pre-built skeleton widgets
class SkeletonPostCard extends StatelessWidget {
  const SkeletonPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SkeletonLoader(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader(width: 120, height: 16),
                      const SizedBox(height: 4),
                      SkeletonLoader(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SkeletonLoader(width: double.infinity, height: 200),
            const SizedBox(height: 12),
            SkeletonLoader(width: double.infinity, height: 14),
            const SizedBox(height: 4),
            SkeletonLoader(width: 200, height: 14),
          ],
        ),
      ),
    );
  }
}

class SkeletonEventCard extends StatelessWidget {
  const SkeletonEventCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoader(width: double.infinity, height: 20),
            const SizedBox(height: 8),
            SkeletonLoader(width: 150, height: 16),
            const SizedBox(height: 12),
            Row(
              children: [
                SkeletonLoader(width: 16, height: 16, borderRadius: BorderRadius.circular(4)),
                const SizedBox(width: 8),
                SkeletonLoader(width: 100, height: 14),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SkeletonLoader(width: 16, height: 16, borderRadius: BorderRadius.circular(4)),
                const SizedBox(width: 8),
                SkeletonLoader(width: 120, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonProfile extends StatelessWidget {
  const SkeletonProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SkeletonLoader(width: 100, height: 100, borderRadius: BorderRadius.all(Radius.circular(50))),
        const SizedBox(height: 16),
        SkeletonLoader(width: 150, height: 24),
        const SizedBox(height: 8),
        SkeletonLoader(width: 200, height: 16),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SkeletonLoader(width: 60, height: 60),
            SkeletonLoader(width: 60, height: 60),
            SkeletonLoader(width: 60, height: 60),
          ],
        ),
      ],
    );
  }
}

