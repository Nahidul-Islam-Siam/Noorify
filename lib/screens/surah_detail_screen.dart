import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../app/brand_colors.dart';
import '../models/quran_models.dart';
import '../services/quran_api_service.dart';
import '../services/quran_offline_download_service.dart';

class SurahDetailScreen extends StatefulWidget {
  const SurahDetailScreen({super.key, required this.chapter});

  final QuranChapter chapter;

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranApiService _api = QuranApiService();
  final QuranOfflineDownloadService _offline = QuranOfflineDownloadService();
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  QuranSurahDetail? _detail;
  String? _error;
  bool _isLoading = true;
  bool _isPreparingAudio = false;
  bool _isDownloadingAudio = false;
  bool _didDownloadAudio = false;
  bool _usingCachedContent = false;

  int? _selectedReciterId;
  int? _preparedReciterId;
  final Set<int> _cachedReciterIds = {};

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _bindAudioStreams();
    _loadSurahDetail();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _bindAudioStreams() {
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
      });
    });

    _positionSub = _player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });

    _durationSub = _player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration ?? Duration.zero);
    });
  }

  Future<void> _loadSurahDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _api.fetchSurahDetail(
        widget.chapter.surahNo,
        lang: 'bn',
      );
      final fromCache = _api.lastReadFromCache;
      final cachedIds = <int>{};
      for (final reciter in detail.audioByReciter) {
        final isCached = await _offline.hasAudio(reciter.url);
        if (isCached) cachedIds.add(reciter.id);
      }

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _selectedReciterId = detail.audioByReciter.isNotEmpty
            ? detail.audioByReciter.first.id
            : null;
        _cachedReciterIds
          ..clear()
          ..addAll(cachedIds);
        _usingCachedContent = fromCache;
        _isLoading = false;
      });
      if (fromCache) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('অফলাইন সেভ করা সূরার কনটেন্ট দেখানো হচ্ছে।'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'সূরার বিস্তারিত লোড করা যায়নি। একবার ইন্টারনেট অন করে এই সূরা খুলুন, পরে অফলাইনে পাবেন।';
        _isLoading = false;
      });
    }
  }

  QuranReciterAudio? get _selectedReciter {
    final detail = _detail;
    if (detail == null || detail.audioByReciter.isEmpty) return null;
    if (_selectedReciterId == null) return detail.audioByReciter.first;

    for (final reciter in detail.audioByReciter) {
      if (reciter.id == _selectedReciterId) return reciter;
    }
    return detail.audioByReciter.first;
  }

  String _toBanglaDigits(String input) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var output = input;
    for (var i = 0; i < latin.length; i++) {
      output = output.replaceAll(latin[i], bangla[i]);
    }
    return output;
  }

  String _revelationLabel(String place) {
    final lower = place.toLowerCase();
    if (lower.contains('mecca')) return 'মক্কী';
    if (lower.contains('medina')) return 'মাদানী';
    return place;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _onReciterChanged(int? reciterId) async {
    if (reciterId == null || reciterId == _selectedReciterId) return;
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _selectedReciterId = reciterId;
      _preparedReciterId = null;
      _position = Duration.zero;
      _duration = Duration.zero;
    });
  }

  Future<void> _prepareAudio(QuranReciterAudio reciter) async {
    final cachedFile = await _offline.getCachedAudio(reciter.url);
    if (cachedFile != null) {
      await _player.setFilePath(cachedFile.path);
      _cachedReciterIds.add(reciter.id);
      return;
    }
    await _player.setUrl(reciter.url);
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    final reciter = _selectedReciter;
    if (reciter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এই সূরার অডিও পাওয়া যায়নি')),
      );
      return;
    }

    if (_preparedReciterId == reciter.id && _player.audioSource != null) {
      await _player.play();
      return;
    }

    setState(() => _isPreparingAudio = true);
    try {
      await _prepareAudio(reciter);
      await _player.play();
      if (!mounted) return;
      setState(() {
        _preparedReciterId = reciter.id;
        _isPreparingAudio = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPreparingAudio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অডিও প্লে করা যায়নি। ইন্টারনেট চেক করুন।'),
        ),
      );
    }
  }

  Future<void> _stopAudio() async {
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _position = Duration.zero;
      _duration = Duration.zero;
    });
  }

  Future<void> _downloadSelectedAudio() async {
    final reciter = _selectedReciter;
    if (reciter == null || _isDownloadingAudio) return;

    setState(() => _isDownloadingAudio = true);
    try {
      final path = await _offline.downloadAudio(reciter.url);
      if (!mounted) return;
      setState(() {
        _cachedReciterIds.add(reciter.id);
        _isDownloadingAudio = false;
        _didDownloadAudio = true;
      });
      final fileName = path.split('\\').last.split('/').last;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('অডিও সেভ হয়েছে: $fileName')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDownloadingAudio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অডিও ডাউনলোড ব্যর্থ হয়েছে')),
      );
    }
  }

  Widget _buildAudioCard(QuranSurahDetail detail) {
    final reciter = _selectedReciter;
    final hasReciters = detail.audioByReciter.isNotEmpty;
    final isCached = reciter != null && _cachedReciterIds.contains(reciter.id);

    final durationMs = _duration.inMilliseconds;
    final maxMs = durationMs > 0 ? durationMs : 1;
    final currentMs = _position.inMilliseconds.clamp(0, maxMs);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.tintBackground, Color(0xFFF2FBFD)],
        ),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.surahNameArabicLong,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: BrandColors.textPrimary,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 4),
          Text(
            '${_toBanglaDigits(detail.surahNo.toString())}. ${detail.surahName} • ${_revelationLabel(detail.revelationPlace)} • ${_toBanglaDigits(detail.totalAyah.toString())} আয়াত',
            style: const TextStyle(
              color: BrandColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_usingCachedContent) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: BrandColors.tintBackgroundStrong,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Offline saved content',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.primaryDark,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (hasReciters)
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'রিসাইটার',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedReciter?.id,
                  items: detail.audioByReciter
                      .map(
                        (reciter) => DropdownMenuItem<int>(
                          value: reciter.id,
                          child: Text(
                            reciter.reciter,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _onReciterChanged,
                ),
              ),
            )
          else
            const Text(
              'এই সূরার জন্য অডিও সোর্স পাওয়া যায়নি।',
              style: TextStyle(
                color: Color(0xFF7A4444),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: currentMs.toDouble(),
              min: 0,
              max: maxMs.toDouble(),
              onChanged: durationMs > 0
                  ? (value) =>
                        _player.seek(Duration(milliseconds: value.round()))
                  : null,
            ),
          ),
          Row(
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(
                  fontSize: 12,
                  color: BrandColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(
                  fontSize: 12,
                  color: BrandColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: hasReciters && !_isPreparingAudio
                      ? _togglePlayPause
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: _isPreparingAudio
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                  label: Text(_isPlaying ? 'Pause' : 'Play'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _isPlaying || _position > Duration.zero
                    ? _stopAudio
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: BrandColors.primaryDark,
                  side: const BorderSide(color: BrandColors.border),
                ),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Stop'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: hasReciters && !_isDownloadingAudio
                    ? _downloadSelectedAudio
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: BrandColors.tintBackgroundStrong,
                  foregroundColor: BrandColors.primaryDark,
                ),
                icon: _isDownloadingAudio
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isCached
                            ? Icons.download_done_rounded
                            : Icons.download_rounded,
                      ),
                label: Text(isCached ? 'Saved' : 'Offline'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAyahCard({
    required int index,
    required String arabic,
    required String bengali,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrandColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: BrandColors.tintBackground,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _toBanglaDigits((index + 1).toString()),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: BrandColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'আরবি + বাংলা',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: BrandColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (arabic.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                arabic,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                  color: BrandColors.textPrimary,
                ),
              ),
            ),
          ],
          if (bengali.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bengali,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: BrandColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_didDownloadAudio);
      },
      child: Scaffold(
        backgroundColor: BrandColors.screenBackground,
        appBar: AppBar(
          backgroundColor: BrandColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(_didDownloadAudio),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(widget.chapter.surahName),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _loadSurahDetail,
                      style: FilledButton.styleFrom(
                        backgroundColor: BrandColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('আবার চেষ্টা করুন'),
                    ),
                  ],
                ),
              )
            : Builder(
                builder: (context) {
                  final detail = _detail!;
                  final totalAyah = math.max(
                    detail.arabicAyahs.length,
                    detail.bengaliAyahs.length,
                  );

                  return Column(
                    children: [
                      _buildAudioCard(detail),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: totalAyah,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final arabic = index < detail.arabicAyahs.length
                                ? detail.arabicAyahs[index]
                                : '';
                            final bengali = index < detail.bengaliAyahs.length
                                ? detail.bengaliAyahs[index]
                                : '';

                            return _buildAyahCard(
                              index: index,
                              arabic: arabic,
                              bengali: bengali,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
