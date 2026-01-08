import 'dart:ui';
import 'package:flutter/material.dart';

class BlurBackground extends StatelessWidget {
  final Widget child;
  final double sigma;

  const BlurBackground({
    super.key,
    required this.child,
    this.sigma = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
}
