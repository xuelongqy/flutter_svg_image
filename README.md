# flutter_svg_image

Svg ImageProvider for Flutter. Use jovial_svg to parse svg and use flutter_cache_manager to cache svg files.

## Getting Started

```dart
import 'package:flutter_svg_image/flutter_svg_image.dart';

Image(
  fit: BoxFit.contain,
  image: SvgImage.cachedNetwork(
    'https://jovial.com/images/jupiter.svg',
  ),
)
```

