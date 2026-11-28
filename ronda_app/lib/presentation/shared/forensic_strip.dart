import 'package:flutter/material.dart';
import 'package:ronda_app/core/theme/civic_tokens.dart';

/// Display mode for [ForensicStrip].
enum ForensicStripLayout { wrap, table }

/// Single labeled forensic reading rendered with tabular monospace alignment.
@immutable
class ForensicEntry {
  const ForensicEntry({
    required this.label,
    required this.value,
    this.icon,
    this.isAlert = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool isAlert;
}

/// Civic Operational forensic data strip for coordinates, timestamps, accuracy, and hashes.
class ForensicStrip extends StatelessWidget {
  const ForensicStrip({
    super.key,
    required this.entries,
    this.layout = ForensicStripLayout.wrap,
    this.title,
  });

  /// Builds a structured strip directly from check-in forensic fields.
  factory ForensicStrip.metadata({
    Key? key,
    required double latitude,
    required double longitude,
    required String timestampLabel,
    String? sha256Hash,
    double? distanceMeters,
    double? accuracyMeters,
    bool? isMocked,
    ForensicStripLayout layout = ForensicStripLayout.wrap,
    String? title,
  }) {
    final items = <ForensicEntry>[
      ForensicEntry(
        label: 'Waktu',
        value: timestampLabel,
        icon: Icons.schedule_outlined,
      ),
      ForensicEntry(
        label: 'Koordinat',
        value: formatCoordinates(latitude, longitude),
        icon: Icons.my_location_outlined,
      ),
      if (distanceMeters != null)
        ForensicEntry(
          label: 'Jarak ke Pos',
          value: '${distanceMeters.toStringAsFixed(1)} m',
          icon: Icons.straighten_outlined,
        ),
      if (accuracyMeters != null)
        ForensicEntry(
          label: 'Akurasi GPS',
          value: '${accuracyMeters.toStringAsFixed(1)} m',
          icon: Icons.gps_fixed_outlined,
          isAlert: accuracyMeters > 35.0,
        ),
      if (isMocked != null)
        ForensicEntry(
          label: 'Deteksi Fake GPS',
          value: isMocked ? 'Terdeteksi Mock' : 'GPS Asli',
          icon: isMocked
              ? Icons.gpp_bad_outlined
              : Icons.verified_outlined,
          isAlert: isMocked,
        ),
      if (sha256Hash != null && sha256Hash.trim().isNotEmpty)
        ForensicEntry(
          label: 'SHA-256',
          value: layout == ForensicStripLayout.wrap
              ? formatHashPreview(sha256Hash)
              : sha256Hash.trim(),
          icon: Icons.fingerprint_outlined,
        ),
    ];

    return ForensicStrip(
      key: key,
      entries: items,
      layout: layout,
      title: title,
    );
  }

  final List<ForensicEntry> entries;
  final ForensicStripLayout layout;
  final String? title;

  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  static String formatHashPreview(String hash) {
    final trimmed = hash.trim();
    if (trimmed.length <= 16) {
      return trimmed;
    }
    return '${trimmed.substring(0, 8)}...${trimmed.substring(trimmed.length - 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(CivicTokens.radiusChip),
        border: Border.all(color: tokens.borderHairline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(CivicTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null && title!.trim().isNotEmpty) ...[
              Text(
                title!,
                style: textTheme.labelMedium?.copyWith(
                  color: tokens.inkPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: CivicTokens.spaceSm),
            ],
            if (layout == ForensicStripLayout.wrap)
              Wrap(
                spacing: CivicTokens.spaceSm,
                runSpacing: CivicTokens.spaceSm,
                children: entries
                    .map((entry) => _ForensicChip(entry: entry))
                    .toList(growable: false),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    _ForensicTableRow(entry: entries[i]),
                    if (i < entries.length - 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: CivicTokens.spaceSm,
                        ),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: tokens.borderHairline,
                        ),
                      ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ForensicChip extends StatelessWidget {
  const _ForensicChip({required this.entry});

  final ForensicEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;
    final bgColor =
        entry.isAlert ? tokens.statusEmergencyTint : tokens.surface;
    final borderColor = entry.isAlert
        ? tokens.statusEmergencyText.withValues(alpha: 0.45)
        : tokens.borderHairline;
    final valueColor =
        entry.isAlert ? tokens.statusEmergencyText : tokens.inkPrimary;
    final labelColor =
        entry.isAlert ? tokens.statusEmergencyText : tokens.inkSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(CivicTokens.radiusChip),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (entry.icon != null) ...[
                  Icon(entry.icon, size: 13, color: labelColor),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    entry.label,
                    style: textTheme.labelSmall?.copyWith(color: labelColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              entry.value,
              softWrap: true,
              style: tokens.forensicMono.copyWith(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForensicTableRow extends StatelessWidget {
  const _ForensicTableRow({required this.entry});

  final ForensicEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.civicTokens;
    final textTheme = Theme.of(context).textTheme;
    final valueColor =
        entry.isAlert ? tokens.statusEmergencyText : tokens.inkPrimary;
    final iconColor =
        entry.isAlert ? tokens.statusEmergencyText : tokens.inkSecondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 300;
        final labelWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.icon != null) ...[
              Icon(entry.icon, size: 15, color: iconColor),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                entry.label,
                style: textTheme.labelSmall?.copyWith(
                  color: tokens.inkSecondary,
                ),
              ),
            ),
          ],
        );

        final valueWidget = Text(
          entry.value,
          softWrap: true,
          textAlign: stackVertically ? TextAlign.start : TextAlign.end,
          style: tokens.forensicMono.copyWith(color: valueColor),
        );

        if (stackVertically) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              labelWidget,
              const SizedBox(height: 4),
              valueWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: labelWidget),
            const SizedBox(width: CivicTokens.spaceMd),
            Expanded(flex: 3, child: valueWidget),
          ],
        );
      },
    );
  }
}
