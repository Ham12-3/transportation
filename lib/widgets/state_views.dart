import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'buttons.dart';

/// Loading placeholder — a centred blue spinner.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});
  final String? label;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary)),
            if (label != null) ...[
              const SizedBox(height: 14),
              Text(label!, style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600)),
            ]
          ],
        ),
      );
}

/// Generic empty / error / permission state with an icon, message and action.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.tint = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color tint;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: tint.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(icon, color: tint, size: 30),
              ),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, height: 1.4)),
              ],
              if (actionLabel != null) ...[
                const SizedBox(height: 20),
                PrimaryButton(label: actionLabel!, onPressed: onAction, expand: false),
              ],
            ],
          ),
        ),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.message, this.onRetry});
  final String? message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => MessageView(
        icon: Icons.wifi_off_rounded,
        title: 'Something went wrong',
        message: message ?? 'Check your connection and try again.',
        actionLabel: onRetry == null ? null : 'Retry',
        onAction: onRetry,
        tint: AppColors.red,
      );
}
