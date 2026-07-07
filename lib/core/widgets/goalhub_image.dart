import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goalhub/core/network/image_repository.dart';
import 'package:shimmer/shimmer.dart';

class GoalHubImage extends StatefulWidget {
  final String? imageUrl; // Optional, if provided and not ESPN, will be used
  final String? name;
  final ImageType? type;
  final String? secondaryName; // e.g., Team name for player
  final String? tertiaryName;  // e.g., Nationality for player
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final bool useShimmer;
  final int? memCacheHeight;
  final int? memCacheWidth;

  const GoalHubImage({
    super.key,
    this.imageUrl,
    this.name,
    this.type,
    this.secondaryName,
    this.tertiaryName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.useShimmer = true,
    this.memCacheHeight,
    this.memCacheWidth,
  });

  @override
  State<GoalHubImage> createState() => _GoalHubImageState();
}

class _GoalHubImageState extends State<GoalHubImage> {
  String? _resolvedUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(GoalHubImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.name != widget.name ||
        oldWidget.type != widget.type) {
      _resolveImage();
    }
  }

  Future<void> _resolveImage() async {
    // 1. Check if provided URL is ESPN. If so, ignore it.
    String? url = widget.imageUrl;
    if (url != null && (url.contains('espncdn.com') || url.contains('espn.com'))) {
      url = null;
    }

    // 2. If we have a non-ESPN URL, use it.
    if (url != null && url.isNotEmpty) {
      if (mounted) setState(() => _resolvedUrl = url);
      return;
    }

    // 3. If we have metadata, use ImageRepository
    if (widget.name != null && widget.type != null) {
      if (mounted) setState(() => _isLoading = true);
      
      final repo = context.read<ImageRepository>();
      String? result;

      switch (widget.type!) {
        case ImageType.player:
          result = await repo.getPlayerImage(
            widget.name!,
            team: widget.secondaryName,
            nationality: widget.tertiaryName,
          );
          break;
        case ImageType.team:
          result = await repo.getTeamLogo(
            widget.name!,
            league: widget.secondaryName,
            country: widget.tertiaryName,
          );
          break;
        case ImageType.league:
          result = await repo.getLeagueLogo(widget.name!);
          break;
      }

      if (mounted) {
        setState(() {
          _resolvedUrl = result;
          _isLoading = false;
        });
      }
    } else {
       if (mounted) setState(() => _resolvedUrl = url);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder(context);
    }

    if (_resolvedUrl == null || _resolvedUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    return CachedNetworkImage(
      imageUrl: _resolvedUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      memCacheHeight: widget.memCacheHeight,
      memCacheWidth: widget.memCacheWidth,
      placeholder: widget.useShimmer
          ? (context, url) => _buildShimmer(context)
          : null,
      errorWidget: (context, url, error) => widget.errorWidget ?? _buildPlaceholder(context),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    IconData icon;
    switch (widget.type) {
      case ImageType.player:
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.surfaceContainerHighest,
          ),
          child: Icon(
            Icons.person,
            color: colorScheme.onSurfaceVariant.withAlpha(128),
            size: (widget.width != null && widget.width! < 40) ? 20 : 40,
          ),
        );
      case ImageType.team:
        icon = Icons.shield;
        break;
      case ImageType.league:
        icon = Icons.emoji_events; // Trophy
        break;
      default:
        icon = Icons.sports_soccer;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          icon,
          color: colorScheme.onSurfaceVariant.withAlpha(128),
          size: (widget.width != null && widget.width! < 40) ? 20 : 40,
        ),
      ),
    );
  }
}
