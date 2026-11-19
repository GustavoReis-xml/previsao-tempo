import 'package:sqflite/sqflite.dart';

import '../../models/cidade.dart';
import '../../models/previsao_cidade.dart';
import '../../models/previsao_dia.dart';
import '../database/banco_previsao.dart';

class RepositorioPrevisao {
  RepositorioPrevisao(this._banco);

  final BancoPrevisao _banco;

  /// Salva/atualiza a cidade como selecionada e persiste o cache da previsão de 4 dias.
  Future<Cidade> salvarPrevisao(PrevisaoCidade previsao) async {
    final db = await _banco.conexao;
    return db.transaction((txn) async {
      final existente = await txn.query(
        'cidades_salvas',
        columns: ['favorita'],
        where: 'id = ?',
        whereArgs: [previsao.cidade.id],
        limit: 1,
      );
      final eraFavorita = existente.isNotEmpty
          ? ((existente.first['favorita'] as num? ?? 0) == 1)
          : previsao.cidade.favorita;

      await txn.update('cidades_salvas', {'selecionada': 0});

      final cidadeAtualizada = previsao.cidade.copyWith(
        favorita: eraFavorita,
        selecionada: true,
        ultimaConsulta: DateTime.now().toUtc(),
      );

      await txn.insert(
        'cidades_salvas',
        cidadeAtualizada.toMap(
          atualizacaoCptec: previsao.atualizacao,
          atualizadoEm: previsao.atualizadoEmLocal ?? DateTime.now().toUtc(),
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await txn.delete(
        'previsoes_cache',
        where: 'cidade_id = ?',
        whereArgs: [cidadeAtualizada.id],
      );
      for (final dia in previsao.dias) {
        await txn.insert('previsoes_cache', dia.toMap(cidadeAtualizada.id));
      }

      return cidadeAtualizada;
    });
  }

  /// Marca uma cidade como selecionada (sem apagar seu cache se já existir).
  Future<void> selecionarCidade(Cidade cidade) async {
    final db = await _banco.conexao;
    await db.transaction((txn) async {
      await txn.update('cidades_salvas', {'selecionada': 0});
      final linhas = await txn.update(
        'cidades_salvas',
        {
          'selecionada': 1,
          'ultima_consulta': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [cidade.id],
      );
      if (linhas == 0) {
        await txn.insert(
          'cidades_salvas',
          cidade
              .copyWith(
                selecionada: true,
                ultimaConsulta: DateTime.now().toUtc(),
              )
              .toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Retorna a última cidade selecionada (ou a consultada mais recentemente).
  Future<Cidade?> obterCidadeSelecionada() async {
    final db = await _banco.conexao;
    final selecionadas = await db.query(
      'cidades_salvas',
      where: 'selecionada = 1',
      limit: 1,
    );
    if (selecionadas.isNotEmpty) {
      return Cidade.fromMap(selecionadas.first);
    }
    final recentes = await db.query(
      'cidades_salvas',
      orderBy: 'favorita DESC, ultima_consulta DESC',
      limit: 1,
    );
    if (recentes.isEmpty) return null;
    return Cidade.fromMap(recentes.first);
  }

  /// Recupera a previsão salva localmente no SQLite para a cidade informada.
  Future<PrevisaoCidade?> obterPrevisaoEmCache(int cidadeId) async {
    final db = await _banco.conexao;
    final cidades = await db.query(
      'cidades_salvas',
      where: 'id = ?',
      whereArgs: [cidadeId],
      limit: 1,
    );
    if (cidades.isEmpty) return null;

    final linhaCidade = cidades.first;
    final cidade = Cidade.fromMap(linhaCidade);
    final atualizacaoStr = linhaCidade['atualizacao_cptec'] as String?;
    final atualizadoEmStr = linhaCidade['atualizado_em'] as String?;

    final linhasDias = await db.query(
      'previsoes_cache',
      where: 'cidade_id = ?',
      whereArgs: [cidadeId],
      orderBy: 'data_previsao ASC, id ASC',
    );
    if (linhasDias.isEmpty) return null;

    return PrevisaoCidade(
      cidade: cidade,
      dias: linhasDias.map(PrevisaoDia.fromMap).toList(),
      atualizacao: atualizacaoStr == null
          ? null
          : DateTime.tryParse(atualizacaoStr),
      carregadoDoCache: true,
      atualizadoEmLocal: atualizadoEmStr == null
          ? null
          : DateTime.tryParse(atualizadoEmStr)?.toUtc(),
    );
  }

  /// Lista todas as cidades salvas (favoritas primeiro, depois mais recentes).
  Future<List<Cidade>> listarCidadesSalvas() async {
    final db = await _banco.conexao;
    final linhas = await db.query(
      'cidades_salvas',
      orderBy: 'favorita DESC, ultima_consulta DESC',
    );
    return linhas.map(Cidade.fromMap).toList();
  }

  Future<void> alternarFavorita(int cidadeId, bool favorita) async {
    final db = await _banco.conexao;
    await db.update(
      'cidades_salvas',
      {'favorita': favorita ? 1 : 0},
      where: 'id = ?',
      whereArgs: [cidadeId],
    );
  }

  Future<void> excluirCidade(int cidadeId) async {
    final db = await _banco.conexao;
    await db.transaction((txn) async {
      await txn.delete(
        'previsoes_cache',
        where: 'cidade_id = ?',
        whereArgs: [cidadeId],
      );
      await txn.delete(
        'cidades_salvas',
        where: 'id = ?',
        whereArgs: [cidadeId],
      );
    });
  }
}
