import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/feedback_view.dart';
import 'package:romeu_lanches_mobile/components/page_content.dart';
import 'package:romeu_lanches_mobile/components/top_title.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/features/cart/components/cart_button.dart';
import 'package:romeu_lanches_mobile/features/cart/components/cart_toast.dart';
import 'package:romeu_lanches_mobile/features/catalog/components/category_chips.dart';
import 'package:romeu_lanches_mobile/features/catalog/components/menu_row.dart';
import 'package:romeu_lanches_mobile/features/catalog/view/product_details_page.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CatalogPage extends SignalWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = deps.catalogFullDependencies.catalog;
    final cart = deps.cartFullDependencies.cart;

    final isLoading = catalog.isLoading.value;
    final error = catalog.errorMessage.value;
    final categories = catalog.categories.value;
    final selectedCategory = catalog.selectedCategory.value;
    final items = catalog.selectedItems.value;

    return PageContent(
      child: RefreshIndicator(
        onRefresh: catalog.load,
        color: const Color(0xFFE23725),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  TopTitle(
                    title: 'Cardápio',
                    trailing: CartButton(cart: cart),
                    leading: IconButton.filledTonal(
                      onPressed: () =>
                          deps.scaffoldFullDependencies.scaffold.goTo(0),
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
                  if (categories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    CategoryChips(
                      catalog: catalog,
                      showSelectedBackground: true,
                    ),
                  ],
                  if (selectedCategory != null) ...[
                    const SizedBox(height: 18),
                    Text(
                      selectedCategory.name,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0XFF2A1810),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                ],
              ),
            ),
            if (isLoading && categories.isEmpty)
              const SliverToBoxAdapter(child: LoadingView())
            else if (error != null && categories.isEmpty)
              SliverToBoxAdapter(
                child: FeedbackView(
                  icon: Icons.wifi_off,
                  title: 'Nao foi possivel carregar o cardapio',
                  message: error,
                  actionLabel: 'Tentar de novo',
                  onAction: catalog.load,
                ),
              )
            else if (items.isEmpty)
              const SliverToBoxAdapter(
                child: FeedbackView(
                  icon: Icons.restaurant_menu,
                  title: 'Nada por aqui ainda',
                  message: 'Essa categoria nao tem itens disponiveis agora.',
                ),
              )
            else
              SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return MenuRow(
                    item: item,
                    onTap: () => openProductDetails(context, item),
                    onAdd: () {
                      cart.addProduct(item.id);
                      showAddedToast(context);
                    },
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
