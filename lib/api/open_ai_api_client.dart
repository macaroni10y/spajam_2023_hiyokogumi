import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// client for handmade api (not calling open ai directly)
class ConversationApiClient {
  // var authority = Platform.isAndroid ? '10.0.2.2:8080' : 'localhost:8080';
  var authority = 'qepphvcqim.ap-northeast-1.awsapprunner.com';

  /// fetch conversation from server by conversationId
  ///
  /// usage:
  /// ```dart
  /// ConversationApiClient()
  ///   .fetchConversation("__conversationId__")
  ///   .then((value) => setState(() => _someState = value));
  /// ```
  Future<Conversation> fetchConversation(String conversationId) async {
    var response = await http.get(
      Uri.https(authority, '/conversation', {"conversationId": conversationId}),
    );
    return Conversation.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }

  /// submit a message and get response that contains whole conversation
  ///
  /// usage:
  /// ```dart
  /// ConversationApiClient()
  ///   .submitMessage("__conversationId__", "hello")
  ///   .then((value) => setState(() => _someState = value));
  /// ```
  Future<Conversation> submitMessage(
      String conversationId, String message) async {
    var response = await http.post(Uri.https(authority, '/conversation'),
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: json.encode({
          "prompt": message,
          "conversationId": conversationId,
          "needAllHistory": true
        }));
    return Conversation.fromJson(json.decode(utf8.decode(response.bodyBytes)));
  }
}

class Conversation {
  final String id;
  final List<Message> messages;

  Conversation(this.id, this.messages);

  Conversation.fromJson(Map<String, dynamic> json)
      : id = json['conversationId'],
        messages = (json['conversations'] as List<dynamic>)
            .map((e) => Message(e['text'], e['speaker']))
            .toList();
}

class Message {
  final String text;

  /// "user" or "assistant"
  final String speaker;

  Message(this.text, this.speaker);
}
