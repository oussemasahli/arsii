/// OpenRouter API configuration.
/// Paste your API key below.
class ApiConfig {
  ApiConfig._();

  /// OpenRouter API key.
  static const String openRouterApiKey = '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';

  /// OpenRouter API endpoint
  static const String openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';

  /// Model to use for quiz generation (fast + cheap)
  static const String model = 'nvidia/nemotron-3-super-120b-a12b:free';
}
