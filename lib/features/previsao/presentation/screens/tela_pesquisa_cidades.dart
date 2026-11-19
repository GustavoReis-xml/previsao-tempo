import 'package:flutter/material.dart';

import '../../data/repositories/repositorio_previsao.dart';
import '../../models/cidade.dart';
import '../../services/cptec_inpe_service.dart';

class TelaPesquisaCidades extends StatefulWidget {
  const TelaPesquisaCidades({
    super.key,
    required this.servico,
    required this.repositorio,
  });

  final CptecInpeService servico;
  final RepositorioPrevisao repositorio;

  @override
  State<TelaPesquisaCidades> createState() => _TelaPesquisaCidadesState();
}

class _TelaPesquisaCidadesState extends State<TelaPesquisaCidades> {
  final _buscaController = TextEditingController();

  bool _buscando = false;
  bool _jaPesquisou = false;
  String _ultimoTermo = '';
  String? _erro;
  List<Cidade> _resultados = const [];
  List<Cidade> _recentes = const [];

  @override
  void initState() {
    super.initState();
    _carregarRecentes();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregarRecentes() async {
    try {
      final salvas = await widget.repositorio.listarCidadesSalvas();
      if (!mounted) return;
      setState(() => _recentes = salvas);
    } catch (_) {
      // Falha silenciosa apenas nas sugestões recentes locais.
    }
  }

  Future<void> _pesquisar() async {
    final termo = _buscaController.text.trim();
    if (termo.length < 2) {
      setState(() {
        _erro = 'Digite pelo menos 2 caracteres para pesquisar uma cidade.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _buscando = true;
      _erro = null;
      _ultimoTermo = termo;
    });

    try {
      final encontradas = await widget.servico.pesquisarCidades(termo);
      if (!mounted) return;
      setState(() {
        _resultados = encontradas;
        _jaPesquisou = true;
        _buscando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = erro.toString().replaceFirst('Exception: ', '');
        _resultados = const [];
        _jaPesquisou = true;
        _buscando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pesquisar cidade')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _buscaController,
                      decoration: InputDecoration(
                        hintText: 'Ex.: São José dos Campos, Curitiba...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _buscaController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _buscaController.clear();
                                  setState(() {
                                    _erro = null;
                                    _jaPesquisou = false;
                                    _resultados = const [];
                                  });
                                },
                                tooltip: 'Limpar busca',
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _pesquisar(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _buscando ? null : _pesquisar,
                    child: const Text('Buscar'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.public_outlined,
                    size: 14,
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Localidades consultadas via XML no serviço oficial do CPTEC/INPE',
                      style: tema.textTheme.labelSmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),
            Expanded(child: _construirConteudo(context)),
          ],
        ),
      ),
    );
  }

  Widget _construirConteudo(BuildContext context) {
    final tema = Theme.of(context);

    if (_buscando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Consultando localidades no CPTEC/INPE...'),
          ],
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 46,
                color: tema.colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                _erro!,
                style: tema.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_ultimoTermo.length >= 2)
                FilledButton.icon(
                  onPressed: _pesquisar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
            ],
          ),
        ),
      );
    }

    if (_jaPesquisou) {
      if (_resultados.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off_outlined,
                  size: 46,
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma cidade encontrada para "$_ultimoTermo".',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Verifique a ortografia ou tente pesquisar apenas parte do nome da cidade.',
                  style: tema.textTheme.bodySmall?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _resultados.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _itemCidade(_resultados[index]),
      );
    }

    if (_recentes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 48,
                color: tema.colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                'Encontre qualquer cidade do Brasil',
                style: tema.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Informe o nome da cidade acima para consultar a previsão dos próximos 4 dias no CPTEC/INPE.',
                style: tema.textTheme.bodySmall?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(
            'Consultadas recentemente',
            style: tema.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final cidade in _recentes) ...[
          _itemCidade(cidade, mostrarFavorita: true),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _itemCidade(Cidade cidade, {bool mostrarFavorita = false}) {
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tema.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            cidade.uf,
            style: TextStyle(
              color: tema.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          cidade.nome,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('UF: ${cidade.uf} • Código CPTEC: ${cidade.id}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mostrarFavorita && cidade.favorita)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
              ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () => Navigator.pop(context, cidade),
      ),
    );
  }
}
