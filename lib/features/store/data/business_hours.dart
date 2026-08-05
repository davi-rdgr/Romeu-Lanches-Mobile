/// `HorarioResponse` — horario de funcionamento publicado.
///
/// E **decorativo**: nao abre nem fecha a loja. A loja pode estar aberta fora
/// do horario publicado (e o contrario). Para disponibilidade real use sempre
/// `/public/loja/status`.
class BusinessHours {
  /// Convencao `java.time.DayOfWeek`: 1 = Segunda ... 7 = Domingo.
  /// Nao e 0-6 comecando no domingo.
  final int weekday;
  final bool open;
  final String? opensAt;
  final String? closesAt;

  const BusinessHours({
    required this.weekday,
    required this.open,
    this.opensAt,
    this.closesAt,
  });

  factory BusinessHours.fromJson(Map<String, dynamic> json) => BusinessHours(
    weekday: (json['diaSemana'] as num).toInt(),
    open: json['aberto'] as bool? ?? false,
    opensAt: _hhmm(json['abertura'] as String?),
    closesAt: _hhmm(json['fechamento'] as String?),
  );

  /// O backend manda `"HH:mm"` ou `"HH:mm:ss"`.
  static String? _hhmm(String? value) {
    if (value == null || value.isEmpty) return null;
    return value.length >= 5 ? value.substring(0, 5) : value;
  }

  static const _dayNames = [
    'Segunda',
    'Terca',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sabado',
    'Domingo',
  ];

  String get dayLabel =>
      weekday >= 1 && weekday <= 7 ? _dayNames[weekday - 1] : '-';

  /// `fechamento < abertura` e valido de proposito — significa virar a
  /// madrugada (ex.: 18:30 as 00:00). Nao ha ordem a validar.
  String get hoursLabel {
    if (!open || opensAt == null || closesAt == null) return 'Fechado';
    return '$opensAt - $closesAt';
  }

  /// Hoje na convencao do backend (`DateTime.weekday` do Dart ja e 1=Seg..7=Dom).
  static int todayWeekday() => DateTime.now().weekday;
}
