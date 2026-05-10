import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';

typedef AIChatCallback =
    Future<String> Function({
      required String ownerId,
      required String userMessage,
      required List<Map<String, String>> history,
    });

class AIChatPageScaffold extends StatefulWidget {
  final String title;
  final String botId;
  final String botName;
  final String threadId;
  final String welcomeText;
  final Color appBarColor;
  final Color backgroundColor;
  final PreferredSizeWidget? customAppBar;
  final AIChatCallback onAsk;

  const AIChatPageScaffold({
    super.key,
    required this.title,
    required this.botId,
    required this.botName,
    required this.threadId,
    required this.welcomeText,
    required this.appBarColor,
    required this.backgroundColor,
    this.customAppBar,
    required this.onAsk,
  });

  @override
  State<AIChatPageScaffold> createState() => _AIChatPageScaffoldState();
}

class _AIChatPageScaffoldState extends State<AIChatPageScaffold> {
  late final ChatUser _bot;
  ChatUser? _currentChatUser;
  List<ChatMessage> _messages = const [];
  bool _isLoading = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _bot = ChatUser(id: widget.botId, firstName: widget.botName);
    _loadMessages();
  }

  CollectionReference<Map<String, dynamic>>? _threadRef() {
    final uid =
        FirebaseAuth.instance.currentUser?.uid ??
        context.read<UserProvider>().currentUser?.id;
    if (uid == null || uid.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection('chatMessages')
        .doc(uid)
        .collection(widget.threadId);
  }

  String? _ownerId() {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      return FirebaseAuth.instance.currentUser?.uid;
    }
    if (user.role == 'restaurant' || user.role == 'hotel') {
      final venueId = user.entityId ?? user.restaurantId ?? user.hotelId;
      if (venueId != null && venueId.trim().isNotEmpty) {
        return venueId.trim();
      }
    }
    return user.id;
  }

  ChatMessage _welcomeMessage() {
    return ChatMessage(
      text: widget.welcomeText,
      user: _bot,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _loadMessages() async {
    final uid =
        FirebaseAuth.instance.currentUser?.uid ??
        context.read<UserProvider>().currentUser?.id ??
        'anonymous';
    final displayName = context.read<UserProvider>().currentUser?.name;
    _currentChatUser = ChatUser(
      id: uid,
      firstName: (displayName == null || displayName.trim().isEmpty)
          ? 'You'
          : displayName.trim(),
    );

    try {
      final ref = _threadRef();
      if (ref == null) {
        setState(() {
          _messages = [_welcomeMessage()];
          _isLoading = false;
        });
        return;
      }

      final snap = await ref
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      final loaded = snap.docs.map(_messageFromDoc).toList();
      setState(() {
        _messages = loaded.isEmpty ? [_welcomeMessage()] : loaded;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages = [_welcomeMessage()];
        _isLoading = false;
      });
      _showError(e);
    }
  }

  ChatMessage _messageFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final createdAt = data['createdAt'];
    final role = data['role']?.toString() ?? 'assistant';
    return ChatMessage(
      text: data['content']?.toString() ?? '',
      user: role == 'assistant' ? _bot : _currentChatUser!,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
    );
  }

  List<Map<String, String>> _history() {
    final welcome = widget.welcomeText.trim();
    return _messages.reversed
        .where((message) => message.text.trim().isNotEmpty)
        .where((message) => message.text.trim() != welcome)
        .map(
          (message) => {
            'role': message.user.id == _bot.id ? 'assistant' : 'user',
            'content': message.text,
          },
        )
        .toList(growable: false);
  }

  Future<void> _saveMessage(ChatMessage message) async {
    final ref = _threadRef();
    if (ref == null) throw StateError('Please sign in before chatting.');
    await ref.add({
      'role': message.user.id == _bot.id ? 'assistant' : 'user',
      'content': message.text,
      'createdAt': Timestamp.fromDate(message.createdAt),
    });
  }

  Future<void> _handleSend(ChatMessage message) async {
    final ownerId = _ownerId();
    if (ownerId == null || ownerId.isEmpty) {
      _showError(StateError('Please sign in before chatting.'));
      return;
    }

    setState(() {
      _messages = [message, ..._messages];
      _isTyping = true;
    });

    try {
      await _saveMessage(message);
      final answer = await widget.onAsk(
        ownerId: ownerId,
        userMessage: message.text,
        history: _history(),
      );
      final reply = ChatMessage(
        text: answer,
        user: _bot,
        createdAt: DateTime.now(),
      );
      await _saveMessage(reply);
      if (!mounted) return;
      setState(() => _messages = [reply, ..._messages]);
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString()), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentChatUser;
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: widget.customAppBar ??
          AppBar(
            backgroundColor: widget.appBarColor,
            foregroundColor: Colors.white,
            title: Text(widget.title),
          ),
      body: _isLoading || currentUser == null
          ? const Center(child: CircularProgressIndicator())
          : DashChat(
              currentUser: currentUser,
              onSend: _handleSend,
              messages: _messages,
              typingUsers: _isTyping ? [_bot] : const <ChatUser>[],
              messageOptions: const MessageOptions(borderRadius: 16),
            ),
    );
  }
}
