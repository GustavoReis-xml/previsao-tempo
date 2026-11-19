import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatadores.dart';
import '../../models/previsao_dia.dart';

class GraficoIuv extends StatelessWidget {
  const GraficoIuv({
    super.key,
    required this.dias,
  });

  final List<PrevisaoDia> dias;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final disponiveis = dias.where((d) => d.possuiIuv).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.corSol.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_outlined,
                    size: 18,
                    color: AppTheme.corSol,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Índice Ultravioleta (IUV)',
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Nível de radiação UV previsto por dia',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (disponiveis.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tema.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Índice ultravioleta não disponibilizado pelo CPTEC/INPE para este período.',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 180,
                child: _construirGrafico(context, disponiveis),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirGrafico(BuildContext context, List<PrevisaoDia> disponiveis) {
    final tema = Theme.of(context);
    final maiorIuv = disponiveis.map((d) => d.iuv!).reduce(math.max);
    final maxY = math.max(((maiorIuv + 2) / 3).ceil() * 3.0, 12.0);
    final intervaloY = maxY / 4;

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: intervaloY,
          getDrawingHorizontalLine: (_) => FlLine(
            color: tema.colorScheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(
              color: tema.colorScheme.outlineVariant.withValues(alpha: 0.8),
            ),
            left: BorderSide(
              color: tema.colorScheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: intervaloY,
              getTitlesWidget: (valor, meta) {
                if (valor == meta.max) return const SizedBox.shrink();
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    valor.round().toString(),
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (valor, meta) {
                final idx = valor.toInt();
                if (idx < 0 || idx >= dias.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    Formatadores.formatarDataCurta(dias[idx].data),
                    style: tema.textTheme.labelSmall?.copyWith(
                      color: tema.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipColor: (_) => const Color(0xFF0F172A),
            getTooltipItem: (grupo, grupoIdx, barra, barraIdx) {
              final dia = dias[grupo.x];
              if (!dia.possuiIuv) return null;
              final classe = Formatadores.classificarIuv(dia.iuv!);
              return BarTooltipItem(
                'IUV ${Formatadores.formatarIuv(dia.iuv)}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: classe.nivel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < dias.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dias[i].possuiIuv ? dias[i].iuv! : 0,
                  color: dias[i].possuiIuv
                      ? Formatadores.classificarIuv(dias[i].iuv!).cor
                      : tema.colorScheme.outlineVariant,
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
