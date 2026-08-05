import 'package:romeu_lanches_mobile/core/network/api_exception.dart';
import 'package:romeu_lanches_mobile/features/addresses/data/address.dart';
import 'package:romeu_lanches_mobile/features/addresses/data/address_repository.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AddressController {
  final AddressRepository _repository;

  AddressController(this._repository);

  final addresses = signal<List<Address>>([]);
  final selectedId = signal<String?>(null);
  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);

  late final selected = computed(() {
    final list = addresses.value;
    if (list.isEmpty) return null;
    final id = selectedId.value;
    for (final address in list) {
      if (address.id == id) return address;
    }
    // Sem escolha explicita, vale o mais recente (a API ja ordena assim).
    return list.first;
  });

  late final isEmpty = computed(() => addresses.value.isEmpty);

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await _repository.fetchAll();
      addresses.value = result;
      final stillThere = result.any(
        (address) => address.id == selectedId.value,
      );
      if (!stillThere) selectedId.value = result.isEmpty ? null : result.first.id;
    } on ApiException catch (error) {
      errorMessage.value = error.displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  /// Cria e ja deixa selecionado — quem acabou de cadastrar quer usar esse.
  Future<Address> create(Address address) async {
    final created = await _repository.create(address);
    addresses.value = [created, ...addresses.value];
    selectedId.value = created.id;
    return created;
  }

  Future<Address> update(Address address) async {
    final updated = await _repository.update(address);
    addresses.value = addresses.value
        .map((item) => item.id == updated.id ? updated : item)
        .toList(growable: false);
    return updated;
  }

  Future<void> remove(String id) async {
    await _repository.remove(id);
    addresses.value = addresses.value
        .where((address) => address.id != id)
        .toList(growable: false);
    if (selectedId.value == id) {
      selectedId.value = addresses.value.isEmpty
          ? null
          : addresses.value.first.id;
    }
  }

  void select(String id) => selectedId.value = id;

  /// Chamado no logout: os enderecos sao do cliente que saiu.
  void clear() {
    addresses.value = [];
    selectedId.value = null;
    errorMessage.value = null;
  }

  void dispose() {
    addresses.dispose();
    selectedId.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    selected.dispose();
    isEmpty.dispose();
  }
}
