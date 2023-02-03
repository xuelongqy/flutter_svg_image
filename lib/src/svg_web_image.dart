part of flutter_svg_image;

typedef HandlerCallback = void Function(List arguments);

/// Minimum SVG width.
const _kSvgMinWidth = 400.0;

/// Use WebView to convert SVG to image.
class SvgWebImage extends ImageProvider<SvgWebImageKey> {
  /// Headless WebView.
  /// Convert svg to image using webview,
  static HeadlessInAppWebView? _headlessWebView;
  static InAppWebViewController? _webViewController;
  static const String _handlerName = 'resultSvgImage';
  static const String _handlerErrorName = 'resultSvgError';
  static List<HandlerCallback> _resultListeners = [];
  static List<HandlerCallback> _resultErrorListeners = [];

  /// Task queue.
  static Map<String, _TaskItem> _taskQueue = {};

  /// Add Task.
  static _addTask(_TaskItem task) {
    final isEmpty = _taskQueue.isEmpty;
    _taskQueue[task.key] = task;
    if (isEmpty) {
      runTask();
    }
  }

  /// Run task.
  static runTask() {
    if (_taskQueue.isNotEmpty) {
      _webViewController!.evaluateJavascript(
        source: _taskQueue.entries.first.value.script,
      );
    }
  }

  /// Initialize WebView.
  /// Environment for loading SvgToPng.
  static Future initWebView() async {
    if (_headlessWebView != null) {
      disposeWebView();
    }
    final completer = Completer<bool>();
    _headlessWebView = HeadlessInAppWebView(
      initialData: InAppWebViewInitialData(
          data: await rootBundle.loadString(
              'packages/flutter_svg_image/assets/web/svg2png.html')),
      onWebViewCreated: (controller) {
        _webViewController = controller;
        controller.addJavaScriptHandler(
            handlerName: _handlerName,
            callback: (arguments) {
              final String key = arguments.first;
              _taskQueue.remove(key);
              runTask();
              for (final listener in _resultListeners) {
                listener(arguments);
              }
            });
        controller.addJavaScriptHandler(
            handlerName: _handlerErrorName,
            callback: (arguments) {
              final String key = arguments.first;
              _taskQueue.remove(key);
              runTask();
              for (final listener in _resultErrorListeners) {
                listener(arguments);
              }
            });
        completer.complete(true);
      },
    );
    await _headlessWebView!.run();
    await completer.future;
  }

  /// Release WebView.
  static disposeWebView() {
    _resultListeners.clear();
    _headlessWebView?.dispose();
  }

  /// SVG fetcher.
  final SvgFetcher fetcher;

  /// Canvas height. Use SVG default height if not set.
  final double? height;

  /// Canvas height. Use SVG default height if not set.
  final double? width;

  /// Image background color.
  final Color? backgroundColor;

  /// Image scale.
  final double scale;

  /// Cache SVG.
  final bool cacheSvg;

  /// CacheManager from which the SVG files are loaded.
  final BaseCacheManager? cacheSvgManager;

  /// Minimum width.
  final double minWidth;

  SvgWebImage({
    required this.fetcher,
    this.height,
    this.width,
    this.backgroundColor,
    this.scale = 1.0,
    this.cacheSvg = true,
    this.cacheSvgManager,
    this.minWidth = _kSvgMinWidth,
  }) : assert(_webViewController != null,
            'Please initialize WebView first, use SvgWebImage.initWebView.');

  SvgWebImage.data(
    String data, {
    this.height,
    this.width,
    this.backgroundColor,
    this.scale = 1.0,
    this.minWidth = _kSvgMinWidth,
  })  : assert(_webViewController != null,
            'Please initialize WebView first, use SvgWebImage.initWebView.'),
        this.cacheSvg = false,
        this.cacheSvgManager = null,
        this.fetcher = DataSvgFetcher(
          data: data,
          height: height,
          width: width,
          minWidth: minWidth,
          backgroundColor: backgroundColor,
        );

  SvgWebImage.file(
    File file, {
    this.height,
    this.width,
    this.backgroundColor,
    this.scale = 1.0,
    this.minWidth = _kSvgMinWidth,
  })  : assert(_webViewController != null,
            'Please initialize WebView first, use SvgWebImage.initWebView.'),
        this.cacheSvg = false,
        this.cacheSvgManager = null,
        this.fetcher = FileSvgFetcher(
          file: file,
          height: height,
          width: width,
          minWidth: minWidth,
          backgroundColor: backgroundColor,
        );

