import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// Single-file LAN lobby with:
/// - Host creates a room (Room ID + display name)
/// - Others join via host IP + Room ID + display name
/// - Group chat (broadcast to all)
/// - Roster list with assigned player indices (host is Player 0)
/// - Turn system (who can send a "move")
/// Protocol (newline delimited):
///   JOIN|roomId|name
///   ASSIGN|roomId|index|name1,name2,...
///   ROSTER|roomId|name1,name2,...
///   CHAT|roomId|name|text
///   MOVE|roomId|index|move
///   TURN|roomId|index
///   ERROR|roomId|reason
///
/// Notes:
/// - Host runs a TCP server and *is* Player 0 (no client socket needed).
/// - Max players = 4 (host + 3 clients).
/// - This is a logical “room”; one server instance hosts one room.


class LanRoomGame extends StatefulWidget {
  const LanRoomGame({super.key});

  @override
  State<LanRoomGame> createState() => _LanRoomGameState();
}

class _LanRoomGameState extends State<LanRoomGame> {
  // --- Networking ---
  static const int port = 4567;
  ServerSocket? server;
  final List<Socket> _clients = []; // server-side
  Socket? clientSocket; // client-side
  bool isServer = false;

  // --- Room / Players ---
  static const int maxPlayers = 4;
  String? localIp;
  String roomId = '';
  String myName = '';
  int myIndex = -1; // host=0, client=assigned by server
  List<String> roster = []; // player names in index order

  // --- Game state ---
  int currentTurn = 0;
  final List<String> moves = List.filled(maxPlayers, '');

  // --- Chat ---
  final List<_ChatMsg> chat = [];

  // --- UI controllers ---
  final TextEditingController hostRoomCtrl = TextEditingController();
  final TextEditingController hostNameCtrl = TextEditingController(text: "Host");
  final TextEditingController joinIpCtrl = TextEditingController();
  final TextEditingController joinRoomCtrl = TextEditingController();
  final TextEditingController joinNameCtrl = TextEditingController(text: "Player");
  final TextEditingController moveCtrl = TextEditingController();
  final TextEditingController chatCtrl = TextEditingController();

  final ScrollController chatScroll = ScrollController();
  final ScrollController rosterScroll = ScrollController();

  String status = 'Idle';

  @override
  void initState() {
    super.initState();
    _loadIp();
  }

