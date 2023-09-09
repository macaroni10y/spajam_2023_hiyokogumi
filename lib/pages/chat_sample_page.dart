import 'package:flutter/material.dart';

import '../api/open_ai_api_client.dart';

class ChatSamplePage extends StatefulWidget {
  const ChatSamplePage({super.key});

  @override
  State<ChatSamplePage> createState() => _ChatSamplePageState();
}

class _ChatSamplePageState extends State<ChatSamplePage> {
  Conversation _conversation = Conversation('', List.empty(growable: true));
  final _controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Chat Sample Page"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() =>
                _conversation = Conversation('', List.empty(growable: true))),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // messages
            // _conversation.messages.isEmpty
            //     ? const Text("submit message")
                 Flexible(
                    child: ListView.builder(
                      itemCount: _conversation.messages.length,
                      itemBuilder: (BuildContext context, int index) => Card(
                        child: ListTile(
                          title: Text(_conversation.messages[index].text),
                        ),
                      ),
                    ),
                  ),
            // message bar
            SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey))),
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        enableSuggestions: true,
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'send a message',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_controller.text.isEmpty) return;
                        setState(() {
                          _conversation.messages.add(Message(
                              _controller.text, "user"));
                        });
                        ConversationApiClient()
                            .submitMessage(_conversation.id, _controller.text)
                            .then(
                                (value) => setState(() => _conversation = value));
                        _controller.clear();
                      },
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
