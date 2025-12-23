import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  // এখানে আপনার Google AI Studio থেকে প্রাপ্ত API Key টি বসান
  static const String _apiKey = "api";

  static Future<String> getResponse(String prompt) async {
    try {
      // বিভিন্ন মডেল চেষ্টা করার লিস্ট
      final List<String> modelsToTry = [
        'gemini-pro',        // সবচেয়ে কমন
        'gemini-1.0-pro',    // আরেকটি ভার্সন
        'models/text-bison-001', // পুরনো মডেল
      ];

      String? lastError;

      for (var modelName in modelsToTry) {
        try {
          print("Trying model: $modelName");

          final model = GenerativeModel(
            model: modelName,
            apiKey: _apiKey,
            generationConfig: GenerationConfig(
              temperature: 0.7,
              topP: 0.8,
              topK: 40,
            ),
          );

          final content = [Content.text(prompt)];
          final response = await model.generateContent(content);

          if (response.text != null && response.text!.isNotEmpty) {
            print("Success with model: $modelName");
            return response.text!;
          }
        } catch (e) {
          lastError = e.toString();
          print("Failed with $modelName: $e");
          continue; // পরবর্তী মডেল চেষ্টা করুন
        }
      }

      return "ত্রুটি: কোনো মডেল কাজ করছে না। লগ: $lastError";

    } catch (e) {
      print("General Error: $e");

      // বিশেষ ত্রুটি হ্যান্ডলিং
      if (e.toString().contains('quota')) {
        return "মাসিক লিমিট শেষ হয়েছে। পরের মাস পর্যন্ত অপেক্ষা করুন।";
      } else if (e.toString().contains('404')) {
        return "মডেল পাওয়া যায়নি। দয়া অন্য মডেল চেষ্টা করুন।";
      } else if (e.toString().contains('API key')) {
        return "API Key সঠিক নয়। দয়া চেক করুন।";
      } else if (e.toString().contains('PERMISSION_DENIED')) {
        return "অনুমতি নেই। API Key চেক করুন।";
      } else if (e.toString().contains('NOT_FOUND')) {
        return "মডেল পাওয়া যায়নি। 'gemini-pro' মডেল চেষ্টা করুন।";
      }

      return "ত্রুটি হয়েছে: ${e.toString()}";
    }
  }

  // API Key ভ্যালিডেশন মেথড
  static Future<bool> validateApiKey() async {
    try {
      final model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey,
      );

      // একটি ছোট রিকোয়েস্ট দিয়ে টেস্ট করুন
      final content = [Content.text("Hello")];
      final response = await model.generateContent(content);

      return response.text != null;
    } catch (e) {
      print("API Key Validation Failed: $e");
      return false;
    }
  }
}