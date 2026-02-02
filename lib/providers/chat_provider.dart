import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/llama_service.dart';
import '../services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Providers for Services
final settingsServiceProvider = FutureProvider<SettingsService>((ref) async {
  return await SettingsService.init();
});

final llamaServiceProvider = Provider<LlamaService>((ref) {
  final service = LlamaService();
  ref.onDispose(() => service.dispose());
  return service;
});

// UI State Providers
class Message {
  final String text;
  final bool isUser;
  Message({required this.text, required this.isUser});
}

class ChatState {
  final List<Message> messages;
  final bool isStreaming;
  final String? error;
  final String? currentModelPath;

  ChatState({
    required this.messages,
    required this.isStreaming,
    this.error,
    this.currentModelPath,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isStreaming,
    String? error,
    String? currentModelPath,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      error: error,
      currentModelPath: currentModelPath ?? this.currentModelPath,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final LlamaService _llamaService;
  final SettingsService? _settingsService;

  ChatNotifier(this._llamaService, this._settingsService) 
      : super(ChatState(messages: [], isStreaming: false)) {
    _init();
  }

  Future<void> _init() async {
    if (_settingsService == null) return;
    
    String? modelPath = _settingsService!.getModelPath();
    if (modelPath == null) {
      modelPath = await _settingsService!.autoDiscoverModel();
    }

    if (modelPath != null) {
      loadModel(modelPath);
    }
  }

  Future<void> loadModel(String path) async {
    try {
      state = state.copyWith(isStreaming: true, error: null);
      await _llamaService.initialize(
        modelPath: path,
        useGpu: _settingsService?.isGpuEnabled() ?? true,
      );
      await _settingsService?.setModelPath(path);
      state = state.copyWith(isStreaming: false, currentModelPath: path);
    } catch (e) {
      state = state.copyWith(isStreaming: false, error: "Failed to load model: $e");
    }
  }

  Future<void> sendMessage(String text) async {
    if (!_llamaService.isReady) {
      state = state.copyWith(error: "Model not loaded. Please select a .gguf file.");
      return;
    }

    final userMessage = Message(text: text, isUser: true);
    final botMessage = Message(text: "", isUser: false);
    
    state = state.copyWith(
      messages: [...state.messages, userMessage, botMessage],
      isStreaming: true,
      error: null,
    );

    String fullResponse = "";
    try {
      _llamaService.streamResponse(text).listen(
        (token) {
          fullResponse += token;
          final updatedMessages = List<Message>.from(state.messages);
          updatedMessages[updatedMessages.length - 1] = Message(text: fullResponse, isUser: false);
          state = state.copyWith(messages: updatedMessages);
        },
        onDone: () {
          state = state.copyWith(isStreaming: false);
        },
        onError: (e) {
          state = state.copyWith(isStreaming: false, error: "Streaming error: $e");
        },
      );
    } catch (e) {
      state = state.copyWith(isStreaming: false, error: "Error: $e");
    }
  }

  void clearChat() {
    state = state.copyWith(messages: []);
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final llama = ref.watch(llamaServiceProvider);
  final settings = ref.watch(settingsServiceProvider).valueOrNull;
  return ChatNotifier(llama, settings);
});
