import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/journey.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/buttons.dart';
import 'ar_overlay_painter.dart';
import 'nav_controller.dart';

/// S7 / S4 — AR-only live navigation. Full camera feed with sensor-fused
/// path chevrons, turn cards and destination bearing. No 2D fallback: if AR
/// is unsupported or camera permission is denied, a clear prompt is shown.
class ARNavigationScreen extends StatefulWidget {
  const ARNavigationScreen({super.key, required this.journey});
  final Journey journey;
  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

enum _ArStatus { checking, ready, denied, unsupported }

class _ARNavigationScreenState extends State<ARNavigationScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _camera;
  late final NavController _nav;
  late final AnimationController _pulse;
  _ArStatus _status = _ArStatus.checking;
  bool _audioOn = true;

  @override
  void initState() {
    super.initState();
    _nav = NavController(widget.journey);
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _init();
  }

  Future<void> _init() async {
    // 1. Camera permission — hard requirement for AR.
    final perm = await Permission.camera.request();
    if (!perm.isGranted) {
      setState(() => _status = _ArStatus.denied);
      return;
    }
    // 2. A rear camera must exist (AR is unsupported otherwise).
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _status = _ArStatus.unsupported);
        return;
      }
      final rear = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final controller = CameraController(rear, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) return;
      _camera = controller;
      await _nav.start();
      setState(() => _status = _ArStatus.ready);
    } catch (_) {
      setState(() => _status = _ArStatus.unsupported);
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _pulse.dispose();
    _nav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (_status) {
        _ArStatus.checking => const _CheckingView(),
        _ArStatus.denied => _PermissionView(
            title: 'Camera access needed',
            message:
                'AR navigation shows directions over your camera view. Enable camera access to continue — there is no map-only mode.',
            actionLabel: 'Open Settings',
            onAction: openAppSettings,
            onExit: () => context.pop(),
          ),
        _ArStatus.unsupported => _PermissionView(
            title: 'AR not supported',
            message:
                'This device has no compatible rear camera for AR navigation. Try on a device with ARKit (iOS) or ARCore (Android).',
            actionLabel: 'Go back',
            onAction: () => context.pop(),
            onExit: () => context.pop(),
          ),
        _ArStatus.ready => _buildAr(context),
      },
    );
  }

  /// Full-bleed camera preview that covers the screen without distortion.
  Widget _cameraLayer(BuildContext context) {
    final cam = _camera;
    if (cam == null || !cam.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    final media = MediaQuery.of(context).size;
    var scale = media.aspectRatio * cam.value.aspectRatio;
    if (scale < 1) scale = 1 / scale;
    return ClipRect(
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.center,
        child: Center(child: CameraPreview(cam)),
      ),
    );
  }

  Widget _buildAr(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_nav, _pulse]),
      builder: (context, _) {
        final next = _nav.next;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed camera feed
            _cameraLayer(context),

            // Depth scrim: darken top & bottom so overlays read clearly and the
            // scene gains a sense of horizon depth.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x00000000), Color(0x00000000), Color(0x59000000)],
                  stops: [0.0, 0.28, 0.68, 1.0],
                ),
              ),
            ),

            // AR path chevrons
            CustomPaint(
              painter: ARPathPainter(
                relativeAngle: _nav.relativeAngle,
                turn: next?.turn ?? 'STRAIGHT',
                pulse: _pulse.value,
              ),
            ),

            // Destination bearing marker floating near the horizon
            Positioned(
              top: MediaQuery.of(context).size.height * 0.42,
              left: 0,
              right: 0,
              child: Center(
                child: DestinationBearingBadge(
                  relativeAngle: _nav.relativeAngle,
                  label: _nav.remainingMeters >= 1000
                      ? '${(_nav.remainingMeters / 1000).toStringAsFixed(1)} km'
                      : '${_nav.remainingMeters.round()} m',
                ),
              ),
            ),

            _TopBanner(
              turnText: _nav.arrived ? 'Arrived' : (next?.instruction ?? 'Continue'),
              subtitle: next?.legLabel ?? '',
              distance: _nav.arrived ? '' : '${_nav.distanceToNext.round()} m',
              remainingMin: _nav.remainingMinutes,
              eta: _nav.eta,
              audioOn: _audioOn,
              onAudio: () => setState(() => _audioOn = !_audioOn),
              onExit: () => context.pop(),
            ),

            // Floating right controls (report + recenter)
            Positioned(
              right: 16,
              top: MediaQuery.of(context).size.height * 0.32,
              child: Column(
                children: [
                  CircleIconButton(
                    icon: Icons.report_problem_rounded,
                    iconColor: AppColors.amber,
                    onPressed: () => _report(context),
                  ),
                  const SizedBox(height: 12),
                  CircleIconButton(
                    icon: Icons.gps_fixed_rounded,
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            _BottomCard(nav: _nav),
          ],
        );
      },
    );
  }

  void _report(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Thanks — issue reported for this location.'),
      backgroundColor: AppColors.navy,
    ));
  }
}

