part of flutter_svg_image;

/// SVG [ImageProvider].
/// Use jovial_svg to convert SVG to image.
class SvgImage extends ImageProvider<SvgImageKey> {
  ///
  /// A default cache.  By default, this cache holds zero unreferenced
  /// image sources.
  ///
  /// This isn't exposed.  On balance, the extremely slight chance of slightly
  /// more convenient instance-sharing isn't worth the slight chance that
  /// someone might think it's OK to change the size to something bigger
  /// than zero, and thereby potentially cause other modules to consume
  /// memory with large, retained assets.
  ///
  static final _defaultCache = ScalableImageCache(size: 0);

  /// An asynchronous source of a [ScalableImage].
  final ScalableImageSource source;

  /// Canvas height. Use [ScalableImage.viewport] if not set.
  /// Always keep the aspect ratio of [ScalableImage.viewport].
  final double? height;

  /// Canvas width. Use [ScalableImage.viewport] if not set.
  /// Always keep the aspect ratio of [ScalableImage.viewport].
  final double? width;

  /// Image scale.
  final double? scale;

  /// Image background color.
  final Color? backgroundColor;

  /// An LRU cache of [ScalableImage] futures derived from [ScalableImageSource]
  /// instances.
  final ScalableImageCache cache;

  SvgImage({
    required this.source,
    this.height,
    this.width,
    this.scale,
    this.backgroundColor,
    ScalableImageCache? cache,
    bool reload = false,
  }) : cache = cache ?? _defaultCache {
    if (reload) {
      this.cache.forceReload(source);
    }
  }

  factory SvgImage.asset(
    String name, {
    AssetBundle? bundle,
    double? height,
    double? width,
    double? scale,
    Color? backgroundColor,
    ScalableImageCache? cache,
    bool reload = false,
    bool compact = false,
    bool bigFloats = false,
    Color? currentColor,
    void Function(String)? warnF,
  }) {
    return SvgImage(
      source: ScalableImageSource.fromSvg(
        bundle ?? rootBundle,
        name,
        compact: compact,
        bigFloats: bigFloats,
        currentColor: currentColor,
        warnF: warnF,
      ),
      height: height,
      width: width,
      scale: scale,
      backgroundColor: backgroundColor,
      cache: cache,
      reload: reload,
    );
  }

  factory SvgImage.network(
    String url, {
    double? height,
    double? width,
    double? scale,
    Color? backgroundColor,
    ScalableImageCache? cache,
    bool reload = false,
    bool compact = false,
    bool bigFloats = false,
    Color? currentColor,
    void Function(String)? warnF,
  }) {
    return SvgImage(
      source: ScalableImageSource.fromSvgHttpUrl(
        Uri.parse(url),
        compact: compact,
        bigFloats: bigFloats,
        currentColor: currentColor,
        warnF: warnF,
      ),
      height: height,
      width: width,
      scale: scale,
      backgroundColor: backgroundColor,
      cache: cache,
      reload: reload,
    );
  }

  factory SvgImage.cachedNetwork(
    String url, {
    double? height,
    double? width,
    double? scale,
    Color? backgroundColor,
    ScalableImageCache? cache,
    bool reload = false,
    bool compact = false,
    bool bigFloats = false,
    Color? currentColor,
    void Function(String)? warnF,
    Map<String, String>? headers,
    BaseCacheManager? cacheManager,
    String? cacheKey,
  }) {
    return SvgImage(
      source: CachedNetworkSvgSource(
        url,
        compact: compact,
        bigFloats: bigFloats,
        currentColor: currentColor,
        warnF: warnF,
        headers: headers,
        cacheManager: cacheManager,
        cacheKey: cacheKey,
      ),
      height: height,
      width: width,
      scale: scale,
      backgroundColor: backgroundColor,
      cache: cache,
      reload: reload,
    );
  }

  @override
  Future<SvgImageKey> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<SvgImageKey>(SvgImageKey(
      source: source,
      height: height ?? configuration.size?.height,
      width: width ?? configuration.size?.width,
      scale: scale,
      backgroundColor: backgroundColor,
    ));
  }

  @override
  ImageStreamCompleter loadBuffer(
      SvgImageKey key, DecoderBufferCallback decode) {
    return OneFrameImageStreamCompleter(_loadAsync(key));
  }

  Future<ImageInfo> _loadAsync(SvgImageKey key) async {
    final si = await cache.addReference(source);
    final viewport = si.viewport;
    double sx = scale ?? 1;
    double? sy;
    if (key.height != null && key.width == null) {
      sx *= (key.height! / viewport.height);
    } else if (key.height == null && key.width != null) {
      sx *= (key.width! / viewport.width);
    } else if (key.height != null && key.width != null) {
      sy = sx * (key.height! / viewport.height);
      sx *= (key.width! / viewport.width);
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, viewport);
    if (backgroundColor != null) {
      canvas.drawColor(backgroundColor!, BlendMode.src);
    }
    canvas.scale(sx, sy);
    si.paint(canvas);
    final ui.Image image = await recorder.endRecording().toImage(
          (viewport.width * sx).round(),
          (viewport.height * (sy ?? sx)).round(),
        );

    return ImageInfo(
      image: image,
      scale: sy != null ? (sy > sx ? sy : sx) : sx,
    );
  }
}

@immutable
class SvgImageKey {
  final ScalableImageSource source;
  final double? height;
  final double? width;
  final Color? backgroundColor;
  final double? scale;

  const SvgImageKey({
    required this.source,
    this.height,
    this.width,
    this.backgroundColor,
    this.scale,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SvgImageKey &&
          runtimeType == other.runtimeType &&
          source == other.source &&
          height == other.height &&
          width == other.width &&
          backgroundColor == other.backgroundColor &&
          scale == other.scale;

  @override
  int get hashCode =>
      source.hashCode ^
      height.hashCode ^
      width.hashCode ^
      backgroundColor.hashCode ^
      scale.hashCode;
}
