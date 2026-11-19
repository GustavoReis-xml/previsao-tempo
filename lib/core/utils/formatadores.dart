import 'package:flutter/material.dart';

class ClassificacaoIuv {
  const ClassificacaoIuv({
    required this.nivel,
    required this.cor,
    required this.recomendacao,
  });

  final String nivel;
  final Color cor;
  final String recomendacao;
}

class Formatadores {
  static const _diasCurtos = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  static const _diasCompletos = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];
  static const _meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static String _dois(int valor) => valor.toString().padLeft(2, '0');

  static String formatarData(DateTime data) =>
      '${_dois(data.day)}/${_dois(data.month)}/${data.year}';

  static String formatarDataCurta(DateTime data) =>
      '${_dois(data.day)}/${_dois(data.month)}';

  static String formatarDiaSemanaCurto(DateTime data) =>
      _diasCurtos[data.weekday - 1];

  static String formatarDiaSemanaCompleto(DateTime data) =>
      _diasCompletos[data.weekday - 1];

  static String formatarDataExtenso(DateTime data) =>
      '${formatarDiaSemanaCompleto(data)}, ${data.day} de ${_meses[data.month - 1]} de ${data.year}';

  static String formatarDataHoraLocal(DateTime dataHora) {
    final local = dataHora.toLocal();
    return '${formatarData(local)} ${_dois(local.hour)}:${_dois(local.minute)}';
  }

  static String formatarTemperatura(double? celsius) {
    if (celsius == null || !celsius.isFinite) return '—';
    final inteiro = celsius == celsius.roundToDouble();
    final texto = inteiro
        ? celsius.round().toString()
        : celsius.toStringAsFixed(1).replaceAll('.', ',');
    return '$texto°C';
  }

  static String formatarIuv(double? iuv) {
    if (iuv == null || !iuv.isFinite || iuv <= 0) return 'Indisponível';
    final inteiro = iuv == iuv.roundToDouble();
    return inteiro
        ? iuv.round().toString()
        : iuv.toStringAsFixed(1).replaceAll('.', ',');
  }

  static ClassificacaoIuv classificarIuv(double iuv) {
    if (iuv < 3) {
      return const ClassificacaoIuv(
        nivel: 'Baixo',
        cor: Color(0xFF16A34A),
        recomendacao: 'Risco baixo de exposição solar; óculos de sol recomendados em dias claros.',
      );
    }
    if (iuv < 6) {
      return const ClassificacaoIuv(
        nivel: 'Moderado',
        cor: Color(0xFFCA8A04),
        recomendacao: 'Use protetor solar e evite exposição prolongada perto do meio-dia.',
      );
    }
    if (iuv < 8) {
      return const ClassificacaoIuv(
        nivel: 'Alto',
        cor: Color(0xFFEA580C),
        recomendacao: 'Proteção necessária: protetor solar FPS 30+, chapéu e sombra entre 10h e 16h.',
      );
    }
    if (iuv < 11) {
      return const ClassificacaoIuv(
        nivel: 'Muito alto',
        cor: Color(0xFFDC2626),
        recomendacao: 'Proteção extra obrigatória: reduza a exposição solar direta ao máximo.',
      );
    }
    return const ClassificacaoIuv(
      nivel: 'Extremo',
      cor: Color(0xFF7C3AED),
      recomendacao: 'Evite exposição ao sol entre 10h e 16h e utilize proteção solar reforçada.',
    );
  }

  /// Remove acentos e cedilha para aumentar a compatibilidade na consulta `city` do CPTEC/INPE.
  static String removerAcentos(String texto) {
    const mapa = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
      'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'É': 'E', 'È': 'E', 'Ê': 'E', 'Ë': 'E',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
      'Í': 'I', 'Ì': 'I', 'Î': 'I', 'Ï': 'I',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'Ó': 'O', 'Ò': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
      'Ú': 'U', 'Ù': 'U', 'Û': 'U', 'Ü': 'U',
      'ç': 'c', 'Ç': 'C',
    };
    final buffer = StringBuffer();
    for (var i = 0; i < texto.length; i++) {
      final ch = texto[i];
      buffer.write(mapa[ch] ?? ch);
    }
    return buffer.toString();
  }
}
