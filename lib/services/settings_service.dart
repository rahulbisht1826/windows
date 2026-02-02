import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _modelPathKey = 'model_path';
  static const String _gpuEnabledKey = 'gpu_enabled';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  /// Returns the base directory for the application.
  /// On Windows, this is relative to the executable for portability.
  /// On other platforms, it uses standard application documents directory.
  Future<String> getAppBaseDir() async {
    if (Platform.isWindows) {
      // For portability, use the directory where the executable is located.
      final exePath = Platform.resolvedExecutable;
      return p.dirname(exePath);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

  /// Returns the default models directory.
  Future<String> getModelsDir() async {
    final baseDir = await getAppBaseDir();
    return p.join(baseDir, 'models');
  }

  /// Gets the currently saved model path.
  String? getModelPath() {
    return _prefs.getString(_modelPathKey);
  }

  /// Sets the model path.
  Future<void> setModelPath(String path) async {
    await _prefs.setString(_modelPathKey, path);
  }

  /// Gets if GPU acceleration is enabled.
  bool isGpuEnabled() {
    return _prefs.getBool(_gpuEnabledKey) ?? true;
  }

  /// Sets if GPU acceleration is enabled.
  Future<void> setGpuEnabled(bool enabled) async {
    await _prefs.setBool(_gpuEnabledKey, enabled);
  }

  /// Automatically discovers a model in the /models directory on Windows.
  Future<String?> autoDiscoverModel() async {
    if (!Platform.isWindows) return null;

    final modelsDir = Directory(await getModelsDir());
    if (await modelsDir.exists()) {
      final List<FileSystemEntity> files = await modelsDir.list().toList();
      for (var file in files) {
        if (file is File && file.path.endsWith('.gguf')) {
          return file.path;
        }
      }
    }
    return null;
  }
}
