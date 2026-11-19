import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_tempo/features/previsao/models/cidade.dart';
import 'package:previsao_tempo/features/previsao/services/cptec_xml_parser.dart';

void main() {
  test('interpreta lista de cidades válida e ignora entradas incompletas', () {
    const xml = '''
<?xml version='1.0' encoding='ISO-8859-1'?>
<cidades>
  <cidade><nome>São José dos Campos</nome><uf>SP</uf><id>4963</id></cidade>
  <cidade><nome>Jacareí</nome><uf>SP</uf><id>2661</id></cidade>
  <cidade><nome>null</nome><uf>SP</uf><id>9999</id></cidade>
  <cidade><nome>Sem ID</nome><uf>MG</uf></cidade>
</cidades>
''';

    final cidades = CptecXmlParser.parseCidades(xml);
    expect(cidades.length, 2);
    expect(cidades[0].id, 4963);
    expect(cidades[0].nome, 'São José dos Campos');
    expect(cidades[0].uf, 'SP');
    expect(cidades[1].id, 2661);
  });

  test('interpreta previsão de 4 dias e trata campos ausentes e IUV 0.0', () {
    const xml = '''
<?xml version='1.0' encoding='ISO-8859-1'?>
<cidade>
  <nome>São José dos Campos</nome>
  <uf>SP</uf>
  <atualizacao>2026-11-19</atualizacao>
  <previsao>
    <dia>2026-11-20</dia>
    <tempo>pn</tempo>
    <maxima>30</maxima>
    <minima>21</minima>
    <iuv>9.5</iuv>
  </previsao>
  <previsao>
    <dia>2026-11-21</dia>
    <tempo>c</tempo>
    <maxima>27</maxima>
    <minima>20</minima>
    <iuv>0.0</iuv>
  </previsao>
  <previsao>
    <dia>2026-11-22</dia>
    <maxima>26</maxima>
  </previsao>
</cidade>
''';

    final ref = Cidade(id: 4963, nome: 'São José dos Campos', uf: 'SP');
    final previsao = CptecXmlParser.parsePrevisao(xml, cidadeReferencia: ref);

    expect(previsao.atualizacao, DateTime(2026, 11, 19));
    expect(previsao.dias.length, 3);

    expect(previsao.dias[0].condicao.descricao, 'Parcialmente nublado');
    expect(previsao.dias[0].maxima, 30);
    expect(previsao.dias[0].minima, 21);
    expect(previsao.dias[0].possuiIuv, isTrue);
    expect(previsao.dias[0].iuv, 9.5);

    // IUV 0.0 tratado como indisponível
    expect(previsao.dias[1].possuiIuv, isFalse);
    expect(previsao.dias[1].iuv, isNull);

    // Dia com campos ausentes (<tempo>, <minima>, <iuv>) tratado sem crash
    expect(previsao.dias[2].condicao.descricao, 'Condição não informada');
    expect(previsao.dias[2].minima, isNull);
    expect(previsao.dias[2].maxima, 26);
    expect(previsao.dias[2].possuiIuv, isFalse);
  });

  test('retorna lista vazia quando CPTEC envia tags literais "null"', () {
    const xmlInvalido = '''
<?xml version='1.0' encoding='ISO-8859-1'?>
<cidade>
  <nome>null</nome>
  <uf>null</uf>
  <atualizacao>null</atualizacao>
  <previsao><dia>null</dia><tempo>null</tempo><maxima>null</maxima><minima>null</minima><iuv>0.0</iuv></previsao>
</cidade>
''';

    final ref = Cidade(id: 999999, nome: 'Inexistente', uf: 'SP');
    final previsao = CptecXmlParser.parsePrevisao(
      xmlInvalido,
      cidadeReferencia: ref,
    );
    expect(previsao.possuiPrevisao, isFalse);
    expect(previsao.atualizacao, isNull);
  });

  test('lança FormatException para XML malformado', () {
    expect(
      () => CptecXmlParser.parseCidades('<cidades><quebrado>'),
      throwsFormatException,
    );
  });
}
