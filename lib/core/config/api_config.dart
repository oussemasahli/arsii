import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OpenRouter API configuration.
class ApiConfig {
  ApiConfig._();

  /// OpenRouter API key loaded from .env.
  static String get openRouterApiKey =>
      (dotenv.env['OPENROUTER_API_KEY'] ?? '').trim();

  /// OpenRouter API endpoint
  static const String openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';

  /// Model to use for quiz generation (fast + cheap)
  static const String model = 'nvidia/nemotron-3-super-120b-a12b:free';
}