  Future<void> _loadIp() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      setState(() => localIp = ip ?? 'Unknown');
    } catch (_) {
      setState(() => localIp = 'Unknown');
    }
  }

  // =========================
  // ===== Server logic  =====
  // =========================

  Future<void> startServerAndCreateRoom() async {
    if (hostRoomCtrl.text.trim().isEmpty || hostNameCtrl.text.trim().isEmpty) {
      _toast('Enter Room ID and your Name');
      return;
    }
    roomId = hostRoomCtrl.text.trim();
    myName = hostNameCtrl.text.trim();

    // Initialize room with host as Player 0
    roster = [myName];
    myIndex = 0;
    currentTurn = 0;
    for (int i = 0; i < maxPlayers; i++) {
      moves[i] = '';
    }
    chat.clear();

    try {
      server?.close();
      server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      isServer = true;

      server!.listen((Socket sock) {
        // Accept connection but wait for a valid JOIN before adding to room
        sock.listen(
              (data) => _serverHandleData(sock, data),
          onDone: () => _serverHandleDisconnect(sock),
          onError: (_) => _serverHandleDisconnect(sock),
        );
      });

      setState(() {
        status = 'Server started on $localIp:$port — Room "$roomId"';
      });
    } catch (e) {
      setState(() {
        status = 'Failed to start server: $e';
      });
    }
  }

  void _serverHandleData(Socket sock, List<int> bytes) {
    final text = utf8.decode(bytes);
    // Handle multiple newline-delimited frames
    for (final line in text.split('\n')) {
      final msg = line.trim();
      if (msg.isEmpty) continue;

      final parts = msg.split('|');
      final type = parts[0];

      if (type == 'JOIN' && parts.length >= 3) {
        final joinRoom = parts[1];
        final name = parts.sublist(2).join('|'); // allow '|' in names if needed

        if (joinRoom != roomId) {
          _sendLine(sock, 'ERROR|$roomId|Wrong room');
          return;
        }
        if (roster.length >= maxPlayers) {
          _sendLine(sock, 'ERROR|$roomId|Room full');
          return;
        }

        // Accept player
        _clients.add(sock);
        roster.add(name);
        final assignedIndex = roster.length - 1;

        // Send assignment + full roster to the new client
        _sendLine(sock, 'ASSIGN|$roomId|$assignedIndex|${roster.join(',')}');

        // Notify everyone about new roster
        _serverBroadcast('ROSTER|$roomId|${roster.join(',')}');

        setState(() {
          status = '$name joined. Players: ${roster.length}/$maxPlayers';
        });

      } else if (type == 'CHAT' && parts.length >= 3) {
        final msgRoom = parts[1];
        if (msgRoom != roomId) return;
        // CHAT|room|name|text (text may contain pipes; rejoin)
        final name = parts[2];
        final textRaw = parts.length >= 4 ? parts.sublist(3).join('|') : '';
        final item = _ChatMsg(name: name, text: textRaw, when: DateTime.now());
        chat.add(item);
        _serverBroadcast('CHAT|$roomId|$name|$textRaw');
        _scrollChatSoon();
        setState(() {});

      } else if (type == 'MOVE' && parts.length >= 4) {
        final msgRoom = parts[1];
        if (msgRoom != roomId) return;
        final index = int.tryParse(parts[2]) ?? -1;
        final mv = parts.sublist(3).join('|');

        if (index < 0 || index >= maxPlayers) return;
        // Turn gate on server side
        if (index != currentTurn) {
          _sendLine(sock, 'ERROR|$roomId|Not your turn');
          return;
        }
        moves[index] = mv;
        currentTurn = (currentTurn + 1) % roster.length;
        _serverBroadcast('MOVE|$roomId|$index|$mv');
        _serverBroadcast('TURN|$roomId|$currentTurn');
        setState(() {});
      }
    }
  }

  void _serverHandleDisconnect(Socket sock) {
    // Remove disconnected client from _clients and roster
    final idxInClients = _clients.indexOf(sock);
    if (idxInClients >= 0) {
      // Map client index to player index:
      // host is 0, clients are 1..roster.length-1 in the same order they joined.
      final playerIndex = idxInClients + 1; // since host occupies index 0
      String name = (playerIndex >= 0 && playerIndex < roster.length)
          ? roster[playerIndex]
          : 'Player';

      _clients.removeAt(idxInClients);
      if (playerIndex >= 0 && playerIndex < roster.length) {
        roster.removeAt(playerIndex);
        // Fix moves array (compact) for display: reset and keep length
        for (int i = 0; i < maxPlayers; i++) {
          moves[i] = (i < roster.length) ? moves[i] : '';
        }
        // Adjust currentTurn if needed
        if (currentTurn >= roster.length) currentTurn = 0;
        _serverBroadcast('ROSTER|$roomId|${roster.join(',')}');
        _serverBroadcast('TURN|$roomId|$currentTurn');
      }
      setState(() {
        status = '$name disconnected.';
      });
    }
    try {
      sock.destroy();
    } catch (_) {}
  }

  void _serverBroadcast(String line) {
    for (final c in _clients) {
      _sendLine(c, line);
    }
  }

  void _sendLine(Socket sock, String line) {
    try {
      sock.write('$line\n');
    } catch (_) {
      // ignore
    }
  }

  // =========================
  // ===== Client logic  =====
  // =========================

  Future<void> connectAsClient() async {
    final ip = joinIpCtrl.text.trim();
    final rid = joinRoomCtrl.text.trim();
    final nm = joinNameCtrl.text.trim();

    if (ip.isEmpty || rid.isEmpty || nm.isEmpty) {
      _toast('Enter IP, Room ID, and Name');
      return;
    }

    try {
      clientSocket?.destroy();
      clientSocket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      setState(() => status = 'Connected. Joining room...');

      clientSocket!.listen(
        _clientHandleBytes,
        onDone: _clientDisconnected,
        onError: (_) => _clientDisconnected(),
      );

      // Send JOIN
      _clientSend('JOIN|$rid|$nm');
    } catch (e) {
      setState(() => status = 'Connection failed: $e');
      _toast('Connection failed');
    }
  }

  void _clientHandleBytes(List<int> data) {
    final text = utf8.decode(data);
    for (final line in text.split('\n')) {
      final msg = line.trim();
      if (msg.isEmpty) continue;

      final parts = msg.split('|');
      final type = parts[0];

      if (type == 'ASSIGN' && parts.length >= 4) {
        // ASSIGN|room|index|rosterCSV
        roomId = parts[1];
        myIndex = int.tryParse(parts[2]) ?? -1;
        roster = parts[3].isEmpty ? [] : parts[3].split(',');
        setState(() {
          status = 'Joined room "$roomId" as Player $myIndex';
        });

      } else if (type == 'ROSTER' && parts.length >= 3) {
        final rid = parts[1];
        if (roomId.isEmpty) roomId = rid;
        if (rid != roomId) continue;
        roster = parts[2].isEmpty ? [] : parts[2].split(',');
        // Adjust turn if necessary
        if (currentTurn >= roster.length) currentTurn = 0;
        setState(() {});

      } else if (type == 'CHAT' && parts.length >= 4) {
        final rid = parts[1];
        if (rid != roomId) continue;
        final name = parts[2];
        final textRaw = parts.sublist(3).join('|');
        chat.add(_ChatMsg(name: name, text: textRaw, when: DateTime.now()));
        _scrollChatSoon();
        setState(() {});

      } else if (type == 'MOVE' && parts.length >= 4) {
        final rid = parts[1];
        if (rid != roomId) continue;
        final idx = int.tryParse(parts[2]) ?? -1;
        final mv = parts.sublist(3).join('|');
        if (idx >= 0 && idx < maxPlayers) {
          moves[idx] = mv;
          setState(() {});
        }

      } else if (type == 'TURN' && parts.length >= 3) {
        final rid = parts[1];
        if (rid != roomId) continue;
        currentTurn = int.tryParse(parts[2]) ?? currentTurn;
        setState(() {});

      } else if (type == 'ERROR' && parts.length >= 3) {
        final reason = parts.sublist(2).join('|');
        _toast('Server error: $reason');
      }
    }
  }

  void _clientSend(String line) {
    try {
      clientSocket?.write('$line\n');
    } catch (_) {}
  }

  void _clientDisconnected() {
    setState(() {
      status = 'Disconnected from server';
      myIndex = -1;
      roster = [];
    });
    try {
      clientSocket?.destroy();
    } catch (_) {}
    clientSocket = null;
  }

  // =========================
  // ===== Shared actions ====
  // =========================

  bool get isConnectedAsClient => !isServer && clientSocket != null;
  bool get iAmInRoom => isServer || isConnectedAsClient;
  bool get myTurn => iAmInRoom && myIndex == currentTurn && myIndex >= 0 && myIndex < roster.length;

  void sendChat() {
    if (!iAmInRoom) return;
    final txt = chatCtrl.text.trim();
    if (txt.isEmpty) return;
    chatCtrl.clear();

    if (isServer) {
      final item = _ChatMsg(name: myNameOrFallback(), text: txt, when: DateTime.now());
      chat.add(item);
      _serverBroadcast('CHAT|$roomId|${myNameOrFallback()}|$txt');
      _scrollChatSoon();
      setState(() {});
    } else {
      _clientSend('CHAT|$roomId|${myNameOrFallback()}|$txt');
    }
  }

  void sendMove() {
    if (!myTurn) {
      _toast("It's not your turn.");
      return;
    }
    final mv = moveCtrl.text.trim();
    if (mv.isEmpty) return;
    moveCtrl.clear();

    if (isServer) {
      // Host acts as player 0 locally
      moves[myIndex] = mv;
      currentTurn = (currentTurn + 1) % roster.length;
      _serverBroadcast('MOVE|$roomId|$myIndex|$mv');
      _serverBroadcast('TURN|$roomId|$currentTurn');
      setState(() {});
    } else {
      _clientSend('MOVE|$roomId|$myIndex|$mv');
    }
  }

  String myNameOrFallback() {
    if (isServer) return roster.isNotEmpty ? roster[0] : (myName.isEmpty ? 'Host' : myName);
    if (myIndex >= 0 && myIndex < roster.length) return roster[myIndex];
    return 'Me';
  }

  void resetRoomState() {
    if (!iAmInRoom) return;
    for (int i = 0; i < maxPlayers; i++) {
      moves[i] = '';
    }
    currentTurn = 0;
    setState(() {});
    if (isServer) {
      _serverBroadcast('TURN|$roomId|$currentTurn');
    }
  }

  @override
  void dispose() {
    try {
      server?.close();
    } catch (_) {}
    for (final c in _clients) {
      try {
        c.destroy();
      } catch (_) {}
    }
    try {
      clientSocket?.destroy();
    } catch (_) {}

    hostRoomCtrl.dispose();
    hostNameCtrl.dispose();
    joinIpCtrl.dispose();
    joinRoomCtrl.dispose();
    joinNameCtrl.dispose();
    moveCtrl.dispose();
    chatCtrl.dispose();
    chatScroll.dispose();
    rosterScroll.dispose();
    super.dispose();
  }

  // =========================
  // ========= UI ============
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LAN Rooms: 4-Player (Chat + Turns)'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildTopInfo(),
              const SizedBox(height: 8),
              if (!iAmInRoom) _buildLobbyChooser(),
              if (iAmInRoom) Expanded(child: _buildRoomView()),
              if (iAmInRoom) _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopInfo() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Status: $status',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        Text('Your IP: ${localIp ?? '...'}'),
      ],
    );
  }

  Widget _buildLobbyChooser() {
    return Column(
      children: [
        // HOST CARD
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Create Room (Host)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: hostRoomCtrl,
                      decoration: const InputDecoration(labelText: 'Room ID (e.g., HEZZ2-1234)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 160,
                    child: TextField(
                      controller: hostNameCtrl,
                      decoration: const InputDecoration(labelText: 'Your name'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: startServerAndCreateRoom,
                    child: const Text('Create'),
                  ),
                ]),
                const SizedBox(height: 6),
                Text('Others will join using your IP: ${localIp ?? '...'} and this Room ID.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // JOIN CARD
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Join Room (Client)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: joinIpCtrl,
                        decoration: const InputDecoration(labelText: 'Host IP (e.g., 192.168.1.10)'),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: joinRoomCtrl,
                        decoration: const InputDecoration(labelText: 'Room ID'),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: joinNameCtrl,
                        decoration: const InputDecoration(labelText: 'Your name'),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: connectAsClient,
                      child: const Text('Join'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomView() {
    return Row(
      children: [
        // Left: roster + moves
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Room: $roomId   •   Players: ${roster.length}/$maxPlayers',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text('Turn: P$currentTurn'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          controller: rosterScroll,
                          itemCount: maxPlayers,
                          itemBuilder: (_, i) {
                            final inUse = i < roster.length;
                            final name = inUse ? roster[i] : '—';
                            final mv = inUse && moves[i].isNotEmpty ? moves[i] : 'No move';
                            final isMe = i == myIndex;
                            final isTurn = i == currentTurn;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 2,
                                  color: isTurn ? Colors.blueAccent : Colors.black12,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text('P$i'),
                                ),
                                title: Text(
                                  '${isMe ? "(You) " : ""}$name',
                                  style: TextStyle(
                                    fontWeight: isTurn ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(mv),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Make a Move', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: moveCtrl,
                              enabled: myTurn,
                              decoration: InputDecoration(
                                labelText: myTurn ? 'Your move (e.g., "play 7♣", "draw")' : "Wait for your turn...",
                              ),
                              onSubmitted: (_) => sendMove(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: myTurn ? sendMove : null,
                            child: const Text('Send Move'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: iAmInRoom ? resetRoomState : null,
                            child: const Text('Reset Moves'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Right: chat
        Expanded(
          flex: 3,
          child: Card(
            elevation: 2,
            child: Column(
              children: [
                const SizedBox(height: 6),
                const Text('Group Chat', style: TextStyle(fontWeight: FontWeight.w600)),
                const Divider(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: chatScroll,
                    itemCount: chat.length,
                    itemBuilder: (_, i) {
                      final m = chat[i];
                      final isMe = m.name == myNameOrFallback();
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.name, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 2),
                              Text(m.text),
                              const SizedBox(height: 2),
                              Text(_hhmm(m.when), style: const TextStyle(fontSize: 10, color: Colors.black38)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatCtrl,
                          decoration: const InputDecoration(hintText: 'Type a message...'),
                          onSubmitted: (_) => sendChat(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: sendChat, child: const Text('Send')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Row(
      children: [
        if (isServer)
          ElevatedButton.icon(
            onPressed: () {
              // Simple end server for demo
              server?.close();
              for (final c in _clients) {
                try {
                  c.destroy();
                } catch (_) {}
              }
              _clients.clear();
              setState(() {
                isServer = false;
                status = 'Server stopped';
                roster.clear();
                myIndex = -1;
                roomId = '';
              });
            },
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Stop Server'),
          ),
        const SizedBox(width: 8),
        if (isConnectedAsClient)
          OutlinedButton.icon(
            onPressed: _clientDisconnected,
            icon: const Icon(Icons.logout),
            label: const Text('Leave Room'),
          ),
        const Spacer(),
        Text('You: ${myNameOrFallback()}  •  Index: ${myIndex >= 0 ? myIndex : '-'}'),
      ],
    );
  }

  // =========================
  // ===== Helpers ===========
  // =========================

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _hhmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _scrollChatSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatScroll.hasClients) {
        chatScroll.jumpTo(chatScroll.position.maxScrollExtent);
      }
    });
  }
}

class _ChatMsg {
  final String name;
  final String text;
  final DateTime when;
  _ChatMsg({required this.name, required this.text, required this.when});
}
