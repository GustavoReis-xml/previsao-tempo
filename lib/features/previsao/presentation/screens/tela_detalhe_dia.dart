import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatadores.dart';
import '../../models/cidade.dart';
import '../../models/previsao_dia.dart';

class TelaDetalheDia extends StatelessWidget {
  const TelaDetalheDia({
    super.key,
    required this.cidade,
    required this.previsao,
    this.atualizacaoCptec,
  });

  final Cidade cidade;
  final PrevisaoDia previsao;
  final DateTime? atualizacaoCptec;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final condicao = previsao.condicao;
    final iuvClass = previsao.possuiIuv
        ? Formatadores.classificarIuv(previsao.iuv!)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(cidade.nomeCompleto)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Text(
                      Formatadores.formatarDataExtenso(previsao.data),
                      style: tema.textTheme.labelLarge?.copyWith(
                        color: tema.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: condicao.cor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        condicao.icone,
                        size: 56,
                        color: condicao.cor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      condicao.descricao,
                      style: tema.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tema.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Sigla CPTEC/INPE: ${condicao.sigla.toUpperCase()}',
                        style: tema.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CardTemperatura(
                    titulo: 'Mínima',
                    valor: Formatadores.formatarTemperatura(previsao.minima),
                    icone: Icons.arrow_downward_rounded,
                    cor: AppTheme.corMinima,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardTemperatura(
                    titulo: 'Máxima',
                    valor: Formatadores.formatarTemperatura(previsao.maxima),
                    icone: Icons.arrow_upward_rounded,
                    cor: AppTheme.corMaxima,
                  ),
                ),
              ],
            ),
            if (previsao.amplitude != null) ...[
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.thermostat_auto_rounded,
                    color: tema.colorScheme.primary,
                  ),
                  title: const Text(
                    'Amplitude térmica prevista',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    Formatadores.formatarTemperatura(previsao.amplitude),
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          color: iuvClass?.cor ?? tema.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Índice Ultravioleta (IUV)',
                            style: tema.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (iuvClass != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: iuvClass.cor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${Formatadores.formatarIuv(previsao.iuv)} • ${iuvClass.nivel}',
                              style: TextStyle(
                                color: iuvClass.cor,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      iuvClass != null
                          ? iuvClass.recomendacao
                          : 'Índice ultravioleta não disponibilizado pelo CPTEC/INPE para este dia.',
                      style: tema.textTheme.bodyMedium?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              atualizacaoCptec != null
                  ? 'Fonte: CPTEC/INPE • Atualizado em ${Formatadores.formatarData(atualizacaoCptec!)}'
                  : 'Fonte: CPTEC/INPE',
              style: tema.textTheme.labelSmall?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTemperatura extends StatelessWidget {
  const _CardTemperatura({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, size: 18, color: cor),
                const SizedBox(width: 6),
                Text(
                  titulo,
                  style: tema.textTheme.labelMedium?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: tema.textTheme.headlineSmall?.copyWith(
                color: cor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
