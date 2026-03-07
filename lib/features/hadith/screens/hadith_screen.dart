import 'package:flutter/material.dart';

import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/features/hadith/models/hadith_item.dart';
import 'package:first_project/features/hadith/services/hadith_service.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final HadithService _hadithService = HadithService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  String _query = '';
  List<HadithItem> _hadiths = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadHadiths();
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

  Future<void> _loadHadiths() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hadiths = await _hadithService.loadHadiths();
      if (!mounted) return;
      setState(() {
        _hadiths = hadiths;
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

  List<HadithItem> get _filteredHadiths {
    if (_query.isEmpty) return _hadiths;
    return _hadiths
        .where((item) {
          return item.id.toString().contains(_query) ||
              item.category.toLowerCase().contains(_query) ||
              item.titleEn.toLowerCase().contains(_query) ||
              item.titleBn.toLowerCase().contains(_query) ||
              item.arabic.contains(_query) ||
              item.english.toLowerCase().contains(_query) ||
              item.bangla.toLowerCase().contains(_query) ||
              item.reference.toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }

  String _categoryLabel(String value) {
    if (value.trim().isEmpty) return 'General';
    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void _openHadithDetails(HadithItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titleBn.isNotEmpty ? item.titleBn : item.titleEn,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.reference,
                  style: const TextStyle(
                    fontSize: 12,
                    color: BrandColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BrandColors.tintBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.arabic,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: BrandColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'English',
                  style: TextStyle(
                    fontSize: 12,
                    color: BrandColors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.english,
                  style: const TextStyle(
                    fontSize: 14,
                    color: BrandColors.textPrimary,
                  ),
                ),
                if (item.bangla.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Bangla',
                    style: TextStyle(
                      fontSize: 12,
                      color: BrandColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.bangla,
                    style: const TextStyle(
                      fontSize: 14,
                      color: BrandColors.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTapPlay(HadithItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hadith audio will be added in a future update.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHadiths;

    return Scaffold(
      backgroundColor: BrandColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                          'Sahih Bukhari (50)',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '${filtered.length}/${_hadiths.length}',
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
                    'Lightweight offline hadith collection for initial release',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xE8FFFFFF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search hadith, category, or reference',
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
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFB3261E)),
                            ),
                            const SizedBox(height: 10),
                            FilledButton(
                              onPressed: _loadHadiths,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final hasAudio = (item.audio ?? '').trim().isNotEmpty;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _openHadithDetails(item),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: BrandColors.tintBackground,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        '#${item.id}',
                                        style: const TextStyle(
                                          color: BrandColors.primaryDark,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _categoryLabel(item.category),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: BrandColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    IconButton.filledTonal(
                                      tooltip: hasAudio
                                          ? 'Play audio'
                                          : 'No audio yet',
                                      onPressed: hasAudio
                                          ? () => _onTapPlay(item)
                                          : null,
                                      icon: const Icon(
                                        Icons.play_arrow_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.titleBn.isNotEmpty
                                      ? item.titleBn
                                      : item.titleEn,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: BrandColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.english,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: BrandColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.reference,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: BrandColors.warning,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