class _TopBanner extends StatelessWidget {
  const _TopBanner({
    required this.turnText,
    required this.subtitle,
    required this.distance,
    required this.remainingMin,
    required this.eta,
    required this.audioOn,
    required this.onAudio,
    required this.onExit,
  });
  final String turnText, subtitle, distance;
  final int remainingMin;
  final DateTime? eta;
  final bool audioOn;
  final VoidCallback onAudio, onExit;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(18, top + 10, 18, 18),
        decoration: const BoxDecoration(
          color: AppColors.navy,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Color(0x59173B6E), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // remaining time + arrival pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14), borderRadius: AppRadius.pill),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('$remainingMin min',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF9FBBDF), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(eta == null ? '' : '${DateFormat('HH:mm').format(eta!)} arrival',
                        style: const TextStyle(color: Color(0xFFB7CBE6), fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const Spacer(),
                _round(audioOn ? Icons.volume_up_rounded : Icons.volume_off_rounded, onAudio),
                const SizedBox(width: 10),
                _round(Icons.close_rounded, onExit),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(_turnIcon(turnText), color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(turnText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFB7CBE6), fontSize: 15)),
                    ],
                  ),
                ),
                if (distance.isNotEmpty)
                  Text(distance,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: -0.3, duration: 350.ms, curve: Curves.easeOut);
  }

  Widget _round(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );

  IconData _turnIcon(String t) {
    final s = t.toLowerCase();
    if (s.contains('right')) return Icons.turn_right_rounded;
    if (s.contains('left')) return Icons.turn_left_rounded;
    if (s.contains('arriv')) return Icons.flag_rounded;
    return Icons.straight_rounded;
  }
}

class _BottomCard extends StatelessWidget {
  const _BottomCard({required this.nav});
  final NavController nav;
  @override
  Widget build(BuildContext context) {
    final next = nav.next;
    final speed = nav.remainingMinutes == 0 ? 0 : (nav.remainingMeters / 1000);
    return Positioned(
      left: 16,
      right: 16,
      bottom: 28,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.float,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: AppColors.blueTint, borderRadius: BorderRadius.circular(16)),
              child: Icon(next?.legMode.icon ?? Icons.directions_walk_rounded,
                  color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(
                        text: '${nav.remainingMinutes} ',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textStrong)),
                    const TextSpan(
                        text: 'min',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  ])),
                  Text('${speed.toStringAsFixed(2)} km · ${next?.legLabel ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            GoButton(
              size: 46,
              label: '',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckingView extends StatelessWidget {
  const _CheckingView();
  @override
  Widget build(BuildContext context) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Starting AR navigation…', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _PermissionView extends StatelessWidget {
  const _PermissionView({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.onExit,
  });
  final String title, message, actionLabel;
  final VoidCallback onAction, onExit;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.16), shape: BoxShape.circle),
                  child: const Icon(Icons.view_in_ar_rounded, color: AppColors.darkPrimary, size: 38),
                ),
                const SizedBox(height: 20),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Text(message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 26),
                PrimaryButton(label: actionLabel, onPressed: onAction, expand: false),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8,
          right: 12,
          child: IconButton(onPressed: onExit, icon: const Icon(Icons.close_rounded, color: Colors.white)),
        ),
      ],
    );
  }
}
