class Cidade {
  Cidade({
    required this.id,
    required String nome,
    required String uf,
    this.favorita = false,
    this.selecionada = false,
    DateTime? ultimaConsulta,
  }) : nome = nome.trim(),
       uf = uf.trim().toUpperCase(),
       ultimaConsulta = (ultimaConsulta ?? DateTime.now()).toUtc() {
    if (id <= 0) {
      throw ArgumentError('Código da cidade inválido: $id');
    }
    if (this.nome.isEmpty) {
      throw ArgumentError('Nome da cidade não pode estar vazio.');
    }
    if (this.uf.isEmpty) {
      throw ArgumentError('UF da cidade não pode estar vazia.');
    }
  }

  /// Identificador retornado pelo serviço oficial do CPTEC/INPE.
  final int id;
  final String nome;
  final String uf;
  final bool favorita;
  final bool selecionada;
  final DateTime ultimaConsulta;

  String get nomeCompleto => '$nome - $uf';

  Cidade copyWith({
    int? id,
    String? nome,
    String? uf,
    bool? favorita,
    bool? selecionada,
    DateTime? ultimaConsulta,
  }) => Cidade(
    id: id ?? this.id,
    nome: nome ?? this.nome,
    uf: uf ?? this.uf,
    favorita: favorita ?? this.favorita,
    selecionada: selecionada ?? this.selecionada,
    ultimaConsulta: ultimaConsulta ?? this.ultimaConsulta,
  );

  Map<String, Object?> toMap({
    DateTime? atualizacaoCptec,
    DateTime? atualizadoEm,
  }) => {
    'id': id,
    'nome': nome,
    'uf': uf,
    'favorita': favorita ? 1 : 0,
    'selecionada': selecionada ? 1 : 0,
    'ultima_consulta': ultimaConsulta.toUtc().toIso8601String(),
    if (atualizacaoCptec != null)
      'atualizacao_cptec': _formatarIsoData(atualizacaoCptec),
    if (atualizadoEm != null)
      'atualizado_em': atualizadoEm.toUtc().toIso8601String(),
  };

  static String _formatarIsoData(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  factory Cidade.fromMap(Map<String, Object?> mapa) => Cidade(
    id: (mapa['id'] as num).toInt(),
    nome: mapa['nome'] as String,
    uf: mapa['uf'] as String,
    favorita: (mapa['favorita'] as num? ?? 0) == 1,
    selecionada: (mapa['selecionada'] as num? ?? 0) == 1,
    ultimaConsulta: mapa['ultima_consulta'] is String
        ? DateTime.tryParse(mapa['ultima_consulta']! as String)?.toUtc()
        : null,
  );

  @override
  bool operator ==(Object other) => other is Cidade && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
