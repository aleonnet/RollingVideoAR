import 'package:path_provider/path_provider.dart';

Future<String> getRollviTempDir() async {
  final rawDir = (await getTemporaryDirectory()).path;
  return '$rawDir/rollvi';
}
