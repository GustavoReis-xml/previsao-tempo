import 'condicao_tempo.dart';

class PrevisaoDia {
  const PrevisaoDia({
    required this.data,
    required this.condicao,
    this.minima,
    this.maxima,
    this.iuv,
  });

  final DateTime data;
  final CondicaoTempo condicao;
  final double? minima;
  final double? maxima;

  /// Índice ultravioleta quando disponível (valores > 0 informados pelo CPTEC/INPE).
  final double? iuv;

  bool get possuiIuv => iuv != null && iuv!.isFinite && iuv! > 0;

  double? get amplitude =>
      (minima != null && maxima != null) ? (maxima! - minima!) : null;

  Map<String, Object?> toMap(int cidadeId) => {
    'cidade_id': cidadeId,
    'data_previsao':
        '${data.year.toString().padLeft(4, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.day.toString().padLeft(2, '0')}',
    'sigla_tempo': condicao.sigla,
    'minima': minima,
    'maxima': maxima,
    'iuv': possuiIuv ? iuv : null,
  };

  factory PrevisaoDia.fromMap(Map<String, Object?> mapa) {
    final dataStr = (mapa['data_previsao'] as String?) ?? '';
    final data = DateTime.tryParse(dataStr) ?? DateTime.now();
    final iuvRaw = (mapa['iuv'] as num?)?.toDouble();
    return PrevisaoDia(
      data: DateTime(data.year, data.month, data.day),
      condicao: CondicaoTempo.fromSigla(mapa['sigla_tempo'] as String?),
      minima: (mapa['minima'] as num?)?.toDouble(),
      maxima: (mapa['maxima'] as num?)?.toDouble(),
      iuv: (iuvRaw != null && iuvRaw > 0) ? iuvRaw : null,
    );
  }
}
