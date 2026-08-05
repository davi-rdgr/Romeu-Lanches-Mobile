import 'package:flutter/material.dart';

class Surface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0DDCE)),
      ),
      child: child,
    );
  }
}
