import 'package:flutter/material.dart';

import '../../../../core/utils/formatadores.dart';
import '../../data/repositories/repositorio_previsao.dart';
import '../../models/cidade.dart';
import '../../models/previsao_cidade.dart';
import '../../models/previsao_dia.dart';
import '../../services/cptec_inpe_service.dart';
import '../widgets/card_cabecalho_previsao.dart';
import '../widgets/card_previsao_dia.dart';
import '../widgets/grafico_iuv.dart';
import '../widgets/grafico_temperaturas.dart';
import 'tela_cidades_salvas.dart';
import 'tela_detalhe_dia.dart';
import 'tela_pesquisa_cidades.dart';

class TelaPrevisao extends StatefulWidget {
  const TelaPrevisao({
    super.key,
    required this.servico,
    required this.repositorio,
  });

  final CptecInpeService servico;
  final RepositorioPrevisao repositorio;

  @override
  State<TelaPrevisao> createState() => _TelaPrevisaoState();
}

class _TelaPrevisaoState extends State<TelaPrevisao> {
  bool _carregandoInicial = true;
  bool _atualizando = false;
  Cidade? _cidadeAtual;
  PrevisaoCidade? _previsao;
  String? _erro;
  String? _avisoOffline;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    setState(() {
      _carregandoInicial = true;
      _erro = null;
      _avisoOffline = null;
    });
    try {
      final cidade = await widget.repositorio.obterCidadeSelecionada();
      if (!mounted) return;
      if (cidade == null) {
        setState(() {
          _cidadeAtual = null;
          _previsao = null;
          _carregandoInicial = false;
        });
        return;
      }

      // Exibe imediatamente o cache local enquanto busca a atualização no CPTEC/INPE.
      final emCache = await widget.repositorio.obterPrevisaoEmCache(cidade.id);
      if (!mounted) return;
      setState(() {
        _cidadeAtual = cidade;
        _previsao = emCache;
        _carregandoInicial = false;
      });
      await _consultarPrevisao(cidade, manterCacheSeFalhar: emCache != null);
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar os dados salvos: $erro';
        _carregandoInicial = false;
      });
    }
  }

  Future<void> _consultarPrevisao(
    Cidade cidade, {
    bool manterCacheSeFalhar = true,
  }) async {
    if (_atualizando) return;
    setState(() {
      _atualizando = true;
      _erro = null;
      _avisoOffline = null;
      _cidadeAtual = cidade;
    });

    PrevisaoCidade? cacheLocal = _previsao?.cidade.id == cidade.id
        ? _previsao
        : null;

    if (cacheLocal == null && manterCacheSeFalhar) {
      try {
        cacheLocal = await widget.repositorio.obterPrevisaoEmCache(cidade.id);
        if (mounted && cacheLocal != null) {
          setState(() => _previsao = cacheLocal);
        }
      } catch (_) {
        // Segue tentando consulta online.
      }
    }

    try {
      final resposta = await widget.servico.consultarPrevisao4Dias(cidade);
      final cidadeSalva = await widget.repositorio.salvarPrevisao(resposta);
      if (!mounted) return;
      setState(() {
        _cidadeAtual = cidadeSalva;
        _previsao = resposta.copyWith(cidade: cidadeSalva);
        _atualizando = false;
        _erro = null;
        _avisoOffline = null;
      });
    } catch (erro) {
      if (!mounted) return;
      final mensagem = erro.toString().replaceFirst('Exception: ', '');
      if (cacheLocal != null) {
        setState(() {
          _previsao = cacheLocal!.copyWith(carregadoDoCache: true);
          _avisoOffline =
              'Exibindo última previsão salva localmente. $mensagem';
          _erro = null;
          _atualizando = false;
        });
      } else {
        setState(() {
          _previsao = null;
          _erro = mensagem;
          _atualizando = false;
        });
      }
    }
  }

  Future<void> _abrirPesquisa() async {
    final escolhida = await Navigator.push<Cidade>(
      context,
      MaterialPageRoute<Cidade>(
        builder: (context) => TelaPesquisaCidades(
          servico: widget.servico,
          repositorio: widget.repositorio,
        ),
      ),
    );
    if (escolhida == null || !mounted) return;
    await widget.repositorio.selecionarCidade(escolhida);
    if (!mounted) return;
    setState(() => _previsao = null);
    await _consultarPrevisao(escolhida);
  }

  Future<void> _abrirCidadesSalvas() async {
    final escolhida = await Navigator.push<Cidade>(
      context,
      MaterialPageRoute<Cidade>(
        builder: (context) => TelaCidadesSalvas(
          repositorio: widget.repositorio,
          cidadeAtualId: _cidadeAtual?.id,
        ),
      ),
    );
    if (!mounted) return;
    if (escolhida != null) {
      await widget.repositorio.selecionarCidade(escolhida);
      if (!mounted) return;
      setState(() => _previsao = null);
      await _consultarPrevisao(escolhida);
      return;
    }

    // Caso o usuário tenha excluído a cidade ativa ou alterado favorito.
    final atualizada = await widget.repositorio.obterCidadeSelecionada();
    if (!mounted) return;
    if (atualizada == null) {
      setState(() {
        _cidadeAtual = null;
        _previsao = null;
        _erro = null;
        _avisoOffline = null;
      });
    } else if (_cidadeAtual == null || atualizada.id != _cidadeAtual!.id) {
      await _consultarPrevisao(atualizada);
    } else if (_previsao != null) {
      setState(() {
        _cidadeAtual = atualizada;
        _previsao = _previsao!.copyWith(cidade: atualizada);
      });
    }
  }

  Future<void> _alternarFavorita() async {
    final cidade = _cidadeAtual;
    if (cidade == null) return;
    final novoValor = !cidade.favorita;
    try {
      await widget.repositorio.alternarFavorita(cidade.id, novoValor);
      if (!mounted) return;
      final atualizada = cidade.copyWith(favorita: novoValor);
      setState(() {
        _cidadeAtual = atualizada;
        if (_previsao != null) {
          _previsao = _previsao!.copyWith(cidade: atualizada);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            novoValor
                ? '${cidade.nomeCompleto} adicionada aos favoritos.'
                : '${cidade.nomeCompleto} removida dos favoritos.',
          ),
        ),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível atualizar favorito: $erro')),
      );
    }
  }

  void _abrirDetalheDia(PrevisaoDia dia) {
    final cidade = _cidadeAtual;
    if (cidade == null) return;
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TelaDetalheDia(
          cidade: cidade,
          previsao: dia,
          atualizacaoCptec: _previsao?.atualizacao,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Previsão do Tempo'),
        actions: [
          IconButton(
            onPressed: _abrirPesquisa,
            tooltip: 'Pesquisar cidade',
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: _abrirCidadesSalvas,
            tooltip: 'Cidades salvas',
            icon: const Icon(Icons.bookmarks_outlined),
          ),
          if (_cidadeAtual != null)
            IconButton(
              onPressed: _atualizando
                  ? null
                  : () => _consultarPrevisao(_cidadeAtual!),
              tooltip: 'Atualizar previsão',
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: SafeArea(child: _construirCorpo(context)),
    );
  }

  Widget _construirCorpo(BuildContext context) {
    final tema = Theme.of(context);

    if (_carregandoInicial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cidadeAtual == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: tema.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wb_sunny_outlined,
                  size: 52,
                  color: tema.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Consulte a previsão do tempo',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pesquise qualquer cidade brasileira para visualizar a previsão dos próximos 4 dias, temperaturas mínima/máxima, índice UV e gráficos com dados oficiais do CPTEC/INPE.',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _abrirPesquisa,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Pesquisar cidade'),
              ),
              const SizedBox(height: 16),
              Text(
                'Fonte dos dados: CPTEC/INPE',
                style: tema.textTheme.labelSmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_atualizando && _previsao == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text('Buscando previsão para ${_cidadeAtual!.nomeCompleto}...'),
          ],
        ),
      );
    }

    if (_erro != null && _previsao == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 50,
                color: tema.colorScheme.error,
              ),
              const SizedBox(height: 14),
              Text(
                'Não foi possível obter a previsão',
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _erro!,
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _consultarPrevisao(_cidadeAtual!),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _abrirPesquisa,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Pesquisar outra cidade'),
              ),
            ],
          ),
        ),
      );
    }

    final previsao = _previsao!;

    return RefreshIndicator(
      onRefresh: () => _consultarPrevisao(_cidadeAtual!),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (_atualizando)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: LinearProgressIndicator(),
            ),
          if (_avisoOffline != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                color: const Color(0xFFFEF3C7),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 20,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _avisoOffline!,
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF78350F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          CardCabecalhoPrevisao(
            previsao: previsao,
            aoAlternarFavorita: _alternarFavorita,
          ),
          const SizedBox(height: 16),
          if (!previsao.possuiPrevisao)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_busy_outlined,
                      size: 42,
                      color: tema.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Nenhuma previsão disponível',
                      style: tema.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'O serviço do CPTEC/INPE não retornou dias de previsão para ${_cidadeAtual!.nomeCompleto} no momento.',
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => _consultarPrevisao(_cidadeAtual!),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Atualizar previsão'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            GraficoTemperaturas(dias: previsao.dias),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Previsão para ${previsao.dias.length} ${previsao.dias.length == 1 ? 'dia' : 'dias'}',
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Toque para detalhes',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final dia in previsao.dias) ...[
              CardPrevisaoDia(
                previsao: dia,
                aoTocar: () => _abrirDetalheDia(dia),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            GraficoIuv(dias: previsao.dias),
          ],
          const SizedBox(height: 20),
          Column(
            children: [
              Text(
                'Fonte dos dados: CPTEC/INPE (Centro de Previsão de Tempo e Estudos Climáticos)',
                style: tema.textTheme.labelSmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (previsao.atualizadoEmLocal != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Sincronizado no aparelho em ${Formatadores.formatarDataHoraLocal(previsao.atualizadoEmLocal!)}',
                  style: tema.textTheme.labelSmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.8,
                    ),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
