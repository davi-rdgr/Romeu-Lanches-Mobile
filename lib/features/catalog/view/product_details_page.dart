import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/app_text_field.dart';
import 'package:romeu_lanches_mobile/components/money.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/core/network/api_exception.dart';
import 'package:romeu_lanches_mobile/features/cart/components/cart_toast.dart';
import 'package:romeu_lanches_mobile/features/cart/components/quantity_button.dart';
import 'package:romeu_lanches_mobile/features/catalog/components/product_image.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/add_on.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/menu_item.dart';

Future<void> openProductDetails(BuildContext context, MenuItem product) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product)),
  );
}

/// Detalhes do produto: foto, descricao, adicionais da categoria, observacao e
/// quantidade. E aqui que a linha do carrinho e montada — o botao "+" da
/// listagem e so um atalho para "uma unidade, sem adicionais".
class ProductDetailsPage extends StatefulWidget {
  final MenuItem product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final _noteController = TextEditingController();
  final _selectedAddOnIds = <String>{};

  List<AddOn> _addOns = const [];
  bool _isLoadingAddOns = true;
  String? _addOnsError;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadAddOns();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAddOns() async {
    setState(() {
      _isLoadingAddOns = true;
      _addOnsError = null;
    });
    try {
      final result = await deps.catalogFullDependencies.catalog.addOnsFor(
        widget.product.id,
      );
      if (!mounted) return;
      setState(() {
        _addOns = result;
        _isLoadingAddOns = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _addOnsError = error.displayMessage;
        _isLoadingAddOns = false;
      });
    }
  }

  List<AddOn> get _selectedAddOns =>
      _addOns.where((addOn) => _selectedAddOnIds.contains(addOn.id)).toList();

  double get _unitPrice =>
      widget.product.price +
      _selectedAddOns.fold(0.0, (sum, addOn) => sum + addOn.price);

  double get _total => _unitPrice * _quantity;

  void _addToCart() {
    deps.cartFullDependencies.cart.addItem(
      product: widget.product,
      quantity: _quantity,
      addOns: _selectedAddOns,
      note: _noteController.text,
    );
    // O toast entra no overlay do Navigator raiz, entao sobrevive ao pop — mas
    // precisa ser inserido antes, com o context ainda ativo.
    showAddedToast(context);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0XFFFFF7F0),
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0XFFF2E9E0),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 18),
                color: const Color(0XFF2A1810),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ProductImage(
                imageUrl: product.imageUrl,
                borderRadius: 0,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.categoryName.isNotEmpty)
                    Text(
                      product.categoryName.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9A7E6A),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0XFF2A1810),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (product.description.isNotEmpty)
                    Text(
                      product.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0XFF8A7363),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    formatMoney(product.price),
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFE23725),
                    ),
                  ),
                  if (!product.available) ...[
                    const SizedBox(height: 12),
                    _unavailableBanner(),
                  ],
                  const SizedBox(height: 22),
                  _addOnsSection(),
                  const SizedBox(height: 22),
                  Text(
                    'Alguma observacao?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0XFF2A1810),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _noteController,
                    hintText: 'Ex: sem cebola, bem passado',
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 22),
                  _quantityRow(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FilledButton(
          onPressed: product.available ? _addToCart : null,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            backgroundColor: const Color(0xFFE23725),
            disabledBackgroundColor: const Color(0xFFD9CBB8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                product.available
                    ? 'Adicionar ao carrinho'
                    : 'Produto indisponivel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0XFFFFFFFF),
                ),
              ),
              if (product.available) ...[
                const Spacer(),
                Text(
                  formatMoney(_total),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0XFFFFFFFF),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _unavailableBanner() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFDEDEB),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, size: 16, color: Color(0xFFE23725)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Esse item esta fora do cardapio agora.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE23725),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _addOnsSection() {
    if (_isLoadingAddOns) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFB59A86),
            ),
          ),
        ),
      );
    }

    if (_addOnsError != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Nao foi possivel carregar os adicionais.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8A7363),
              ),
            ),
          ),
          TextButton(onPressed: _loadAddOns, child: const Text('Tentar de novo')),
        ],
      );
    }

    if (_addOns.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adicionais',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: const Color(0XFF2A1810),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Escolha quantos quiser',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0XFF9A7E6A),
          ),
        ),
        const SizedBox(height: 8),
        for (final addOn in _addOns) _addOnRow(addOn),
      ],
    );
  }

  Widget _addOnRow(AddOn addOn) {
    final selected = _selectedAddOnIds.contains(addOn.id);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() {
        if (selected) {
          _selectedAddOnIds.remove(addOn.id);
        } else {
          _selectedAddOnIds.add(addOn.id);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: selected,
              onChanged: (_) => setState(() {
                if (selected) {
                  _selectedAddOnIds.remove(addOn.id);
                } else {
                  _selectedAddOnIds.add(addOn.id);
                }
              }),
              activeColor: const Color(0xFFE23725),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              side: const BorderSide(color: Color(0xFFD9CBB8), width: 1.5),
            ),
            Expanded(
              child: Text(
                addOn.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0XFF2A1810),
                ),
              ),
            ),
            Text(
              '+ ${formatMoney(addOn.price)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0XFF5A4636),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quantityRow() => Row(
    children: [
      Text(
        'Quantidade',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: const Color(0XFF2A1810),
        ),
      ),
      const Spacer(),
      QuantityButton(
        icon: Icons.remove,
        onTap: () => setState(() {
          if (_quantity > 1) _quantity--;
        }),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(
          '$_quantity',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0XFF2A1810),
          ),
        ),
      ),
      QuantityButton(
        icon: Icons.add,
        onTap: () => setState(() => _quantity++),
      ),
    ],
  );
}
