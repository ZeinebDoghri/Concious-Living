import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../services/ai_chat_service.dart';
import '../../shared/ai_chat_page_scaffold.dart';

class NoraChatPage extends StatelessWidget {
  const NoraChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AIChatPageScaffold(
      title: 'Nora',
      botId: 'nora',
      botName: 'Nora',
      botSubtitle: 'AI Nutritionist',
      botLetter: 'N',
      threadId: 'nora',
      appBarColor: const Color(0xFF45C4B0),
      backgroundColor: const Color(0xFFF0FFF4),
      welcomeText:
          "Hi! I'm Nora, your AI nutritionist. Ask me anything about your diet, nutrients, or health goals.",
      onBack: () => context.canPop()
          ? context.pop()
          : context.go(AppRoutes.customerHome),
      onAsk: ({required ownerId, required userMessage, required history}) =>
          AIChatService.askNora(
            uid: ownerId,
            userMessage: userMessage,
            history: history,
          ),
    );
  }
}
