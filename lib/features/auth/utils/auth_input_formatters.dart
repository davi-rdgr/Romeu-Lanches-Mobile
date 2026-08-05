import 'package:flutter/services.dart';

/// Formata enquanto digita: `123.456.789-09`.
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final allDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digitsOnly = allDigits.length > 11
        ? allDigits.substring(0, 11)
        : allDigits;

    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length; i++) {
      buffer.write(digitsOnly[i]);
      final isLast = i + 1 == digitsOnly.length;
      if (isLast) continue;
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('-');
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formata enquanto digita: `(51) 99999-8888` (celular) ou `(51) 3333-4444`
/// (fixo). O separador do numero so entra quando ja da para saber o tamanho.
class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final allDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digitsOnly = allDigits.length > 11
        ? allDigits.substring(0, 11)
        : allDigits;

    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(digitsOnly[i]);
      final isLast = i + 1 == digitsOnly.length;
      if (isLast) continue;
      if (i == 1) buffer.write(') ');
      // Celular (11 digitos) quebra depois do 5o numero; fixo, depois do 4o.
      if (digitsOnly.length > 10 ? i == 6 : i == 5) buffer.write('-');
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
