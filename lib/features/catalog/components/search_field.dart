import 'package:flutter/material.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/catalog_controller.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Busca do cardapio. Filtra o que ja foi carregado de `/public/cardapio` — nao
/// ha endpoint de busca no backend, e nem precisa: o menu inteiro vem numa
/// requisicao.
class SearchField extends StatefulWidget {
  final CatalogController catalog;

  const SearchField({super.key, required this.catalog});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.catalog.clearSearch();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: SignalBuilder(
        builder: (context) {
          final isSearching = widget.catalog.isSearching.value;

          return TextField(
            controller: _controller,
            onChanged: widget.catalog.setSearchText,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              hintText: 'Buscar bauru, x-tudo, pizza...',
              hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0XFFA78D79),
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0XFFA78D79)),
              suffixIcon: isSearching
                  ? IconButton(
                      onPressed: _clear,
                      icon: const Icon(Icons.close, color: Color(0XFFA78D79)),
                    )
                  : null,
              fillColor: const Color(0xFFF2E9E0),
              filled: true,
              border: const OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(14)),
              ),
            ),
          );
        },
      ),
    );
  }
}
