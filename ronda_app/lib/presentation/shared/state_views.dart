import 'package:flutter/material.dart';
import 'package:ronda_app/core/errors/app_failure.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';

/// Actionable loading state with explicit operational context (never a bare spinner).
class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, required this.message, this.detail});

  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      label: message,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CivicTokens.spaceSection),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: tokens.brandPrimary,
                  ),
                ),
                const SizedBox(height: CivicTokens.spaceLg),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
                if (detail != null && detail!.trim().isNotEmpty) ...[
                  const SizedBox(height: CivicTokens.spaceSm),
                  Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Actionable empty state that explains why a view is empty and offers one clear next action.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;
    final hasAction =
        actionLabel != null && actionLabel!.trim().isNotEmpty && onAction != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(CivicTokens.spaceSection),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(CivicTokens.radiusCard),
              border: Border.all(color: tokens.borderHairline, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(CivicTokens.spaceXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tokens.surfaceSubtle,
                      borderRadius: BorderRadius.circular(
                        CivicTokens.radiusControl,
                      ),
                      border: Border.all(
                        color: tokens.borderHairline,
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 24, color: tokens.brandPrimary),
                  ),
                  const SizedBox(height: CivicTokens.spaceLg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: CivicTokens.spaceSm),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
                  ),
                  if (hasAction) ...[
                    const SizedBox(height: CivicTokens.spaceXl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onAction,
                        child: Text(actionLabel!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Actionable error state with plain Indonesian cause and optional retry callback.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    this.title = 'Gagal memuat data',
    required this.message,
    this.errorCode,
    this.retryLabel = 'Coba Lagi',
    this.onRetry,
  });

  factory ErrorStateView.fromFailure(
    AppFailure failure, {
    Key? key,
    String title = 'Gagal memuat data',
    String retryLabel = 'Coba Lagi',
    VoidCallback? onRetry,
  }) {
    return ErrorStateView(
      key: key,
      title: title,
      message: failure.message,
      errorCode: failure.code,
      retryLabel: retryLabel,
      onRetry: onRetry,
    );
  }

  final String title;
  final String message;
  final String? errorCode;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CivicTokens.spaceSection),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(CivicTokens.radiusCard),
                border: Border.all(
                  color: tokens.statusEmergencyText.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(CivicTokens.spaceXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: tokens.statusEmergencyTint,
                        borderRadius: BorderRadius.circular(
                          CivicTokens.radiusControl,
                        ),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 24,
                        color: tokens.statusEmergencyText,
                      ),
                    ),
                    const SizedBox(height: CivicTokens.spaceLg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: CivicTokens.spaceSm),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    if (errorCode != null && errorCode!.trim().isNotEmpty) ...[
                      const SizedBox(height: CivicTokens.spaceMd),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.surfaceSubtle,
                          borderRadius: BorderRadius.circular(
                            CivicTokens.radiusChip,
                          ),
                          border: Border.all(
                            color: tokens.borderHairline,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: CivicTokens.spaceSm,
                            vertical: CivicTokens.spaceXs,
                          ),
                          child: Text(
                            'KODE: $errorCode',
                            style: tokens.forensicMono.copyWith(
                              color: tokens.inkSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (onRetry != null) ...[
                      const SizedBox(height: CivicTokens.spaceXl),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onRetry,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(retryLabel),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
