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
  final String botSubtitle;
  final String botLetter;
  final String threadId;
  final String welcomeText;
  final Color appBarColor;
  final Color backgroundColor;
  final VoidCallback? onBack;
  final AIChatCallback onAsk;

  const AIChatPageScaffold({
    super.key,
    required this.title,
    required this.botId,
    required this.botName,
    required this.botSubtitle,
    required this.botLetter,
    required this.threadId,
    required this.welcomeText,
    required this.appBarColor,
    required this.backgroundColor,
    this.onBack,
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
    if (user == null) return FirebaseAuth.instance.currentUser?.uid;
    if (user.role == 'restaurant' || user.role == 'hotel') {
      final venueId = user.entityId ?? user.restaurantId ?? user.hotelId;
      if (venueId != null && venueId.trim().isNotEmpty) return venueId.trim();
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
      final snap = await ref.orderBy('createdAt', descending: true).limit(20).get();
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
        .where((m) => m.text.trim().isNotEmpty && m.text.trim() != welcome)
        .map((m) => {
              'role': m.user.id == _bot.id ? 'assistant' : 'user',
              'content': m.text,
            })
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

  Future<void> _clearChat() async {
    final ref = _threadRef();
    if (ref != null) {
      try {
        final snap = await ref.get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _messages = [_welcomeMessage()]);
  }

  Future<void> _handleSend(ChatMessage message) async {
    final ownerId = _ownerId();
    if (ownerId == null || ownerId.isEmpty) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear conversation'),
        content: const Text('Delete all messages in this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Clear',
                style: TextStyle(color: widget.appBarColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok == true) await _clearChat();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _currentChatUser;
    final accent = widget.appBarColor;

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: AppBar(
        backgroundColor: accent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: widget.onBack ?? () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Text(
                widget.botLetter,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.botName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.botSubtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: 'Clear chat',
            onPressed: _confirmClear,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading || currentUser == null
          ? Center(child: CircularProgressIndicator(color: accent))
          : DashChat(
              currentUser: currentUser,
              onSend: _handleSend,
              messages: _messages,
              typingUsers: _isTyping ? [_bot] : const <ChatUser>[],
              messageOptions: MessageOptions(
                borderRadius: 16,
                currentUserContainerColor: accent,
                containerColor: Colors.white,
                currentUserTextColor: Colors.white,
                textColor: const Color(0xFF1A1A2E),
                showTime: true,
                messagePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              inputOptions: InputOptions(
                inputDecoration: InputDecoration(
                  hintText: 'Write a message...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: accent.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: accent, width: 1.5),
                  ),
                ),
                sendButtonBuilder: (onSend) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: CircleAvatar(
                    backgroundColor: accent,
                    radius: 22,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 18),
                      onPressed: onSend,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
