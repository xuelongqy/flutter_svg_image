import 'package:flutter/material.dart';
import 'package:flutter_svg_image/flutter_svg_image.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Builder(
          builder: (context) {
            final size = MediaQuery.of(context).size;
            return SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Image(
                fit: BoxFit.contain,
                image: SvgImage.cachedNetwork(
                  'https://jovial.com/images/jupiter.svg',
                  height: size.height >= size.width ? size.height : null,
                  width: size.width > size.height ? size.width : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
