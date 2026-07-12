import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'buttons.dart';
import 'roundel.dart';

/// Loading placeholder — a spinning roundel, the app's signature loader.
/// Set [onDark] when placed on the navy sheet so the label stays legible.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label, this.onDark = false});
  final String? label;
  final bool onDark;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RoundelLoader(size: 40, barColor: onDark ? Colors.white : AppColors.roundelBlue),
            if (label != null) ...[
              const SizedBox(height: 16),
              Text(label!,
                  style: TextStyle(
                      color: onDark ? Colors.white70 : AppColors.muted,
                      fontWeight: FontWeight.w600)),
            ]
          ],
        ),
      );
}

/// Generic empty / error / permission state with a mark, message and action.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tint = AppColors.primary,
    this.brandMark = false,
    this.onDark = false,
  });

  final IconData? icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color tint;

  /// Show the roundel as the mark instead of an icon square — for the app's
  /// own empty states (nothing saved, no stops) where the brand should carry it.
  final bool brandMark;

  /// Set when shown on the navy sheet so text stays legible on a dark surface.
  final bool onDark;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (brandMark || icon == null)
                const Roundel(size: 62)
              else
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(icon, color: tint, size: 32),
                ),
              const SizedBox(height: 18),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: onDark ? Colors.white : AppColors.ink)),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: onDark ? Colors.white70 : AppColors.muted,
                        fontWeight: FontWeight.w500,
                        height: 1.45)),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 22),
                PrimaryButton(label: actionLabel!, onPressed: onAction, expand: false),
              ],
            ],
          ),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.message, this.onRetry, this.detail, this.onDark = false});
  final String? message;
  final VoidCallback? onRetry;
  final bool onDark;

  /// Raw exception text. Rendered only in debug builds, below the message, so
  /// the real failure (e.g. a DioException) is visible while developing.
  final Object? detail;

  @override
  Widget build(BuildContext context) {
    final view = MessageView(
      icon: Icons.wifi_off_rounded,
      title: 'Signal lost',
      message: message ?? 'Check your connection and try again.',
      actionLabel: onRetry == null ? null : 'Retry',
      onAction: onRetry,
      tint: AppColors.red,
      onDark: onDark,
    );

    if (!kDebugMode || detail == null) return view;

    // Debug-only: show the actual exception so failures are diagnosable.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: view),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.red.withValues(alpha: 0.25)),
            ),
            child: SelectableText(
              'DEBUG · $detail',
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.4,
                fontFamily: 'monospace',
                color: AppColors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
