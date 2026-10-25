import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/constants.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/language_selector_widget.dart';
import '../../../l10n/app_localizations.dart';

/// Full-screen blocking screen shown when installed app version is below minAppVersion.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  Future<void> _launchUpdateUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        final fallbackLaunched = await launchUrl(uri, mode: LaunchMode.platformDefault);
        if (!fallbackLaunched && context.mounted) {
          _showCopyFallback(context, url);
        }
      }
    } catch (_) {
      if (context.mounted) {
        _showCopyFallback(context, url);
      }
    }
  }

  void _showCopyFallback(BuildContext context, String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Update link copied: $url'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final configState = ref.watch(appConfigNotifierProvider);
    final minVersion =
        configState.value?.config.minAppVersion.version ?? '1.0.0';
    final downloadUrl = configState.value?.config.minAppVersion.downloadUrl ??
        'https://keraspare.et/download';

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: LanguageSegmentedSwitch(),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.system_update_rounded,
                        size: 52,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.updateRequiredTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.updateRequiredMessage(minVersion),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  ElevatedButton.icon(
                    onPressed: () => _launchUpdateUrl(context, downloadUrl),
                    icon: const Icon(Icons.download_rounded),
                    label: Text(l10n.updateNow),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(
                        double.infinity,
                        AppConstants.standardButtonHeight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
