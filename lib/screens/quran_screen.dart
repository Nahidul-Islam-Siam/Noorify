import 'package:flutter/material.dart';

import '../models/quran_models.dart';
import 'surah_detail_screen.dart';
import '../services/quran_api_service.dart';
import '../widgets/bottom_nav.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  static const _quickLinkIds = [18, 36, 55, 67];

  final QuranApiService _api = QuranApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final Set<int> _downloadedSurahNos = {};

  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filter = 'all';
  bool _showOnlyDownloaded = false;

  List<QuranChapter> _chapters = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

  Future<void> _loadChapters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final chapters = await _api.fetchChapters();
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'কুরআনের তালিকা লোড করা যায়নি।';
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

  Future<void> _showSurahDetail(QuranChapter chapter) async {
    final downloaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SurahDetailScreen(chapter: chapter),
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

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D8F77), Color(0xFF1AA390), Color(0xFF45BCAA)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'কুরআন',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'API • অডিও • অফলাইন',
                style: TextStyle(
                  color: Color(0xD9FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderActionButton(
                  icon: Icons.menu_book_outlined,
                  label: 'তিলাওয়াত',
                  onTap: () {},
                ),
                _HeaderActionButton(
                  icon: Icons.search_rounded,
                  label: 'অনুসন্ধান',
                  onTap: () => _searchFocusNode.requestFocus(),
                ),
                _HeaderActionButton(
                  icon: Icons.headphones_rounded,
                  label: 'অডিও',
                  onTap: () {
                    if (_chapters.isEmpty) return;
                    _showSurahDetail(_chapters.first);
                  },
                ),
                _HeaderActionButton(
                  icon: Icons.ondemand_video_rounded,
                  label: 'ভিডিও',
                  onTap: _showVideoInfo,
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: quickLinks.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chapter = quickLinks[index];
                  return ActionChip(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    label: Text(
                      chapter.surahNameArabic,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    onPressed: () => _showSurahDetail(chapter),
                  );
                },
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
                borderSide: const BorderSide(color: Color(0xFFD8E6E2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD8E6E2)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
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
      backgroundColor: const Color(0xFFF4F8F7),
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
                            onAudio: () => _showSurahDetail(chapter),
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

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
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
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
          color: selected ? const Color(0xFF0C9A77) : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: selected ? const Color(0xFF0C9A77) : const Color(0xFFD4E3DF),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF30534A),
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
            border: Border.all(color: const Color(0xFFD9E6E2)),
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
                    colors: [Color(0xFF0E9A78), Color(0xFF36B49B)],
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
                        color: Color(0xFF1E3F38),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      chapter.surahName,
                      style: const TextStyle(
                        color: Color(0xFF395D54),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$revelationLabel • ${chapter.totalAyah} আয়াত • ${chapter.surahNameTranslation}',
                      style: const TextStyle(
                        color: Color(0xFF627772),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onAudio,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEAF3F0),
                  foregroundColor: downloaded
                      ? const Color(0xFF0C9A77)
                      : const Color(0xFF3B8375),
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