  SvgWebImage.asset(
    String name, {
    AssetBundle? bundle,
    this.height,
    this.width,
    this.backgroundColor,
    this.scale = 1.0,
    this.minWidth = _kSvgMinWidth,
  })  : assert(_webViewController != null,
            'Please initialize WebView first, use SvgWebImage.initWebView.'),
        this.cacheSvg = false,
        this.cacheSvgManager = null,
        this.fetcher = AssetSvgFetcher(
          name: name,
          bundle: bundle,
          height: height,
          width: width,
          minWidth: minWidth,
          backgroundColor: backgroundColor,
        );

  SvgWebImage.network(
    String url, {
    this.height,
    this.width,
    this.backgroundColor,
    this.scale = 1.0,
    this.cacheSvg = true,
    this.cacheSvgManager,
    this.minWidth = _kSvgMinWidth,
    Map<String, String>? headers,
  })  : assert(_webViewController != null,
            'Please initialize WebView first, use SvgWebImage.initWebView.'),
        this.fetcher = NetworkSvgFetcher(
          url: url,
          height: height,
          width: width,
          minWidth: minWidth,
          backgroundColor: backgroundColor,
          headers: headers,
        );

  SvgWebImage.cachedNetwork(
    String url, {
    this.height,
    this.width,
    this.backgroundColor,
    this.scale = 1.0,
    this.cacheSvg = true,
    this.cacheSvgManager,
    this.minWidth = _kSvgMinWidth,
    Map<String, String>? headers,
    BaseCacheManager? cacheManager,
    String? cacheKey,
  })  : assert(_webViewController != null,
            'Please initialize WebView first, use SvgWebImage.initWebView.'),
        this.fetcher = CachedNetworkSvgFetcher(
          url: url,
          height: height,
          width: width,
          minWidth: minWidth,
          backgroundColor: backgroundColor,
          headers: headers,
          cacheManager: cacheManager,
          cacheKey: cacheKey,
        );

  BaseCacheManager get _cacheSvgManager =>
      cacheSvgManager ?? DefaultCacheManager();

  @override
  ImageStreamCompleter loadBuffer(
      SvgWebImageKey key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      informationCollector: () {
        if (cacheSvg) {
          fetcher.getKey().then((value) {
            _cacheSvgManager.removeFile(value);
          });
        }
        return <DiagnosticsNode>[
          ErrorDescription('Svg: ${fetcher.getPath()}'),
        ];
      },
    );
  }

  Future<ui.Codec> _loadAsync(
      SvgWebImageKey key, DecoderBufferCallback decode) async {
    final svgKey = await fetcher.getKey();
    Uint8List imageBytes;
    if (cacheSvg) {
      final file = (await _cacheSvgManager.getFileFromCache(svgKey))?.file;
      if (file != null) {
        return _fileDecode(file, key, decode);
      } else {
        imageBytes = await _svgToPng(svgKey);
        final file = (await _cacheSvgManager.getFileFromCache(svgKey))?.file;
        if (file != null) {
          return _fileDecode(file, key, decode);
        }
      }
    } else {
      imageBytes = await _svgToPng(svgKey);
    }
    final ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(imageBytes);
    return decode(buffer);
  }

  Future<ui.Codec> _fileDecode(
      File file, SvgWebImageKey key, DecoderBufferCallback decode) async {
    final int lengthInBytes = await file.length();
    if (lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(key);
      final svgKey = await fetcher.getKey();
      await _cacheSvgManager.removeFile(svgKey);
      throw StateError('$file is empty and cannot be loaded as an image.');
    }
    if (file.runtimeType == File) {
      return decode(await ui.ImmutableBuffer.fromFilePath(file.path));
    }
    return decode(
        await ui.ImmutableBuffer.fromUint8List(await file.readAsBytes()));
  }

  Future<Uint8List> _svgToPng(String svgKey) async {
    final completer = Completer<String>();
    _addTask(_TaskItem(
      key: svgKey,
      script:
          "svgToPng('$svgKey', `${await fetcher.getSvgString()}`, $minWidth, $width, $height, ${backgroundColor == null ? null : "'rgba(${backgroundColor!.red}, ${backgroundColor!.green}, ${backgroundColor!.blue}, ${backgroundColor!.opacity})'"})",
    ));
    final callback = (List arguments) {
      if (arguments.first == svgKey) {
        completer.complete(arguments[1]);
      }
    };
    final errorCallback = (List arguments) {
      if (arguments.first == svgKey) {
        completer.completeError(arguments[1]);
      }
    };
    _resultListeners.add(callback);
    _resultErrorListeners.add(errorCallback);
    try {
      final imageBase64 =
          (await completer.future).replaceFirst('data:image/png;base64,', '');
      var imageBytes = base64.decode(imageBase64);
      try {
        imageBytes = await FlutterImageCompress.compressWithList(
          imageBytes,
          minHeight: 2000,
          minWidth: 2000,
          format: CompressFormat.png,
        );
      } catch (_) {}
      _resultListeners.remove(callback);
      _resultErrorListeners.remove(errorCallback);
      if (cacheSvg) {
        await _cacheSvgManager.putFile(
          svgKey,
          imageBytes,
          fileExtension: 'png',
        );
      }
      return imageBytes;
    } catch (_) {
      _resultListeners.remove(callback);
      _resultErrorListeners.remove(callback);
      rethrow;
    }
  }

  @override
  Future<SvgWebImageKey> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<SvgWebImageKey>(SvgWebImageKey(
      fetcher: fetcher,
      height: height ?? configuration.size?.height,
      width: width ?? configuration.size?.width,
      minWidth: minWidth,
      backgroundColor: backgroundColor,
      scale: scale,
      cacheSvg: cacheSvg,
    ));
  }
}

