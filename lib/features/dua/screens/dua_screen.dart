import 'package:flutter/material.dart';

import 'package:first_project/features/dua/models/dua_item.dart';
import 'package:first_project/features/dua/services/dua_service.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  final DuaService _duaService = DuaService();

  bool _isLoading = true;
  String? _error;
  List<DuaItem> _duas = const [];

  static const List<_PrayerCategory> _prayerCategories = [
    _PrayerCategory(
      key: 'after_fajr',
      titleBn: '????? ??????? ?? ???',
      titleEn: 'After Fajr Prayer',
      icon: Icons.wb_sunny_outlined,
    ),
    _PrayerCategory(
      key: 'after_zuhr',
      titleBn: '?????? ??????? ?? ???',
      titleEn: 'After Zuhr Prayer',
      icon: Icons.light_mode_outlined,
    ),
    _PrayerCategory(
      key: 'after_asr',
      titleBn: '????? ??????? ?? ???',
      titleEn: 'After Asr Prayer',
      icon: Icons.schedule_rounded,
    ),
    _PrayerCategory(
      key: 'after_maghrib',
      titleBn: '???????? ??????? ?? ???',
      titleEn: 'After Maghrib Prayer',
      icon: Icons.nights_stay_outlined,
    ),
    _PrayerCategory(
      key: 'after_isha',
      titleBn: '??? ??????? ?? ???',
      titleEn: 'After Isha Prayer',
      icon: Icons.dark_mode_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadDuas();
  }

  Future<void> _loadDuas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final duas = await _duaService.loadDuas();
      if (!mounted) return;
      setState(() {
        _duas = duas;
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

  int _categoryCount(String key) =>
      _duas.where((item) => item.category == key).length;

  void _openCategory(_PrayerCategory category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _DuaCategoryScreen(category: category, allDuas: _duas),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguageNotifier,
      builder: (context, language, _) {
        final isBangla = language == AppLanguage.bangla;

        return Scaffold(
          backgroundColor: glass.bgBottom,
          body: NoorifyGlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                    child: NoorifyGlassCard(
                      radius: BorderRadius.circular(20),
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBangla ? '????' : 'Dua',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: glass.textPrimary,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isBangla
                                      ? '?????-??????? ??? ????????? ????? ????'
                                      : 'Choose a prayer-based dua category',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: glass.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.menu_book_rounded,
                            color: glass.accent,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: glass.accent,
                            ),
                          )
                        : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: glass.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  FilledButton(
                                    onPressed: _loadDuas,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: glass.accent,
                                      foregroundColor: glass.isDark
                                          ? const Color(0xFF052830)
                                          : Colors.white,
                                    ),
                                    child: Text(
                                      isBangla ? '???? ?????? ????' : 'Retry',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                            children: [
                              _PrayerCategoryGrid(
                                categories: _prayerCategories,
                                isBangla: isBangla,
                                countForKey: _categoryCount,
                                onOpen: _openCategory,
                              ),
                            ],
                          ),
                  ),
                  bottomNav(context, 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DuaCategoryScreen extends StatefulWidget {
  const _DuaCategoryScreen({required this.category, required this.allDuas});

  final _PrayerCategory category;
  final List<DuaItem> allDuas;

  @override
  State<_DuaCategoryScreen> createState() => _DuaCategoryScreenState();
}

class _DuaCategoryScreenState extends State<_DuaCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _showSearch = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

  List<DuaItem> _filtered() {
    final byCategory = widget.allDuas.where(
      (item) => item.category == widget.category.key,
    );

    if (_query.isEmpty) return byCategory.toList(growable: false);

    return byCategory
        .where((item) {
          return item.id.toString().contains(_query) ||
              item.titleEn.toLowerCase().contains(_query) ||
              item.titleBn.toLowerCase().contains(_query) ||
              item.arabic.contains(_query) ||
              item.english.toLowerCase().contains(_query) ||
              item.bangla.toLowerCase().contains(_query) ||
              item.reference.toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }

  String _titleFor(DuaItem item, bool isBangla) {
    final bn = item.titleBn.trim();
    final en = item.titleEn.trim();
    if (isBangla) return bn.isNotEmpty ? bn : en;
    return en.isNotEmpty ? en : bn;
  }

  String _subtitleFor(DuaItem item, bool isBangla) {
    final en = item.titleEn.trim();
    final bn = item.titleBn.trim();
    return isBangla ? en : bn;
  }

  void _openDuaDetails(DuaItem item, bool isBangla) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final glass = NoorifyGlassTheme(sheetContext);
        final title = _titleFor(item, isBangla);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: glass.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: glass.isDark
                        ? const Color(0x33162833)
                        : const Color(0xFFF2F8FB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: glass.glassBorder),
                  ),
                  child: Text(
                    item.arabic,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 34,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: glass.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  isBangla ? item.bangla : item.english,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.7,
                    color: glass.textPrimary,
                  ),
                ),
                if (item.reference.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    isBangla ? '?????????' : 'Reference',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: glass.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.reference,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: glass.textSecondary,
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

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguageNotifier,
      builder: (context, language, _) {
        final isBangla = language == AppLanguage.bangla;
        final filtered = _filtered();

        return Scaffold(
          backgroundColor: glass.bgBottom,
          body: NoorifyGlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                    child: NoorifyGlassCard(
                      radius: BorderRadius.circular(18),
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.arrow_back_rounded),
                                tooltip: isBangla ? '???? ???' : 'Back',
                              ),
                              Expanded(
                                child: Text(
                                  isBangla
                                      ? widget.category.titleBn
                                      : widget.category.titleEn,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: glass.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _showSearch = !_showSearch;
                                    if (!_showSearch) {
                                      _searchController.clear();
                                    }
                                  });
                                },
                                icon: Icon(
                                  _showSearch
                                      ? Icons.close_rounded
                                      : Icons.search_rounded,
                                ),
                                tooltip: isBangla ? '??????' : 'Search',
                              ),
                            ],
                          ),
                          if (_showSearch) ...[
                            const SizedBox(height: 8),
                            TextField(
                              controller: _searchController,
                              style: TextStyle(color: glass.textPrimary),
                              decoration: InputDecoration(
                                hintText: isBangla
                                    ? '??????? ?? ???? ???? ??????'
                                    : 'Search by title or meaning',
                                hintStyle: TextStyle(color: glass.textMuted),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: glass.textMuted,
                                ),
                                filled: true,
                                fillColor: glass.isDark
                                    ? const Color(0x33152933)
                                    : const Color(0xF2FFFFFF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: glass.glassBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: glass.glassBorder,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                      children: [
                        NoorifyGlassCard(
                          radius: BorderRadius.circular(16),
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: Row(
                            children: [
                              Icon(
                                widget.category.icon,
                                size: 18,
                                color: glass.accent,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isBangla
                                      ? widget.category.titleBn
                                      : widget.category.titleEn,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: glass.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: glass.isDark
                                      ? const Color(0x2A2EB8E6)
                                      : const Color(0x221EA8B8),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${filtered.length}',
                                  style: TextStyle(
                                    color: glass.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (filtered.isEmpty)
                          NoorifyGlassCard(
                            radius: BorderRadius.circular(16),
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              isBangla
                                  ? '?? ???????? ???? ???? ????? ??????'
                                  : 'No dua found for this filter.',
                              style: TextStyle(
                                color: glass.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          ...filtered.map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => _openDuaDetails(item, isBangla),
                                child: NoorifyGlassCard(
                                  radius: BorderRadius.circular(14),
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    12,
                                    10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _titleFor(item, isBangla),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: glass.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _subtitleFor(item, isBangla),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: glass.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.bookmark_add_outlined,
                                        size: 21,
                                        color: glass.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PrayerCategoryGrid extends StatelessWidget {
  const _PrayerCategoryGrid({
    required this.categories,
    required this.isBangla,
    required this.countForKey,
    required this.onOpen,
  });

  final List<_PrayerCategory> categories;
  final bool isBangla;
  final int Function(String key) countForKey;
  final ValueChanged<_PrayerCategory> onOpen;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final itemWidth = (MediaQuery.of(context).size.width - 38) / 2;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories
          .map((category) {
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onOpen(category),
              child: SizedBox(
                width: itemWidth,
                child: NoorifyGlassCard(
                  radius: BorderRadius.circular(16),
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                  child: Column(
                    children: [
                      Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: glass.isDark
                              ? const Color(0x33243C46)
                              : const Color(0xFFE5F5F6),
                          border: Border.all(
                            color: glass.glassBorder,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          category.icon,
                          size: 34,
                          color: glass.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isBangla ? category.titleBn : category.titleEn,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: glass.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: glass.isDark
                              ? const Color(0x2A2EB8E6)
                              : const Color(0x221EA8B8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${countForKey(category.key)}',
                          style: TextStyle(
                            color: glass.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _PrayerCategory {
  const _PrayerCategory({
    required this.key,
    required this.titleBn,
    required this.titleEn,
    required this.icon,
  });

  final String key;
  final String titleBn;
  final String titleEn;
  final IconData icon;
}
