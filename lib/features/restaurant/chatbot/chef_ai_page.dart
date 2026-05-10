import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../services/ai_chat_service.dart';
import '../../shared/ai_chat_page_scaffold.dart';

class ChefAIChatPage extends StatelessWidget {
  const ChefAIChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AIChatPageScaffold(
      title: 'Chef AI',
      botId: 'chefai',
      botName: 'Chef AI',
      threadId: 'chefai',
      appBarColor: const Color(0xFF5C7A3E),
      backgroundColor: const Color(0xFFF2FAF0),
      welcomeText: "Hi! I'm Chef AI. How can I optimize your kitchen?",
      customAppBar: AppBar(
        backgroundColor: const Color(0xFF5C7A3E),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.restaurantDashboard),
          ),
        ),
        title: const _BotTitle(
          name: 'Chef AI',
          subtitle: 'Kitchen Assistant',
          accent: Color(0xFF5C7A3E),
          letter: 'C',
        ),
      ),
      onAsk: ({required ownerId, required userMessage, required history}) =>
          AIChatService.askChefAI(
            restaurantId: ownerId,
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
