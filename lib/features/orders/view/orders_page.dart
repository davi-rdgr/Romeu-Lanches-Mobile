import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:romeu_lanches_mobile/components/feedback_view.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/components/page_content.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';
import 'package:romeu_lanches_mobile/components/top_title.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/features/auth/view/login_page.dart';
import 'package:romeu_lanches_mobile/features/orders/components/order_status_chip.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order.dart';
import 'package:romeu_lanches_mobile/features/orders/view/order_tracking_page.dart';
import 'package:signals_flutter/signals_flutter.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    // O historico e `/app/**`: sem sessao nao ha o que buscar.
    if (deps.authFullDependencies.auth.isLoggedIn.value) {
      deps.ordersFullDependencies.orders.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = deps.ordersFullDependencies.orders;
    final auth = deps.authFullDependencies.auth;

    return PageContent(
      child: SignalBuilder(
        builder: (context) {
          final isLoggedIn = auth.isLoggedIn.value;
          final list = orders.orders.value;
          final isLoading = orders.isLoading.value;
          final error = orders.errorMessage.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              TopTitle(
                title: 'Meus pedidos',
                leading: IconButton.filledTonal(
                  onPressed: () =>
                      deps.scaffoldFullDependencies.scaffold.goTo(0),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0XFFF2E9E0),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20),
                  color: const Color(0XFF2A1810),
                ),
              ),
              if (!isLoggedIn)
                Expanded(
                  child: FeedbackView(
                    icon: Icons.receipt_long_outlined,
                    title: 'Entre para ver seus pedidos',
                    message:
                        'Seu historico fica ligado ao seu CPF. Ver o cardapio '
                        'nao precisa de login.',
                    actionLabel: 'Entrar',
                    onAction: () async {
                      final loggedIn = await openLogin(context);
                      if (loggedIn) orders.load();
                    },
                  ),
                )
              else if (isLoading && list.isEmpty)
                const Expanded(child: LoadingView())
              else if (error != null && list.isEmpty)
                Expanded(
                  child: FeedbackView(
                    icon: Icons.wifi_off,
                    title: 'Nao foi possivel carregar seus pedidos',
                    message: error,
                    actionLabel: 'Tentar de novo',
                    onAction: orders.load,
                  ),
                )
              else if (list.isEmpty)
                const Expanded(
                  child: FeedbackView(
                    icon: Icons.receipt_long_outlined,
                    title: 'Nenhum pedido ainda',
                    message: 'Seu primeiro pedido aparece aqui.',
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: orders.load,
                    color: const Color(0xFFE23725),
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 18, bottom: 24),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) =>
                          _orderCard(list[index]),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _orderCard(OrderSummary order) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderTrackingPage(orderId: order.id),
        ),
      ),
      child: Surface(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${order.number}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0XFF2A1810),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${DateFormat('EEE, dd/MM/yy', 'pt_BR').format(order.createdAt)}'
                    ' - ${order.itemsCount} '
                    '${order.itemsCount == 1 ? 'item' : 'itens'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0XFF9A7E6A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formatMoney(order.total),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0XFF2A1810),
                    ),
                  ),
                ],
              ),
            ),
            OrderStatusChip(
              status: order.status,
              deliveryMethod: order.deliveryMethod,
            ),
          ],
        ),
      ),
    );
  }
}
