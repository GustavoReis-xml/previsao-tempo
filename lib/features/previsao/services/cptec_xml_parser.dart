import 'package:xml/xml.dart';

import '../models/cidade.dart';
import '../models/condicao_tempo.dart';
import '../models/previsao_cidade.dart';
import '../models/previsao_dia.dart';

class CptecXmlParser {
  /// Interpreta o XML retornado por `/XML/listaCidades?city=...`.
  static List<Cidade> parseCidades(String xmlBruto) {
    final documento = _parseDocumento(xmlBruto);
    final raiz = documento.rootElement;
    if (raiz.name.local.toLowerCase() != 'cidades') {
      throw const FormatException(
        'Resposta XML inesperada ao consultar localidades no CPTEC/INPE.',
      );
    }

    final vistos = <int>{};
    final cidades = <Cidade>[];
    for (final elemento in raiz.findElements('cidade')) {
      final nome = _textoValido(elemento, 'nome');
      final uf = _textoValido(elemento, 'uf');
      final idTexto = _textoValido(elemento, 'id');
      final id = idTexto == null ? null : int.tryParse(idTexto);

      if (nome == null || uf == null || id == null || id <= 0) {
        continue;
      }
      if (vistos.add(id)) {
        cidades.add(Cidade(id: id, nome: nome, uf: uf));
      }
    }
    return cidades;
  }

  /// Interpreta o XML retornado por `/XML/cidade/{id}/previsao.xml`.
  static PrevisaoCidade parsePrevisao(
    String xmlBruto, {
    required Cidade cidadeReferencia,
  }) {
    final documento = _parseDocumento(xmlBruto);
    final raiz = documento.rootElement;
    if (raiz.name.local.toLowerCase() != 'cidade') {
      throw const FormatException(
        'Resposta XML inesperada ao consultar a previsão no CPTEC/INPE.',
      );
    }

    final nomeXml = _textoValido(raiz, 'nome');
    final ufXml = _textoValido(raiz, 'uf');
    final atualizacao = _parseData(_textoValido(raiz, 'atualizacao'));

    final cidadeAtualizada = cidadeReferencia.copyWith(
      nome: nomeXml ?? cidadeReferencia.nome,
      uf: ufXml ?? cidadeReferencia.uf,
      ultimaConsulta: DateTime.now().toUtc(),
    );

    final dias = <PrevisaoDia>[];
    for (final item in raiz.findElements('previsao')) {
      final data = _parseData(_textoValido(item, 'dia'));
      if (data == null) {
        // Ignora blocos inválidos (ex.: quando o CPTEC retorna <dia>null</dia>)
        continue;
      }

      final condicao = CondicaoTempo.fromSigla(_textoValido(item, 'tempo'));
      final minima = _parseNumero(_textoValido(item, 'minima'));
      final maxima = _parseNumero(_textoValido(item, 'maxima'));
      final iuvBruto = _parseNumero(_textoValido(item, 'iuv'));
      final iuv = (iuvBruto != null && iuvBruto > 0) ? iuvBruto : null;

      dias.add(
        PrevisaoDia(
          data: data,
          condicao: condicao,
          minima: minima,
          maxima: maxima,
          iuv: iuv,
        ),
      );
    }

    return PrevisaoCidade(
      cidade: cidadeAtualizada,
      dias: List.unmodifiable(dias),
      atualizacao: atualizacao,
      carregadoDoCache: false,
      atualizadoEmLocal: DateTime.now().toUtc(),
    );
  }

  static XmlDocument _parseDocumento(String xmlBruto) {
    final texto = xmlBruto.trim();
    if (texto.isEmpty) {
      throw const FormatException('Resposta vazia recebida do CPTEC/INPE.');
    }
    try {
      return XmlDocument.parse(texto);
    } on XmlException {
      throw const FormatException(
        'Resposta XML inválida recebida do CPTEC/INPE.',
      );
    }
  }

  static String? _textoValido(XmlElement pai, String tag) {
    final valor = pai.getElement(tag)?.innerText.trim();
    if (valor == null || valor.isEmpty || valor.toLowerCase() == 'null') {
      return null;
    }
    return valor;
  }

  static DateTime? _parseData(String? texto) {
    if (texto == null) return null;
    final iso = DateTime.tryParse(texto);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }
    // Suporte defensivo caso venha como DD/MM/AAAA
    final partes = texto.split('/');
    if (partes.length == 3) {
      final dia = int.tryParse(partes[0]);
      final mes = int.tryParse(partes[1]);
      final ano = int.tryParse(partes[2]);
      if (dia != null && mes != null && ano != null) {
        return DateTime(ano, mes, dia);
      }
    }
    return null;
  }

  static double? _parseNumero(String? texto) {
    if (texto == null) return null;
    final valor = double.tryParse(texto.replaceAll(',', '.'));
    if (valor == null || !valor.isFinite) return null;
    return valor;
  }
}
