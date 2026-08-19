import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/components/price_line.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';
import 'package:romeu_lanches_mobile/features/orders/view/order_tracking_page.dart';

class OrderConfirmedPage extends StatelessWidget {
  final Order order;

  const OrderConfirmedPage({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final store = deps.storeFullDependencies.store;
    final isDelivery = order.deliveryMethod == DeliveryMethod.delivery;

    final paymentLabel = switch (order.paymentMethod) {
      PaymentMethod.pix => 'Pix - pago',
      PaymentMethod.card => isDelivery
          ? 'Cartão na entrega'
          : 'Cartão na retirada',
      PaymentMethod.cash => isDelivery
          ? 'Dinheiro na entrega'
          : 'Dinheiro na retirada',
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B9E54), Color(0xFF35C97A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF1B9E54),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pedido confirmado!',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // O numero sequencial e o que o cliente fala no balcao.
                      'Pedido #${order.number}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Surface(
                child: Column(
                  children: [
                    PriceLine(
                      label: 'Tempo estimado',
                      value: store.estimatedTimeLabel(order.deliveryMethod),
                    ),
                    PriceLine(
                      label: 'Tipo',
                      value: order.deliveryMethod.label,
                    ),
                    PriceLine(label: 'Pagamento', value: paymentLabel),
                    if (order.address != null)
                      PriceLine(
                        label: 'Endereço',
                        value: order.address!.summary,
                      ),
                    const Divider(height: 20),
                    PriceLine(
                      label: 'Total',
                      value: formatMoney(order.total),
                      strong: true,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderTrackingPage(orderId: order.id),
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFFE23725),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Acompanhar pedido',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0XFFFFFFFF),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  deps.scaffoldFullDependencies.scaffold.goTo(0);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  'Voltar ao início',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0XFF9A7E6A),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
