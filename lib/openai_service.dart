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
