import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class PlantImageStore {
  final _picker = ImagePicker();
  Directory? _dir;

  Future<Directory> directory() async {
    final cached = _dir;
    if (cached != null) return cached;
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'plants'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return _dir = dir;
  }

  Future<String?> pickTemp(ImageSource source, {int maxSide = 1280}) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: maxSide.toDouble(),
      maxHeight: maxSide.toDouble(),
      imageQuality: 80,
    );
    return picked?.path;
  }

  Future<String> adopt(String sourcePath) async {
    final dir = await directory();
    final name = '${const Uuid().v4()}.jpg';
    await File(sourcePath).copy(p.join(dir.path, name));
    try {
      await File(sourcePath).delete();
    } on FileSystemException {
      // file cache diabaikan
    }
    return name;
  }

  Future<String?> pick(ImageSource source) async {
    final temp = await pickTemp(source);
    return temp == null ? null : await adopt(temp);
  }

  Future<void> delete(String name) async {
    final file = File(p.join((await directory()).path, p.basename(name)));
    if (file.existsSync()) await file.delete();
  }
}
