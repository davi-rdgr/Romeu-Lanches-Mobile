import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';
import 'package:romeu_lanches_mobile/features/orders/data/pix_payment.dart';

class PixPanel extends StatelessWidget {
  final PixPayment payment;

  /// Recalculado a cada segundo pela tela, para o contador andar.
  final Duration remaining;

  const PixPanel({
    super.key,
    required this.payment,
    required this.remaining,
  });

  bool get _isExpired => remaining == Duration.zero;

  @override
  Widget build(BuildContext context) {
    final minutes = remaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Column(
      children: [
        Surface(
          child: Column(
            children: [
              Text(
                _isExpired ? 'Este PIX expirou' : 'Pague com PIX',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0XFF2A1810),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isExpired
                    ? 'O pedido foi cancelado por falta de pagamento.'
                    : 'Escaneie o QR Code no app do banco',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0XFF9A7E6A),
                ),
              ),
              const SizedBox(height: 18),
              _qrCode(),
              const SizedBox(height: 18),
              Text(
                formatMoney(payment.amount),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0XFF2A1810),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isExpired ? 'Expirado' : 'Expira em $minutes:$seconds',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _isExpired
                      ? const Color(0xFFE23725)
                      : const Color(0XFF9A7E6A),
                ),
              ),
              if (!_isExpired) ...[
                const SizedBox(height: 16),
                _copyPasteField(context),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!_isExpired)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3D6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Assim que o pagamento cair, seu pedido entra na fila da cozinha '
              'automaticamente. Pode deixar essa tela aberta.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0XFF8A6D1F),
              ),
            ),
          ),
      ],
    );
  }

  /// `pixQrBase64` e um PNG em base64 sem o prefixo `data:`.
  Widget _qrCode() {
    if (payment.qrBase64.isEmpty) {
      return _qrFallback('QR Code indisponivel');
    }

    try {
      final bytes = base64Decode(payment.qrBase64);
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0DDCE)),
        ),
        child: Opacity(
          opacity: _isExpired ? 0.25 : 1,
          child: Image.memory(bytes, width: 190, height: 190),
        ),
      );
    } catch (_) {
      return _qrFallback('Nao foi possivel ler o QR Code');
    }
  }

  Widget _qrFallback(String message) => Container(
    width: 190,
    height: 190,
    decoration: BoxDecoration(
      color: const Color(0xFFF2E9E0),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '$message.\nUse o codigo copia e cola abaixo.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8A7363),
          ),
        ),
      ),
    ),
  );

  Widget _copyPasteField(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFF2E9E0),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            payment.copyPasteCode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0XFF5A4636),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: payment.copyPasteCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Codigo copiado')),
            );
          },
          child: Text(
            'Copiar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0XFFE23725),
            ),
          ),
        ),
      ],
    ),
  );
}
