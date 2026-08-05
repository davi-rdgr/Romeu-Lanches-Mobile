import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/feedback_view.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';
import 'package:romeu_lanches_mobile/components/top_title.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/core/network/api_exception.dart';
import 'package:romeu_lanches_mobile/features/addresses/data/address.dart';
import 'package:romeu_lanches_mobile/features/addresses/view/address_form_page.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Abre a lista de enderecos. Em `selecting: true` a tela vira seletor: tocar
/// num endereco escolhe e volta.
Future<void> openAddresses(BuildContext context, {bool selecting = false}) {
  return Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => AddressesPage(selecting: selecting)),
  );
}

class AddressesPage extends StatefulWidget {
  final bool selecting;

  const AddressesPage({super.key, this.selecting = false});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  @override
  void initState() {
    super.initState();
    deps.addressesFullDependencies.addresses.load();
  }

  Future<void> _confirmRemove(Address address) async {
    final controller = deps.addressesFullDependencies.addresses;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0XFFFFF7F0),
        title: Text(
          'Remover endereco?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0XFF2A1810),
          ),
        ),
        content: Text(
          address.summary,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0XFF8A7363),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Remover',
              style: TextStyle(color: Color(0xFFE23725)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await controller.remove(address.id);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.displayMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = deps.addressesFullDependencies.addresses;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SignalBuilder(
            builder: (context) {
              final addresses = controller.addresses.value;
              final selectedId = controller.selected.value?.id;
              final isLoading = controller.isLoading.value;
              final error = controller.errorMessage.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  TopTitle(
                    title: widget.selecting
                        ? 'Escolher endereco'
                        : 'Meus enderecos',
                    leading: IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
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
                  const SizedBox(height: 12),
                  if (isLoading && addresses.isEmpty)
                    const Expanded(child: LoadingView())
                  else if (error != null && addresses.isEmpty)
                    Expanded(
                      child: FeedbackView(
                        icon: Icons.wifi_off,
                        title: 'Nao foi possivel carregar seus enderecos',
                        message: error,
                        actionLabel: 'Tentar de novo',
                        onAction: controller.load,
                      ),
                    )
                  else if (addresses.isEmpty)
                    Expanded(
                      child: FeedbackView(
                        icon: Icons.location_off_outlined,
                        title: 'Nenhum endereco salvo',
                        message: 'Cadastre um endereco para pedir entrega.',
                        actionLabel: 'Cadastrar endereco',
                        onAction: () => openAddressForm(context),
                      ),
                    )
                  else
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: controller.load,
                        color: const Color(0xFFE23725),
                        child: ListView.separated(
                          itemCount: addresses.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final address = addresses[index];
                            return _addressCard(
                              address,
                              isSelected: address.id == selectedId,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: OutlinedButton.icon(
          onPressed: () => openAddressForm(context),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: Color(0xFFD9CBB8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          icon: const Icon(Icons.add, size: 18, color: Color(0xFFE23725)),
          label: Text(
            'Novo endereco',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFE23725),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addressCard(Address address, {required bool isSelected}) {
    final controller = deps.addressesFullDependencies.addresses;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        controller.select(address.id);
        if (widget.selecting) Navigator.of(context).pop();
      },
      child: Surface(
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected
                  ? const Color(0xFFE23725)
                  : const Color(0xFFB59A86),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.summary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0XFF2A1810),
                    ),
                  ),
                  if (address.details.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      address.details,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0XFF9A7E6A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => openAddressForm(context, address: address),
              icon: const Icon(Icons.edit_outlined, size: 18),
              color: const Color(0xFF9A7E6A),
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              onPressed: () => _confirmRemove(address),
              icon: const Icon(Icons.delete_outline, size: 18),
              color: const Color(0xFF9A7E6A),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
