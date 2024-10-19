import 'package:chatapp/chat_list.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

void main() {
  runApp(MyChatApp());
}

class MyChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: ChatListScreen(isUser1: true, currentUser: '',), // Pass the required parameter
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String name;

  const ChatScreen({super.key, required this.name});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late WebSocketChannel channel;
  List<Message> messages = [];
  TextEditingController messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    connectToWebSocket();
  }

  void connectToWebSocket() {
    // Connect to WebSocket server
    channel = WebSocketChannel.connect(
      Uri.parse('ws://10.0.2.2:8080'),
    );

    // Listen for incoming messages
    channel.stream.listen(
      (dynamic data) {
        try {
          final Map<String, dynamic> messageData = jsonDecode(data.toString());
          setState(() {
            messages.add(Message(
              text: messageData['message'],
              isSender: messageData['sender'] == widget.name,
              sender: messageData['sender'],
            ));
          });
        } catch (e) {
          print('Error processing message: $e');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        // Attempt to reconnect
        Future.delayed(Duration(seconds: 5), connectToWebSocket);
      },
      onDone: () {
        print('WebSocket connection closed');
        // Attempt to reconnect
        Future.delayed(Duration(seconds: 5), connectToWebSocket);
      },
    );
  }

  void sendMessage() {
    if (messageController.text.isNotEmpty) {
      final messageData = {
        'message': messageController.text,
        'sender': widget.name,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Send message to server
      channel.sink.add(jsonEncode(messageData));
      
      messageController.clear();
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(messages[index]);
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    return Align(
      alignment: message.isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: message.isSender ? Colors.teal[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: message.isSender 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
          children: [
            if (!message.isSender)
              Text(
                message.sender,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            Text(
              message.text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class Message {
  final String text;
  final bool isSender;
  final String sender;

  Message({
    required this.text, 
    required this.isSender, 
    required this.sender,
  });
}
