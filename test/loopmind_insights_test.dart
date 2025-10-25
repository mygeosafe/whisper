import 'package:flutter_test/flutter_test.dart';

import 'package:whispair_loopmind/features/ai/application/ai_models.dart';

void main() {
  test('parses summary and prompts from combined text', () {
    final content = 'Summary: This is the idea.\nPrompts:\n1. How might you test it?\n2. Who benefits most?\n3. What resources are required?';
    final insights = LoopMindInsights.fromCombinedText(content);

    expect(insights.summary, contains('This is the idea'));
    expect(insights.prompts.length, 3);
    expect(insights.prompts.first, 'How might you test it?');
  });
}
