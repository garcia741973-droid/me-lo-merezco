import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../models/admin_message.dart';
import '../services/communications_service.dart';

class ChatScreen extends StatefulWidget {
  final int otherUserId;
  final int currentUserId;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver {

  List<AdminMessage> messages = [];

  final TextEditingController controller =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  bool _loading = true;

  Timer? _pollingTimer;

  int? _lastMessageId;
  int _lastCount = 0;

  bool _sendingNow = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    loadMessages(forceScrollToBottom: true);

    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5), // aca se maneja el retardo bajamos 
      (_) => loadMessages(),
    );
  }

  bool _isNearBottom() {
    if (!scrollController.hasClients) return true;

    final max = scrollController.position.maxScrollExtent;
    final current = scrollController.position.pixels;

    return (max - current) <= 120;
  }

  Future<void> _scrollToBottom() async {

    await Future.delayed(
        const Duration(milliseconds: 60));

    if (!scrollController.hasClients) return;

    scrollController.jumpTo(
      scrollController.position.maxScrollExtent,
    );
  }

  Future<void> loadMessages(
      {bool forceScrollToBottom = false}) async {

    try {

      final wasNearBottom = _isNearBottom();

      final data =
          await CommunicationsService.getMessages(
        widget.otherUserId,
      );

      if (!mounted) return;

      final newCount = data.length;
      final newLastId =
          newCount > 0 ? data.last.id : null;

      final changed =
          (newCount != _lastCount) ||
          (newLastId != _lastMessageId);

      if (!changed) {

        if (_loading) {
          setState(() => _loading = false);
        }

        return;
      }

      bool hasNewIncoming = false;

      if (_lastMessageId != null &&
          newLastId != null) {

        final lastMsg = data.last;

        hasNewIncoming =
            (newLastId != _lastMessageId) &&
            (lastMsg.senderId !=
                widget.currentUserId);

      } else if (_lastMessageId == null &&
          newLastId != null) {

        final lastMsg = data.last;

        hasNewIncoming =
            lastMsg.senderId !=
                widget.currentUserId;
      }

      setState(() {

        messages = data;

        _loading = false;

        _lastCount = newCount;

        _lastMessageId = newLastId;

      });

      if (hasNewIncoming) {

        await CommunicationsService
            .markConversationAsRead(
          widget.otherUserId,
        );
      }

      if (forceScrollToBottom ||
          wasNearBottom ||
          _sendingNow) {

        _sendingNow = false;

        await _scrollToBottom();
      }

    } catch (_) {

      if (!mounted) return;

      setState(() => _loading = false);
    }
  }

  Future<void> send() async {

    final text = controller.text.trim();

    if (text.isEmpty) return;

    _sendingNow = true;

    await CommunicationsService.sendMessage(
      receiverId: widget.otherUserId,
      message: text,
    );

    controller.clear();

    await loadMessages(forceScrollToBottom: true);
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }  

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state) {

    if (state == AppLifecycleState.paused) {

      _pollingTimer?.cancel();
    }

    if (state == AppLifecycleState.resumed) {

      _startPolling();
    }
  }

  @override
  void dispose() {

    WidgetsBinding.instance.removeObserver(this);

    _pollingTimer?.cancel();

    controller.dispose();

    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        title: const Text("Chat"),
      ),

      body: Column(

        children: [

          Expanded(

            child: _loading

                ? const Center(
                    child: CircularProgressIndicator(),
                  )

                : ListView.builder(

                    controller: scrollController,

                    itemCount: messages.length,

              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.senderId == widget.currentUserId;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  child: Row(
                    mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [

                      if (!isMe)
                        const CircleAvatar(
                          radius: 14,
                          child: Icon(Icons.person, size: 16),
                        ),

                      if (!isMe) const SizedBox(width: 6),

                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.black
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(12),
                              topRight: const Radius.circular(12),
                              bottomLeft:
                                  Radius.circular(isMe ? 12 : 2),
                              bottomRight:
                                  Radius.circular(isMe ? 2 : 12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [

                              Text(
                                msg.message,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  color:
                                      isMe ? Colors.white : Colors.black,
                                ),
                              ),

                              const SizedBox(height: 4),

                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  _formatTime(msg.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
                  ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => send(),
                      decoration: const InputDecoration(
                        hintText: "Escribe un mensaje...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}