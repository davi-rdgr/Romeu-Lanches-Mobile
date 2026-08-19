import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/app_text_field.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/components/price_line.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';
import 'package:romeu_lanches_mobile/components/top_title.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/features/addresses/data/address.dart';
import 'package:romeu_lanches_mobile/features/addresses/view/address_form_page.dart';
import 'package:romeu_lanches_mobile/features/addresses/view/addresses_page.dart';
import 'package:romeu_lanches_mobile/features/auth/view/login_page.dart';
import 'package:romeu_lanches_mobile/features/cart/data/cart_item.dart';
import 'package:romeu_lanches_mobile/features/checkout/view/payment_page.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late final _noteController = TextEditingController(
    text: deps.cartFullDependencies.cart.note.value,
  );

  @override
  void initState() {
    super.initState();
    // Entrega exige endereco salvo; se ja esta logado, adianta a lista.
    if (deps.authFullDependencies.auth.isLoggedIn.value) {
      deps.addressesFullDependencies.addresses.load();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _goToPayment() async {
    final cart = deps.cartFullDependencies.cart;
    final store = deps.storeFullDependencies.store;
    final addresses = deps.addressesFullDependencies.addresses;
    final isDelivery = cart.deliveryMethod.value == DeliveryMethod.delivery;

    cart.setNote(_noteController.text);

    // Finalizar exige sessao — ver o cardapio nao.
    final loggedIn = await ensureLoggedIn(context);
    if (!mounted || !loggedIn) return;

    await addresses.load();
    if (!mounted) return;

    if (isDelivery && addresses.selected.value == null) {
      final created = await openAddressForm(context);
      if (!mounted || !created) return;
    }

    // Recheca antes de seguir: a loja pode ter fechado com o carrinho montado.
    final isOpen = await store.refreshIsOpen();
    if (!mounted) return;
    if (!isOpen) {
      _showClosedDialog();
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PaymentPage()));
  }

  void _showClosedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0XFFFFF7F0),
        title: Text(
          'A loja esta fechada',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0XFF2A1810),
          ),
        ),
        content: Text(
          'Nao e possivel enviar pedidos agora. Sua sacola fica salva.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0XFF8A7363),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = deps.cartFullDependencies.cart;
    final store = deps.storeFullDependencies.store;
    final addresses = deps.addressesFullDependencies.addresses;
    final auth = deps.authFullDependencies.auth;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SignalBuilder(
            builder: (context) {
              final items = cart.items.value;
              final method = cart.deliveryMethod.value;
              final isDelivery = method == DeliveryMethod.delivery;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  TopTitle(
                    title: 'Finalizar pedido',
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
                  Expanded(
                    child: ListView(
                      children: [
                        if (isDelivery)
                          _addressCard(
                            isLoggedIn: auth.isLoggedIn.value,
                            address: addresses.selected.value,
                          )
                        else
                          _pickupCard(),
                        const SizedBox(height: 14),
                        _estimatedTimeCard(store.estimatedTimeLabel(method)),
                        const SizedBox(height: 14),
                        _noteCard(),
                        const SizedBox(height: 14),
                        _summaryCard(isDelivery: isDelivery, items: items),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: _goToPayment,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: const Color(0xFFE23725),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Text(
            'Ir para pagamento',
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

  Widget _addressCard({required bool isLoggedIn, required Address? address}) {
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENTREGAR EM',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9A7E6A),
            ),
          ),
          const SizedBox(height: 4),
          if (!isLoggedIn)
            _cardTitle('Entre para escolher o endereco')
          else if (address == null)
            _cardTitle('Nenhum endereco cadastrado')
          else ...[
            _cardTitle(address.summary),
            if (address.details.isNotEmpty)
              Text(
                address.details,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0XFF9A7E6A),
                ),
              ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () async {
                final loggedIn = await ensureLoggedIn(context);
                if (!mounted || !loggedIn) return;
                await openAddresses(context, selecting: true);
              },
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                address == null ? 'Cadastrar endereço' : 'Trocar endereço',
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
  }

  Widget _pickupCard() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RETIRAR NO BALCÃO',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF9A7E6A),
          ),
        ),
        const SizedBox(height: 4),
        _cardTitle('Romeu Lanches'),
        Text(
          'Voce retira o pedido na loja — sem taxa de entrega.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0XFF9A7E6A),
          ),
        ),
      ],
    ),
  );

  Widget _estimatedTimeCard(String label) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F7E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: Color(0xFF1B9E54),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Tempo estimado',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0XFF2A1810),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: const Color(0XFF2A1810),
          ),
        ),
      ],
    ),
  );

  Widget _noteCard() => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Observação do pedido',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0XFF2A1810),
          ),
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _noteController,
          hintText: 'Ex: interfone quebrado, ligar ao chegar',
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    ),
  );

  Widget _summaryCard({
    required bool isDelivery,
    required List<CartItem> items,
  }) {
    final cart = deps.cartFullDependencies.cart;

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0XFF2A1810),
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items)
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
                          '${item.quantity}x ${item.product.name}',
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
                      ],
                    ),
                  ),
                  Text(
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
          PriceLine(
            label: 'Subtotal',
            value: formatMoney(cart.subtotal.value),
          ),
          PriceLine(
            label: isDelivery ? 'Entrega' : 'Retirada',
            value: isDelivery
                ? formatMoney(cart.deliveryFee.value)
                : 'Grátis',
          ),
          const Divider(height: 20),
          PriceLine(
            label: 'Total',
            value: formatMoney(cart.total.value),
            strong: true,
          ),
          const SizedBox(height: 6),
          /* Text(
            'O valor final e calculado pelo servidor ao enviar o pedido.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0XFF9A7E6A),
            ),
          ), */
        ],
      ),
    );
  }

  Widget _cardTitle(String text) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w800,
      color: const Color(0XFF2A1810),
    ),
  );
}
