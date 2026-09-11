// lib/core/widgets/animated_top_bar_title.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AnimatedTopBarTitle extends StatefulWidget {
  final bool isMobile;
  const AnimatedTopBarTitle({super.key, this.isMobile = false});

  @override
  State<AnimatedTopBarTitle> createState() => _AnimatedTopBarTitleState();
}

class _AnimatedTopBarTitleState extends State<AnimatedTopBarTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shimmerAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.015), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.015, end: 1.0), weight: 50),
    ]).animate(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = widget.isMobile || screenWidth < 768;
    final isVerySmall = screenWidth < 385;

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 20,
                vertical: isMobile ? 4 : 7,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFAB47BC).withValues(alpha: 0.08),
                    const Color(0xFFF3E5F5).withValues(alpha: 0.6),
                    const Color(0xFFAB47BC).withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFAB47BC).withValues(alpha: 0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFAB47BC).withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: isMobile ? 6 : 8,
                    height: isMobile ? 6 : 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isMobile ? 6 : 10),
                  Flexible(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        final shimmerPos = _shimmerAnimation.value;
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: const [
                            Color(0xFF8E24AA), // Deep Violet-Purple
                            Color(0xFFAB47BC), // Brand Primary #AB47BC
                            Color(0xFFE1BEE7), // Shimmer Light Highlights
                            Color(0xFFAB47BC), // Brand Primary
                            Color(0xFF8E24AA), // Deep Violet-Purple
                          ],
                          stops: [
                            0.0,
                            (shimmerPos - 0.25).clamp(0.0, 1.0),
                            shimmerPos.clamp(0.0, 1.0),
                            (shimmerPos + 0.25).clamp(0.0, 1.0),
                            1.0,
                          ],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.srcIn,
                      child: Text(
                        isVerySmall
                            ? 'ROH AUTISM CENTER'
                            : (isMobile ? 'ROH CENTER FOR AUTISM' : 'RAY OF HOPE CENTER FOR AUTISM'),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: isVerySmall ? 10.0 : (isMobile ? 11.0 : 14.5),
                          fontWeight: FontWeight.w800,
                          letterSpacing: isMobile ? 0.4 : 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: isMobile ? 6 : 10),
                  Container(
                    width: isMobile ? 6 : 8,
                    height: isMobile ? 6 : 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.6),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
