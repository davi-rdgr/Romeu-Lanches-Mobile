/// Valida CPF pelos digitos verificadores, do mesmo jeito que o backend faz.
/// Vale validar aqui para nao gastar uma requisicao num `400 CPF invalido`.
bool isValidCpf(String value) {
  final digits = onlyDigits(value);
  if (digits.length != 11) return false;

  // 000.000.000-00, 111.111.111-11 etc. passam na conta dos digitos, mas nao
  // sao CPFs validos.
  if (RegExp(r'^(\d)\1{10}$').hasMatch(digits)) return false;

  final numbers = digits.split('').map(int.parse).toList();

  for (var position = 9; position < 11; position++) {
    var sum = 0;
    for (var i = 0; i < position; i++) {
      sum += numbers[i] * (position + 1 - i);
    }
    final remainder = (sum * 10) % 11;
    final expected = remainder == 10 ? 0 : remainder;
    if (numbers[position] != expected) return false;
  }

  return true;
}

/// Telefone brasileiro: 10 digitos (fixo) ou 11 (celular).
bool isValidPhone(String value) {
  final digits = onlyDigits(value);
  return digits.length == 10 || digits.length == 11;
}

String onlyDigits(String value) => value.replaceAll(RegExp(r'\D'), '');

/// `12345678909` -> `123.456.789-09`
String formatCpf(String value) {
  final digits = onlyDigits(value);
  if (digits.length != 11) return value;
  return '${digits.substring(0, 3)}.${digits.substring(3, 6)}'
      '.${digits.substring(6, 9)}-${digits.substring(9)}';
}

/// `51999998888` -> `(51) 99999-8888`
String formatPhone(String value) {
  final digits = onlyDigits(value);
  if (digits.length < 10 || digits.length > 11) return value;
  final area = digits.substring(0, 2);
  final rest = digits.substring(2);
  final split = rest.length - 4;
  return '($area) ${rest.substring(0, split)}-${rest.substring(split)}';
}