@immutable
class SvgWebImageKey {
  final SvgFetcher fetcher;
  final double? height;
  final double? width;
  final double minWidth;
  final Color? backgroundColor;
  final double scale;
  final bool cacheSvg;

  const SvgWebImageKey({
    required this.fetcher,
    required this.minWidth,
    required this.cacheSvg,
    this.height,
    this.width,
    this.backgroundColor,
    this.scale = 1.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SvgWebImageKey &&
          runtimeType == other.runtimeType &&
          fetcher == other.fetcher &&
          height == other.height &&
          width == other.width &&
          minWidth == other.minWidth &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode =>
      fetcher.hashCode ^
      height.hashCode ^
      width.hashCode ^
      minWidth.hashCode ^
      backgroundColor.hashCode;
}

/// Task item.
class _TaskItem {
  final String key;
  final String script;

  _TaskItem({
    required this.key,
    required this.script,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _TaskItem &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          script == other.script;

  @override
  int get hashCode => key.hashCode ^ script.hashCode;
}

/// SVG fetcher.
/// Get SVG string and key.
abstract class SvgFetcher {
  Future<String> getKey();

  Future<String> getSvgString();

  String getPath();
}

/// Cached network SVG fetcher.
class CachedNetworkSvgFetcher extends SvgFetcher {
  /// SVG url.
  final String url;

  /// Canvas height. Use SVG default height if not set.
  final double? height;

  /// Canvas height. Use SVG default height if not set.
  final double? width;

  /// Minimum SVG width.
  final double minWidth;

  /// Image background color.
  final Color? backgroundColor;

  /// Set headers for the image provider, for example for authentication
  final Map<String, String>? headers;

  /// CacheManager from which the image files are loaded.
  final BaseCacheManager? cacheManager;

  /// Cache key of the image to cache
  final String? cacheKey;

  CachedNetworkSvgFetcher({
    required this.url,
    required this.minWidth,
    this.height,
    this.width,
    this.backgroundColor,
    this.headers,
    this.cacheManager,
    this.cacheKey,
  });

  BaseCacheManager get _cacheManager => cacheManager ?? DefaultCacheManager();

  @override
  Future<String> getKey() async {
    return '$url?$width-$height-$backgroundColor';
  }

  @override
  Future<String> getSvgString() async {
    final file = await _cacheManager.getSingleFile(
      url,
      headers: headers ?? {},
      key: cacheKey ?? url,
    );
    return await file.readAsString();
  }

  @override
  String getPath() => url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedNetworkSvgFetcher &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          height == other.height &&
          width == other.width &&
          backgroundColor == other.backgroundColor &&
          headers == other.headers &&
          cacheManager == other.cacheManager &&
          cacheKey == other.cacheKey;

  @override
  int get hashCode =>
      url.hashCode ^
      height.hashCode ^
      width.hashCode ^
      backgroundColor.hashCode ^
      headers.hashCode ^
      cacheManager.hashCode ^
      cacheKey.hashCode;
}

/// Network SVG fetcher.
class NetworkSvgFetcher extends SvgFetcher {
  /// SVG url.
  final String url;

  /// Canvas height. Use SVG default height if not set.
  final double? height;

  /// Canvas height. Use SVG default height if not set.
  final double? width;

  /// Minimum SVG width.
  final double minWidth;

  /// Image background color.
  final Color? backgroundColor;

  /// Set headers for the image provider, for example for authentication
  final Map<String, String>? headers;

  NetworkSvgFetcher({
    required this.url,
    required this.minWidth,
    this.height,
    this.width,
    this.backgroundColor,
    this.headers,
  });

  @override
  Future<String> getKey() async {
    return '$url?$width-$height-$minWidth-$backgroundColor';
  }

  @override
  Future<String> getSvgString() async {
    final client = HttpClient();
    final Uri resolved = Uri.base.resolve(url);
    final request = await client.getUrl(resolved);
    headers?.forEach((String name, String value) {
      request.headers.add(name, value);
    });
    final HttpClientResponse response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      // The network may be only temporarily unavailable, or the file will be
      // added on the server later. Avoid having future calls to resolve
      // fail to check the network again.
      await response.drain<List<int>>(<int>[]);
      throw NetworkImageLoadException(
          statusCode: response.statusCode, uri: resolved);
    }
    final svgString = await response.transform(utf8.decoder).join();
    client.close();
    return svgString;
  }

  @override
  String getPath() => url;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkSvgFetcher &&
          runtimeType == other.runtimeType &&
          url == other.url &&
          height == other.height &&
          width == other.width &&
          backgroundColor == other.backgroundColor &&
          headers == other.headers;

  @override
  int get hashCode =>
      url.hashCode ^
      height.hashCode ^
      width.hashCode ^
      backgroundColor.hashCode ^
      headers.hashCode;
}

/// SVG file fetcher.
class FileSvgFetcher extends SvgFetcher {
  /// SVG file.
  final File file;

  /// Canvas height. Use SVG default height if not set.
  final double? height;

  /// Canvas height. Use SVG default height if not set.
  final double? width;

  /// Minimum SVG width.
  final double minWidth;

  /// Image background color.
  final Color? backgroundColor;

  FileSvgFetcher({
    required this.file,
    required this.minWidth,
    this.height,
    this.width,
    this.backgroundColor,
  });

  @override
  Future<String> getKey() async {
    return '${file.path}?$width-$height-$minWidth-$backgroundColor';
  }

  @override
  Future<String> getSvgString() {
    return file.readAsString();
  }

  @override
  String getPath() => file.path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileSvgFetcher &&
          runtimeType == other.runtimeType &&
          file == other.file &&
          height == other.height &&
          width == other.width &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode =>
      file.hashCode ^
      height.hashCode ^
      width.hashCode ^
      backgroundColor.hashCode;
}

/// SVG data fetcher.
class DataSvgFetcher extends SvgFetcher {
  /// SVG data.
  final String data;

  /// Canvas height. Use SVG default height if not set.
  final double? height;

  /// Canvas height. Use SVG default height if not set.
  final double? width;

  /// Minimum SVG width.
  final double minWidth;

  /// Image background color.
  final Color? backgroundColor;

  DataSvgFetcher({
    required this.data,
    required this.minWidth,
    this.height,
    this.width,
    this.backgroundColor,
  });

  @override
  Future<String> getKey() async {
    return '${data.hashCode}${data.length}?$width-$height-$minWidth-$backgroundColor';
  }

  @override
  Future<String> getSvgString() async {
    return data;
  }

  @override
  String getPath() => data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DataSvgFetcher &&
          runtimeType == other.runtimeType &&
          data == other.data &&
          height == other.height &&
          width == other.width &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode =>
      data.hashCode ^
      height.hashCode ^
      width.hashCode ^
      backgroundColor.hashCode;
}

/// SVG asset fetcher.
class AssetSvgFetcher extends SvgFetcher {
  /// SVG asset name.
  final String name;

  /// Asset bundle
  AssetBundle? bundle;

  /// Canvas height. Use SVG default height if not set.
  final double? height;

  /// Canvas height. Use SVG default height if not set.
  final double? width;

  /// Minimum SVG width.
  final double minWidth;

  /// Image background color.
  final Color? backgroundColor;

  AssetSvgFetcher({
    required this.name,
    required this.minWidth,
    this.bundle,
    this.height,
    this.width,
    this.backgroundColor,
  });

  @override
  Future<String> getKey() async {
    final svgString = await getSvgString();
    return '$name${svgString.hashCode}${svgString.length}?$width-$height-$minWidth-$backgroundColor';
  }

  @override
  Future<String> getSvgString() async {
    return await (bundle ?? rootBundle).loadString(name);
  }

  @override
  String getPath() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetSvgFetcher &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          bundle == other.bundle &&
          height == other.height &&
          width == other.width &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode =>
      name.hashCode ^
      bundle.hashCode ^
      height.hashCode ^
      width.hashCode ^
      backgroundColor.hashCode;
}
