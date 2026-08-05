import 'package:signals_flutter/signals_flutter.dart';

class ScaffoldController {
  final pageIndex = signal(0);
  final cartItemsCount = signal(0);

  void goTo(int index) {
    if (pageIndex.value == index) return;
    pageIndex.value = index;
  }

  void setCartItemsCount(int count) => cartItemsCount.value = count;

  void dispose() {
    pageIndex.dispose();
    cartItemsCount.dispose();
  }
}
