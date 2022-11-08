part of flutter_svg_image;

class CachedNetworkSvgSource extends ScalableImageSource {
  final String url;
  final Color? currentColor;
  final bool compact;
  final bool bigFloats;
  @override
  final void Function(String)? warnF;

  /// Set headers for the image provider, for example for authentication
  final Map<String, String>? headers;

  /// CacheManager from which the image files are loaded.
  final BaseCacheManager? cacheManager;

  /// Cache key of the image to cache
  final String? cacheKey;

  CachedNetworkSvgSource(
    this.url, {
    this.currentColor,
    this.compact = false,
    this.bigFloats = false,
    this.warnF,
    this.headers,
    this.cacheManager,
    this.cacheKey,
  });

  BaseCacheManager get _cacheManager => cacheManager ?? DefaultCacheManager();

  @override
  Future<ScalableImage> get si => createSI();

  @override
  Future<ScalableImage> createSI() async {
    final file = await _cacheManager.getSingleFile(
      url,
      headers: headers ?? {},
      key: cacheKey ?? url,
    );
    return ScalableImage.fromSvgString(
      await file.readAsString(),
      compact: compact,
      bigFloats: bigFloats,
      warnF: warnF,
      currentColor: currentColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is CachedNetworkSvgSource) {
      return url == other.url &&
          currentColor == other.currentColor &&
          compact == other.compact &&
          bigFloats == other.bigFloats &&
          warnF == other.warnF &&
          headers == other.headers &&
          cacheManager == other.cacheManager &&
          cacheKey == other.cacheKey;
    } else {
      return false;
    }
  }

  @override
  int get hashCode =>
      url.hashCode ^
      currentColor.hashCode ^
      compact.hashCode ^
      bigFloats.hashCode ^
      warnF.hashCode ^
      headers.hashCode ^
      cacheManager.hashCode ^
      cacheKey.hashCode;
}
