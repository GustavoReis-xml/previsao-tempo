import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatadores.dart';
import '../../models/previsao_dia.dart';

class GraficoTemperaturas extends StatelessWidget {
  const GraficoTemperaturas({
    super.key,
    required this.dias,
  });

  final List<PrevisaoDia> dias;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final pontosMaxima = <FlSpot>[];
    final pontosMinima = <FlSpot>[];

    for (var i = 0; i < dias.length; i++) {
      final d = dias[i];
      if (d.maxima != null && d.maxima!.isFinite) {
        pontosMaxima.add(FlSpot(i.toDouble(), d.maxima!));
      }
      if (d.minima != null && d.minima!.isFinite) {
        pontosMinima.add(FlSpot(i.toDouble(), d.minima!));
      }
    }

    final todosValores = [
      ...pontosMaxima.map((s) => s.y),
      ...pontosMinima.map((s) => s.y),
    ];

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
                    color: AppTheme.corMaxima.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.thermostat_rounded,
                    size: 18,
                    color: AppTheme.corMaxima,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temperaturas previstas (°C)',
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Evolução de mínima e máxima nos próximos dias',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _ItemLegenda(cor: AppTheme.corMaxima, texto: 'Máxima (°C)'),
                _ItemLegenda(cor: AppTheme.corMinima, texto: 'Mínima (°C)'),
              ],
            ),
            const SizedBox(height: 16),
            if (todosValores.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tema.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Dados de temperatura indisponíveis para montar o gráfico.',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              SizedBox(
                height: 215,
                child: _construirGrafico(
                  context,
                  pontosMaxima,
                  pontosMinima,
                  todosValores,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirGrafico(
    BuildContext context,
    List<FlSpot> pontosMaxima,
    List<FlSpot> pontosMinima,
    List<double> todosValores,
  ) {
    final tema = Theme.of(context);
    final menor = todosValores.reduce(math.min);
    final maior = todosValores.reduce(math.max);
    final minY = ((menor - 3) / 2).floor() * 2.0;
    final maxY = ((maior + 3) / 2).ceil() * 2.0;
    final intervaloY = math.max(((maxY - minY) / 4).ceilToDouble(), 2.0);

    final minX = dias.length <= 1 ? -0.5 : -0.22;
    final maxX = dias.length <= 1 ? 0.5 : (dias.length - 1) + 0.22;

    final series = <LineChartBarData>[
      if (pontosMaxima.isNotEmpty)
        LineChartBarData(
          spots: pontosMaxima,
          isCurved: pontosMaxima.length >= 3,
          curveSmoothness: 0.28,
          preventCurveOverShooting: true,
          color: AppTheme.corMaxima,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 4.5,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: AppTheme.corMaxima,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.corMaxima.withValues(alpha: 0.16),
                AppTheme.corMaxima.withValues(alpha: 0.01),
              ],
            ),
          ),
        ),
      if (pontosMinima.isNotEmpty)
        LineChartBarData(
          spots: pontosMinima,
          isCurved: pontosMinima.length >= 3,
          curveSmoothness: 0.28,
          preventCurveOverShooting: true,
          color: AppTheme.corMinima,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 4.5,
                  color: Colors.white,
                  strokeWidth: 2.5,
                  strokeColor: AppTheme.corMinima,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.corMinima.withValues(alpha: 0.18),
                AppTheme.corMinima.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),
    ];

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.none(),
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
              reservedSize: 42,
              interval: intervaloY,
              getTitlesWidget: (valor, meta) {
                if (valor == meta.min || valor == meta.max) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(
                    '${valor.round()}°',
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
              reservedSize: 38,
              interval: 1,
              getTitlesWidget: (valor, meta) {
                if (valor != valor.roundToDouble()) {
                  return const SizedBox.shrink();
                }
                final idx = valor.toInt();
                if (idx < 0 || idx >= dias.length) {
                  return const SizedBox.shrink();
                }
                final data = dias[idx].data;
                return SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Formatadores.formatarDiaSemanaCurto(data),
                        style: tema.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tema.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        Formatadores.formatarDataCurta(data),
                        style: tema.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipColor: (_) => const Color(0xFF0F172A),
            getTooltipItems: (pontos) => pontos.map((ponto) {
              final ehMaxima = ponto.bar.color == AppTheme.corMaxima;
              return LineTooltipItem(
                '${ehMaxima ? 'Máx' : 'Mín'}: ${Formatadores.formatarTemperatura(ponto.y)}',
                TextStyle(
                  color: ehMaxima
                      ? const Color(0xFFFDBA74)
                      : const Color(0xFF7DD3FC),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: series,
      ),
    );
  }
}

class _ItemLegenda extends StatelessWidget {
  const _ItemLegenda({required this.cor, required this.texto});

  final Color cor;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
