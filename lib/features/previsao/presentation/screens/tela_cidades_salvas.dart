import 'package:flutter/material.dart';

import '../../../../core/utils/formatadores.dart';
import '../../data/repositories/repositorio_previsao.dart';
import '../../models/cidade.dart';

class TelaCidadesSalvas extends StatefulWidget {
  const TelaCidadesSalvas({
    super.key,
    required this.repositorio,
    this.cidadeAtualId,
  });

  final RepositorioPrevisao repositorio;
  final int? cidadeAtualId;

  @override
  State<TelaCidadesSalvas> createState() => _TelaCidadesSalvasState();
}

class _TelaCidadesSalvasState extends State<TelaCidadesSalvas> {
  bool _carregando = true;
  String? _erro;
  List<Cidade> _cidades = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await widget.repositorio.listarCidadesSalvas();
      if (!mounted) return;
      setState(() {
        _cidades = lista;
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;
      setState(() {
        _erro = 'Não foi possível carregar as cidades salvas: $erro';
        _carregando = false;
      });
    }
  }

  Future<void> _alternarFavorita(Cidade cidade) async {
    try {
      await widget.repositorio.alternarFavorita(cidade.id, !cidade.favorita);
      await _carregar();
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao atualizar favorito: $erro')),
      );
    }
  }

  Future<void> _confirmarExclusao(Cidade cidade) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover cidade salva?'),
        content: Text(
          'Deseja remover ${cidade.nomeCompleto} e a previsão armazenada localmente para ela?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    try {
      await widget.repositorio.excluirCidade(cidade.id);
      if (!mounted) return;
      await _carregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${cidade.nomeCompleto} removida.')),
      );
    } catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível remover a cidade: $erro')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cidades salvas')),
      body: SafeArea(
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_erro!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _carregar,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            : _cidades.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmarks_outlined,
                        size: 48,
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Nenhuma cidade salva localmente',
                        style: tema.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'As cidades consultadas ficam armazenadas no dispositivo para acesso rápido e visualização offline.',
                        style: tema.textTheme.bodySmall?.copyWith(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _cidades.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final cidade = _cidades[index];
                  final ativa = cidade.id == widget.cidadeAtualId;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: ativa
                            ? tema.colorScheme.primary
                            : tema.colorScheme.outlineVariant.withValues(
                                alpha: 0.65,
                              ),
                        width: ativa ? 1.8 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ativa
                              ? tema.colorScheme.primary
                              : tema.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cidade.uf,
                          style: TextStyle(
                            color: ativa
                                ? Colors.white
                                : tema.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        cidade.nome,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Código ${cidade.id} • Consultado em ${Formatadores.formatarDataHoraLocal(cidade.ultimaConsulta)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _alternarFavorita(cidade),
                            tooltip: cidade.favorita
                                ? 'Remover dos favoritos'
                                : 'Favoritar cidade',
                            icon: Icon(
                              cidade.favorita
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              color: cidade.favorita
                                  ? const Color(0xFFF59E0B)
                                  : tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _confirmarExclusao(cidade),
                            tooltip: 'Remover cidade',
                            icon: Icon(
                              Icons.delete_outline,
                              color: tema.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.pop(context, cidade),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
