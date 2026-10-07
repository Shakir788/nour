import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/ai_service.dart';
import '../../core/theme/app_theme.dart';

class NourScreen extends StatefulWidget {
  const NourScreen({super.key});

  @override
  State<NourScreen> createState() => _NourScreenState();
}

class _NourScreenState extends State<NourScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController(); 
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  bool _isBannerVisible = true;
  String? _selectedImagePath;

  late AnimationController _welcomeController;
  late Animation<Offset> _welcomeOffset;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _welcomeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _welcomeOffset = Tween<Offset>(begin: const Offset(0, -1.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeOutExpo),
    );

    _welcomeController.forward().then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _welcomeController.reverse().then((_) {
            if (mounted) setState(() => _isBannerVisible = false);
          });
        }
      });
    });

    _loadChatHistory();
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    _controller.dispose();
    _scrollController.dispose(); 
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedChat = prefs.getString('nour_chat_history');

    if (savedChat != null && savedChat.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(savedChat);
      setState(() {
        _messages.clear();
        _messages.addAll(decoded.map((e) => Map<String, String>.from(e)).toList());
      });
    } else {
      setState(() {
        _messages.add({
          'sender': 'nour',
          'text': 'As-salamu alaykum! I am Nour, your spiritual companion. How can I help you today? ✨',
          'image': '',
        });
      });
      _saveChatHistory();
    }
    _scrollToBottom();
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nour_chat_history', jsonEncode(_messages));
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (image != null) {
      setState(() {
        _selectedImagePath = image.path;
      });
    }
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear Chat?', style: AppTextStyles.bodyLarge.copyWith(fontSize: 18)),
        content: Text('Are you sure you want to delete all messages?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('nour_chat_history');
              setState(() {
                _messages.clear();
                _messages.add({'sender': 'nour', 'text': 'As-salamu alaykum! I am Nour, your spiritual companion. How can I help you today? ✨', 'image': ''});
              });
              _saveChatHistory();
              _scrollToBottom();
            },
            child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleIncomingAIResponse(String rawText) {
    String cleanText = rawText.replaceAll(RegExp(r'\*[^*]+\*'), '').trim();
    if (cleanText.isEmpty) {
      cleanText = "✨";
    }

    setState(() {
      _isLoading = false;
      _messages.add({'sender': 'nour', 'text': cleanText, 'image': ''});
    });

    _saveChatHistory();
    _scrollToBottom(); 
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final imagePath = _selectedImagePath;

    if (text.isEmpty && imagePath == null) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text, 'image': imagePath ?? ''});
      _isLoading = true;
      _selectedImagePath = null;
    });

    _saveChatHistory();
    _controller.clear();
    _scrollToBottom(); 

    List<Map<String, String>> aiHistory = _messages.map((m) {
      return {
        "role": m['sender'] == 'user' ? "user" : "assistant",
        "content": m['text'] ?? '',
        "image": m['image'] ?? '',
      };
    }).toList();

    final response = await AIService.chatWithLulu(aiHistory);

    if (!mounted) return;
    _handleIncomingAIResponse(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.5),
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.gold),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.sparkles, color: AppColors.gold, size: 22),
            const SizedBox(width: 8),
            Text('Nour', style: AppTextStyles.bodyLarge.copyWith(fontSize: 18, letterSpacing: 1.2)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.trash, color: AppColors.textSecondary, size: 22),
            onPressed: _showClearChatDialog,
            tooltip: "Clear Chat",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController, 
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
                ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _NourTypingIndicator(),
                    ),
                  ),

                _buildInputArea(),
              ],
            ),
          ),

          if (_isBannerVisible)
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: SlideTransition(
                  position: _welcomeOffset,
                  child: Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 10)],
                    ),
                    child: Text(
                      "Welcome to Nour ✨",
                      style: TextStyle(color: AppColors.background, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['sender'] == 'user';
    final text = message['text'] ?? '';
    final imagePath = message['image'] ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.gold.withValues(alpha: 0.85) : AppColors.surfaceElevated.withValues(alpha: 0.7),
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            if (!isUser) BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 5),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.broken_image, color: AppColors.textMuted),
                ),
              ),
              if (text.isNotEmpty) const SizedBox(height: 8),
            ],
            if (text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                  color: isUser ? AppColors.background : AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.5,
                  letterSpacing: 0.3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 30, top: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImagePath != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 8),
                child: Stack(
                  children: [
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(File(_selectedImagePath!), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImagePath = null),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              // ✨ Removed Voice Chat Mic Button from here
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 44,
                  width: 44,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Icon(CupertinoIcons.camera_fill, color: AppColors.textSecondary, size: 18),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: AppTextStyles.bodyLarge,
                    cursorColor: AppColors.gold,
                    decoration: InputDecoration(
                      hintText: 'Message Nour...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                  child: Icon(CupertinoIcons.paperplane_fill, color: AppColors.background, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NourTypingIndicator extends StatefulWidget {
  const _NourTypingIndicator();

  @override
  State<_NourTypingIndicator> createState() => _NourTypingIndicatorState();
}

class _NourTypingIndicatorState extends State<_NourTypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_pulseController),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.sparkles, color: AppColors.gold, size: 14),
          const SizedBox(width: 8),
          Text(
            'Nour is typing...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}