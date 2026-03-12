import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuoteWidget extends StatelessWidget {
  final String quote;
  final String attribution;

  const QuoteWidget({
    super.key,
    required this.quote,
    required this.attribution,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left accent border — muted gold
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF8A7F70),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quote,
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFFF0EDE8),
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    attribution,
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      color: const Color(0xFFF0EDE8).withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
