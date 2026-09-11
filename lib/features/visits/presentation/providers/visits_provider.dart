import 'package:flutter/foundation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/country_mastery.dart';
import '../../domain/entities/country_quest.dart';
import '../../domain/entities/country_visit_badge.dart';
import '../../domain/entities/travel_dna.dart';
import '../../domain/entities/passport_milestone.dart';
import '../../domain/entities/travel_year_summary.dart';
import '../../domain/repositories/visits_repository.dart';

class VisitsProvider extends ChangeNotifier {
  VisitsProvider({
    required VisitsRepository repository,
    required AuthProvider authProvider,
  })  : _repository = repository,
        _authProvider = authProvider {
    _authProvider.addListener(_handleAuthChanged);
    _handleAuthChanged();
  }

  final VisitsRepository _repository;
  final AuthProvider _authProvider;

  List<CountryVisitBadge> _badges = const <CountryVisitBadge>[];
  List<CountryQuest> _countryQuests = const <CountryQuest>[];
  List<CountryMastery> _countryMastery = const <CountryMastery>[];
  TravelYearSummary? _yearSummary;
  TravelDna? _travelDna;
  bool _isLoading = false;
  bool _isQuestLoading = false;
  String? _questErrorMessage;
  int _questRequestGeneration = 0;
  bool _isMasteryLoading = false;
  String? _masteryErrorMessage;
  int _masteryRequestGeneration = 0;
  String? _errorMessage;
  String? _loadedUserId;
  int _requestGeneration = 0;
  bool _disposed = false;

  List<CountryVisitBadge> get badges =>
      List<CountryVisitBadge>.unmodifiable(_badges);
  List<CountryQuest> get countryQuests =>
      List<CountryQuest>.unmodifiable(_countryQuests);
  List<CountryMastery> get countryMastery =>
      List<CountryMastery>.unmodifiable(_countryMastery);

  bool get isLoading => _isLoading;
  bool get isQuestLoading => _isQuestLoading;
  String? get questErrorMessage => _questErrorMessage;
  bool get isMasteryLoading => _isMasteryLoading;
  String? get masteryErrorMessage => _masteryErrorMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  TravelYearSummary? get yearSummary => _yearSummary;
  TravelDna? get travelDna => _travelDna;

  List<CountryVisitBadge> get mappableBadges => _badges
      .where((badge) => badge.hasMapLocation)
      .toList(growable: false);

  int get countryCount => _badges.length;

  int get shiningCount =>
      _badges.where((badge) => badge.isShining).length;

  int get unlockedCount => shiningCount;

  int get totalPhotoCount =>
      _badges.fold<int>(0, (sum, badge) => sum + badge.photoCount);


  static const List<PassportMilestone> milestones = <PassportMilestone>[
    PassportMilestone(
      key: 'first_stamp',
      requiredCountries: 1,
      titleKey: 'milestoneFirstStamp',
      subtitleKey: 'milestoneFirstStampSubtitle',
    ),
    PassportMilestone(
      key: 'traveler',
      requiredCountries: 3,
      titleKey: 'milestoneTraveler',
      subtitleKey: 'milestoneTravelerSubtitle',
    ),
    PassportMilestone(
      key: 'explorer',
      requiredCountries: 5,
      titleKey: 'milestoneExplorer',
      subtitleKey: 'milestoneExplorerSubtitle',
    ),
    PassportMilestone(
      key: 'globetrotter',
      requiredCountries: 10,
      titleKey: 'milestoneGlobetrotter',
      subtitleKey: 'milestoneGlobetrotterSubtitle',
    ),
    PassportMilestone(
      key: 'world_seeker',
      requiredCountries: 25,
      titleKey: 'milestoneWorldSeeker',
      subtitleKey: 'milestoneWorldSeekerSubtitle',
    ),
    PassportMilestone(
      key: 'world_legend',
      requiredCountries: 50,
      titleKey: 'milestoneWorldLegend',
      subtitleKey: 'milestoneWorldLegendSubtitle',
    ),
  ];

  List<PassportMilestone> get unlockedMilestones => milestones
      .where((milestone) => milestone.isUnlockedBy(countryCount))
      .toList(growable: false);

  PassportMilestone? get nextMilestone {
    for (final milestone in milestones) {
      if (!milestone.isUnlockedBy(countryCount)) {
        return milestone;
      }
    }
    return null;
  }

  int get countriesToNextMilestone {
    final next = nextMilestone;
    if (next == null) return 0;
    return (next.requiredCountries - countryCount).clamp(0, next.requiredCountries);
  }

  double get proofRatio {
    if (countryCount == 0) return 0;
    return shiningCount / countryCount;
  }

