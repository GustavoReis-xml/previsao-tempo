import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class CondicaoTempo {
  const CondicaoTempo({
    required this.sigla,
    required this.descricao,
    required this.icone,
    required this.cor,
  });

  final String sigla;
  final String descricao;
  final IconData icone;
  final Color cor;

  static const CondicaoTempo naoInformada = CondicaoTempo(
    sigla: 'nd',
    descricao: 'Condição não informada',
    icone: Icons.help_outline_rounded,
    cor: AppTheme.corNuvem,
  );

  /// Dicionário completo das siglas oficiais de condição do tempo do CPTEC/INPE.
  static const Map<String, CondicaoTempo> _tabelaOficial = {
    'ec': CondicaoTempo(
      sigla: 'ec',
      descricao: 'Encoberto com chuvas isoladas',
      icone: Icons.grain_rounded,
      cor: AppTheme.corChuva,
    ),
    'ci': CondicaoTempo(
      sigla: 'ci',
      descricao: 'Chuvas isoladas',
      icone: Icons.water_drop_outlined,
      cor: AppTheme.corChuva,
    ),
    'c': CondicaoTempo(
      sigla: 'c',
      descricao: 'Chuva',
      icone: Icons.water_drop_rounded,
      cor: AppTheme.corChuva,
    ),
    'in': CondicaoTempo(
      sigla: 'in',
      descricao: 'Instável',
      icone: Icons.cloud_sync_outlined,
      cor: AppTheme.corNuvem,
    ),
    'pp': CondicaoTempo(
      sigla: 'pp',
      descricao: 'Possibilidade de pancadas de chuva',
      icone: Icons.grain_rounded,
      cor: AppTheme.corChuva,
    ),
    'cm': CondicaoTempo(
      sigla: 'cm',
      descricao: 'Chuva pela manhã',
      icone: Icons.water_drop_outlined,
      cor: AppTheme.corChuva,
    ),
    'cn': CondicaoTempo(
      sigla: 'cn',
      descricao: 'Chuva à noite',
      icone: Icons.nights_stay_outlined,
      cor: AppTheme.corTempestade,
    ),
    'pt': CondicaoTempo(
      sigla: 'pt',
      descricao: 'Pancadas de chuva à tarde',
      icone: Icons.thunderstorm_outlined,
      cor: AppTheme.corChuva,
    ),
    'pm': CondicaoTempo(
      sigla: 'pm',
      descricao: 'Pancadas de chuva pela manhã',
      icone: Icons.thunderstorm_outlined,
      cor: AppTheme.corChuva,
    ),
    'np': CondicaoTempo(
      sigla: 'np',
      descricao: 'Nublado e pancadas de chuva',
      icone: Icons.thunderstorm_outlined,
      cor: AppTheme.corChuva,
    ),
    'pc': CondicaoTempo(
      sigla: 'pc',
      descricao: 'Pancadas de chuva',
      icone: Icons.thunderstorm_outlined,
      cor: AppTheme.corChuva,
    ),
    'pn': CondicaoTempo(
      sigla: 'pn',
      descricao: 'Parcialmente nublado',
      icone: Icons.wb_cloudy_outlined,
      cor: AppTheme.corSol,
    ),
    'cv': CondicaoTempo(
      sigla: 'cv',
      descricao: 'Chuvisco',
      icone: Icons.grain_rounded,
      cor: AppTheme.corMinima,
    ),
    'ch': CondicaoTempo(
      sigla: 'ch',
      descricao: 'Chuvoso',
      icone: Icons.umbrella_rounded,
      cor: AppTheme.corChuva,
    ),
    't': CondicaoTempo(
      sigla: 't',
      descricao: 'Tempestade',
      icone: Icons.thunderstorm_rounded,
      cor: AppTheme.corTempestade,
    ),
    'ps': CondicaoTempo(
      sigla: 'ps',
      descricao: 'Predomínio de sol',
      icone: Icons.wb_sunny_rounded,
      cor: AppTheme.corSol,
    ),
    'e': CondicaoTempo(
      sigla: 'e',
      descricao: 'Encoberto',
      icone: Icons.cloud_rounded,
      cor: AppTheme.corNuvem,
    ),
    'n': CondicaoTempo(
      sigla: 'n',
      descricao: 'Nublado',
      icone: Icons.cloud_outlined,
      cor: AppTheme.corNuvem,
    ),
    'cl': CondicaoTempo(
      sigla: 'cl',
      descricao: 'Céu claro',
      icone: Icons.wb_sunny_rounded,
      cor: AppTheme.corSol,
    ),
    'nv': CondicaoTempo(
      sigla: 'nv',
      descricao: 'Nevoeiro',
      icone: Icons.foggy,
      cor: AppTheme.corNuvem,
    ),
    'g': CondicaoTempo(
      sigla: 'g',
      descricao: 'Geada',
      icone: Icons.ac_unit_rounded,
      cor: AppTheme.corMinima,
    ),
    'ne': CondicaoTempo(
      sigla: 'ne',
      descricao: 'Neve',
      icone: Icons.cloudy_snowing,
      cor: AppTheme.corMinima,
    ),
    'nd': CondicaoTempo(
      sigla: 'nd',
      descricao: 'Não definido',
      icone: Icons.help_outline_rounded,
      cor: AppTheme.corNuvem,
    ),
    'pnt': CondicaoTempo(
      sigla: 'pnt',
      descricao: 'Pancadas de chuva à noite',
      icone: Icons.nights_stay_outlined,
      cor: AppTheme.corTempestade,
    ),
    'psc': CondicaoTempo(
      sigla: 'psc',
      descricao: 'Possibilidade de chuva',
      icone: Icons.water_drop_outlined,
      cor: AppTheme.corChuva,
    ),
    'pcm': CondicaoTempo(
      sigla: 'pcm',
      descricao: 'Possibilidade de chuva pela manhã',
      icone: Icons.water_drop_outlined,
      cor: AppTheme.corChuva,
    ),
    'pct': CondicaoTempo(
      sigla: 'pct',
      descricao: 'Possibilidade de chuva à tarde',
      icone: Icons.water_drop_outlined,
      cor: AppTheme.corChuva,
    ),
    'pcn': CondicaoTempo(
      sigla: 'pcn',
      descricao: 'Possibilidade de chuva à noite',
      icone: Icons.nights_stay_outlined,
      cor: AppTheme.corTempestade,
    ),
    'npt': CondicaoTempo(
      sigla: 'npt',
      descricao: 'Nublado com pancadas à tarde',
      icone: Icons.thunderstorm_outlined,
      cor: AppTheme.corChuva,
    ),
    'npn': CondicaoTempo(
      sigla: 'npn',
      descricao: 'Nublado com pancadas à noite',
      icone: Icons.nights_stay_outlined,
      cor: AppTheme.corTempestade,
    ),
    'ncn': CondicaoTempo(
      sigla: 'ncn',
      descricao: 'Nublado com possibilidade de chuva à noite',
      icone: Icons.nights_stay_outlined,
      cor: AppTheme.corTempestade,
    ),
    'nct': CondicaoTempo(
      sigla: 'nct',
      descricao: 'Nublado com possibilidade de chuva à tarde',
      icone: Icons.grain_rounded,
      cor: AppTheme.corChuva,
    ),
    'ncm': CondicaoTempo(
      sigla: 'ncm',
      descricao: 'Nublado com possibilidade de chuva pela manhã',
      icone: Icons.grain_rounded,
      cor: AppTheme.corChuva,
    ),
    'npm': CondicaoTempo(
      sigla: 'npm',
      descricao: 'Nublado com pancadas pela manhã',
      icone: Icons.thunderstorm_outlined,
      cor: AppTheme.corChuva,
    ),
    'npp': CondicaoTempo(
      sigla: 'npp',
      descricao: 'Nublado com possibilidade de chuva',
      icone: Icons.grain_rounded,
      cor: AppTheme.corChuva,
    ),
    'vn': CondicaoTempo(
      sigla: 'vn',
      descricao: 'Variação de nebulosidade',
      icone: Icons.wb_cloudy_outlined,
      cor: AppTheme.corNuvem,
    ),
    'ct': CondicaoTempo(
      sigla: 'ct',
      descricao: 'Chuva à tarde',
      icone: Icons.water_drop_rounded,
      cor: AppTheme.corChuva,
    ),
    'ppn': CondicaoTempo(
      sigla: 'ppn',
      descricao: 'Possibilidade de pancadas de chuva à noite',
      icone: Icons.nights_stay_outlined,
      cor: AppTheme.corTempestade,
    ),
    'ppt': CondicaoTempo(
      sigla: 'ppt',
      descricao: 'Possibilidade de pancadas de chuva à tarde',
      icone: Icons.grain_rounded,
      cor: AppTheme.corChuva,
    ),
    'ppm': CondicaoTempo(
      sigla: 'ppm',
      descricao: 'Possibilidade de pancadas de chuva pela manhã',
      icone: Icons.grain_rounded,
      cor: AppTheme.corChuva,
    ),
  };

  /// Converte qualquer sigla do CPTEC/INPE em descrição compreensível e ícone.
  /// Trata valores nulos, vazios ou desconhecidos de forma segura.
  static CondicaoTempo fromSigla(String? siglaBruta) {
    final limpa = siglaBruta?.trim().toLowerCase() ?? '';
    if (limpa.isEmpty || limpa == 'null') {
      return naoInformada;
    }
    return _tabelaOficial[limpa] ??
        CondicaoTempo(
          sigla: limpa,
          descricao: 'Condição não catalogada ($limpa)',
          icone: Icons.wb_cloudy_outlined,
          cor: AppTheme.corNuvem,
        );
  }
}
