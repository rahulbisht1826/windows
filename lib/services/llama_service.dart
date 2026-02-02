import 'dart:async';
import 'dart:io';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LlamaService {
  LlamaProcessor? _processor;
  bool _isInitializing = false;

  bool get isReady => _processor != null;
  bool get isInitializing => _isInitializing;

  Future<void> initialize({
    required String modelPath,
    bool useGpu = true,
  }) async {
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      // Unload previous if exists
      _processor?.unload();

      final settings = ContextSettings()
        ..nContext = 4096
        ..nGpuLayers = useGpu ? (Platform.isAndroid ? 32 : 100) : 0; // High number for GPU acceleration if available

      _processor = LlamaProcessor(modelPath, settings);
      
    } catch (e) {
      print("Error initializing Llama: $e");
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Stream<String> streamResponse(String prompt) {
    if (_processor == null) {
      throw Exception("LlamaProcessor not initialized. Call initialize() first.");
    }

    final controller = StreamController<String>();

    // Using prompt template for DeepSeek or similar Instruct models
    final formattedPrompt = """
### Instruction:
$prompt

### Response:
""";

    _processor!.stream(formattedPrompt).listen(
      (token) {
        controller.add(token);
      },
      onDone: () {
        controller.close();
      },
      onError: (error) {
        controller.addError(error);
        controller.close();
      },
    );

    return controller.stream;
  }

  void dispose() {
    _processor?.unload();
  }
}
