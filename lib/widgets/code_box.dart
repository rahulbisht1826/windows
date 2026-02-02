import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';

class CodeBox extends StatelessWidget {
  final String code;
  final String? language;

  const CodeBox({super.key, required this.code, this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  language?.toUpperCase() ?? "CODE",
                  style: GoogleFonts.firaCode(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Copied to clipboard"),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.copy, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "Copy",
                        style: GoogleFonts.firaCode(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: HighlightView(
              code,
              language: language ?? 'dart',
              theme: atomOneDarkTheme,
              padding: const EdgeInsets.all(0),
              textStyle: GoogleFonts.firaCode(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
