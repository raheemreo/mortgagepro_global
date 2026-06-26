// lib/shared/widgets/live_rate_banner.dart
// Reusable live rate strip banner used across all USA screens.
// Shows real-time FRED/Alpha Vantage/Census data with live badge.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/usa_api_service.dart';
import '../../app/theme/text_styles.dart';

/// A single cell inside the rate strip banner
class LiveRateCell extends StatelessWidget {
  final String label;
  final AsyncValue<LiveRate> rateAsync;
  final double fallback;
  final String? suffix;
  final bool isGold;
  final bool isDollar;

  const LiveRateCell({
    super.key,
    required this.label,
    required this.rateAsync,
    this.fallback = 0,
    this.suffix = '%',
    this.isGold = false,
    this.isDollar = false,
  });

  @override
  Widget build(BuildContext context) {
    return rateAsync.when(
      loading: () => _RateCellContent(
        label: label,
        value: '...',
        note: 'loading',
        isGold: isGold,
        isLive: false,
        isDollar: isDollar,
        suffix: suffix,
      ),
      error: (_, __) => _RateCellContent(
        label: label,
        value: isDollar
            ? '\$${(fallback / 1000).toStringAsFixed(0)}K'
            : '${fallback.toStringAsFixed(2)}${suffix ?? '%'}',
        note: 'est.',
        isGold: isGold,
        isLive: false,
        isDollar: isDollar,
        suffix: suffix,
      ),
      data: (rate) => _RateCellContent(
        label: label,
        value: isDollar
            ? '\$${(rate.value / 1000).toStringAsFixed(0)}K'
            : '${rate.value.toStringAsFixed(2)}${suffix ?? '%'}',
        note: rate.isLive ? 'LIVE · ${rate.source}' : 'est. · ${rate.source}',
        isGold: isGold,
        isLive: rate.isLive,
        isDollar: isDollar,
        suffix: suffix,
      ),
    );
  }
}

class _RateCellContent extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final bool isGold;
  final bool isLive;
  final bool isDollar;
  final String? suffix;

  const _RateCellContent({
    required this.label,
    required this.value,
    required this.note,
    required this.isGold,
    required this.isLive,
    required this.isDollar,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(
            size: 7.5,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isLive)
              Container(
                width: 5,
                height: 5,
                margin: const EdgeInsets.only(right: 3),
                decoration: const BoxDecoration(
                  color: Color(0xFF4ADE80),
                  shape: BoxShape.circle,
                ),
              ),
            Flexible(
              child: Text(
                value,
                style: AppTextStyles.playfair(
                  size: 13.5,
                  color: isGold ? const Color(0xFFFCD34D) : Colors.white,
                  weight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Text(
          note,
          style: AppTextStyles.dmSans(
            size: 6.5,
            color: Colors.white.withValues(alpha: 0.40),
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Full-width dark rate strip banner (dark navy gradient)
/// Used in Mortgage, Refinance, ARM, PITI screens
class DarkRateStripBanner extends ConsumerWidget {
  final List<RateStripItem> items;

  const DarkRateStripBanner({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1D3A), Color(0xFF1B3F72)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: items.map((item) {
          final isLast = items.last == item;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: LiveRateCell(
                    label: item.label,
                    rateAsync: ref.watch(item.provider),
                    fallback: item.fallback,
                    suffix: item.suffix,
                    isGold: item.isGold,
                    isDollar: item.isDollar,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 1,
                    height: 24,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Light card rate strip (for Affordability, FHA, VA etc.)
class LightRateStripBanner extends ConsumerWidget {
  final List<RateStripItem> items;

  const LightRateStripBanner({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F4FF),
        border: Border.all(
            color: isDark ? Colors.white10 : const Color(0x1B1B3F72)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: _LightRateCell(
              label: item.label,
              rateAsync: ref.watch(item.provider),
              fallback: item.fallback,
              suffix: item.suffix,
              isGold: item.isGold,
              isDollar: item.isDollar,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _LightRateCell extends StatelessWidget {
  final String label;
  final AsyncValue<LiveRate> rateAsync;
  final double fallback;
  final String? suffix;
  final bool isGold;
  final bool isDollar;

  const _LightRateCell({
    required this.label,
    required this.rateAsync,
    this.fallback = 0,
    this.suffix = '%',
    this.isGold = false,
    this.isDollar = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0B1D3A);
    final mutedColor = isDark ? Colors.white54 : const Color(0xFF5B6E8F);

    return rateAsync.when(
      loading: () => _buildCell('...', 'loading', textColor, mutedColor),
      error: (_, __) => _buildCell(
        isDollar
            ? '\$${(fallback / 1000).toStringAsFixed(0)}K'
            : '${fallback.toStringAsFixed(2)}${suffix ?? '%'}',
        'est.',
        textColor,
        mutedColor,
      ),
      data: (rate) => _buildCell(
        isDollar
            ? '\$${(rate.value / 1000).toStringAsFixed(0)}K'
            : '${rate.value.toStringAsFixed(2)}${suffix ?? '%'}',
        rate.isLive ? '🟢 LIVE' : 'est.',
        isGold ? const Color(0xFFD97706) : textColor,
        mutedColor,
      ),
    );
  }

  Widget _buildCell(
      String value, String note, Color textColor, Color mutedColor) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.dmSans(size: 8.5, color: mutedColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.playfair(
            size: 13.5,
            color: textColor,
            weight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 1),
        Text(
          note,
          style: AppTextStyles.dmSans(size: 7, color: mutedColor),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Rate Strip Item Definition ───────────────────────────────────────────────
class RateStripItem {
  final String label;
  final ProviderBase<AsyncValue<LiveRate>> provider;
  final double fallback;
  final String? suffix;
  final bool isGold;
  final bool isDollar;

  const RateStripItem({
    required this.label,
    required this.provider,
    this.fallback = 6.82,
    this.suffix = '%',
    this.isGold = false,
    this.isDollar = false,
  });
}

// ─── Compact live badge chip (for investment screens) ───────────────────────
class LiveValueChip extends ConsumerWidget {
  final String label;
  final ProviderBase<AsyncValue<LiveRate>> provider;
  final double fallback;
  final bool isDollar;
  final String? suffix;
  final Color accentColor;

  const LiveValueChip({
    super.key,
    required this.label,
    required this.provider,
    this.fallback = 0,
    this.isDollar = false,
    this.suffix,
    this.accentColor = const Color(0xFF0F766E),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rateAsync = ref.watch(provider);

    return rateAsync.when(
      loading: () => _chip('...', false, isDark),
      error: (_, __) => _chip(_fallbackText(), false, isDark),
      data: (rate) => _chip(
        isDollar
            ? '\$${rate.value.toStringAsFixed(0)}'
            : '${rate.value.toStringAsFixed(2)}${suffix ?? ''}',
        rate.isLive,
        isDark,
      ),
    );
  }

  String _fallbackText() {
    if (isDollar) return '\$${fallback.toStringAsFixed(0)}';
    return '${fallback.toStringAsFixed(2)}${suffix ?? ''}';
  }

  Widget _chip(String value, bool isLive, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLive)
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            label,
            style: AppTextStyles.dmSans(
              size: 9,
              color: accentColor,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: AppTextStyles.playfair(
              size: 12,
              color: accentColor,
              weight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
