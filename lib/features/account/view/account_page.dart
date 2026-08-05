import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:romeu_lanches_mobile/components/page_content.dart';
import 'package:romeu_lanches_mobile/components/surface.dart';
import 'package:romeu_lanches_mobile/components/top_title.dart';
import 'package:romeu_lanches_mobile/core/di/app_dependencies.dart';
import 'package:romeu_lanches_mobile/features/account/components/account_action.dart';
import 'package:romeu_lanches_mobile/features/account/components/schedule_row.dart';
import 'package:romeu_lanches_mobile/features/addresses/view/addresses_page.dart';
import 'package:romeu_lanches_mobile/features/auth/utils/cpf_validator.dart';
import 'package:romeu_lanches_mobile/features/auth/view/login_page.dart';
import 'package:romeu_lanches_mobile/features/store/data/business_hours.dart';
import 'package:signals_flutter/signals_flutter.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = deps.authFullDependencies.auth;
    final store = deps.storeFullDependencies.store;

    return PageContent(
      child: SignalBuilder(
        builder: (context) {
          final session = auth.session.value;
          final hours = store.hours.value;
          final today = BusinessHours.todayWeekday();

          return ListView(
            children: [
              const SizedBox(height: 8),
              TopTitle(
                title: 'Conta',
                leading: IconButton.filledTonal(
                  onPressed: () =>
                      deps.scaffoldFullDependencies.scaffold.goTo(0),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0XFFF2E9E0),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20),
                  color: const Color(0XFF2A1810),
                ),
              ),
              const SizedBox(height: 16),
              if (session == null)
                _loggedOutCard(context)
              else
                Surface(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFFF5722),
                        child: Text(
                          session.name.isEmpty
                              ? '?'
                              : session.name.characters.first.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0XFF2A1810),
                              ),
                            ),
                            // Nao ha endpoint de perfil: o que sabemos e o que
                            // o cliente digitou no login.
                            Text(
                              formatCpf(session.cpf),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0XFF9A7E6A),
                              ),
                            ),
                            Text(
                              formatPhone(session.phone),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0XFF9A7E6A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              Surface(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.schedule,
                        color: Color(0xFFE23725),
                      ),
                      title: Text(
                        'Horario de funcionamento',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0XFF2A1810),
                        ),
                      ),
                      subtitle: Text(
                        // O horario e informativo: quem manda e o toggle da loja.
                        'A loja pode abrir ou fechar fora desse horario.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0XFF9A7E6A),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    if (hours.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Horarios nao carregados.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0XFF9A7E6A),
                          ),
                        ),
                      )
                    else
                      for (final row in hours)
                        ScheduleRow(
                          hours: row,
                          isToday: row.weekday == today,
                        ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AccountAction(
                title: 'Historico de pedidos',
                icon: Icons.receipt_long_outlined,
                onTap: () => deps.scaffoldFullDependencies.scaffold.goTo(2),
              ),
              const SizedBox(height: 10),
              AccountAction(
                title: 'Enderecos salvos',
                icon: Icons.location_on_outlined,
                onTap: () async {
                  final loggedIn = await ensureLoggedIn(context);
                  if (!loggedIn || !context.mounted) return;
                  await openAddresses(context);
                },
              ),
              const SizedBox(height: 24),
              if (session != null)
                TextButton(
                  onPressed: () => _confirmLogout(context),
                  child: Text(
                    'Sair da conta',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0XFFC0392B),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _loggedOutCard(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voce nao esta logado',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0XFF2A1810),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Entrar e opcional para ver o cardapio — so precisa na hora de '
          'finalizar o pedido.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0XFF9A7E6A),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: () => openLogin(context),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
            backgroundColor: const Color(0xFFE23725),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          child: Text(
            'Entrar ou criar conta',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0XFFFFF7F0),
        title: Text(
          'Sair da conta?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0XFF2A1810),
          ),
        ),
        content: Text(
          'Voce vai precisar do CPF e do telefone para entrar de novo.',
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
              'Sair',
              style: TextStyle(color: Color(0xFFE23725)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deps.authFullDependencies.auth.logout();
    }
  }
}
