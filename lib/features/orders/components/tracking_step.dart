import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum TrackingStepState { done, current, pending }

class TrackingStep extends StatelessWidget {
  final String label;
  final TrackingStepState state;
  final bool isLast;

  const TrackingStep({
    super.key,
    required this.label,
    required this.state,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      TrackingStepState.done => const Color(0xFF1B9E54),
      TrackingStepState.current => const Color(0xFFE23725),
      TrackingStepState.pending => const Color(0xFFD9C7B8),
    };
    final sublabel = switch (state) {
      TrackingStepState.done => 'Concluido',
      TrackingStepState.current => 'Agora',
      TrackingStepState.pending => 'Aguardando',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              state == TrackingStepState.done
                  ? Icons.check_circle
                  : state == TrackingStepState.current
                      ? Icons.radio_button_checked
                      : Icons.circle_outlined,
              color: color,
              size: 22,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: state == TrackingStepState.done
                    ? const Color(0xFF1B9E54)
                    : const Color(0xFFE7D8C8),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: state == TrackingStepState.pending
                      ? const Color(0xFF9A7E6A)
                      : const Color(0XFF2A1810),
                ),
              ),
              Text(
                sublabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF9A7E6A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
