import '../entities/country_mastery.dart';
import '../entities/country_quest.dart';
import '../entities/country_visit_badge.dart';
import '../entities/travel_dna.dart';
import '../entities/travel_year_summary.dart';

abstract interface class VisitsRepository {
  Future<List<CountryVisitBadge>> getCountryBadges();

  Future<List<CountryQuest>> getCountryQuests(String languageCode);

  Future<List<CountryMastery>> getCountryMastery();

  Future<TravelYearSummary> getYearSummary(int year);

  Future<TravelDna> getTravelDna();
}
