import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/previsao/data/database/banco_previsao.dart';
import 'features/previsao/data/repositories/repositorio_previsao.dart';
import 'features/previsao/presentation/screens/tela_previsao.dart';
import 'features/previsao/services/cptec_inpe_service.dart';

class AppPrevisaoTempo extends StatefulWidget {
  const AppPrevisaoTempo({
    super.key,
    this.servico,
    this.repositorio,
  });

  final CptecInpeService? servico;
  final RepositorioPrevisao? repositorio;

  @override
  State<AppPrevisaoTempo> createState() => _AppPrevisaoTempoState();
}

class _AppPrevisaoTempoState extends State<AppPrevisaoTempo> {
  late final CptecInpeService _servico;
  late final RepositorioPrevisao _repositorio;
  late final bool _criouServico;

  @override
  void initState() {
    super.initState();
    _criouServico = widget.servico == null;
    _servico = widget.servico ?? CptecInpeService();
    _repositorio = widget.repositorio ?? RepositorioPrevisao(BancoPrevisao());
  }

  @override
  void dispose() {
    if (_criouServico) {
      _servico.fechar();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Previsão do Tempo — CPTEC/INPE',
    debugShowCheckedModeBanner: false,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.construir(),
    home: TelaPrevisao(
      servico: _servico,
      repositorio: _repositorio,
    ),
  );
}
