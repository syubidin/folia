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

  Future<String?> pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final dir = await directory();
    final name = '${const Uuid().v4()}.jpg';
    await File(picked.path).copy(p.join(dir.path, name));
    return name;
  }

  Future<void> delete(String name) async {
    final file = File(p.join((await directory()).path, p.basename(name)));
    if (file.existsSync()) await file.delete();
  }
}
