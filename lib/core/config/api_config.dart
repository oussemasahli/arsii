/// OpenRouter API configuration.
/// Paste your API key below.
class ApiConfig {
  ApiConfig._();

  /// Your OpenRouter API key from https://openrouter.ai/keys
  static const String openRouterApiKey = 'YOUR_OPENROUTER_API_KEY_HERE';

  /// OpenRouter API endpoint
  static const String openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';

  /// Model to use for quiz generation (fast + cheap)
  static const String model = 'openai/gpt-oss-120b:free';
}
