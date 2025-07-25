import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIService {
  final String apiKey =
      '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';

  Future<String> sendMessage(String prompt) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer \$apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "user", "content": prompt}
        ]
      }),
    );

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'];
  }
}
