import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';

class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;

  /// O texto de `PRONTO` e `CONCLUIDO` muda entre entrega e retirada.
  final DeliveryMethod deliveryMethod;

  const OrderStatusChip({
    super.key,
    required this.status,
    required this.deliveryMethod,
  });

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      OrderStatus.completed => (const Color(0xFFE3F7E9), const Color(0xFF1B9E54)),
      OrderStatus.cancelled => (const Color(0xFFF0EAE4), const Color(0xFF8A7363)),
      OrderStatus.awaitingPayment => (
        const Color(0xFFFFF3D6),
        const Color(0xFF8A6D1F),
      ),
      _ => (const Color(0xFFFFF1E8), const Color(0xFFE23725)),
    };

    return Chip(
      label: Text(status.labelFor(deliveryMethod)),
      backgroundColor: background,
      side: BorderSide.none,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
    );
  }
}
