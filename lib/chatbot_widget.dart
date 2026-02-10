import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skin_disease1/utils/responsive_helper.dart';

class ChatbotWidget extends StatefulWidget {
  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  final List<Map<String, dynamic>> _messages = [
    {
      'text':
          'Hello! I\'m your DermaSense AI assistant. How can I help you today?',
      'isUser': false,
      'timestamp': DateTime.now(),
    },
  ];

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _toggleChatbot() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add({
        'text': userMessage,
        'isUser': true,
        'timestamp': DateTime.now(),
      });
      _messageController.clear();
    });

    // Simulate AI response after a delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': _getAIResponse(userMessage),
            'isUser': false,
            'timestamp': DateTime.now(),
          });
        });
      }
    });
  }

  String _getAIResponse(String userMessage) {
    // Simple response logic - this would be replaced with actual AI integration
    final message = userMessage.toLowerCase();

    if (message.contains('hello') || message.contains('hi')) {
      return 'Hello! How can I assist you with your skin health today?';
    } else if (message.contains('scan') || message.contains('analyze')) {
      return 'To analyze your skin condition, tap the "Scan Your Skin" button on the home screen. Make sure you have good lighting for better results!';
    } else if (message.contains('doctor') || message.contains('consult')) {
      return 'You can find qualified dermatologists in the Doctors section. Browse their profiles and contact them directly for consultations.';
    } else if (message.contains('profile') || message.contains('account')) {
      return 'You can manage your profile in the Profile section. Update your personal information and view your scan history there.';
    } else if (message.contains('help') || message.contains('support')) {
      return 'I\'m here to help! You can ask me about:\n• Skin analysis\n• Finding doctors\n• Managing your profile\n• App features\n• General skin care tips';
    } else {
      return 'That\'s an interesting question! For specific medical advice, I recommend consulting with a dermatologist from our Doctors section.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final double chatWidth = ResponsiveHelper.isMobile(context)
        ? MediaQuery.of(context).size.width * 0.9
        : 400.0;

    return Stack(
      children: [
        // Chatbot Interface
        if (_isExpanded)
          Positioned(
            bottom: 80,
            right: 20,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  width: chatWidth,
                  height: MediaQuery.of(context).size.height * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF3B9AE1), Color(0xFF6C5CE7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Image.asset(
                                  'assets/icon/logo.png',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'DermaSense AI Assistant',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: _toggleChatbot,
                            ),
                          ],
                        ),
                      ),

                      // Messages
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return _buildMessageBubble(message);
                          },
                        ),
                      ),

                      // Input Field
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: const Color(0xFFE0E0E0),
                                  ),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  decoration: const InputDecoration(
                                    hintText: 'Type your message...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: Color(0xFFBDC3C7),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF2C3E50),
                                  ),
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF3B9AE1),
                                    Color(0xFF6C5CE7),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                ),
                                onPressed: _sendMessage,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Floating Action Button
        Positioned(
          bottom: 20,
          right: 20,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isExpanded
                      ? [Colors.red, Colors.red.shade700]
                      : [const Color(0xFF3B9AE1), const Color(0xFF6C5CE7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isExpanded
                        ? Colors.red.withOpacity(0.3)
                        : const Color(0xFF3B9AE1).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FloatingActionButton(
                onPressed: _toggleChatbot,
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isExpanded
                      ? const Icon(
                          Icons.close,
                          key: ValueKey('close'),
                          color: Colors.white,
                          size: 28,
                        )
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            'assets/icon/logo.png',
                            key: const ValueKey('chat'),
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] as bool;
    final text = message['text'] as String;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF3B9AE1) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUser ? 16 : 4),
            topRight: Radius.circular(isUser ? 4 : 16),
            bottomLeft: const Radius.circular(16),
            bottomRight: const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: isUser ? Colors.white : const Color(0xFF2C3E50),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
