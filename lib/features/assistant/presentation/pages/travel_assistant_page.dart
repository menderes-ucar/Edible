import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/error/app_error_presenter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/router/app_routes.dart';
import '../../../subscription/domain/entities/subscription_entitlement.dart';
import '../../../subscription/presentation/widgets/premium_gate.dart';
import '../providers/travel_assistant_provider.dart';

class TravelAssistantPage extends StatefulWidget {
  const TravelAssistantPage({
    this.defaultCityName,
    super.key,
  });

  final String? defaultCityName;

  @override
  State<TravelAssistantPage> createState() => _TravelAssistantPageState();
}

class _TravelAssistantPageState extends State<TravelAssistantPage> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    final city = widget.defaultCityName;
    if (city != null && city.trim().isNotEmpty) {
      _controller.text = '$city, 4 saat, yerel yemek ve kültür';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    if (!PremiumGate.allowOrOpenPaywall(
      context,
      PremiumFeature.travelAssistant,
    )) {
      return;
    }

    await context.read<TravelAssistantProvider>().ask(
          message: _controller.text,
          languageCode: Localizations.localeOf(context).languageCode,
          defaultCityName: widget.defaultCityName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TravelAssistantProvider>();
    final response = state.response;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('travelAssistant')),
        actions: [
          if (response != null)
            IconButton(
              onPressed: state.clear,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            context.l10n.text('assistantHeadline'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 6),
          Text(context.l10n.text('assistantSubtitle')),
          const SizedBox(height: 18),
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: context.l10n.text('assistantHint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: state.isLoading ? null : _ask,
            icon: state.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(context.l10n.text('buildMyRoute')),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              AppErrorPresenter.message(context, state.errorMessage),
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          if (response != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      response.summary,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${response.cityName} • ${response.hours} ${context.l10n.text('hours')}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...response.stops.map(
              (stop) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      stop.timeLabel,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                  title: Text(
                    stop.content.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: Text(stop.reason),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    AppRoutes.contentDetail(stop.content.id),
                    extra: stop.content,
                  ),
                ),
              ),
            ),
            if (response.tips.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                context.l10n.text('assistantTips'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              ...response.tips.map(
                (tip) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: Text(tip),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
