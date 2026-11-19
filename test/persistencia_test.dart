import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:previsao_tempo/features/previsao/data/database/banco_previsao.dart';
import 'package:previsao_tempo/features/previsao/data/repositories/repositorio_previsao.dart';
import 'package:previsao_tempo/features/previsao/models/cidade.dart';
import 'package:previsao_tempo/features/previsao/models/condicao_tempo.dart';
import 'package:previsao_tempo/features/previsao/models/previsao_cidade.dart';
import 'package:previsao_tempo/features/previsao/models/previsao_dia.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Directory pasta;
  late BancoPrevisao banco;
  late RepositorioPrevisao repositorio;

  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('previsao_teste_');
    banco = BancoPrevisao(
      caminho: p.join(pasta.path, 'previsao_tempo.db'),
      abrir: (caminho, opcoes) =>
          databaseFactoryFfi.openDatabase(caminho, options: opcoes),
    );
    repositorio = RepositorioPrevisao(banco);
  });

  tearDown(() async {
    await banco.fechar();
    await pasta.delete(recursive: true);
  });

  PrevisaoCidade criarPrevisao(int id, String nome, String uf) =>
      PrevisaoCidade(
        cidade: Cidade(id: id, nome: nome, uf: uf),
        atualizacao: DateTime(2026, 11, 19),
        dias: [
          PrevisaoDia(
            data: DateTime(2026, 11, 20),
            condicao: CondicaoTempo.fromSigla('ps'),
            minima: 19,
            maxima: 30,
            iuv: 9.0,
          ),
          PrevisaoDia(
            data: DateTime(2026, 11, 21),
            condicao: CondicaoTempo.fromSigla('c'),
            minima: 18,
            maxima: 25,
          ),
        ],
      );

  test('persiste cidade selecionada, favoritos e cache de previsão após reabrir', () async {
    await repositorio.salvarPrevisao(
      criarPrevisao(4963, 'São José dos Campos', 'SP'),
    );
    await repositorio.alternarFavorita(4963, true);
    // Atualizar previsão preserva status de favorita
    await repositorio.salvarPrevisao(
      criarPrevisao(4963, 'São José dos Campos', 'SP'),
    );

    await banco.fechar();

    final selecionada = await repositorio.obterCidadeSelecionada();
    expect(selecionada, isNotNull);
    expect(selecionada!.id, 4963);
    expect(selecionada.favorita, isTrue);

    final cache = await repositorio.obterPrevisaoEmCache(4963);
    expect(cache, isNotNull);
    expect(cache!.carregadoDoCache, isTrue);
    expect(cache.atualizacao, DateTime(2026, 11, 19));
    expect(cache.dias.length, 2);
    expect(cache.dias.first.iuv, 9.0);
    expect(cache.dias.last.iuv, isNull);
  });

  test('excluir cidade remove também seu cache de previsões', () async {
    await repositorio.salvarPrevisao(criarPrevisao(244, 'São Paulo', 'SP'));
    await repositorio.excluirCidade(244);

    expect(await repositorio.listarCidadesSalvas(), isEmpty);
    expect(await repositorio.obterPrevisaoEmCache(244), isNull);
  });
}
