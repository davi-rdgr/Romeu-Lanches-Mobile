import 'package:flutter/material.dart';

class PageContent extends StatelessWidget {
  final Widget child;

  const PageContent({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: child,
      ),
    );
  }
}
