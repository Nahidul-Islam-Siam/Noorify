import 'dart:async';

import 'package:flutter/material.dart';

import '../app/brand_colors.dart';
import '../models/quran_models.dart';
import 'surah_detail_screen.dart';
import '../services/quran_api_service.dart';
import '../services/quran_last_read_service.dart';
import '../widgets/bottom_nav.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  static const _quickLinkIds = [18, 36, 55, 67];

  final QuranApiService _api = QuranApiService();
  final QuranLastReadService _lastReadService = QuranLastReadService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final Set<int> _downloadedSurahNos = {};

  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filter = 'all';
  bool _showOnlyDownloaded = false;
  bool _usingCachedContent = false;
  int? _lastReadSurahNo;

  List<QuranChapter> _chapters = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _restoreLastRead();
    _loadChapters();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  Future<void> _restoreLastRead() async {
    final saved = await _lastReadService.readLastReadSurahNo();
    if (!mounted || saved == null) return;
    setState(() => _lastReadSurahNo = saved);
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final chapters = await _api.fetchChapters();
      final fromCache = _api.lastReadFromCache;
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _usingCachedContent = fromCache;
        _isLoading = false;
      });
      if (fromCache) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ইন্টারনেট নেই। সেভ করা কনটেন্ট দেখানো হচ্ছে।'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'কুরআনের তালিকা লোড করা যায়নি।';
        _usingCachedContent = false;
        _isLoading = false;
      });
    }
  }

  List<QuranChapter> get _filteredChapters {
    return _chapters
        .where((chapter) {
          if (_showOnlyDownloaded &&
              !_downloadedSurahNos.contains(chapter.surahNo)) {
            return false;
          }

          if (_filter == 'meccan' && !chapter.isMeccan) return false;
          if (_filter == 'medinan' && !chapter.isMedinan) return false;

          if (_searchQuery.isEmpty) return true;
          return chapter.surahNo.toString() == _searchQuery ||
              chapter.surahName.toLowerCase().contains(_searchQuery) ||
              chapter.surahNameArabic.contains(_searchQuery) ||
              chapter.surahNameTranslation.toLowerCase().contains(_searchQuery);
        })
        .toList(growable: false);
  }

  String _revelationLabel(String place) {
    final lower = place.toLowerCase();
    if (lower.contains('mecca')) return 'মক্কী';
    if (lower.contains('medina')) return 'মাদানী';
    return place;
  }

  Future<void> _showSurahDetail(
    QuranChapter chapter, {
    bool autoStartAudio = false,
  }) async {
    if (_lastReadSurahNo != chapter.surahNo) {
      setState(() => _lastReadSurahNo = chapter.surahNo);
      unawaited(_lastReadService.saveLastReadSurahNo(chapter.surahNo));
    }

    final downloaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SurahDetailScreen(
          chapter: chapter,
          autoStartAudio: autoStartAudio,
        ),
      ),
    );
    if (!mounted || downloaded != true) return;
    setState(() => _downloadedSurahNos.add(chapter.surahNo));
  }

  void _showVideoInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ভিডিও তথ্য'),
          content: const Text(
            'QuranAPI docs এ সরাসরি ভিডিও endpoint নেই।\n'
            'অডিও endpoint আছে এবং সেটি অফলাইনে ডাউনলোড করা যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ঠিক আছে'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    final quickLinks = _quickLinkIds
        .map(
          (id) => _chapters.firstWhere(
            (chapter) => chapter.surahNo == id,
            orElse: () => QuranChapter(
              surahNo: id,
              surahName: 'Surah $id',
              surahNameArabic: '...',
              surahNameArabicLong: '...',
              surahNameTranslation: '',
              revelationPlace: '',
              totalAyah: 0,
            ),
          ),
        )
        .toList(growable: false);

    final lastReadChapter = _chapters.firstWhere(
      (chapter) => chapter.surahNo == (_lastReadSurahNo ?? 2),
      orElse: () => quickLinks.first,
    );

    return Container(
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
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(54),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(54),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -34,
              child: Container(
                width: 132,
                height: 132,
                decoration: const BoxDecoration(
                  color: Color(0x26FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -42,
              bottom: -64,
              child: Container(
                width: 178,
                height: 178,
                decoration: const BoxDecoration(
                  color: Color(0x17FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'কুরআন',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Read • Listen • Offline',
                              style: TextStyle(
                                color: Color(0xDDFFFFFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _usingCachedContent
                                  ? Icons.cloud_off_rounded
                                  : Icons.cloud_done_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _usingCachedContent ? 'Offline' : 'Live',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _showVideoInfo,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bookmark_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Read',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${lastReadChapter.surahName} • Surah ${lastReadChapter.surahNo}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _showSurahDetail(lastReadChapter),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: BrandColors.primaryDark,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 34),
                          ),
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeaderQuickActionChip(
                        icon: Icons.search_rounded,
                        label: 'Search',
                        onTap: () => _searchFocusNode.requestFocus(),
                      ),
                      _HeaderQuickActionChip(
                        icon: Icons.menu_book_outlined,
                        label: 'Tilawat',
                        onTap: () => _showSurahDetail(lastReadChapter),
                      ),
                      _HeaderQuickActionChip(
                        icon: Icons.headphones_rounded,
                        label: 'Audio',
                        onTap: () => _showSurahDetail(
                          lastReadChapter,
                          autoStartAudio: true,
                        ),
                      ),
                      _HeaderQuickActionChip(
                        icon: Icons.ondemand_video_rounded,
                        label: 'Video',
                        onTap: _showVideoInfo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Surah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final chapter in quickLinks) ...[
                          _HeaderSurahChip(
                            label: chapter.surahNameArabic,
                            onTap: () => _showSurahDetail(chapter),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'সূরা নাম/নম্বর দিয়ে খুঁজুন',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: BrandColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: BrandColors.border),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (_usingCachedContent)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: BrandColors.tintBackground,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: BrandColors.border),
                  ),
                  child: const Text(
                    'Offline cache',
                    style: TextStyle(
                      fontSize: 12,
                      color: BrandColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              _FilterChipButton(
                label: 'সব',
                selected: _filter == 'all',
                onTap: () => setState(() => _filter = 'all'),
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                label: 'মক্কী',
                selected: _filter == 'meccan',
                onTap: () => setState(() => _filter = 'meccan'),
              ),
              const SizedBox(width: 8),
              _FilterChipButton(
                label: 'মাদানী',
                selected: _filter == 'medinan',
                onTap: () => setState(() => _filter = 'medinan'),
              ),
              const Spacer(),
              FilterChip(
                selected: _showOnlyDownloaded,
                label: const Text('ডাউনলোডেড'),
                selectedColor: BrandColors.tintBackgroundStrong,
                checkmarkColor: BrandColors.primaryDark,
                side: const BorderSide(color: BrandColors.border),
                onSelected: (v) => setState(() => _showOnlyDownloaded = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.screenBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _loadChapters,
                            style: FilledButton.styleFrom(
                              backgroundColor: BrandColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('আবার চেষ্টা করুন'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      itemCount: _filteredChapters.length,
                      itemBuilder: (context, index) {
                        final chapter = _filteredChapters[index];
                        final downloaded = _downloadedSurahNos.contains(
                          chapter.surahNo,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _QuranSurahTile(
                            chapter: chapter,
                            downloaded: downloaded,
                            revelationLabel: _revelationLabel(
                              chapter.revelationPlace,
                            ),
                            onTap: () => _showSurahDetail(chapter),
                            onAudio: () => _showSurahDetail(
                              chapter,
                              autoStartAudio: true,
                            ),
                          ),
                        );
                      },
                    ),
            ),
            bottomNav(context, 2),
          ],
        ),
      ),
    );
  }
}

class _HeaderQuickActionChip extends StatelessWidget {
  const _HeaderQuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSurahChip extends StatelessWidget {
  const _HeaderSurahChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? BrandColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? BrandColors.primary : BrandColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : BrandColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _QuranSurahTile extends StatelessWidget {
  const _QuranSurahTile({
    required this.chapter,
    required this.downloaded,
    required this.revelationLabel,
    required this.onTap,
    required this.onAudio,
  });

  final QuranChapter chapter;
  final bool downloaded;
  final String revelationLabel;
  final VoidCallback onTap;
  final VoidCallback onAudio;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrandColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [BrandColors.primaryDark, BrandColors.primary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  chapter.surahNo.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.surahNameArabic,
                      style: const TextStyle(
                        color: BrandColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      chapter.surahName,
                      style: const TextStyle(
                        color: BrandColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$revelationLabel • ${chapter.totalAyah} আয়াত • ${chapter.surahNameTranslation}',
                      style: const TextStyle(
                        color: BrandColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onAudio,
                style: IconButton.styleFrom(
                  backgroundColor: BrandColors.tintBackground,
                  foregroundColor: downloaded
                      ? BrandColors.primary
                      : BrandColors.primaryDark,
                ),
                icon: Icon(
                  downloaded
                      ? Icons.download_done_rounded
                      : Icons.headphones_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
