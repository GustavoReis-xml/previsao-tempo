import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class BancoPrevisao {
  BancoPrevisao({
    String? caminho,
    Future<Database> Function(String, OpenDatabaseOptions)? abrir,
  }) : _caminho = caminho,
       _abrir =
           abrir ??
           ((caminhoBanco, opcoes) =>
               databaseFactory.openDatabase(caminhoBanco, options: opcoes));

  final String? _caminho;
  final Future<Database> Function(String, OpenDatabaseOptions) _abrir;
  Future<Database>? _conexao;

  Future<Database> get conexao => _conexao ??= _abrirBanco();

  Future<Database> _abrirBanco() async {
    try {
      final caminho =
          _caminho ?? p.join(await getDatabasesPath(), 'previsao_tempo.db');
      return await _abrir(
        caminho,
        OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE cidades_salvas (
                id INTEGER PRIMARY KEY,
                nome TEXT NOT NULL,
                uf TEXT NOT NULL,
                favorita INTEGER NOT NULL DEFAULT 0,
                selecionada INTEGER NOT NULL DEFAULT 0,
                ultima_consulta TEXT NOT NULL,
                atualizacao_cptec TEXT,
                atualizado_em TEXT
              )
            ''');
            await db.execute('''
              CREATE TABLE previsoes_cache (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                cidade_id INTEGER NOT NULL,
                data_previsao TEXT NOT NULL,
                sigla_tempo TEXT NOT NULL,
                minima REAL,
                maxima REAL,
                iuv REAL,
                FOREIGN KEY (cidade_id) REFERENCES cidades_salvas (id) ON DELETE CASCADE
              )
            ''');
            await db.execute('''
              CREATE INDEX idx_previsoes_cidade_data
              ON previsoes_cache (cidade_id, data_previsao)
            ''');
          },
        ),
      );
    } catch (_) {
      _conexao = null;
      rethrow;
    }
  }

  Future<void> fechar() async {
    final conexao = _conexao;
    if (conexao == null) return;
    try {
      await (await conexao).close();
    } finally {
      _conexao = null;
    }
  }
}
