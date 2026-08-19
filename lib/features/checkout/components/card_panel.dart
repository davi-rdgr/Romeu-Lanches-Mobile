import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';

/// Cartao nao e processado pelo app: o backend nao tem gateway para essa forma
/// (so PIX tem). Um pedido com `formaPagamento=CARTAO` nasce direto em `NOVO`,
/// igual dinheiro — a maquininha e levada pelo entregador ou fica no balcao.
class CardPanel extends StatelessWidget {
  final double total;
  final bool isDelivery;

  const CardPanel({super.key, required this.total, required this.isDelivery});

  @override
  Widget build(BuildContext context) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDelivery ? 'Pagar na entrega' : 'Pagar na retirada',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0XFF2A1810),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isDelivery
                ? 'A maquininha vai com o entregador. Não pedimos dados do seu '
                      'cartão aqui.'
                : 'Voce passa o cartão no balcao ao retirar o pedido. Não '
                      'pedimos dados do seu cartão aqui.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0XFF9A7E6A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF2E9E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.credit_card,
                  color: Color(0xFF5A4636),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Total a pagar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0XFF2A1810),
                ),
              ),
              const Spacer(),
              Text(
                formatMoney(total),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0XFF2A1810),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
