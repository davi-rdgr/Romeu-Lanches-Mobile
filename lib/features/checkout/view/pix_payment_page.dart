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

/// Cobranca PIX de um pedido recem-criado.
///
/// O app nunca confirma o pagamento: a aprovacao chega no backend pelo webhook
/// do Mercado Pago e o pedido sai de `AGUARDANDO_PAGAMENTO` para `NOVO`. Aqui
/// so exibimos o QR e recarregamos o pedido ate ele mudar de estado.
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

  Timer? _ticker;
  Timer? _poller;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadPayment();
    _startTicker();
    _startPolling();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _poller?.cancel();
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

  void _startPolling() {
    _poller = Timer.periodic(AppConfig.orderPollingInterval, (_) => _check());
  }

  /// Recarrega o pedido para ver se o webhook ja aprovou (ou se o job de
  /// expiracao cancelou).
  Future<void> _check() async {
    final updated = await deps.ordersFullDependencies.orders.refreshOrder(
      widget.order.id,
    );
    if (!mounted || updated == null) return;

    if (updated.status == OrderStatus.cancelled) {
      _poller?.cancel();
      _ticker?.cancel();
      setState(() => _wasCancelled = true);
      return;
    }

    if (updated.status != OrderStatus.awaitingPayment) {
      _poller?.cancel();
      _ticker?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderConfirmedPage(order: updated)),
      );
    }
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
