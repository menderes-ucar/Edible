import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../explore/presentation/providers/explore_provider.dart';
import '../../domain/entities/trip_plan_request.dart';
import '../../../subscription/domain/entities/subscription_entitlement.dart';
import '../../../subscription/presentation/widgets/premium_gate.dart';
import '../providers/trip_planner_provider.dart';

class TripPlannerPage extends StatefulWidget {
  const TripPlannerPage({super.key});

  @override
  State<TripPlannerPage> createState() => _TripPlannerPageState();
}

class _TripPlannerPageState extends State<TripPlannerPage> {
  int _hours = 4;
  TripBudget _budget = TripBudget.cheap;
  WalkingPreference _walking = WalkingPreference.medium;
  int _foodStops = 1;
  int _cultureStops = 2;

  @override
  Widget build(BuildContext context) {
    final explore = context.watch<ExploreProvider>();
    final planner = context.watch<TripPlannerProvider>();

    final cities = explore.items.map((e) => e.cityName).toSet().toList()..sort();
    final city = cities.isNotEmpty ? cities.first : '';

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.text('tripPlanner'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.l10n.text('planYourDay'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Text('${context.l10n.text('hours')}: $_hours'),
          Slider(value: _hours.toDouble(), min: 2, max: 12, divisions: 10, label: '$_hours', onChanged: (v) => setState(() => _hours = v.round())),
          const SizedBox(height: 12),
          DropdownButtonFormField<TripBudget>(
            value: _budget,
            decoration: InputDecoration(labelText: context.l10n.text('budget')),
            items: TripBudget.values.map((v) => DropdownMenuItem(value: v, child: Text(v.name))).toList(),
            onChanged: (v) => setState(() => _budget = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<WalkingPreference>(
            value: _walking,
            decoration: InputDecoration(labelText: context.l10n.text('walking')),
            items: WalkingPreference.values.map((v) => DropdownMenuItem(value: v, child: Text(v.name))).toList(),
            onChanged: (v) => setState(() => _walking = v!),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: city.isEmpty
                ? null
                : () {
                    if (!PremiumGate.allowOrOpenPaywall(
                      context,
                      PremiumFeature.advancedTripPlanner,
                    )) {
                      return;
                    }

                    planner.generate(
                      request: TripPlanRequest(
                        cityName: city,
                        hours: _hours,
                        budget: _budget,
                        walking: _walking,
                        foodStops: _foodStops,
                        cultureStops: _cultureStops,
                      ),
                      contents: explore.items,
                    );
                  },
            child: Text(context.l10n.text('generatePlan')),
          ),
          if (planner.plan != null) ...[
            const SizedBox(height: 24),
            Text(planner.plan!.cityName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ...planner.plan!.stops.map((stop) => Card(
                  child: ListTile(
                    leading: Text(stop.timeLabel, style: const TextStyle(fontWeight: FontWeight.w900)),
                    title: Text(stop.content.title),
                    subtitle: Text('${stop.content.category.name} • ${stop.content.cityName}'),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
