import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/features/store/data/business_hours.dart';

class ScheduleRow extends StatelessWidget {
  final BusinessHours hours;
  final bool isToday;

  const ScheduleRow({super.key, required this.hours, this.isToday = false});

  @override
  Widget build(BuildContext context) {
    final isClosed = !hours.open;
    final color = isClosed
        ? const Color(0xFFE23725)
        : isToday
        ? const Color(0xFF2A1810)
        : const Color(0xFF5A4636);

    return Container(
      color: isClosed
          ? const Color(0xFFFFEEE5)
          : isToday
          ? const Color(0xFFF7F0E8)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            isToday ? '${hours.dayLabel} (hoje)' : hours.dayLabel,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: isClosed || isToday
                  ? FontWeight.w900
                  : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            hours.hoursLabel,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: isClosed || isToday
                  ? FontWeight.w900
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
