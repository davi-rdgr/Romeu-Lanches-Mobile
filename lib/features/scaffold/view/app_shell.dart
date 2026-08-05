import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/features/account/view/account_page.dart';
import 'package:romeu_lanches_mobile/features/catalog/view/catalog_page.dart';
import 'package:romeu_lanches_mobile/features/home/view/home_page.dart';
import 'package:romeu_lanches_mobile/features/orders/view/orders_page.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AppShell extends SignalWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final scaffold = deps.scaffoldFullDependencies.scaffold;
    final pageIndex = scaffold.pageIndex.value;

    return Scaffold(
      body: IndexedStack(
        index: pageIndex,
        children: const [
          HomePage(),
          CatalogPage(),
          OrdersPage(),
          AccountPage(),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          navigationBarTheme: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                color: selected ? Color(0xFFE23725) : Color(0xFF9A7E6A),
              );
            }),
          ),
        ),
        child: NavigationBar(
          height: 78,

          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return selected
                ? GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE23725),
                  )
                : GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0XFF000000),
                  );
          }),
          selectedIndex: pageIndex,
          onDestinationSelected: scaffold.goTo,
          backgroundColor: Color(0XFFFFFFFF),
          indicatorColor: Color(0XFFFFFFFF),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Cardapio',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Pedidos',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Conta',
            ),
          ],
        ),
      ),
    );
  }
}
