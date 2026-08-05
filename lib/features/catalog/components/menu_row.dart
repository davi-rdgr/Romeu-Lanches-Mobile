import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/features/catalog/components/product_image.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/menu_item.dart';

class MenuRow extends StatelessWidget {
  final MenuItem item;

  /// Botao "+": adiciona uma unidade sem adicionais.
  final VoidCallback onAdd;

  /// Toque na linha: abre os detalhes, onde da para escolher adicionais.
  final VoidCallback? onTap;

  const MenuRow({
    super.key,
    required this.item,
    required this.onAdd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0XFF2A1810),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0XFF8A7363),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatMoney(item.price),
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE23725),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 78,
            height: 78,
            child: ProductImage(imageUrl: item.imageUrl, onAdd: onAdd),
          ),
        ],
      ),
    );
  }
}
