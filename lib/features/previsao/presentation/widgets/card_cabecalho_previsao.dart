import 'package:flutter/material.dart';

import '../../../../core/utils/formatadores.dart';
import '../../models/previsao_cidade.dart';

class CardCabecalhoPrevisao extends StatelessWidget {
  const CardCabecalhoPrevisao({
    super.key,
    required this.previsao,
    required this.aoAlternarFavorita,
  });

  final PrevisaoCidade previsao;
  final VoidCallback aoAlternarFavorita;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cidade = previsao.cidade;
    final primeiroDia = previsao.dias.isNotEmpty ? previsao.dias.first : null;

    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A4375), Color(0xFF1565A8), Color(0xFF1D7AC4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cidade.uf} • Código CPTEC ${cidade.id}',
                              style: tema.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cidade.nome,
                          style: tema.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: aoAlternarFavorita,
                    tooltip: cidade.favorita
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                    icon: Icon(
                      cidade.favorita
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: cidade.favorita
                          ? const Color(0xFFFBBF24)
                          : Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              if (primeiroDia != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        primeiroDia.condicao.icone,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${Formatadores.formatarDiaSemanaCurto(primeiroDia.data)} • '
                            '${Formatadores.formatarData(primeiroDia.data)}',
                            style: tema.textTheme.labelMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            primeiroDia.condicao.descricao,
                            style: tema.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _PillMetrica(
                                icone: Icons.arrow_downward_rounded,
                                texto:
                                    'Mín ${Formatadores.formatarTemperatura(primeiroDia.minima)}',
                              ),
                              _PillMetrica(
                                icone: Icons.arrow_upward_rounded,
                                texto:
                                    'Máx ${Formatadores.formatarTemperatura(primeiroDia.maxima)}',
                                destaque: true,
                              ),
                              if (primeiroDia.possuiIuv)
                                _PillMetrica(
                                  icone: Icons.wb_sunny_outlined,
                                  texto:
                                      'IUV ${Formatadores.formatarIuv(primeiroDia.iuv)}',
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Divider(
                height: 1,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.update_rounded,
                    size: 15,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      previsao.atualizacao != null
                          ? 'Atualização CPTEC/INPE: ${Formatadores.formatarData(previsao.atualizacao!)}'
                          : 'Atualização CPTEC/INPE: não informada',
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillMetrica extends StatelessWidget {
  const _PillMetrica({
    required this.icone,
    required this.texto,
    this.destaque = false,
  });

  final IconData icone;
  final String texto;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: destaque
            ? const Color(0xFFEA580C).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
