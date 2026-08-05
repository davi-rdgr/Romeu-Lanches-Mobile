import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopTitle extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;

  const TopTitle({super.key, required this.title, this.leading, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 10)],
        Text(
          title,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0XFF2A1810),
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}
