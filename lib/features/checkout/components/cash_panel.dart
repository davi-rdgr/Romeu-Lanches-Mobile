import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';
import 'package:romeu_lanches_mobile/components/app_text_field.dart';

class CashPanel extends StatelessWidget {
  final double total;
  final TextEditingController controller;
  final bool noChangeNeeded;
  final VoidCallback onNoChangeNeeded;
  final VoidCallback onChangeInput;

  const CashPanel({
    super.key,
    required this.total,
    required this.controller,
    required this.noChangeNeeded,
    required this.onNoChangeNeeded,
    required this.onChangeInput,
  });

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pagar na entrega',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0XFF2A1810),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Voce paga em dinheiro quando o pedido chegar.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0XFF9A7E6A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Total',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0XFF2A1810),
                ),
              ),
              const Spacer(),
              Text(
                formatMoney(total),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0XFF2A1810),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Precisa de troco para quanto?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0XFF2A1810),
            ),
          ),
          const SizedBox(height: 6),
          AppTextField(
            controller: controller,
            hintText: 'Ex: 100,00',
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onNoChangeNeeded,
            child: Text(
              'Nao preciso de troco',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0XFFE23725),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
