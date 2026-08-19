import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/feedback_view.dart';
import 'package:romeu_lanches_mobile/core/config/app_config.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/core/network/api_exception.dart';
import 'package:romeu_lanches_mobile/features/checkout/components/pix_panel.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order.dart';
import 'package:romeu_lanches_mobile/features/orders/data/pix_payment.dart';
import 'package:romeu_lanches_mobile/features/orders/view/order_confirmed_page.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Cobranca PIX de um pedido recem-criado.
///
/// O app nunca confirma o pagamento: a aprovacao chega no backend pelo webhook
/// do Mercado Pago e o pedido sai de `AGUARDANDO_PAGAMENTO` para `NOVO`. Aqui
/// so exibimos o QR e esperamos.
///
/// A tela nao consulta o pedido direto: ela observa o cache do
/// `OrdersController`, entao reage igual venha o `STATUS_ATUALIZADO` pelo
/// WebSocket (o caminho normal, quase instantaneo) ou o polling de fallback.
class PixPaymentPage extends StatefulWidget {
  final Order order;

  const PixPaymentPage({super.key, required this.order});

  @override
  State<PixPaymentPage> createState() => _PixPaymentPageState();
}

class _PixPaymentPageState extends State<PixPaymentPage> {
  PixPayment? _payment;
  String? _error;
  bool _isLoading = true;
  bool _wasCancelled = false;

  /// O pedido ja saiu de `AGUARDANDO_PAGAMENTO`: nao ha mais o que observar, e
  /// o desfecho (navegar ou avisar do cancelamento) so acontece uma vez.
  bool _isSettled = false;

  Timer? _ticker;
  Timer? _poller;
  EffectCleanup? _watchOrder;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadPayment();
    _startTicker();
    _startPolling();
    _startWatching();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _poller?.cancel();
    _watchOrder?.call();
    super.dispose();
  }

  /// Idempotente no backend: chamar de novo devolve o mesmo QR enquanto o PIX
  /// estiver pendente e nao vencido.
  Future<void> _loadPayment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final payment = await deps.ordersFullDependencies.orders
          .requestPixPayment(widget.order.id);
      if (!mounted) return;
      setState(() {
        _payment = payment;
        _remaining = payment.remaining;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.displayMessage;
        _isLoading = false;
      });
    }
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final payment = _payment;
      if (payment == null) return;
      final left = payment.remaining;
      if (left == _remaining) return;
      setState(() => _remaining = left);
    });
  }

  /// Fallback do WebSocket: os eventos sao best-effort, entao continuamos
  /// recarregando o pedido de tempo em tempo.
  void _startPolling() {
    _poller = Timer.periodic(AppConfig.orderPollingInterval, (_) => _check());
  }

  /// Observa o pedido no controller. Quem escreve ali pode ser o evento do
  /// WebSocket ou o polling — os dois caem aqui.
  void _startWatching() {
    final orders = deps.ordersFullDependencies.orders;
    _watchOrder = effect(() {
      final order = orders.details.value[widget.order.id];
      if (order != null) _handleUpdate(order);
    });
  }

  /// Recarrega o pedido para ver se o webhook ja aprovou (ou se o job de
  /// expiracao cancelou). O desfecho fica no observador acima.
  Future<void> _check() =>
      deps.ordersFullDependencies.orders.refreshOrder(widget.order.id);

  void _handleUpdate(Order order) {
    if (_isSettled || order.status == OrderStatus.awaitingPayment) return;

    _isSettled = true;
    _poller?.cancel();
    _ticker?.cancel();

    // Este callback roda durante a escrita do signal (e a primeira vez, ainda
    // no initState): navegar ou dar setState aqui e cedo demais, entao o
    // desfecho vai para depois do frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (order.status == OrderStatus.cancelled) {
        setState(() => _wasCancelled = true);
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderConfirmedPage(order: order)),
      );
    });
  }

  void _goHome() {
    deps.scaffoldFullDependencies.scaffold.goTo(0);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
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
                    onPressed: _goHome,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0XFFF2E9E0),
                    ),
                    icon: const Icon(Icons.close, size: 20),
                    color: const Color(0XFF2A1810),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pedido #${widget.order.number}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0XFF2A1810),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_wasCancelled && _payment != null)
              FilledButton(
                onPressed: _check,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: const Color(0xFFE23725),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Ja paguei, verificar',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0XFFFFFFFF),
                  ),
                ),
              ),
            TextButton(
              onPressed: _goHome,
              child: Text(
                'Voltar ao inicio',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0XFF9A7E6A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_wasCancelled) {
      return const FeedbackView(
        icon: Icons.timer_off_outlined,
        title: 'Pedido cancelado',
        message:
            'O prazo do PIX venceu sem o pagamento, e o pedido foi cancelado '
            'automaticamente. Voce pode montar a sacola de novo.',
      );
    }

    if (_isLoading) return const LoadingView();

    if (_error != null) {
      return FeedbackView(
        icon: Icons.qr_code_2_outlined,
        title: 'Nao foi possivel gerar o PIX',
        message: _error,
        actionLabel: 'Tentar de novo',
        onAction: _loadPayment,
      );
    }

    final payment = _payment;
    if (payment == null) return const SizedBox.shrink();

    return ListView(
      children: [
        PixPanel(payment: payment, remaining: _remaining),
        const SizedBox(height: 24),
      ],
    );
  }
}
