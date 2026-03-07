part of '../screens/daily_activity_screen.dart';

mixin DailyActivityViewMixin
    on State<DailyActivityScreen>, DailyActivityControllerMixin {
  Widget _buildRamadanMealsSection() {
    final sehriTime = _localizedTimeOrPlaceholder(_nextSehriAt);
    final iftarTime = _localizedTimeOrPlaceholder(_nextIftarAt);
    final sehriTrailing = '${_localizedDawnPrefix()} $sehriTime';
    final iftarTrailing = '${_localizedSunsetPrefix()} $iftarTime';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E3D9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            child: Row(
              children: [
                const Icon(
                  Icons.lunch_dining_outlined,
                  size: 18,
                  color: Color(0xFF5A6D61),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _localizedNextSehriLabel(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF25332D),
                    ),
                  ),
                ),
                Text(
                  sehriTrailing,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF25332D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFDCE7DD)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2EB),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF0E3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 15,
                    color: Color(0xFF0B8D69),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _localizedNextIftarLabel(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF25332D),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      iftarTrailing,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF25332D),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_localizedRemainingLabel()} ${_formattedIftarRemaining()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4D5F56),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gaugePrayerName = _localizedPrayerName(_displayPrayer);
    final gaugeSubtitle = _isShowingActivePrayer
        ? _localizedActiveRemainingLabel()
        : _localizedPrayerTimeLabel();
    final gaugeValue = _isShowingActivePrayer
        ? _formattedActiveRemaining()
        : _localizedPrayerTime(_prayerTimes[_displayPrayer] ?? '--:--');
    final gaugeProgress = _isShowingActivePrayer ? _activeProgress : 0.0;
    final lastReadSecondary = _lastReadSecondaryLine();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: _headerHeight,
              decoration: const BoxDecoration(
                color: Color(0xFF1D98A9),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/images/header-bg.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              _formattedTime,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 170,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 420),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                layoutBuilder:
                                    (currentChild, previousChildren) => Stack(
                                      alignment: Alignment.centerRight,
                                      children: [
                                        ...previousChildren,
                                        ...?currentChild == null
                                            ? null
                                            : [currentChild],
                                      ],
                                    ),
                                transitionBuilder: (child, animation) {
                                  final slide = Tween<Offset>(
                                    begin: const Offset(0, -0.28),
                                    end: Offset.zero,
                                  ).animate(animation);
                                  return ClipRect(
                                    child: SlideTransition(
                                      position: slide,
                                      child: FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  _activeHeaderDate,
                                  key: ValueKey(_activeHeaderDate),
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _localizedCountdownLabel(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: _refreshLocationFromHeader,
                              borderRadius: BorderRadius.circular(1000),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x33FFFFFF),
                                  borderRadius: BorderRadius.circular(1000),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      width: 132,
                                      child: Text(
                                        _locationLabel,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        HomeActivePrayerGauge(
                          prayerName: gaugePrayerName,
                          subtitle: gaugeSubtitle,
                          remainingTime: gaugeValue,
                          progress: gaugeProgress,
                        ),
                        const SizedBox(height: 6),
                        if (!_isShowingActivePrayer)
                          Align(
                            alignment: Alignment.center,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () {
                                setState(() => _selectedPrayer = null);
                                _syncPrayerPageToActive(animate: true);
                              },
                              icon: const Icon(Icons.my_location, size: 16),
                              label: Text(
                                _isBangla
                                    ? '\u09ac\u09b0\u09cd\u09a4\u09ae\u09be\u09a8 \u09aa\u09cd\u09b0\u09be\u09b0\u09cd\u09a5\u09a8\u09be'
                                    : 'Back to current',
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -12,
                    child: SizedBox(
                      height: 102,
                      child: PageView.builder(
                        controller: _prayerPageController,
                        itemCount: _prayerOrder.length,
                        onPageChanged: (index) {
                          setState(() => _selectedPrayer = _prayerOrder[index]);
                        },
                        itemBuilder: (context, index) {
                          final prayer = _prayerOrder[index];
                          return Center(
                            child: HomePrayerTile(
                              title: _localizedPrayerName(prayer),
                              time: _localizedPrayerTime(
                                _prayerTimes[prayer] ?? '--:--',
                              ),
                              active: prayer == _displayPrayer,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  _buildRamadanMealsSection(),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE1E8EC)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _localizedLastReadLabel(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6F8DA1),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.menu_book_rounded,
                                    size: 16,
                                    color: Color(0xFF1D98A9),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _lastReadPrimaryLine(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1F252D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (lastReadSecondary != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  lastReadSecondary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6F8DA1),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: _openLastRead,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1D98A9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(1000),
                            ),
                          ),
                          child: Text(
                            _localizedContinueLabel(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE1E8EC)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.prayerCompass),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Locate',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1F252D),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Qibla',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D98A9),
                                      borderRadius: BorderRadius.circular(1000),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.explore,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const SizedBox(
                            height: 48,
                            child: VerticalDivider(
                              color: Color(0xFFE1E8EC),
                              thickness: 1,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.findMosque),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Find nearest',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1F252D),
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Mosque',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D98A9),
                                      borderRadius: BorderRadius.circular(1000),
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.location_city,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () =>
                          Navigator.of(context).pushNamed(RouteNames.asma),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE1E8EC)),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Read',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1F252D),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '99 Names (Asma Ul Husna)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D98A9),
                                borderRadius: BorderRadius.circular(1000),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () =>
                          Navigator.of(context).pushNamed(RouteNames.dua),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE1E8EC)),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Read',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1F252D),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Hisnul Muslim Duas',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D98A9),
                                borderRadius: BorderRadius.circular(1000),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () =>
                          Navigator.of(context).pushNamed(RouteNames.hadith),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE1E8EC)),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Read',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1F252D),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Sahih Bukhari (50 Hadith)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D98A9),
                                borderRadius: BorderRadius.circular(1000),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.format_quote_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        'Daily Activity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F252D),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC95C16),
                          borderRadius: BorderRadius.circular(1000),
                        ),
                        child: const Text(
                          '50%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Complete the daily activity checklist',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6F8DA1)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (int i = 0; i < _dailyGoal; i++) ...[
                        Expanded(
                          child: Container(
                            height: 6,
                            margin: EdgeInsets.only(
                              right: i == _dailyGoal - 1 ? 0 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: i < _completedDaily
                                  ? const Color(0xFF1D98A9)
                                  : const Color(0xFFE1E8EC),
                              borderRadius: BorderRadius.circular(1000),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        '$_completedDaily/$_dailyGoal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1D98A9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._activities.map(
                    (activity) => HomeChecklistRow(
                      title: activity.title,
                      status: '${activity.done}/${activity.total}',
                      isDone: activity.done >= activity.total,
                      onTapDone: () {
                        setState(() {
                          if (activity.done < activity.total) {
                            activity.done += 1;
                          }
                          if (_completedDaily < _dailyGoal) {
                            _completedDaily += 1;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 46),
                      backgroundColor: const Color(0xFF1D98A9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Daily activity saved locally'),
                        ),
                      );
                    },
                    child: const Text('Go to Checklist'),
                  ),
                ],
              ),
            ),
            bottomNav(context, 0),
          ],
        ),
      ),
    );
  }
}
