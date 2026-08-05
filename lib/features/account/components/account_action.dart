import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';

class AccountAction extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onTap;

  const AccountAction({super.key, required this.title, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Surface(
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: const Color(0xFFE23725)),
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0XFF2A1810),
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFF9B7D69)),
          ],
        ),
      ),
    );
  }
}
