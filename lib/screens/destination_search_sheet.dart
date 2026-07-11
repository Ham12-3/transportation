import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/stop_point.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../widgets/state_views.dart';

/// A search sheet for choosing a destination StopPoint (TfL StopPoint/Search).
class DestinationSearchSheet extends ConsumerStatefulWidget {
  const DestinationSearchSheet({super.key});
  @override
  ConsumerState<DestinationSearchSheet> createState() => _DestinationSearchSheetState();
}

class _DestinationSearchSheetState extends ConsumerState<DestinationSearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<StopPoint>>? _results;

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _results = q.trim().length < 2
            ? Future.value(const [])
            : ref.read(tflServiceProvider).searchStops(q);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.sheet,
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const SheetGrabber(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: AppRadius.field, boxShadow: AppShadows.card),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onChanged,
                  decoration: const InputDecoration(
                    hintText: 'Where to? Search stops & places',
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 4),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_results == null) {
      return const MessageView(
        icon: Icons.explore_rounded,
        title: 'Search London',
        message: 'Type a station, stop or place to plan a route.',
      );
    }
    return FutureBuilder<List<StopPoint>>(
      future: _results,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const LoadingView();
        if (snap.hasError) {
          return ErrorView(onRetry: () => _onChanged(_controller.text));
        }
        final stops = snap.data ?? const [];
        if (stops.isEmpty) {
          return const MessageView(
              icon: Icons.search_off_rounded, title: 'No matches', message: 'Try another search.');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: stops.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.hairline),
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.place_rounded, color: AppColors.red),
            title: Text(stops[i].name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            subtitle: stops[i].modes.isEmpty
                ? null
                : Text(stops[i].modes.map((m) => m.label).join(' · '),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            onTap: () => Navigator.of(context).pop(stops[i]),
          ),
        );
      },
    );
  }
}
