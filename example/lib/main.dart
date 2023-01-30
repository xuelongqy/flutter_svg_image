import 'package:flutter/material.dart';
import 'package:flutter_svg_image/flutter_svg_image.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _webViewCreated = false;

  @override
  void initState() {
    super.initState();
    SvgWebImage.initWebView().then((value) {
      setState(() {
        _webViewCreated = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Image(
                fit: BoxFit.contain,
                image: SvgImage.cachedNetwork(
                  'https://jovial.com/images/jupiter.svg',
                ),
              ),
              if (_webViewCreated)
                Image(
                  fit: BoxFit.contain,
                  image: SvgWebImage.cachedNetwork(
                    'https://jovial.com/images/jupiter.svg',
                    cacheSvg: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
