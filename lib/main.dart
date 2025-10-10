import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';
import 'package:web_socket_channel/io.dart';

void main() => runApp(const MaterialApp(home: WsDemo()));

class WsDemo extends StatefulWidget {
  const WsDemo({super.key});
  @override State<WsDemo> createState() => _WsDemoState();
}

class _WsDemoState extends State<WsDemo> {
  WebSocketChannel? ch;
  final List<String> log = [];
  final TextEditingController _messageField = TextEditingController();
  final TextEditingController _urlController = TextEditingController(text: 'ws://10.0.2.2:8000/ws');
  
  /// Applies a connection to the specified WebSocket Server
  Future<void> connect() async {
    // Establish connection
    final url = _urlController.text;
    try {
      final ws = await WebSocket.connect(url);
      debugPrint('CONNECTED');
      final ch = IOWebSocketChannel(ws);
      setState(() => this.ch = ch);

      // Message Handler
      ch.stream.listen((data) {
        // If client receives data, add '<<' to it
        setState(() => log.add('<< $data'));
      }, onError: (error) {
        // If client receives error, add 'ERROR:' to it
        setState(() => log.add('ERROR: $error'));
        this.ch = null;
      }, onDone: () {
        // If client disconnects, write 'DONE' (not possible in this example)
        setState(() => log.add('DONE'));
        this.ch = null;
      });
    } catch (error) {
      setState(() => log.add('ERROR: $error'));
    }
}

  /// Sends a message to the server
  /// @param text The message to send
  void send(String text) => ch?.sink.add(text);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Test Client')),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'WebSocket URL',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: connect, child: const Text('Connect')),
        ]),
      ),
      Row(children: [
      ElevatedButton(onPressed: () => send('ping'), child: const Text('Send ping')),
      ]),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _messageField,
              decoration: const InputDecoration(
                labelText: 'message',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            // If send button is pressed, print '>> [message]' for the client and empty the messageField
            onPressed: () {
              if (_messageField.text.isNotEmpty) {
                send(_messageField.text);
                setState(() => log.add('>> ${_messageField.text}'));
                _messageField.clear();
              }
            },
            child: const Text('send'),
          ),
        ]),
      ),
      const Divider(),
      Expanded(child: ListView(children: [for (final m in log) ListTile(title: Text(m))])),
    ]),
  );
}