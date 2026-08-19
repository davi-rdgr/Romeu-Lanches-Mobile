import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/feedback_view.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/components/price_line.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';
import 'package:romeu_lanches_mobile/components/top_title.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/features/cart/components/delivery_option.dart';
import 'package:romeu_lanches_mobile/features/cart/components/quantity_button.dart';
import 'package:romeu_lanches_mobile/features/cart/data/cart_controller.dart';
import 'package:romeu_lanches_mobile/features/cart/data/cart_item.dart';
import 'package:romeu_lanches_mobile/features/checkout/view/checkout_page.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CartPage extends SignalWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = deps.cartFullDependencies.cart;
    final store = deps.storeFullDependencies.store;

    final items = cart.items.value;
    final method = cart.deliveryMethod.value;
    final isDelivery = method == DeliveryMethod.delivery;
    final unavailable = cart.unavailableItems();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              TopTitle(
                title: 'Sacola',
                leading: IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0XFFF2E9E0),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20),
                  color: const Color(0XFF2A1810),
                ),
              ),
              if (items.isEmpty)
                Expanded(
                  child: FeedbackView(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Sua sacola esta vazia',
                    message: 'Escolha um lanche no cardapio para comecar.',
                    actionLabel: 'Ver cardapio',
                    onAction: () {
                      Navigator.of(context).pop();
                      deps.scaffoldFullDependencies.scaffold.goTo(1);
                    },
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      const SizedBox(height: 12),
                      if (unavailable.isNotEmpty) ...[
                        _unavailableWarning(unavailable),
                        const SizedBox(height: 14),
                      ],
                      Surface(
                        padding: EdgeInsets.zero,
                        child: Material(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              for (final item in items)
                                _CartLine(item: item, cart: cart),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Surface(
                        child: Column(
                          children: [
                            DeliveryOption(
                              selected: isDelivery,
                              onTap: () => cart.selectDeliveryMethod(
                                DeliveryMethod.delivery,
                              ),
                              title: Text(
                                'Entrega',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0XFF2A1810),
                                ),
                              ),
                              subtitle: Text(
                                store.estimatedTimeLabel(
                                  DeliveryMethod.delivery,
                                ),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0XFF9A7E6A),
                                ),
                              ),
                              trailing: Text(
                                formatMoney(store.deliveryFee.value),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0XFF2A1810),
                                ),
                              ),
                            ),
                            DeliveryOption(
                              selected: !isDelivery,
                              onTap: () =>
                                  cart.selectDeliveryMethod(DeliveryMethod.pickup),
                              title: Text(
                                'Retirar no balcão',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0XFF2A1810),
                                ),
                              ),
                              subtitle: Text(
                                store.estimatedTimeLabel(DeliveryMethod.pickup),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0XFF9A7E6A),
                                ),
                              ),
                              trailing: Text(
                                'Grátis',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0XFF1B9E54),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      PriceLine(
                        label: 'Subtotal',
                        value: formatMoney(cart.subtotal.value),
                      ),
                      PriceLine(
                        label: isDelivery ? 'Taxa de entrega' : 'Retirada',
                        value: isDelivery
                            ? formatMoney(cart.deliveryFee.value)
                            : 'Gratis',
                      ),
                      const Divider(height: 24),
                      PriceLine(
                        label: 'Total',
                        value: formatMoney(cart.total.value),
                        strong: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CheckoutPage()),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFFE23725),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Continuar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0XFFFFFFFF),
                  ),
                ),
              ),
            ),
    );
  }

  /// O `POST /app/pedidos` recusa o pedido **inteiro** se um item estiver
  /// indisponivel, entao avisamos antes de o cliente chegar no pagamento.
  Widget _unavailableWarning(List<CartItem> unavailable) {
    final names = unavailable.map((item) => item.product.name).toSet().join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDEDEB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFFE23725)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Saiu do cardapio: $names. Remova para continuar.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE23725),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  final CartItem item;
  final CartController cart;

  const _CartLine({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0XFF2A1810),
                  ),
                ),
                if (item.addOns.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '+ ${item.addOnsLabel}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0XFF5A4636),
                    ),
                  ),
                ],
                if (item.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
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
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => cart.remove(item.lineKey),
                  child: Text(
                    'Remover',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0XFFC0392B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(item.subtotal),
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0XFF2A1810),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0XFFF2E9E0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QuantityButton(
                      icon: Icons.remove,
                      onTap: () => cart.decrement(item.lineKey),
                    ),
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0XFF2A1810),
                        ),
                      ),
                    ),
                    QuantityButton(
                      icon: Icons.add,
                      onTap: () => cart.increment(item.lineKey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
