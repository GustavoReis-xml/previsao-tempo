import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:previsao_tempo/core/theme/app_theme.dart';
import 'package:previsao_tempo/features/previsao/data/database/banco_previsao.dart';
import 'package:previsao_tempo/features/previsao/data/repositories/repositorio_previsao.dart';
import 'package:previsao_tempo/features/previsao/models/cidade.dart';
import 'package:previsao_tempo/features/previsao/models/condicao_tempo.dart';
import 'package:previsao_tempo/features/previsao/models/previsao_cidade.dart';
import 'package:previsao_tempo/features/previsao/models/previsao_dia.dart';
import 'package:previsao_tempo/features/previsao/presentation/screens/tela_cidades_salvas.dart';
import 'package:previsao_tempo/features/previsao/presentation/screens/tela_detalhe_dia.dart';
import 'package:previsao_tempo/features/previsao/presentation/screens/tela_pesquisa_cidades.dart';
import 'package:previsao_tempo/features/previsao/presentation/screens/tela_previsao.dart';
import 'package:previsao_tempo/features/previsao/services/cptec_inpe_service.dart';

class _RepositorioCaptura extends RepositorioPrevisao {
  _RepositorioCaptura() : super(BancoPrevisao());

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
    _cidades[cidade.id] = cidade.copyWith(selecionada: true);
    _selecionadaId = cidade.id;
  }

  @override
  Future<Cidade?> obterCidadeSelecionada() async =>
      _selecionadaId == null ? null : _cidades[_selecionadaId];

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

