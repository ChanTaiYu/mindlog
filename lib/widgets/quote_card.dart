import 'package:flutter/material.dart';

import '../services/quote_service.dart';

/// Dashboard card showing today's inspirational quote from the external API.
class QuoteCard extends StatefulWidget {
  const QuoteCard({super.key});

  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard> {
  final _service = QuoteService();
  late Future<Quote> _future = _service.todayQuote();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: FutureBuilder<Quote>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final q = snap.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_quote,
                        color: scheme.onPrimaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'Quote of the day',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh',
                      icon: Icon(Icons.refresh, color: scheme.onPrimaryContainer),
                      onPressed: () => setState(
                          () => _future = _service.todayQuote()),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '“${q.text}”',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontStyle: FontStyle.italic,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '— ${q.author}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
