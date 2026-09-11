import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/error/app_error_presenter.dart';

import '../../../../core/localization/app_localizations.dart';
import '../providers/culture_guide_provider.dart';
import '../widgets/culture_guide_section.dart';

class CultureGuidePage extends StatefulWidget {
  const CultureGuidePage({
    required this.countryCode,
    required this.cityName,
    super.key,
  });

  final String countryCode;
  final String cityName;

  @override
  State<CultureGuidePage> createState() => _CultureGuidePageState();
}

class _CultureGuidePageState extends State<CultureGuidePage> {
  String? _languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final language = Localizations.localeOf(context).languageCode;
    if (_languageCode != language) {
      _languageCode = language;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CultureGuideProvider>().load(
              countryCode: widget.countryCode,
              cityName: widget.cityName,
              languageCode: language,
            );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CultureGuideProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.cityName} • ${context.l10n.text('cultureGuide')}'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(child: Text(AppErrorPresenter.message(context, state.errorMessage)))
              : state.guide == null || state.guide!.isEmpty
                  ? Center(child: Text(context.l10n.text('noCultureGuide')))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                      children: [
                        CultureGuideSection(guide: state.guide!),
                      ],
                    ),
    );
  }
}
