import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';
import 'package:signals_flutter/signals_flutter.dart';

class StoreCard extends SignalWidget {
  const StoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = deps.storeFullDependencies.store;

    // `aberta` e a unica fonte de verdade: o horario publicado e decorativo e
    // pode nao bater com a loja estar aceitando pedidos.
    final isOpen = store.isOpen.value;
    final info = store.info.value;
    final today = store.todayHours.value;

    return Surface(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                colors: [Color(0XFFE23725), Color(0XFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                'R',
                style: GoogleFonts.bricolageGrotesque(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Romeu Lanches',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: const Color(0XFF2A1810),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: isOpen
                          ? const Color(0XFF1B9E54)
                          : const Color(0XFFE23725),
                      size: 10,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOpen ? 'Aberto' : 'Fechado',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isOpen
                            ? const Color(0XFF1B9E54)
                            : const Color(0XFFE23725),
                      ),
                    ),
                    if (info != null) ...[
                      Text(
                        ' - ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: const Color(0XFF7A6453),
                        ),
                      ),
                      Text(
                        store.estimatedTimeLabel(DeliveryMethod.delivery),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: const Color(0XFF7A6453),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  info == null
                      ? 'Carregando dados da loja...'
                      : 'Entrega ${formatMoney(info.deliveryFee)}'
                            '${today == null ? '' : ' - hoje ${today.hoursLabel.toLowerCase()}'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: const Color(0XFF7A6453),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.schedule, color: Color(0xFFB59A86), size: 17),
        ],
      ),
    );
  }
}
