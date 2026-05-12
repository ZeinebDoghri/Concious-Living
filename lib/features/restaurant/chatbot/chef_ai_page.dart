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
      botSubtitle: 'Kitchen Assistant',
      botLetter: 'C',
      threadId: 'chefai',
      appBarColor: const Color(0xFF5C7A3E),
      backgroundColor: const Color(0xFFF2FAF0),
      welcomeText:
          "Hi! I'm Chef AI, your kitchen operations assistant. Ask me about food safety, waste reduction, or kitchen workflow.",
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(AppRoutes.restaurantDashboard),
      onAsk: ({required ownerId, required userMessage, required history}) =>
          AIChatService.askChefAI(
            restaurantId: ownerId,
            userMessage: userMessage,
            history: history,
          ),
    );
  }
}
