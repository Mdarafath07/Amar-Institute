import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; //
import '../../../../app/app_colors.dart'; //
import '../../../../services/gemini_service.dart'; //
import '../../../../providers/theme_provider.dart'; //

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  static const name = '/ai';

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService(); //
  final ImagePicker _picker = ImagePicker(); //

  late Box _chatBox; //
  bool isLoading = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _chatBox = Hive.box('chat_history'); //
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _showDeleteDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode; //
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: isDark ? AppColors.cardDark : Colors.white, //
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              title: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 50),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Clear Chat?",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: isDark ? Colors.white : Colors.black)), //
                  const SizedBox(height: 10),
                  Text("Are you sure you want to delete all messages? This cannot be undone.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 14)), //
                ],
              ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() => _chatBox.clear());
                    Navigator.pop(context);
                  },
                  child: const Text("Yes, Clear", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final userMessage = {
      "role": "user",
      "text": text,
      "imagePath": _selectedImage?.path,
      "time": DateFormat('hh:mm a').format(DateTime.now()),
    };

    setState(() {
      _chatBox.add(userMessage);
      isLoading = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final reply = await _geminiService.answerQuestion(text, imageFile: _selectedImage); //

      final aiMessage = {
        "role": "ai",
        "text": reply,
        "time": DateFormat('hh:mm a').format(DateTime.now()),
      };

      setState(() {
        _chatBox.add(aiMessage);
        isLoading = false;
        _selectedImage = null;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Error connecting to Gemini"), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode; //

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight, //
      appBar: _buildAppBar(isDark),
      body: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _chatBox.listenable(), //
              builder: (context, Box box, _) {
                if (box.isEmpty) return _buildEmptyState(isDark);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final msg = box.getAt(index);
                    return _chatBubble(msg, isDark);
                  },
                );
              },
            ),
          ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      color: AppColors.themeColor,
                      minHeight: 2
                  ) //
              ),
            ),
          _buildInputSection(isDark),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white, //
      leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black, size: 20) //
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.themeColor.withOpacity(0.1), //
            child: Icon(Icons.smart_toy_rounded, color: AppColors.themeColor), //
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Study Buddy",
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.bold)), //
              Text("Always Active", style: TextStyle(color: Colors.green.shade400, fontSize: 11)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(onPressed: _showDeleteDialog, icon: Icon(Icons.more_vert, color: isDark ? Colors.white : Colors.black87)), //
      ],
    );
  }

  Widget _chatBubble(dynamic msg, bool isDark) {
    bool isUser = msg["role"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              gradient: isUser
                  ? LinearGradient(colors: [AppColors.themeColor, AppColors.secendthemeColor]) //
                  : null,
              color: isUser ? null : (isDark ? AppColors.cardDark : Colors.white), //
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4)
                )
              ],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg["imagePath"] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(msg["imagePath"]))
                    ),
                  ),
                Text(
                  msg["text"],
                  style: TextStyle(
                      color: isUser ? Colors.white : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87), //
                      fontSize: 15,
                      height: 1.4
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(msg["time"] ?? "", style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
              opacity: isDark ? 0.8 : 1.0, //
              child: Image.network("https://cdn-icons-png.flaticon.com/512/4712/4712035.png", height: 120)
          ),
          const SizedBox(height: 20),
          Text("Start a smart conversation!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.themeColor)), //
          Text("Ask me math, science or anything.",
              style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey)), //
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedImage != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 70,
                width: 70,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        height: 70,
                        width: 70,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          /// INPUT ROW
          Row(
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.themeColor,
                  size: 30,
                ),
              ),

              /// TEXT FIELD
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2F45)
                        : const Color(0xFFF1F4F9),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: AppColors.themeColor,
                        selectionColor:
                        AppColors.themeColor.withOpacity(0.3),
                        selectionHandleColor: AppColors.themeColor,
                      ),
                      inputDecorationTheme: const InputDecorationTheme(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Ask anything...",
                        hintStyle: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              /// SEND BUTTON
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.themeColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}