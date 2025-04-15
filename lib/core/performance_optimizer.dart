import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart' show compute;

/// Utility class for optimizing app performance
class PerformanceOptimizer {
  /// Schedules a task to run after the current frame is rendered
  /// This helps avoid blocking the main thread during UI rendering
  static void runAfterFrame(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      callback();
    });
  }

  /// Runs a computation-heavy task on a separate isolate
  /// This can be used for data processing operations that would otherwise block the UI
  static Future<T> computeAsync<T, P>(
    Future<T> Function(P message) callback,
    P message,
  ) async {
    return await compute(callback, message);
  }

  /// Creates an optimized ListView that only builds visible items
  /// Use this for long lists to improve performance
  static Widget buildOptimizedList<T>({
    required List<T> items,
    required Widget Function(BuildContext, int) itemBuilder,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsetsGeometry? padding,
    ScrollController? controller,
  }) {
    return ListView.builder(
      itemCount: items.length,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      controller: controller,
      // Use cacheExtent to optimize for scroll performance
      cacheExtent: 500,
      itemBuilder: itemBuilder,
    );
  }

  /// Wraps a widget with optimizations for heavy UI operations
  static Widget optimizedBuilder({
    required Widget Function(BuildContext) builder,
  }) {
    return Builder(
      builder: (context) {
        // Use RepaintBoundary to isolate repaint operations
        return RepaintBoundary(
          child: builder(context),
        );
      },
    );
  }
}
