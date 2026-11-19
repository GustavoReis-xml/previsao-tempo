import 'cidade.dart';
import 'previsao_dia.dart';

class PrevisaoCidade {
  const PrevisaoCidade({
    required this.cidade,
    required this.dias,
    this.atualizacao,
    this.carregadoDoCache = false,
    this.atualizadoEmLocal,
  });

  final Cidade cidade;
  final List<PrevisaoDia> dias;

  /// Data de atualização informada pelo serviço CPTEC/INPE (<atualizacao>).
  final DateTime? atualizacao;

  /// Indica se os dados exibidos vieram do cache SQLite local (ex.: modo offline).
  final bool carregadoDoCache;

  /// Momento local em que a previsão foi salva/atualizada no dispositivo.
  final DateTime? atualizadoEmLocal;

  bool get possuiPrevisao => dias.isNotEmpty;

  bool get possuiIuvDisponivel => dias.any((d) => d.possuiIuv);

  bool get possuiTemperaturas =>
      dias.any((d) => d.minima != null || d.maxima != null);

  PrevisaoCidade copyWith({
    Cidade? cidade,
    List<PrevisaoDia>? dias,
    DateTime? atualizacao,
    bool? carregadoDoCache,
    DateTime? atualizadoEmLocal,
  }) => PrevisaoCidade(
    cidade: cidade ?? this.cidade,
    dias: dias ?? this.dias,
    atualizacao: atualizacao ?? this.atualizacao,
    carregadoDoCache: carregadoDoCache ?? this.carregadoDoCache,
    atualizadoEmLocal: atualizadoEmLocal ?? this.atualizadoEmLocal,
  );
}
