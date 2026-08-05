import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/app_text_field.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/core/network/api_exception.dart';
import 'package:romeu_lanches_mobile/features/auth/utils/auth_input_formatters.dart';
import 'package:romeu_lanches_mobile/features/auth/utils/cpf_validator.dart';
import 'package:romeu_lanches_mobile/features/auth/view/register_page.dart';

/// Devolve `true` quando o cliente terminou logado (por login ou cadastro).
Future<bool> openLogin(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginPage()),
  );
  return result ?? false;
}

/// Garante sessao antes de uma acao que exige `/app/**`. Se ja esta logado, nao
/// mostra nada.
Future<bool> ensureLoggedIn(BuildContext context) async {
  if (deps.authFullDependencies.auth.isLoggedIn.value) return true;
  return openLogin(context);
}

/// Login do cliente: **CPF + telefone**, sem senha e sem e-mail.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _cpfError;
  String? _phoneError;
  String? _formError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cpfController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _validate() {
    final cpf = _cpfController.text;
    final phone = _phoneController.text;

    setState(() {
      _cpfError = isValidCpf(cpf) ? null : 'CPF invalido';
      _phoneError = isValidPhone(phone) ? null : 'Telefone incompleto';
      _formError = null;
    });

    return _cpfError == null && _phoneError == null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await deps.authFullDependencies.auth.login(
        cpf: _cpfController.text,
        phone: _phoneController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;

      // CPF nao existe: leva direto para o cadastro com o que ja foi digitado.
      if (error.isNotRegistered) {
        final registered = await openRegister(
          context,
          cpf: _cpfController.text,
          phone: _phoneController.text,
        );
        if (!mounted) return;
        if (registered) {
          Navigator.of(context).pop(true);
          return;
        }
        setState(() => _isSubmitting = false);
        return;
      }

      setState(() {
        _isSubmitting = false;
        // 401 aqui significa telefone que nao confere com o CPF.
        _formError = error.isUnauthorized
            ? 'O telefone nao confere com esse CPF.'
            : error.displayMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              const SizedBox(height: 8),
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(false),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0XFFF2E9E0),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20),
                color: const Color(0XFF2A1810),
              ),
              const SizedBox(height: 24),
              Text(
                'Entrar',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0XFF2A1810),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'So o CPF e o telefone. Nao pedimos senha nem e-mail.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0XFF8A7363),
                ),
              ),
              const SizedBox(height: 28),
              _label('CPF'),
              const SizedBox(height: 6),
              AppTextField(
                controller: _cpfController,
                hintText: '000.000.000-00',
                keyboardType: TextInputType.number,
                inputFormatters: [CpfInputFormatter()],
                errorText: _cpfError,
                onChanged: (_) {
                  if (_cpfError != null) setState(() => _cpfError = null);
                },
              ),
              const SizedBox(height: 16),
              _label('Telefone'),
              const SizedBox(height: 6),
              AppTextField(
                controller: _phoneController,
                hintText: '(00) 00000-0000',
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                errorText: _phoneError,
                onChanged: (_) {
                  if (_phoneError != null) setState(() => _phoneError = null);
                },
                onSubmitted: (_) => _submit(),
              ),
              if (_formError != null) ...[
                const SizedBox(height: 14),
                _errorBanner(_formError!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: const Color(0xFFE23725),
                  disabledBackgroundColor: const Color(0xFFD9CBB8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Entrar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0XFFFFFFFF),
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              Text(
                'Primeira vez? Se o CPF ainda nao estiver cadastrado, a gente '
                'abre o cadastro para voce.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0XFF9A7E6A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.plusJakartaSans(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: const Color(0XFF2A1810),
    ),
  );

  Widget _errorBanner(String message) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFDEDEB),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, size: 16, color: Color(0xFFE23725)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE23725),
            ),
          ),
        ),
      ],
    ),
  );
}
