import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_tempo/features/previsao/models/condicao_tempo.dart';

void main() {
  test('converte siglas oficiais do CPTEC/INPE em descrições compreensíveis', () {
    expect(CondicaoTempo.fromSigla('cl').descricao, 'Céu claro');
    expect(CondicaoTempo.fromSigla('ps').descricao, 'Predomínio de sol');
    expect(CondicaoTempo.fromSigla('pn').descricao, 'Parcialmente nublado');
    expect(CondicaoTempo.fromSigla('c').descricao, 'Chuva');
    expect(CondicaoTempo.fromSigla('ci').descricao, 'Chuvas isoladas');
    expect(CondicaoTempo.fromSigla('t').descricao, 'Tempestade');
    expect(CondicaoTempo.fromSigla('EC').descricao, 'Encoberto com chuvas isoladas');
    expect(CondicaoTempo.fromSigla('npt').descricao, 'Nublado com pancadas à tarde');
    expect(CondicaoTempo.fromSigla('nv').descricao, 'Nevoeiro');
    expect(CondicaoTempo.fromSigla('g').descricao, 'Geada');
  });

  test('trata sigla ausente, nula ou desconhecida sem lançar exceção', () {
    expect(CondicaoTempo.fromSigla(null).descricao, 'Condição não informada');
    expect(CondicaoTempo.fromSigla('').descricao, 'Condição não informada');
    expect(CondicaoTempo.fromSigla('null').descricao, 'Condição não informada');
    expect(
      CondicaoTempo.fromSigla('xyz').descricao,
      'Condição não catalogada (xyz)',
    );
  });
}
