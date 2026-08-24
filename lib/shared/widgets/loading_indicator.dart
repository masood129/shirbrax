import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shirbrax/app/theme/app_colors.dart';

/// Full-screen centered loading indicator
class LoadingIndicator extends StatelessWidget {
  final String? message;
  const LoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.mutedForeground)),
          ],
        ],
      ),
    );
  }
}

/// Shimmer card placeholder for feed loading
class ShimmerCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 200,
    this.width,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D1520) : const Color(0xFFFFE4E8),
      highlightColor:
          isDark ? const Color(0xFF4A2030) : const Color(0xFFFFF1F2),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Shimmer feed list skeleton
class FeedShimmer extends StatelessWidget {
  const FeedShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const ShimmerCard(height: 40, width: 40, borderRadius: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerCard(height: 14, width: 120, borderRadius: 6),
                  SizedBox(height: 4),
                  ShimmerCard(height: 10, width: 80, borderRadius: 6),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Media area
          const ShimmerCard(height: 240),
          const SizedBox(height: 10),
          // Actions row
          const ShimmerCard(height: 36, borderRadius: 8),
        ],
      ),
    );
  }
}
