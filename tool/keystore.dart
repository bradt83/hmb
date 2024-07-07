import 'package:dcli/dcli.dart';
import 'package:path/path.dart';

final projectRoot = DartProject.self.pathToProjectRoot;
final keyStorePath = join(projectRoot, 'hmb-key.keystore');
const keyStoreAlias = 'hmbkey';