import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';

class PaymentMethodTabs extends StatelessWidget {
  final PaymentMethod selected;

  /// Somente as formas habilitadas em `/public/loja/info`. Mostrar uma forma
  /// desligada so levaria o cliente a um 400 na hora de finalizar.
  final List<PaymentMethod> available;

  final void Function(PaymentMethod) onSelected;

  const PaymentMethodTabs({
    super.key,
    required this.selected,
    required this.available,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2E9E0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final method in available)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(method),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == method
                        ? const Color(0xFFE23725)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    method.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected == method
                          ? Colors.white
                          : const Color(0xFF5A4636),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
