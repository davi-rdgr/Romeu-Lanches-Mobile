import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/app_text_field.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/core/network/api_exception.dart';
import 'package:romeu_lanches_mobile/features/addresses/data/address.dart';

/// Devolve `true` quando salvou.
Future<bool> openAddressForm(BuildContext context, {Address? address}) async {
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => AddressFormPage(address: address)),
  );
  return result ?? false;
}

class AddressFormPage extends StatefulWidget {
  /// `null` cria um endereco novo; preenchido edita o existente.
  final Address? address;

  const AddressFormPage({super.key, this.address});

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  late final _streetController = TextEditingController(
    text: widget.address?.street ?? '',
  );
  late final _numberController = TextEditingController(
    text: widget.address?.number ?? '',
  );
  late final _districtController = TextEditingController(
    text: widget.address?.district ?? '',
  );
  late final _complementController = TextEditingController(
    text: widget.address?.complement ?? '',
  );
  late final _referenceController = TextEditingController(
    text: widget.address?.reference ?? '',
  );

  String? _streetError;
  String? _numberError;
  String? _districtError;
  String? _formError;
  bool _isSubmitting = false;

  bool get _isEditing => widget.address != null;

  @override
  void dispose() {
    _streetController.dispose();
    _numberController.dispose();
    _districtController.dispose();
    _complementController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      // rua, numero e bairro sao obrigatorios no backend.
      _streetError = _streetController.text.trim().isEmpty
          ? 'Informe a rua'
          : null;
      _numberError = _numberController.text.trim().isEmpty
          ? 'Informe o numero'
          : null;
      _districtError = _districtController.text.trim().isEmpty
          ? 'Informe o bairro'
          : null;
      _formError = null;
    });

    return _streetError == null &&
        _numberError == null &&
        _districtError == null;
  }

  Future<void> _submit() async {
    if (_isSubmitting || !_validate()) return;

    final address = Address(
      id: widget.address?.id ?? '',
      street: _streetController.text,
      number: _numberController.text,
      district: _districtController.text,
      complement: _complementController.text,
      reference: _referenceController.text,
    );

    setState(() => _isSubmitting = true);
    try {
      final controller = deps.addressesFullDependencies.addresses;
      if (_isEditing) {
        await controller.update(address);
      } else {
        await controller.create(address);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _formError = error.displayMessage;
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
              const SizedBox(height: 20),
              Text(
                _isEditing ? 'Editar endereco' : 'Novo endereco',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: const Color(0XFF2A1810),
                ),
              ),
              const SizedBox(height: 22),
              _label('Rua'),
              const SizedBox(height: 6),
              AppTextField(
                controller: _streetController,
                hintText: 'Av. Brasil',
                textCapitalization: TextCapitalization.words,
                errorText: _streetError,
                onChanged: (_) {
                  if (_streetError != null) setState(() => _streetError = null);
                },
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Numero'),
                        const SizedBox(height: 6),
                        AppTextField(
                          controller: _numberController,
                          hintText: '1200',
                          errorText: _numberError,
                          onChanged: (_) {
                            if (_numberError != null) {
                              setState(() => _numberError = null);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Bairro'),
                        const SizedBox(height: 6),
                        AppTextField(
                          controller: _districtController,
                          hintText: 'Centro',
                          textCapitalization: TextCapitalization.words,
                          errorText: _districtError,
                          onChanged: (_) {
                            if (_districtError != null) {
                              setState(() => _districtError = null);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _label('Complemento'),
              const SizedBox(height: 6),
              AppTextField(
                controller: _complementController,
                hintText: 'ap 302 (opcional)',
              ),
              const SizedBox(height: 14),
              _label('Ponto de referencia'),
              const SizedBox(height: 6),
              AppTextField(
                controller: _referenceController,
                hintText: 'ao lado da praca (opcional)',
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
                        'Salvar endereco',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0XFFFFFFFF),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
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
