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
      botSubtitle: 'Sustainability Consultant',
      botLetter: 'S',
      threadId: 'sage',
      appBarColor: const Color(0xFF4A7FA5),
      backgroundColor: const Color(0xFFF0F7FB),
      welcomeText:
          "Hello! I'm Sage, your hotel sustainability consultant. Ask me about HACCP, waste reduction, or guest safety.",
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(AppRoutes.hotelDashboard),
      onAsk: ({required ownerId, required userMessage, required history}) =>
          AIChatService.askSage(
            hotelId: ownerId,
            userMessage: userMessage,
            history: history,
          ),
    );
  }
}
