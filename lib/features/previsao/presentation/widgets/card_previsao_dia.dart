import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatadores.dart';
import '../../models/previsao_dia.dart';

class CardPrevisaoDia extends StatelessWidget {
  const CardPrevisaoDia({
    super.key,
    required this.previsao,
    this.aoTocar,
  });

  final PrevisaoDia previsao;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final condicao = previsao.condicao;
    final iuvClass = previsao.possuiIuv
        ? Formatadores.classificarIuv(previsao.iuv!)
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: condicao.cor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(condicao.icone, color: condicao.cor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${Formatadores.formatarDiaSemanaCurto(previsao.data)} • '
                      '${Formatadores.formatarData(previsao.data)}',
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: tema.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      condicao.descricao,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: tema.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (iuvClass != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: iuvClass.cor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'IUV ${Formatadores.formatarIuv(previsao.iuv)} • ${iuvClass.nivel}',
                          style: TextStyle(
                            color: iuvClass.cor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        size: 14,
                        color: AppTheme.corMaxima,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        Formatadores.formatarTemperatura(previsao.maxima),
                        style: tema.textTheme.titleSmall?.copyWith(
                          color: AppTheme.corMaxima,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_downward_rounded,
                        size: 14,
                        color: AppTheme.corMinima,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        Formatadores.formatarTemperatura(previsao.minima),
                        style: tema.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.corMinima,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (aoTocar != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
