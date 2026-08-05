import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/features/catalog/view/product_details_page.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Destaque da home.
///
/// A API nao tem promocao nem preco "de/por" — nao ha campo para isso no
/// cadastro do produto. Para nao anunciar um desconto que nao existe, o banner
/// mostra o item mais caro do cardapio (tipicamente o "serve a galera") com o
/// preco real.
class PromoBanner extends SignalWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = deps.catalogFullDependencies.catalog;
    final items = catalog.allItems.value;
    if (items.isEmpty) return const SizedBox.shrink();

    final highlight = items.reduce(
      (biggest, item) => item.price > biggest.price ? item : biggest,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => openProductDetails(context, highlight),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0XFFE23725), Color(0XFFF97316)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              highlight.name,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0XFFFFFFFF),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            if (highlight.description.isNotEmpty)
              Text(
                highlight.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0XFFFFE3D6),
                ),
              ),
            Text(
              formatMoney(highlight.price),
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFD43B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
