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

void _showBroadcastDialog() {
  String? selectedRole;

  String? selectedInterest;

  List<dynamic> users = [];
  List<int> selectedIds = [];
  final TextEditingController messageController =
      TextEditingController();
  final TextEditingController searchController =
      TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> loadUsers() async {
            if (selectedRole == null) return;

            final data = await CommunicationsService.getUsersByRole(selectedRole!);

            setModalState(() {
              users = data;
            });
          }

          final filteredUsers = users.where((u) {
            final name = u['name'].toString().toLowerCase();
            return name.contains(searchController.text.toLowerCase());
          }).toList();

            return AlertDialog(
              title: const Text("Enviar mensaje específico"),

              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Rol",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "client",
                            child: Text("Clientes"),
                          ),
                          DropdownMenuItem(
                            value: "seller",
                            child: Text("Vendedores"),
                          ),
                        ],
                        onChanged: (value) async {
                          selectedRole = value;
                          await loadUsers();
                        },
                      ),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "Interés (opcional)",
                        ),
                        items: const [
                          DropdownMenuItem(value: "Tecnologia", child: Text("Tecnologia")),
                          DropdownMenuItem(value: "Deportes", child: Text("Deportes")),
                          DropdownMenuItem(value: "Cuidado personal", child: Text("Cuidado personal")),
                          DropdownMenuItem(value: "Ganaderia", child: Text("Ganaderia")),
                          DropdownMenuItem(value: "Ocio", child: Text("Ocio")),
                          DropdownMenuItem(value: "Electrodomesticos", child: Text("Electrodomesticos")),
                        ],
                        onChanged: (value) {
                          selectedInterest = value;
                        },
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          hintText: "Buscar usuario...",
                        ),
                        onChanged: (_) {
                          setModalState(() {});
                        },
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        height: 200,
                        child: ListView(
                          shrinkWrap: true,
                          children: filteredUsers.map((user) {
                            final id = user['id'];
                            final selected = selectedIds.contains(id);

                            return CheckboxListTile(
                              value: selected,
                              title: Text(user['name']),
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    selectedIds.add(id);
                                  } else {
                                    selectedIds.remove(id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: messageController,
                        decoration: const InputDecoration(
                          labelText: "Mensaje",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (messageController.text.trim().isEmpty) return;

                    if (selectedIds.isEmpty && selectedInterest == null) return;

                    await CommunicationsService.sendMessage(
                      receiverIds: selectedIds.isNotEmpty ? selectedIds : null,
                      interestTarget: selectedInterest,
                      message: messageController.text.trim(),
                    );

                    Navigator.pop(context);
                    _load();
                  },
                  child: const Text("Enviar"),
                ),
              ],
            );
        },
      );
    },
  );
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
          actions: [
            IconButton(
              icon: const Icon(Icons.campaign),
              onPressed: _showBroadcastDialog,
            ),
          ],
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
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          child: Text(
                            item['name']
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                          ),
                        ),

                        // 🔴 Indicador de no leído
                        if ((item['unread_count'] ?? 0) > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
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
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUserId: item['id'],
                            currentUserId: currentUser.id,
                          ),
                        ),
                      );

                      _load(); // 🔄 refresca lista al volver
                    },
                  );
                  },
                ),
    );
  }
}