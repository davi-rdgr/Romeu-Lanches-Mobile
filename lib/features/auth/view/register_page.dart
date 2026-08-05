import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/app_text_field.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/core/network/api_exception.dart';
import 'package:romeu_lanches_mobile/features/auth/utils/auth_input_formatters.dart';
import 'package:romeu_lanches_mobile/features/auth/utils/cpf_validator.dart';

Future<bool> openRegister(
  BuildContext context, {
  String cpf = '',
  String phone = '',
}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => RegisterPage(cpf: cpf, phone: phone)),
  );
  return result ?? false;
}

/// Cadastro do cliente. A resposta ja vem com token — nao precisa logar depois.
class RegisterPage extends StatefulWidget {
  final String cpf;
  final String phone;

  const RegisterPage({super.key, this.cpf = '', this.phone = ''});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final _cpfController = TextEditingController(text: widget.cpf);
  late final _phoneController = TextEditingController(text: widget.phone);
  final _nameController = TextEditingController();

  String? _cpfError;
  String? _phoneError;
  String? _nameError;
  String? _formError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cpfController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _cpfError = isValidCpf(_cpfController.text) ? null : 'CPF invalido';
      _phoneError = isValidPhone(_phoneController.text)
          ? null
          : 'Telefone incompleto';
      _nameError = _nameController.text.trim().length >= 2
          ? null
          : 'Informe seu nome';
      _formError = null;
    });

    return _cpfError == null && _phoneError == null && _nameError == null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await deps.authFullDependencies.auth.register(
        cpf: _cpfController.text,
        name: _nameController.text,
        phone: _phoneController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        if (error.statusCode == 409) {
          // CPF ja existe: o telefone informado nao bate com o do cadastro.
          _formError =
              'Esse CPF ja tem cadastro. Volte e entre com o telefone '
              'cadastrado.';
        } else {
          _formError = error.displayMessage;
        }
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
                'Criar conta',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: const Color(0XFF2A1810),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Esse CPF ainda nao esta cadastrado. Complete os dados e pronto.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0XFF8A7363),
                ),
              ),
              const SizedBox(height: 28),
              _label('Nome'),
              const SizedBox(height: 6),
              AppTextField(
                controller: _nameController,
                hintText: 'Como devemos te chamar',
                textCapitalization: TextCapitalization.words,
                errorText: _nameError,
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
              const SizedBox(height: 16),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDEDEB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Color(0xFFE23725),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formError!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE23725),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                        'Criar conta e continuar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0XFFFFFFFF),
                        ),
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
}
