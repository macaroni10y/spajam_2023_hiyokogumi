import 'package:flutter/material.dart';

import 'chat_sample_page.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Column(
        children: [
          const Text("samples"),
          Center(
            child: Card(
                child: ListTile(
                    title: const Text("Chat Sample"),
                    onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ChatSamplePage()),
                        ))),
          ),
        ],
      ));
}
