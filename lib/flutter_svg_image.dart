library flutter_svg_image;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    hide CompressFormat;
import 'package:jovial_svg/jovial_svg.dart';

part './src/svg_image.dart';
part './src/svg_web_image.dart';
part './src/cached_network_svg_source.dart';
