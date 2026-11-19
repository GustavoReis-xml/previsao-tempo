import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:previsao_tempo/app.dart';
import 'package:previsao_tempo/features/previsao/data/database/banco_previsao.dart';
import 'package:previsao_tempo/features/previsao/data/repositories/repositorio_previsao.dart';
import 'package:previsao_tempo/features/previsao/models/cidade.dart';
import 'package:previsao_tempo/features/previsao/models/previsao_cidade.dart';
import 'package:previsao_tempo/features/previsao/services/cptec_inpe_service.dart';

class RepositorioPrevisaoMemoria extends RepositorioPrevisao {
  RepositorioPrevisaoMemoria() : super(BancoPrevisao());

  final Map<int, Cidade> _cidades = {};
  final Map<int, PrevisaoCidade> _caches = {};
  int? _selecionadaId;

  @override
  Future<Cidade> salvarPrevisao(PrevisaoCidade previsao) async {
    final existente = _cidades[previsao.cidade.id];
    final atualizada = previsao.cidade.copyWith(
      favorita: existente?.favorita ?? previsao.cidade.favorita,
      selecionada: true,
    );
    _cidades[atualizada.id] = atualizada;
    _selecionadaId = atualizada.id;
    _caches[atualizada.id] = previsao.copyWith(
      cidade: atualizada,
      carregadoDoCache: true,
    );
    return atualizada;
  }

  @override
  Future<void> selecionarCidade(Cidade cidade) async {
    final existente = _cidades[cidade.id];
    _cidades[cidade.id] = cidade.copyWith(
      favorita: existente?.favorita ?? cidade.favorita,
      selecionada: true,
    );
    _selecionadaId = cidade.id;
  }

  @override
  Future<Cidade?> obterCidadeSelecionada() async {
    if (_selecionadaId != null && _cidades.containsKey(_selecionadaId)) {
      return _cidades[_selecionadaId];
    }
    return _cidades.isEmpty ? null : _cidades.values.first;
  }

  @override
  Future<PrevisaoCidade?> obterPrevisaoEmCache(int cidadeId) async =>
      _caches[cidadeId];

  @override
  Future<List<Cidade>> listarCidadesSalvas() async {
    final lista = _cidades.values.toList()
      ..sort((a, b) {
        if (a.favorita != b.favorita) return a.favorita ? -1 : 1;
        return b.ultimaConsulta.compareTo(a.ultimaConsulta);
      });
    return lista;
  }

  @override
  Future<void> alternarFavorita(int cidadeId, bool favorita) async {
    final c = _cidades[cidadeId];
    if (c != null) _cidades[cidadeId] = c.copyWith(favorita: favorita);
  }

  @override
  Future<void> excluirCidade(int cidadeId) async {
    _cidades.remove(cidadeId);
    _caches.remove(cidadeId);
    if (_selecionadaId == cidadeId) _selecionadaId = null;
  }
}

void main() {
  testWidgets(
    'fluxo completo: pesquisar cidade XML, exibir 4 dias, gráficos, detalhes e erro de busca',
    (tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repositorio = RepositorioPrevisaoMemoria();
      final servico = CptecInpeService(
        client: MockClient((req) async {
          if (req.url.path == '/XML/listaCidades') {
            final termo = (req.url.queryParameters['city'] ?? '').toLowerCase();
            if (termo.contains('inexistente')) {
              return http.Response.bytes(
                latin1.encode(
                  "<?xml version='1.0' encoding='ISO-8859-1'?><cidades></cidades>",
                ),
                200,
                headers: {'content-type': 'text/xml;charset=ISO-8859-1'},
              );
            }
            return http.Response.bytes(
              latin1.encode(
                "<?xml version='1.0' encoding='ISO-8859-1'?>"
                '<cidades>'
                '<cidade><nome>São José dos Campos</nome><uf>SP</uf><id>4963</id></cidade>'
                '</cidades>',
              ),
              200,
              headers: {'content-type': 'text/xml;charset=ISO-8859-1'},
            );
          }
          if (req.url.path == '/XML/cidade/4963/previsao.xml') {
            return http.Response.bytes(
              latin1.encode(
                "<?xml version='1.0' encoding='ISO-8859-1'?>"
                '<cidade><nome>São José dos Campos</nome><uf>SP</uf><atualizacao>2026-11-19</atualizacao>'
                '<previsao><dia>2026-11-20</dia><tempo>ps</tempo><maxima>31</maxima><minima>19</minima><iuv>10.5</iuv></previsao>'
                '<previsao><dia>2026-11-21</dia><tempo>pn</tempo><maxima>29</maxima><minima>20</minima><iuv>8.5</iuv></previsao>'
                '<previsao><dia>2026-11-22</dia><tempo>ci</tempo><maxima>26</maxima><minima>18</minima><iuv>6.0</iuv></previsao>'
                '<previsao><dia>2026-11-23</dia><tempo>t</tempo><maxima>24</maxima><minima>17</minima><iuv>4.5</iuv></previsao>'
                '</cidade>',
              ),
              200,
              headers: {'content-type': 'text/xml;charset=ISO-8859-1'},
            );
          }
          return http.Response('Not Found', 404);
        }),
      );

      await tester.pumpWidget(
        AppPrevisaoTempo(servico: servico, repositorio: repositorio),
      );
      await tester.pumpAndSettle();

      // Estado inicial
      expect(find.text('Consulte a previsão do tempo'), findsOneWidget);
      expect(find.textContaining('CPTEC/INPE'), findsWidgets);

      // Abre tela de pesquisa
      await tester.tap(find.widgetWithText(FilledButton, 'Pesquisar cidade'));
      await tester.pumpAndSettle();

      // Pesquisa cidade inexistente
      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();
      expect(
        find.text('Nenhuma cidade encontrada para "inexistente".'),
        findsOneWidget,
      );

      // Pesquisa São José
      await tester.enterText(find.byType(TextField), 'São José');
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();
      expect(find.text('São José dos Campos'), findsOneWidget);
      expect(find.textContaining('Código CPTEC: 4963'), findsOneWidget);

      // Seleciona cidade
      await tester.tap(find.text('São José dos Campos'));
      await tester.pumpAndSettle();

      // Verifica exibição dos 4 dias, descrições, atualização e gráficos
      expect(find.text('Previsão para 4 dias'), findsOneWidget);
      expect(find.textContaining('19/11/2026'), findsOneWidget);
      expect(find.text('Predomínio de sol'), findsWidgets);
      expect(find.text('Parcialmente nublado'), findsOneWidget);
      expect(find.text('Chuvas isoladas'), findsOneWidget);
      expect(find.text('Tempestade'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);

      // Navega para detalhes do dia
      await tester.tap(find.text('Tempestade'));
      await tester.pumpAndSettle();
      expect(find.text('Sigla CPTEC/INPE: T'), findsOneWidget);
      expect(find.text('Amplitude térmica prevista'), findsOneWidget);
    },
  );
}
