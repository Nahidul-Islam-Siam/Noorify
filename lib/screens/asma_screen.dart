import 'package:flutter/material.dart';

import '../app/brand_colors.dart';
import '../models/asma_name.dart';
import '../services/asma_service.dart';
import '../widgets/bottom_nav.dart';

class AsmaScreen extends StatefulWidget {
  const AsmaScreen({super.key});

  @override
  State<AsmaScreen> createState() => _AsmaScreenState();
}

class _AsmaScreenState extends State<AsmaScreen> {
  final AsmaService _asmaService = AsmaService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  String _query = '';
  List<AsmaName> _names = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAsmaNames();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  Future<void> _loadAsmaNames() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final names = await _asmaService.loadAsmaNames();
      if (!mounted) return;
      setState(() {
        _names = names;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<AsmaName> get _filteredNames {
    if (_query.isEmpty) return _names;
    return _names.where((item) {
      return item.id.toString().contains(_query) ||
          item.arabic.contains(_query) ||
          item.transliteration.toLowerCase().contains(_query) ||
          item.englishMeaning.toLowerCase().contains(_query) ||
          item.banglaName.toLowerCase().contains(_query) ||
          item.banglaMeaning.toLowerCase().contains(_query);
    }).toList(growable: false);
  }

  void _onTapPlay(AsmaName item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio playback integration is next step.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNames = _filteredNames;

    return Scaffold(
      backgroundColor: BrandColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _AsmaHeader(
              searchController: _searchController,
              total: _names.length,
              shown: filteredNames.length,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _AsmaErrorView(error: _error!, onRetry: _loadAsmaNames)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      itemCount: filteredNames.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filteredNames[index];
                        final hasAudio = (item.audio ?? '').trim().isNotEmpty;
                        return _AsmaNameCard(
                          item: item,
                          hasAudio: hasAudio,
                          onPlay: () => _onTapPlay(item),
                        );
                      },
                    ),
            ),
            bottomNav(context, 1),
          ],
        ),
      ),
    );
  }
}

class _AsmaHeader extends StatelessWidget {
  const _AsmaHeader({
    required this.searchController,
    required this.total,
    required this.shown,
  });

  final TextEditingController searchController;
  final int total;
  final int shown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.primaryDark,
            BrandColors.primary,
            BrandColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Asma Ul Husna',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Text(
                  '$shown/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '99 Beautiful Names of Allah',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xE8FFFFFF),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search name, meaning, or number',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AsmaErrorView extends StatelessWidget {
  const _AsmaErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFB3261E)),
            ),
            const SizedBox(height: 10),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _AsmaNameCard extends StatelessWidget {
  const _AsmaNameCard({
    required this.item,
    required this.hasAudio,
    required this.onPlay,
  });

  final AsmaName item;
  final bool hasAudio;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BrandColors.tintBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.id.toString(),
                  style: const TextStyle(
                    color: BrandColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: hasAudio ? 'Play audio' : 'No audio yet',
                onPressed: hasAudio ? onPlay : null,
                icon: const Icon(Icons.play_arrow_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              item.arabic,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: BrandColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.transliteration,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: BrandColors.primaryDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.englishMeaning,
            style: const TextStyle(
              fontSize: 13,
              color: BrandColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.banglaName} - ${item.banglaMeaning}',
            style: const TextStyle(
              fontSize: 13,
              color: BrandColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
