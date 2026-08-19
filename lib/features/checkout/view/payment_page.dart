import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/feedback_view.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/core/network/api_exception.dart';
import 'package:romeu_lanches_mobile/features/checkout/components/card_panel.dart';
import 'package:romeu_lanches_mobile/features/checkout/components/cash_panel.dart';
import 'package:romeu_lanches_mobile/features/checkout/components/payment_method_tabs.dart';
import 'package:romeu_lanches_mobile/features/checkout/view/pix_payment_page.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';
import 'package:romeu_lanches_mobile/features/orders/view/order_confirmed_page.dart';

/// Escolha da forma de pagamento e envio do pedido.
///
/// O PIX **nao** e gerado aqui: primeiro o pedido e criado (nasce
/// `AGUARDANDO_PAGAMENTO`) e so depois pedimos a cobranca, na tela seguinte.
class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  PaymentMethod? _method;
  bool _noChangeNeeded = false;
  bool _isSubmitting = false;

  final _changeForController = TextEditingController();

  @override
  void dispose() {
    _changeForController.dispose();
    super.dispose();
  }

  /// So as formas habilitadas na config da loja: mandar uma desligada volta
  /// `400 Forma de pagamento nao aceita`.
  List<PaymentMethod> get _available =>
      deps.storeFullDependencies.store.availablePaymentMethods.value;

  PaymentMethod? get _selected {
    final available = _available;
    if (available.isEmpty) return null;
    final current = _method;
    if (current != null && available.contains(current)) return current;
    return available.first;
  }

  /// A API nao tem campo de troco — vai na observacao do pedido.
  String _buildNote(PaymentMethod method) {
    final note = deps.cartFullDependencies.cart.note.value.trim();
    if (method != PaymentMethod.cash) return note;

    final parts = [if (note.isNotEmpty) note];
    if (_noChangeNeeded) {
      parts.add('Nao precisa de troco');
    } else {
      final raw = _changeForController.text.trim();
      if (raw.isNotEmpty) parts.add('Troco para R\$ $raw');
    }
    return parts.join(' | ');
  }

  Future<void> _confirm() async {
    final method = _selected;
    if (method == null || _isSubmitting) return;

    final cart = deps.cartFullDependencies.cart;
    final addresses = deps.addressesFullDependencies.addresses;
    final isDelivery = cart.deliveryMethod.value == DeliveryMethod.delivery;
    final addressId = addresses.selected.value?.id;

    if (isDelivery && (addressId == null || addressId.isEmpty)) {
      _showError('Escolha um endereco de entrega antes de continuar.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final order = await deps.ordersFullDependencies.orders.create(
        items: cart.items.value,
        deliveryMethod: cart.deliveryMethod.value,
        paymentMethod: method,
        addressId: isDelivery ? addressId : null,
        note: _buildNote(method),
      );

      cart.clear();
      if (!mounted) return;

      // PIX nasce aguardando pagamento: leva para o QR. As outras formas ja
      // entram na fila da cozinha.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => order.awaitsPixPayment
              ? PixPaymentPage(order: order)
              : OrderConfirmedPage(order: order),
        ),
        (route) => route.isFirst,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // O carrinho pode ter envelhecido: produto que saiu, loja que fechou.
      if (error.isConflict) {
        await deps.catalogFullDependencies.catalog.load();
        await deps.storeFullDependencies.store.refreshIsOpen();
      }
      if (!mounted) return;
      _showError(error.displayMessage);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF2A1810),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = deps.cartFullDependencies.cart;
    final total = cart.total.value;
    final method = _selected;
    final available = _available;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton.filledTonal(
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
                  const SizedBox(width: 10),
                  Text(
                    'Pagamento',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0XFF2A1810),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (method == null)
                const Expanded(
                  child: FeedbackView(
                    icon: Icons.payments_outlined,
                    title: 'Nenhuma forma de pagamento disponivel',
                    message:
                        'A loja desativou todas as formas de pagamento no '
                        'momento. Tente novamente mais tarde.',
                  ),
                )
              else ...[
                PaymentMethodTabs(
                  selected: method,
                  available: available,
                  onSelected: (value) => setState(() => _method = value),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      switch (method) {
                        PaymentMethod.pix => _pixNotice(total),
                        PaymentMethod.card => CardPanel(
                          total: total,
                          isDelivery:
                              cart.deliveryMethod.value ==
                              DeliveryMethod.delivery,
                        ),
                        PaymentMethod.cash => CashPanel(
                          total: total,
                          controller: _changeForController,
                          noChangeNeeded: _noChangeNeeded,
                          onNoChangeNeeded: () => setState(() {
                            _noChangeNeeded = true;
                            _changeForController.clear();
                          }),
                          onChangeInput: () =>
                              setState(() => _noChangeNeeded = false),
                        ),
                      },
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: method == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton(
                onPressed: _isSubmitting ? null : _confirm,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFFE23725),
                  disabledBackgroundColor: const Color(0xFFD9CBB8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            method == PaymentMethod.pix
                                ? 'Gerar PIX e confirmar'
                                : 'Confirmar pedido',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0XFFFFFFFF),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            formatMoney(total),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0XFFFFFFFF),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }

  /// Antes de criar o pedido nao existe QR nenhum — ele so e gerado depois.
  Widget _pixNotice(double total) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0DDCE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pagar com PIX',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0XFF2A1810),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ao confirmar, geramos o QR Code. Você tem 30 minutos para pagar — '
          'depois disso o pedido e cancelado automaticamente.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0XFF9A7E6A),
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
