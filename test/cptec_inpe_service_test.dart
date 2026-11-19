import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:previsao_tempo/features/previsao/services/cptec_inpe_service.dart';

void main() {
  test('remove acentos na consulta e decodifica XML em ISO-8859-1', () async {
    final uris = <Uri>[];
    final client = MockClient((req) async {
      uris.add(req.url);
      if (req.url.path == '/XML/listaCidades') {
        const xml =
            "<?xml version='1.0' encoding='ISO-8859-1'?>"
            '<cidades><cidade><nome>São José dos Campos</nome><uf>SP</uf><id>4963</id></cidade></cidades>';
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
            '<previsao><dia>2026-11-20</dia><tempo>ps</tempo><maxima>30</maxima><minima>19</minima><iuv>10.5</iuv></previsao>'
            '</cidade>';
        return http.Response.bytes(
          latin1.encode(xml),
          200,
          headers: {'content-type': 'text/xml;charset=ISO-8859-1'},
        );
      }
      return http.Response('Not Found', 404);
    });

    final servico = CptecInpeService(client: client);
    final cidades = await servico.pesquisarCidades('São José');

    expect(uris.first.queryParameters['city'], 'Sao Jose');
    expect(cidades.single.nome, 'São José dos Campos');
    expect(cidades.single.id, 4963);

    final previsao = await servico.consultarPrevisao4Dias(cidades.single);
    expect(
      uris.last.toString(),
      'https://servicos.cptec.inpe.br/XML/cidade/4963/previsao.xml',
    );
    expect(previsao.dias.single.condicao.descricao, 'Predomínio de sol');
    expect(previsao.dias.single.iuv, 10.5);
  });

  test('trata indisponibilidade HTTP 503 com mensagem clara', () async {
    final client = MockClient((_) async => http.Response('Indisponível', 503));
    final servico = CptecInpeService(client: client);

    await expectLater(
      servico.pesquisarCidades('Campinas'),
      throwsA(
        predicate(
          (erro) => erro.toString().contains('temporariamente indisponível'),
        ),
      ),
    );
  });
}
