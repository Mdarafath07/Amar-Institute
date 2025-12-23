import 'package:flutter/material.dart';
import '../../../../services/ai_service.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  static const name = '/ai';

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();

  final Color primaryColor = const Color(0xFF9181F4);
  final Color bgColor = const Color(0xFFFDFBFF);
  final Color userBubbleColor = const Color(0xFF9181F4);
  final Color aiBubbleColor = Colors.white;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.bounceInOut,
        );
      }
    });
  }

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final reply = await AiService.getResponse(text);
      setState(() {
        messages.add({"role": "ai", "text": reply});
        isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        messages.add({"role": "system", "text": "Something went wrong!"});
        isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "Ai Assistant",
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text("Online", style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            )
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => messages.clear()),
            icon: Icon(Icons.auto_delete_outlined, color: Colors.grey.shade400),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: messages.length,
              itemBuilder: (context, index) => _chatBubble(messages[index]),
            ),
          ),
          if (isLoading) _buildLoading(),
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://cdn-icons-png.flaticon.com/512/4712/4712035.png', // Cute Bot Icon
            height: 120,
            errorBuilder: (c, e, s) => Icon(Icons.face_retouching_natural, size: 80, color: primaryColor.withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          Text(
            "Hi! How can I help you today?",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _chatBubble(Map<String, dynamic> msg) {
    bool isUser = msg["role"] == "user";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.auto_awesome, size: 14, color: primaryColor),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? userBubbleColor : aiBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Text(
                msg["text"],
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text("typing...", style: TextStyle(color: primaryColor, fontSize: 12, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}