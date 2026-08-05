import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/features/cart/data/cart_controller.dart';
import 'package:romeu_lanches_mobile/features/cart/view/cart_page.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CartButton extends SignalWidget {
  final CartController cart;

  const CartButton({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    final count = cart.itemsCount.value;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CartPage()));
          },
          style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFF1E8)),
          icon: Icon(Icons.shopping_cart_outlined, color: Color(0XFFE23725)),
        ),
        if (count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0XFFE23725),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0XFFFFFFFF),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
