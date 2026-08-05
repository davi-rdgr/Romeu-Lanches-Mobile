import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/feedback_view.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/components/price_line.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';
import 'package:romeu_lanches_mobile/components/top_title.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/features/checkout/view/pix_payment_page.dart';
import 'package:romeu_lanches_mobile/features/orders/components/tracking_step.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Acompanhamento do pedido. Recebe o **id** e le o pedido do controller, para
/// que o avanco de status (que vem do polling) apareca sozinho na tela.
class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  @override
  void initState() {
    super.initState();
    deps.ordersFullDependencies.orders.startTracking(widget.orderId);
  }

  @override
  void dispose() {
    deps.ordersFullDependencies.orders.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = deps.ordersFullDependencies.orders;
    final store = deps.storeFullDependencies.store;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SignalBuilder(
            builder: (context) {
              final order = orders.details.value[widget.orderId];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  TopTitle(
                    title: order == null
                        ? 'Pedido'
                        : 'Pedido #${order.number}',
                    leading: IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0XFFF2E9E0),
                      ),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_outlined,
                        size: 20,
                      ),
                      color: const Color(0XFF2A1810),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (order == null)
                    const Expanded(child: LoadingView())
                  else
                    Expanded(
                      child: ListView(
                        children: [
                          _statusHeader(order, store.estimatedTimeLabel),
                          const SizedBox(height: 14),
                          if (order.awaitsPixPayment) ...[
                            _pixPendingCard(order),
                            const SizedBox(height: 14),
                          ],
                          if (order.status != OrderStatus.cancelled) ...[
                            _stepsCard(order),
                            const SizedBox(height: 14),
                          ],
                          _itemsCard(order),
                          const SizedBox(height: 14),
                          _actions(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _statusHeader(
    Order order,
    String Function(DeliveryMethod) estimatedTime,
  ) {
    final isCancelled = order.status == OrderStatus.cancelled;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCancelled
              ? const [Color(0xFF8A7363), Color(0xFFB59A86)]
              : const [Color(0XFFE23725), Color(0XFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCancelled ? 'Pedido encerrado' : 'Acompanhe seu pedido',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order.statusLabel,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if (order.isActive) ...[
            const SizedBox(height: 4),
            Text(
              'Previsao: ${estimatedTime(order.deliveryMethod)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pixPendingCard(Order order) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF3D6),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Esse pedido ainda nao foi pago. Ele so entra na cozinha depois que '
          'o PIX for confirmado.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0XFF8A6D1F),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PixPaymentPage(order: order)),
            ),
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(
              'Ver o QR Code do PIX',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFE23725),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _stepsCard(Order order) {
    final steps = order.trackingSteps;
    final currentIndex = order.currentStepIndex;

    return Surface(
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            TrackingStep(
              label: steps[i].labelFor(order.deliveryMethod),
              state: i < currentIndex
                  ? TrackingStepState.done
                  : i == currentIndex
                  ? TrackingStepState.current
                  : TrackingStepState.pending,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _itemsCard(Order order) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Itens',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0XFF2A1810),
          ),
        ),
        const SizedBox(height: 10),
        for (final item in order.items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.quantity}x ${item.name}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0XFF5A4636),
                        ),
                      ),
                      if (item.addOns.isNotEmpty)
                        Text(
                          '+ ${item.addOnsLabel}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0XFF9A7E6A),
                          ),
                        ),
                      if (item.note.isNotEmpty)
                        Text(
                          item.note,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic,
                            color: const Color(0XFF9A7E6A),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  // `subtotal` do item ja inclui os adicionais.
                  formatMoney(item.subtotal),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0XFF2A1810),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 20),
        PriceLine(label: 'Subtotal', value: formatMoney(order.subtotal)),
        if (order.deliveryFee > 0)
          PriceLine(
            label: 'Taxa de entrega',
            value: formatMoney(order.deliveryFee),
          ),
        PriceLine(
          label: 'Total',
          value: formatMoney(order.total),
          strong: true,
        ),
        if (order.note.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Observacao: ${order.note}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0XFF9A7E6A),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _actions() => OutlinedButton(
    onPressed: () {
      deps.scaffoldFullDependencies.scaffold.goTo(2);
      Navigator.of(context).popUntil((route) => route.isFirst);
    },
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      side: const BorderSide(color: Color(0xFFE7D8C8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: Text(
      'Meus pedidos',
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0XFF2A1810),
      ),
    ),
  );
}
