import 'dart:io';
import 'package:amar_institute/services/api.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late GenerativeModel _model;
  late ChatSession _chat;

  GeminiService() {
    // Gemini 2.5 Flash ফ্রী ইউজারদের জন্য বর্তমানের সেরা অপশন
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: Apis.gemini,
      systemInstruction: Content.system(
          'You are a professional AI Study Assistant. Your role is to solve academic problems, '
              'explain concepts simply, and help with homework. Use bullet points for clarity.'
      ),
    );

    // মাল্টি-টার্ন বা চ্যাট হিস্ট্রি মেনটেইন করার জন্য
    _chat = _model.startChat();
  }

  Future<String> answerQuestion(String question, {File? imageFile}) async {
    try {
      if (imageFile != null) {
        final imageBytes = await imageFile.readAsBytes();
        final content = [
          Content.multi([
            TextPart(question.isEmpty ? 'Analyze this study material' : question),
            DataPart('image/jpeg', imageBytes),
          ])
        ];

        final response = await _model.generateContent(content);
        return response.text ?? 'I could not read the image. Please try again.';
      } else {
        // sendMessage ব্যবহার করে চ্যাট কন্টিনিউ করা
        final response = await _chat.sendMessage(Content.text(question));
        return response.text ?? 'I am sorry, I could not generate an answer.';
      }
    } catch (e) {
      print('Gemini Error: $e');
      // কোটা শেষ হয়ে গেলে বা এরর হলে ইউজার ফ্রেন্ডলি মেসেজ
      if (e.toString().contains('429')) {
        return "Free tier quota exceeded. Please wait a moment.";
      }
      return "Something went wrong! Please check your internet or API key.";
    }
  }
}