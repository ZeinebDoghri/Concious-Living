import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../services/ai_chat_service.dart';
import '../../shared/ai_chat_page_scaffold.dart';

class SageChatPage extends StatelessWidget {
  const SageChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AIChatPageScaffold(
      title: 'Sage',
      botId: 'sage',
      botName: 'Sage',
      threadId: 'sage',
      appBarColor: const Color(0xFF4A7FA5),
      backgroundColor: const Color(0xFFF0F7FB),
      welcomeText: "Hello! I'm Sage. What would you like to optimize?",
      customAppBar: AppBar(
        backgroundColor: const Color(0xFF4A7FA5),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.hotelDashboard),
          ),
        ),
        title: const _BotTitle(
          name: 'Sage',
          subtitle: 'Sustainability Consultant',
          accent: Color(0xFF4A7FA5),
          letter: 'S',
        ),
      ),
      onAsk: ({required ownerId, required userMessage, required history}) =>
          AIChatService.askSage(
            hotelId: ownerId,
            userMessage: userMessage,
            history: history,
          ),
    );
  }
}

class _BotTitle extends StatelessWidget {
  final String name;
  final String subtitle;
  final Color accent;
  final String letter;

  const _BotTitle({
    required this.name,
    required this.subtitle,
    required this.accent,
    required this.letter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.white,
          radius: 18,
          child: Text(
            letter,
            style: TextStyle(color: accent, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
