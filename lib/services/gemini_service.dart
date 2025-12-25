import 'dart:io';
import 'package:amar_institute/services/api.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late GenerativeModel _model;
  late ChatSession _chat;

  GeminiService() {



    _model = GenerativeModel(

      model: 'gemini-2,0-flash',
      apiKey: Apis.gemini,

      systemInstruction: Content.system(
          'You are a professional AI Study Assistant. Your role is to solve academic problems, '
              'explain concepts simply, and help with homework. Use bullet points for clarity.'
      ),
    );

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
        // টেক্সট চ্যাটের জন্য sendMessage ব্যবহার করুন
        final response = await _chat.sendMessage(Content.text(question));
        return response.text ?? 'I am sorry, I could not generate an answer.';
      }
    } catch (e) {
      print('Gemini Error: $e');
      if (e.toString().contains('not found')) {
        return 'The selected AI model is not available right now. Please check your API key.';
      }
      return 'I am having trouble connecting. Please check your internet.';
    }
  }
}