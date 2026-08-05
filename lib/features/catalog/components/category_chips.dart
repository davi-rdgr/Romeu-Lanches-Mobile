import 'package:flutter/material.dart';
import 'package:romeu_lanches_mobile/features/catalog/data/catalog_controller.dart';
import 'package:signals_flutter/signals_flutter.dart';

class CategoryChips extends SignalWidget {
  final CatalogController catalog;
  final void Function(String id)? onSelected;
  final bool showSelectedBackground;

  const CategoryChips({
    super.key,
    required this.catalog,
    this.onSelected,
    this.showSelectedBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final categories = catalog.categories.value;
    final selected = catalog.selectedCategoryId.value;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category.id == selected;

          return ChoiceChip(
            label: Text(category.name),
            selected: isSelected,
            onSelected: (_) {
              catalog.selectCategory(category.id);
              onSelected?.call(category.id);
            },
            backgroundColor: Color(0XFFF2E9E0),
            selectedColor: showSelectedBackground
                ? Color(0XFFE23725)
                : Color(0XFFF2E9E0),
            labelStyle: TextStyle(
              color: showSelectedBackground && isSelected
                  ? Color(0xFFFFFFFF)
                  : Color(0xFF5A4636),
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
            side: BorderSide.none,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