Future<void> _carregarFontesReais() async {
  final fontDirEnv = Platform.environment['FLUTTER_MATERIAL_FONTS'];
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final robotoDirEnv = Platform.environment['ROBOTO_FONTS_DIR'];

  final diretorios = <String>[
    if (fontDirEnv != null && fontDirEnv.isNotEmpty) fontDirEnv,
    if (flutterRoot != null && flutterRoot.isNotEmpty)
      p.join(flutterRoot, 'bin', 'cache', 'artifacts', 'material_fonts'),
    if (robotoDirEnv != null && robotoDirEnv.isNotEmpty) robotoDirEnv,
    '/usr/share/fonts/truetype/roboto/unhinted/RobotoTTF',
    '/usr/share/fonts/truetype/roboto',
  ];

  Future<void> carregarFamilia(String familia, List<String> arquivos) async {
    final loader = FontLoader(familia);
    var adicionou = false;
    for (final arquivo in arquivos) {
      for (final dir in diretorios) {
        final f = File(p.join(dir, arquivo));
        if (f.existsSync()) {
          final bytes = await f.readAsBytes();
          loader.addFont(Future.value(ByteData.sublistView(bytes)));
          adicionou = true;
          break;
        }
      }
    }
    if (adicionou) await loader.load();
  }

  await carregarFamilia('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Light.ttf',
  ]);
  await carregarFamilia('FlutterTest', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await carregarFamilia('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

Widget _molduraApp(Widget tela, GlobalKey chaveCaptura) => RepaintBoundary(
  key: chaveCaptura,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('pt', 'BR'),
    supportedLocales: const [Locale('pt', 'BR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.construir(),
    home: tela,
  ),
);

Future<void> _salvarCaptura(
  WidgetTester tester,
  GlobalKey chaveCaptura,
  String nomeArquivo,
) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final boundary =
      chaveCaptura.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final imagem = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
    imagem.dispose();
    final saida = File(p.join('docs', 'screenshots', nomeArquivo));
    await saida.parent.create(recursive: true);
    await saida.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('gera capturas reais das telas principais de Previsão do Tempo', (
    tester,
  ) async {
    await tester.runAsync(_carregarFontesReais);

    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repositorio = _RepositorioCaptura();
    var simularOffline = false;

    final servico = CptecInpeService(
      client: MockClient((req) async {
        if (simularOffline) {
          return http.Response('Serviço indisponível', 503);
        }
        if (req.url.path == '/XML/listaCidades') {
          const xml =
              "<?xml version='1.0' encoding='ISO-8859-1'?>"
              '<cidades>'
              '<cidade><nome>São José dos Campos</nome><uf>SP</uf><id>4963</id></cidade>'
              '<cidade><nome>São José do Rio Preto</nome><uf>SP</uf><id>4955</id></cidade>'
              '<cidade><nome>São José</nome><uf>SC</uf><id>4909</id></cidade>'
              '<cidade><nome>São José dos Pinhais</nome><uf>PR</uf><id>4964</id></cidade>'
              '<cidade><nome>São José do Rio Pardo</nome><uf>SP</uf><id>4954</id></cidade>'
              '</cidades>';
          return http.Response.bytes(
            latin1.encode(xml),
            200,
            headers: {'content-type': 'text/xml;charset=ISO-8859-1'},
          );
        }
        if (req.url.path == '/XML/cidade/4963/previsao.xml') {
          const xml =
              "<?xml version='1.0' encoding='ISO-8859-1'?>"
              '<cidade><nome>São José dos Campos</nome><uf>SP</uf><atualizacao>2026-11-19</atualizacao>'
              '<previsao><dia>2026-11-20</dia><tempo>ps</tempo><maxima>31</maxima><minima>19</minima><iuv>10.5</iuv></previsao>'
              '<previsao><dia>2026-11-21</dia><tempo>pn</tempo><maxima>29</maxima><minima>20</minima><iuv>8.5</iuv></previsao>'
              '<previsao><dia>2026-11-22</dia><tempo>ci</tempo><maxima>26</maxima><minima>18</minima><iuv>6.0</iuv></previsao>'
              '<previsao><dia>2026-11-23</dia><tempo>t</tempo><maxima>24</maxima><minima>17</minima><iuv>4.5</iuv></previsao>'
              '</cidade>';
          return http.Response.bytes(
            latin1.encode(xml),
            200,
            headers: {'content-type': 'text/xml;charset=ISO-8859-1'},
          );
        }
        return http.Response('Not Found', 404);
      }),
    );

    // 1. Captura: Pesquisa de cidades (XML CPTEC/INPE)
    final chavePesquisa = GlobalKey();
    await tester.pumpWidget(
      _molduraApp(
        TelaPesquisaCidades(servico: servico, repositorio: repositorio),
        chavePesquisa,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'São José');
    await tester.tap(find.text('Buscar'));
    await _salvarCaptura(tester, chavePesquisa, '01_pesquisa_cidades.png');

    // Popula cidades salvas no repositório em memória
    final sjc = Cidade(
      id: 4963,
      nome: 'São José dos Campos',
      uf: 'SP',
      favorita: true,
      selecionada: true,
      ultimaConsulta: DateTime(2026, 11, 19, 19, 10),
    );
    await repositorio.salvarPrevisao(
      PrevisaoCidade(
        cidade: Cidade(
          id: 244,
          nome: 'São Paulo',
          uf: 'SP',
          favorita: true,
          ultimaConsulta: DateTime(2026, 11, 19, 17, 45),
        ),
        atualizacao: DateTime(2026, 11, 19),
        dias: [
          PrevisaoDia(
            data: DateTime(2026, 11, 20),
            condicao: CondicaoTempo.fromSigla('c'),
            minima: 20,
            maxima: 28,
            iuv: 7.0,
          ),
        ],
      ),
    );
    await repositorio.salvarPrevisao(
      PrevisaoCidade(
        cidade: Cidade(
          id: 2661,
          nome: 'Jacareí',
          uf: 'SP',
          ultimaConsulta: DateTime(2026, 11, 19, 16, 20),
        ),
        atualizacao: DateTime(2026, 11, 19),
        dias: [
          PrevisaoDia(
            data: DateTime(2026, 11, 20),
            condicao: CondicaoTempo.fromSigla('pn'),
            minima: 19,
            maxima: 30,
          ),
        ],
      ),
    );
    await repositorio.selecionarCidade(sjc);
    await repositorio.alternarFavorita(sjc.id, true);

    // 2. Captura: Tela principal (Cabeçalho + Gráfico de Temperaturas °C)
    final chavePrevisao = GlobalKey();
    await tester.pumpWidget(
      _molduraApp(
        TelaPrevisao(servico: servico, repositorio: repositorio),
        chavePrevisao,
      ),
    );
    await _salvarCaptura(
      tester,
      chavePrevisao,
      '02_previsao_grafico_temperaturas.png',
    );

    // 3. Captura: Tela principal rolada (Previsão 4 dias + Gráfico de IUV + Fonte CPTEC/INPE)
    await tester.drag(find.byType(ListView).first, const Offset(0, -640));
    await _salvarCaptura(
      tester,
      chavePrevisao,
      '03_previsao_quatro_dias_iuv.png',
    );

    // 4. Captura: Detalhe de um dia da previsão
    final chaveDetalhe = GlobalKey();
    await tester.pumpWidget(
      _molduraApp(
        TelaDetalheDia(
          cidade: sjc,
          previsao: PrevisaoDia(
            data: DateTime(2026, 11, 20),
            condicao: CondicaoTempo.fromSigla('ps'),
            minima: 19,
            maxima: 31,
            iuv: 10.5,
          ),
          atualizacaoCptec: DateTime(2026, 11, 19),
        ),
        chaveDetalhe,
      ),
    );
    await _salvarCaptura(tester, chaveDetalhe, '04_detalhe_dia.png');

    // 5. Captura: Cidades salvas / favoritas (persistência local SQLite)
    final chaveSalvas = GlobalKey();
    await tester.pumpWidget(
      _molduraApp(
        TelaCidadesSalvas(repositorio: repositorio, cidadeAtualId: sjc.id),
        chaveSalvas,
      ),
    );
    await _salvarCaptura(tester, chaveSalvas, '05_cidades_salvas.png');

    // 6. Captura: Modo offline / serviço indisponível preservando o cache local
    simularOffline = true;
    final chaveOffline = GlobalKey();
    await tester.pumpWidget(
      _molduraApp(
        TelaPrevisao(servico: servico, repositorio: repositorio),
        chaveOffline,
      ),
    );
    await _salvarCaptura(tester, chaveOffline, '06_modo_offline_cache.png');
  });
}
