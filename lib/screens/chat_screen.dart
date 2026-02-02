import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_provider.dart';
import '../widgets/code_box.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  List<Widget> _parseMessage(String text) {
    final List<Widget> widgets = [];
    final codeRegex = RegExp(r'```([a-z0-9]*)\n([\s\S]*?)```');
    
    int lastMatchEnd = 0;
    for (final match in codeRegex.allMatches(text)) {
      // Add text before code block
      if (match.start > lastMatchEnd) {
        widgets.add(SelectableText(
          text.substring(lastMatchEnd, match.start).trim(),
          style: GoogleFonts.firaCode(color: Colors.white, fontSize: 14),
        ));
      }

      final lang = match.group(1);
      final code = match.group(2);
      widgets.add(CodeBox(code: code ?? "", language: lang?.isEmpty == true ? null : lang));
      
      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      widgets.add(SelectableText(
        text.substring(lastMatchEnd).trim(),
        style: GoogleFonts.firaCode(color: Colors.white, fontSize: 14),
      ));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final chatNotifier = ref.read(chatProvider.notifier);

    // Auto scroll when messages update
    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "PLUG & PLAY AI",
          style: GoogleFonts.orbitron(
            color: const Color(0xFF00FF41), // Matrix Green
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open, color: Color(0xFF00FF41)),
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.any,
              );
              if (result != null) {
                chatNotifier.loadModel(result.files.single.path!);
              }
            },
            tooltip: "Select Model (.gguf)",
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => chatNotifier.clearChat(),
            tooltip: "Clear History",
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatState.currentModelPath != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              width: double.infinity,
              color: const Color(0xFF1A1A1A),
              child: Text(
                "MODEL: ${chatState.currentModelPath!.split('/').last.split('\\').last}",
                style: GoogleFonts.firaCode(
                  color: Colors.cyanAccent,
                  fontSize: 10,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              width: double.infinity,
              color: Colors.red.withOpacity(0.2),
              child: Text(
                chatState.error!,
                style: GoogleFonts.firaCode(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            msg.isUser ? Icons.person_outline : Icons.bolt,
                            size: 16,
                            color: msg.isUser ? Colors.cyanAccent : const Color(0xFF00FF41),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            msg.isUser ? "USER" : "AI",
                            style: GoogleFonts.orbitron(
                              color: msg.isUser ? Colors.cyanAccent : const Color(0xFF00FF41),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._parseMessage(msg.text),
                    ],
                  ),
                );
              },
            ),
          ),
          if (chatState.isStreaming && chatState.messages.isNotEmpty && chatState.messages.last.text.isEmpty)
             const Padding(
               padding: EdgeInsets.all(8.0),
               child: LinearProgressIndicator(
                 backgroundColor: Colors.transparent,
                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FF41)),
               ),
             ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(top: BorderSide(color: Colors.grey[900]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.firaCode(color: Colors.white),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: "Enter task...",
                      hintStyle: GoogleFonts.firaCode(color: Colors.grey[700]),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty && !chatState.isStreaming) {
                        chatNotifier.sendMessage(val);
                        _controller.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(
                    chatState.isStreaming ? Icons.hourglass_empty : Icons.send,
                    color: chatState.isStreaming ? Colors.grey : const Color(0xFF00FF41),
                  ),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty && !chatState.isStreaming) {
                      chatNotifier.sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
