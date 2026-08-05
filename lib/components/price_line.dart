import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PriceLine extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const PriceLine({
    super.key,
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: strong ? 18 : 13,
      fontWeight: strong ? FontWeight.w900 : FontWeight.w400,
      color: strong ? const Color(0xFF2A1810) : const Color(0xFF7A6453),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(value, style: style),
        ],
      ),
    );
  }
}
