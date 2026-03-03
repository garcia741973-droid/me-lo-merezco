import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../services/communications_service.dart';
import 'chat_screen.dart';

class AdminCommunicationsScreen extends StatefulWidget {
  const AdminCommunicationsScreen({super.key});

  @override
  State<AdminCommunicationsScreen> createState() =>
      _AdminCommunicationsScreenState();
}

class _AdminCommunicationsScreenState
    extends State<AdminCommunicationsScreen> {

  List<Map<String, dynamic>> conversations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          await CommunicationsService.getAdminConversations();

      if (!mounted) return;

      setState(() {
        conversations = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      return const Scaffold();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Comunicaciones"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : conversations.isEmpty
              ? const Center(
                  child: Text("No hay conversaciones"),
                )
              : ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final item = conversations[index];

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          item['name']
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                        ),
                      ),
                      title: Text(item['name']),
                      subtitle: Text(
                        item['last_message'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        item['role'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              otherUserId: item['id'],
                              currentUserId: currentUser.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}