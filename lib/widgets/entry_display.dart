import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/entry.dart';
import 'quote_widget.dart';

enum SummaryState { loading, loaded, error, notConfigured }

class EntryDisplay extends StatelessWidget {
  final Entry entry;
  final SummaryState summaryState;
  final String? summary; // non-null when summaryState == loaded
  final String? errorMessage; // non-null when summaryState == error
  final VoidCallback? onConfigureTapped;

  const EntryDisplay({
    super.key,
    required this.entry,
    required this.summaryState,
    this.summary,
    this.errorMessage,
    this.onConfigureTapped,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Center(
            child: Text(
              entry.title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              style: TextStyle(
                fontSize: 20,
                letterSpacing: 2.0,
                color: const Color(0xFFF0EDE8).withOpacity(0.75),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Quote block
          QuoteWidget(quote: entry.quote, attribution: entry.attribution),

          const SizedBox(height: 24),

          const _Divider(),

          const SizedBox(height: 24),

          // Body text — split on paragraph breaks, reflow within each paragraph
          ...entry.body.split('\n\n').where((p) => p.trim().isNotEmpty).map((paragraph) {
            final text = paragraph.replaceAll('\n', ' ').trim();
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                text,
                style: GoogleFonts.lora(
                  fontSize: 15,
                  color: const Color(0xFFF0EDE8).withOpacity(0.85),
                  height: 1.8,
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          const _Divider(),

          const SizedBox(height: 20),

          // Summary section
          Text(
            'SUMMARY',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.8,
              color: const Color(0xFFF0EDE8).withOpacity(0.4),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          _buildSummaryContent(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryContent() {
    switch (summaryState) {
      case SummaryState.loading:
        return SizedBox(
          height: 20,
          child: Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: const Color(0xFFF0EDE8).withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Generating summary…',
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFFF0EDE8).withOpacity(0.35),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );

      case SummaryState.loaded:
        return Text(
          summary ?? '',
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFFF0EDE8).withOpacity(0.75),
            fontStyle: FontStyle.italic,
            height: 1.6,
          ),
        );

      case SummaryState.error:
        return Text(
          errorMessage ?? 'Could not generate summary — check Settings.',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFB06060),
            height: 1.5,
          ),
        );

      case SummaryState.notConfigured:
        return GestureDetector(
          onTap: onConfigureTapped,
          child: Text(
            'Set up AI summaries in Settings →',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFFF0EDE8).withOpacity(0.3),
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFFF0EDE8).withOpacity(0.2),
            ),
          ),
        );
    }
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: const Color(0xFFF0EDE8).withOpacity(0.1),
    );
  }
}
