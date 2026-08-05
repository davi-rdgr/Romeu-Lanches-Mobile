import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.bricolageGrotesque(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0XFF2A1810),
      ),
    );
  }
}
