import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:io';
import 'package:web_socket_channel/io.dart'; // für Wrap

void main() => runApp(const MaterialApp(home: WsDemo()));

class WsDemo extends StatefulWidget {
  const WsDemo({super.key});
  @override State<WsDemo> createState() => _WsDemoState();
}

class _WsDemoState extends State<WsDemo> {
  WebSocketChannel? ch;
  final List<String> log = [];

  Future<void> connect() async {
  final url = 'ws://10.0.2.2:8000/ws';            // exakt ohne Slash/Fragment
  debugPrint('CONNECTING (raw): $url');

  try {
    final ws = await WebSocket.connect(url);      // direkter dart:io-Handshake
    debugPrint('CONNECTED OK');                   // sollte erreicht werden
    // optional: in WebSocketChannel wrappen, wenn du Streams nutzen willst
    final ch = IOWebSocketChannel(ws);
    setState(() => this.ch = ch);                 // falls du eine ch-Variable nutzt
    ch.stream.listen((data) {
      setState(() => log.add('<< $data'));
    }, onError: (e) {
      setState(() => log.add('ERROR: $e'));
      this.ch = null;
    }, onDone: () {
      setState(() => log.add('DONE'));
      this.ch = null;
    });
  } catch (e, st) {
    debugPrint('CONNECT ERROR: $e');
    debugPrint('$st');
    setState(() => log.add('ERROR: $e'));
  }
}

  void send() => ch?.sink.add('ping');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('WS Test')),
    body: Column(children: [
      Row(children: [
        ElevatedButton(onPressed: connect, child: const Text('Connect')),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: send, child: const Text('Send ping')),
      ]),
      const Divider(),
      Expanded(child: ListView(children: [for (final m in log) ListTile(title: Text(m))])),
    ]),
  );
}