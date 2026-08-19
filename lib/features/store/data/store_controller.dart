import 'package:romeu_lanches_mobile/core/network/api_exception.dart';
import 'package:romeu_lanches_mobile/features/orders/data/order_enums.dart';
import 'package:romeu_lanches_mobile/features/store/data/business_hours.dart';
import 'package:romeu_lanches_mobile/features/store/data/store_info.dart';
import 'package:romeu_lanches_mobile/features/store/data/store_repository.dart';
import 'package:signals_flutter/signals_flutter.dart';

class StoreController {
  final StoreRepository _repository;

  StoreController(this._repository);

  final isOpen = signal(false);
  final info = signal<StoreInfo?>(null);
  final hours = signal<List<BusinessHours>>([]);
  final isLoading = signal(false);
  final errorMessage = signal<String?>(null);

  late final deliveryFee = computed(() => info.value?.deliveryFee ?? 0);
  late final estimatedMinutes = computed(() => info.value?.estimatedMinutes ?? 0);

  /// Texto do tempo estimado. Entrega usa o tempo configurado pelo admin;
  /// retirada nao tem tempo proprio na API, entao mostramos o mesmo numero sem
  /// a folga do deslocamento.
  String estimatedTimeLabel(DeliveryMethod method) {
    final minutes = estimatedMinutes.value;
    if (minutes <= 0) return '-';
    if (method == DeliveryMethod.pickup) return 'Cerca de $minutes min';
    return '$minutes-${minutes + 15} min';
  }

  late final availablePaymentMethods = computed(
    () => info.value?.availablePaymentMethods ?? const <PaymentMethod>[],
  );

  late final todayHours = computed(() {
    final today = BusinessHours.todayWeekday();
    for (final entry in hours.value) {
      if (entry.weekday == today) return entry;
    }
    return null;
  });

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final results = await Future.wait([
        _repository.fetchIsOpen(),
        _repository.fetchInfo(),
        _repository.fetchHours(),
      ]);
      isOpen.value = results[0] as bool;
      info.value = results[1] as StoreInfo;
      hours.value = results[2] as List<BusinessHours>;
    } on ApiException catch (error) {
      errorMessage.value = error.displayMessage;
    } finally {
      isLoading.value = false;
    }
  }

  /// Recheca so o `aberta` — barato o suficiente para rodar antes de abrir o
  /// checkout, evitando montar o pedido inteiro e tomar 409 no final.
  Future<bool> refreshIsOpen() async {
    try {
      final open = await _repository.fetchIsOpen();
      isOpen.value = open;
      return open;
    } on ApiException {
      // Sem resposta, nao bloqueia o fluxo: o POST do pedido ainda valida.
      return isOpen.value;
    }
  }

  void dispose() {
    isOpen.dispose();
    info.dispose();
    hours.dispose();
    isLoading.dispose();
    errorMessage.dispose();
    deliveryFee.dispose();
    estimatedMinutes.dispose();
    availablePaymentMethods.dispose();
    todayHours.dispose();
  }
}