  double get completionPercent {
    if (_badges.isEmpty) return 0;
    return shiningCount / _badges.length;
  }

  Future<void> _handleAuthChanged() async {
    if (_disposed) return;

    final userId = _authProvider.user?.id;
    if (_loadedUserId == userId) return;

    _requestGeneration++;
    _masteryRequestGeneration++;
    _questRequestGeneration++;
    _loadedUserId = userId;
    _countryQuests = const <CountryQuest>[];
    _questErrorMessage = null;
    _countryMastery = const <CountryMastery>[];
    _masteryErrorMessage = null;

    if (userId == null) {
      _badges = const <CountryVisitBadge>[];
      _yearSummary = null;
      _travelDna = null;
      _isLoading = false;
      _errorMessage = null;
      _notifyIfAlive();
      return;
    }

    await refresh();
  }

  Future<void> refresh() async {
    if (_disposed) return;

    if (_authProvider.isGuest) {
      _badges = const <CountryVisitBadge>[];
      _isLoading = false;
      _errorMessage = null;
      _notifyIfAlive();
      return;
    }

    final requestId = ++_requestGeneration;
    final userId = _authProvider.user?.id;

    _isLoading = true;
    _errorMessage = null;
    _notifyIfAlive();

    try {
      final currentYear = DateTime.now().year;
      final results = await Future.wait<Object>([
        _repository.getCountryBadges(),
        _repository.getYearSummary(currentYear),
        _repository.getTravelDna(),
      ]);

      if (_disposed ||
          requestId != _requestGeneration ||
          userId != _authProvider.user?.id) {
        return;
      }

      _badges = List<CountryVisitBadge>.from(
        results[0] as List<CountryVisitBadge>,
      );
      _yearSummary = results[1] as TravelYearSummary;
      _travelDna = results[2] as TravelDna;
    } catch (error) {
      if (!_disposed &&
          requestId == _requestGeneration &&
          userId == _authProvider.user?.id) {
        _errorMessage = error.toString();
      }
    } finally {
      if (!_disposed &&
          requestId == _requestGeneration &&
          userId == _authProvider.user?.id) {
        _isLoading = false;
        _notifyIfAlive();
      }
    }
  }


  Future<void> loadCountryMastery() async {
    if (_disposed) return;

    if (_authProvider.isGuest) {
      _countryMastery = const <CountryMastery>[];
      _isMasteryLoading = false;
      _masteryErrorMessage = null;
      _notifyIfAlive();
      return;
    }

    final requestId = ++_masteryRequestGeneration;
    final userId = _authProvider.user?.id;

    _isMasteryLoading = true;
    _masteryErrorMessage = null;
    _notifyIfAlive();

    try {
      final loaded = await _repository.getCountryMastery();

      if (_disposed ||
          requestId != _masteryRequestGeneration ||
          userId != _authProvider.user?.id) {
        return;
      }

      _countryMastery = loaded;
    } catch (error) {
      if (!_disposed &&
          requestId == _masteryRequestGeneration &&
          userId == _authProvider.user?.id) {
        _masteryErrorMessage = error.toString();
      }
    } finally {
      if (!_disposed &&
          requestId == _masteryRequestGeneration &&
          userId == _authProvider.user?.id) {
        _isMasteryLoading = false;
        _notifyIfAlive();
      }
    }
  }

  Future<void> loadCountryQuests(String languageCode) async {
    if (_disposed) return;

    if (_authProvider.isGuest) {
      _countryQuests = const <CountryQuest>[];
      _isQuestLoading = false;
      _questErrorMessage = null;
      _notifyIfAlive();
      return;
    }

    final requestId = ++_questRequestGeneration;
    final userId = _authProvider.user?.id;

    _isQuestLoading = true;
    _questErrorMessage = null;
    _notifyIfAlive();

    try {
      final loaded = await _repository.getCountryQuests(languageCode);

      if (_disposed ||
          requestId != _questRequestGeneration ||
          userId != _authProvider.user?.id) {
        return;
      }

      _countryQuests = loaded;
    } catch (error) {
      if (!_disposed &&
          requestId == _questRequestGeneration &&
          userId == _authProvider.user?.id) {
        _questErrorMessage = error.toString();
      }
    } finally {
      if (!_disposed &&
          requestId == _questRequestGeneration &&
          userId == _authProvider.user?.id) {
        _isQuestLoading = false;
        _notifyIfAlive();
      }
    }
  }

  void _notifyIfAlive() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestGeneration++;
    _masteryRequestGeneration++;
    _questRequestGeneration++;
    _isLoading = false;
    _isMasteryLoading = false;
    _isQuestLoading = false;
    _authProvider.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
