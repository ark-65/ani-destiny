import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
}
