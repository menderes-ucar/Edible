import 'package:flutter/material.dart';
import '../../domain/entities/trip_plan.dart';

class TripTimeline extends StatelessWidget {
  const TripTimeline({
    required this.plan,
    super.key,
  });

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: plan.stops.length,
      itemBuilder: (_, index) {
        final stop = plan.stops[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text('${index + 1}'),
          ),
          title: Text(stop.title),
          subtitle: Text('${stop.minutesFromStart} min'),
        );
      },
    );
  }
}