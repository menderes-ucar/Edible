import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/support_config.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/support_mail.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/suggestions_service.dart';

/// "Report a problem with this listing": a documented way for visitors and
/// business owners to ask for a correction or removal. Signed-out users (such as
/// business owners without an account) can still write by e-mail when a support
/// address is configured.
Future<void> showReportIssueSheet(
  BuildContext context, {
  required String contentId,
  required String contentTitle,
}) async {
  final l10n = context.l10n;
  final reasons = <ReportReason, String>{
    ReportReason.wrongInfo: l10n.text('reportReasonWrongInfo'),
    ReportReason.closed: l10n.text('reportReasonClosed'),
    ReportReason.ownerRequest: l10n.text('reportReasonOwner'),
    ReportReason.inappropriate: l10n.text('reportReasonInappropriate'),
    ReportReason.other: l10n.text('reportReasonOther'),
  };
  final hasEmail = SupportConfig.email != null;

  const emailChoice = '__email__';
  final picked = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                sheetContext.l10n.text('reportIssueTitle'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
            for (final entry in reasons.entries)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(entry.value),
                onTap: () => Navigator.of(sheetContext).pop(entry.key),
              ),
            if (hasEmail)
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded),
                title: Text(sheetContext.l10n.text('reportIssueEmail')),
                onTap: () => Navigator.of(sheetContext).pop(emailChoice),
              ),
          ],
        ),
      ),
    ),
  );
  if (picked == null || !context.mounted) return;

  if (picked == emailChoice) {
    await openSupportEmail(context, subject: '$contentTitle ($contentId)');
    return;
  }
  final reason = picked as ReportReason;

  if (!context.read<AuthProvider>().isAuthenticated) {
    if (hasEmail) {
      await openSupportEmail(context, subject: '$contentTitle ($contentId)');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.text('loginToReport'))),
      );
      context.push('/login');
    }
    return;
  }

  final controller = TextEditingController();
  final send = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.l10n.text('reportIssue')),
      content: TextField(
        controller: controller,
        maxLength: 1000,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: dialogContext.l10n.text('reportIssueDetails'),
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(dialogContext.l10n.text('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(dialogContext.l10n.text('reportIssueSend')),
        ),
      ],
    ),
  );
  final details = controller.text.trim();
  controller.dispose();
  if (send != true || !context.mounted) return;

  final result = await const SuggestionsService().reportIssue(
    contentId: contentId,
    contentTitle: contentTitle,
    reason: reason,
    details: details.isEmpty ? null : details,
  );
  if (!context.mounted) return;

  final message = switch (result) {
    ReportIssueResult.ok => context.l10n.text('reportIssueThanks'),
    ReportIssueResult.rateLimited => context.l10n.text('reportIssueRateLimited'),
    ReportIssueResult.invalid || ReportIssueResult.failed => context.l10n.text('referralError'),
  };
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
