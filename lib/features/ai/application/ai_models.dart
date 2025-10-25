class LoopMindInsights {
  LoopMindInsights({required this.summary, required this.prompts});

  final String summary;
  final List<String> prompts;

  factory LoopMindInsights.fromCombinedText(String text) {
    final parts = text.split('Prompts:');
    final summary = parts.first.trim();
    final promptsText = parts.length > 1 ? parts[1] : '';
    final prompts = promptsText
        .split(RegExp(r'\n|\r'))
        .map((line) => line.replaceAll(RegExp(r'^[0-9]+[\).]\s*'), '').trim())
        .where((line) => line.isNotEmpty)
        .take(3)
        .toList();
    return LoopMindInsights(summary: summary, prompts: prompts);
  }
}
