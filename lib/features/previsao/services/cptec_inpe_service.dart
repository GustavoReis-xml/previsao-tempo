import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/utils/formatadores.dart';
import '../models/cidade.dart';
import '../models/previsao_cidade.dart';
import 'cptec_xml_parser.dart';

class CptecInpeService {
  CptecInpeService({http.Client? client})
    : _client = client ?? http.Client(),
      _proprioClient = client == null;

  static const _host = 'servicos.cptec.inpe.br';
  static const _timeout = Duration(seconds: 15);

  final http.Client _client;
  final bool _proprioClient;

  /// Pesquisa localidades no CPTEC/INPE:
  /// GET https://servicos.cptec.inpe.br/XML/listaCidades?city={nome}
  Future<List<Cidade>> pesquisarCidades(String nome) async {
    final limpo = nome.trim();
    if (limpo.isEmpty) return const [];

    final termoConsulta = Formatadores.removerAcentos(limpo);
    final uri = Uri.https(
      _host,
      '/XML/listaCidades',
      {'city': termoConsulta},
    );

    final xml = await _executarGetXml(uri, 'pesquisar cidades');
    return CptecXmlParser.parseCidades(xml);
  }

  /// Consulta a previsão de 4 dias usando o código retornado pelo CPTEC/INPE:
  /// GET https://servicos.cptec.inpe.br/XML/cidade/{codigo}/previsao.xml
  Future<PrevisaoCidade> consultarPrevisao4Dias(Cidade cidade) async {
    final uri = Uri.https(_host, '/XML/cidade/${cidade.id}/previsao.xml');
    final xml = await _executarGetXml(uri, 'consultar a previsão do tempo');
    return CptecXmlParser.parsePrevisao(xml, cidadeReferencia: cidade);
  }

  Future<String> _executarGetXml(Uri uri, String operacao) async {
    try {
      final resposta = await _client
          .get(uri, headers: const {'Accept': 'application/xml, text/xml'})
          .timeout(_timeout);

      if (resposta.statusCode == 429) {
        throw Exception(
          'Limite temporário de consultas ao CPTEC/INPE atingido. Aguarde alguns instantes e tente novamente.',
        );
      }
      if (resposta.statusCode >= 500) {
        throw Exception(
          'O serviço do CPTEC/INPE está temporariamente indisponível (HTTP ${resposta.statusCode}).',
        );
      }
      if (resposta.statusCode != 200) {
        throw Exception(
          'Não foi possível $operacao no CPTEC/INPE (HTTP ${resposta.statusCode}).',
        );
      }

      return _decodificarResposta(resposta);
    } on TimeoutException {
      throw Exception(
        'Tempo esgotado ao $operacao no CPTEC/INPE. Verifique sua conexão.',
      );
    } on SocketException {
      throw Exception(
        'Sem conexão com a internet para $operacao no CPTEC/INPE.',
      );
    } on http.ClientException {
      throw Exception(
        'Falha de conexão ao $operacao no CPTEC/INPE. Tente novamente.',
      );
    }
  }

  /// Decodifica corretamente respostas em ISO-8859-1 (padrão oficial do CPTEC/INPE) ou UTF-8.
  String _decodificarResposta(http.Response resposta) {
    final contentType = (resposta.headers['content-type'] ?? '').toLowerCase();
    if (contentType.contains('utf-8') || contentType.contains('utf8')) {
      return utf8.decode(resposta.bodyBytes, allowMalformed: true);
    }
    return latin1.decode(resposta.bodyBytes, allowInvalid: true);
  }

  void fechar() {
    if (_proprioClient) {
      _client.close();
    }
  }
}
