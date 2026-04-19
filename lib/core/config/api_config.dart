/// OpenRouter API configuration.
/// Paste your API key below.
class ApiConfig {
  ApiConfig._();

  /// OpenRouter API key.
  static const String openRouterApiKey = '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';

  /// OpenRouter API endpoint
  static const String openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';

  /// Model to use for quiz generation (fast + cheap)
  static const String model = 'openai/gpt-oss-120b:free';
}
