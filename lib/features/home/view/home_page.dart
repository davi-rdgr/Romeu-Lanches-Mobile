import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/feedback_view.dart';
import 'package:romeu_lanches_mobile/components/page_content.dart';
import 'package:romeu_lanches_mobile/components/section_title.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/features/addresses/view/addresses_page.dart';
import 'package:romeu_lanches_mobile/features/auth/view/login_page.dart';
import 'package:romeu_lanches_mobile/features/cart/components/cart_button.dart';
import 'package:romeu_lanches_mobile/features/cart/components/cart_toast.dart';
import 'package:romeu_lanches_mobile/features/cart/data/cart_controller.dart';
import 'package:romeu_lanches_mobile/features/catalog/components/category_chips.dart';
import 'package:romeu_lanches_mobile/features/catalog/components/menu_row.dart';
import 'package:romeu_lanches_mobile/features/catalog/components/search_field.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/menu_item.dart';
import 'package:romeu_lanches_mobile/features/catalog/view/product_details_page.dart';
import 'package:romeu_lanches_mobile/features/home/components/product_card.dart';
import 'package:romeu_lanches_mobile/features/home/components/promo_banner.dart';
import 'package:romeu_lanches_mobile/features/home/components/store_card.dart';
import 'package:signals_flutter/signals_flutter.dart';

class HomePage extends SignalWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = deps.catalogFullDependencies.catalog;
    final cart = deps.cartFullDependencies.cart;

    final isSearching = catalog.isSearching.value;
    final results = catalog.searchResults.value;
    final highlighted = catalog.highlightedItems.value;
    final allItems = catalog.allItems.value;
    final isLoading = catalog.isLoading.value;
    final error = catalog.errorMessage.value;

    return PageContent(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            catalog.load(),
            deps.storeFullDependencies.store.load(),
          ]);
        },
        color: const Color(0xFFE23725),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 14),
                    child: Row(
                      children: [
                        Flexible(child: _addressHeader(context)),
                        const Spacer(),
                        CartButton(cart: cart),
                      ],
                    ),
                  ),
                  SearchField(catalog: catalog),
                  const SizedBox(height: 14),
                  if (!isSearching) ...[
                    const StoreCard(),
                    const SizedBox(height: 14),
                    CategoryChips(
                      catalog: catalog,
                      onSelected: (_) =>
                          deps.scaffoldFullDependencies.scaffold.goTo(1),
                    ),
                    const SizedBox(height: 18),
                    const PromoBanner(),
                    const SizedBox(height: 18),
                  ],
                ],
              ),
            ),

            if (isSearching)
              ..._searchSlivers(context, results, cart)
            else if (isLoading && allItems.isEmpty)
              const SliverToBoxAdapter(child: LoadingView())
            else if (error != null && allItems.isEmpty)
              SliverToBoxAdapter(
                child: FeedbackView(
                  icon: Icons.wifi_off,
                  title: 'Nao foi possivel carregar o cardapio',
                  message: error,
                  actionLabel: 'Tentar de novo',
                  onAction: catalog.load,
                ),
              )
            else if (allItems.isEmpty)
              const SliverToBoxAdapter(
                child: FeedbackView(
                  icon: Icons.restaurant_menu,
                  title: 'Cardapio vazio',
                  message: 'A loja ainda nao publicou itens disponiveis.',
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SectionTitle('Mais pedidos'),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 170,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: highlighted.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = highlighted[index];
                      return ProductCard(
                        item: item,
                        onTap: () => openProductDetails(context, item),
                        onAdd: () {
                          cart.addProduct(item.id);
                          showAddedToast(context);
                        },
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 18),
                    SectionTitle('Cardapio completo'),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              SliverList.separated(
                itemCount: allItems.length,
                separatorBuilder: (_, _) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = allItems[index];
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
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  /// Mostra o endereco selecionado. Sem sessao nao ha enderecos salvos, entao
  /// o toque abre o login primeiro.
  Widget _addressHeader(BuildContext context) {
    final addresses = deps.addressesFullDependencies.addresses;
    final isLoggedIn = deps.authFullDependencies.auth.isLoggedIn.value;
    final selected = addresses.selected.value;

    final label = !isLoggedIn
        ? 'Entrar para escolher'
        : selected?.summary ?? 'Cadastrar endereco';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final loggedIn = await ensureLoggedIn(context);
        if (!loggedIn || !context.mounted) return;
        await openAddresses(context, selecting: true);
      },
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
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0XFF2A1810),
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _searchSlivers(
    BuildContext context,
    List<MenuItem> results,
    CartController cart,
  ) {
    if (results.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: FeedbackView(
            icon: Icons.search_off,
            title: 'Nada encontrado',
            message: 'Tente outro nome — bauru, x-tudo, pizza...',
          ),
        ),
      ];
    }

    return [
      SliverList.separated(
        itemCount: results.length,
        separatorBuilder: (_, _) => const Divider(height: 24),
        itemBuilder: (context, index) {
          final item = results[index];
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
    ];
  }

}
