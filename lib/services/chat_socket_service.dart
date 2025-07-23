import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmedia/utils/constants.dart';
import 'dart:async';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  late IO.Socket socket;
  bool _isConnected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  Function(int)? onViewerCountUpdated;
  Function()? onStreamEnded;
  Function(dynamic)? onUserJoinedStream;
  Set<String> _pendingMessages = <String>{};

  // Add these variables to track connection state
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int MAX_RECONNECT_ATTEMPTS = 10;
  static const int RECONNECT_INTERVAL = 3; // seconds

  Function(dynamic)? onMessageReceived;
  Function(dynamic)? onCallReceived;
  Function(dynamic)? onCallEnded;
  Function(dynamic)? onUserJoined;
  Function(dynamic)? onUserLeft;

  Function(dynamic)? onSocketError;

  SocketService._internal();

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) {
      print('Socket already connected');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final socketToken = prefs.getString('socketToken');
      final userId = prefs.getString('user_id');

      if (socketToken == null || userId == null) {
        print('Missing credentials for socket connection');
        return;
      }

      socket = IO.io(
          BASE_URL,
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .setAuth({'token': socketToken})
              .enableAutoConnect()
              .enableReconnection()
              .setReconnectionAttempts(double.infinity)
              .setReconnectionDelay(1000)
              .build());

      socket.onConnect((_) {
        print('Socket Connected');
        _isConnected = true;
        socket.emit('openCall', userId);
        _startPingTimer();
        _setupMessageListeners();
        _setupLiveStreamListeners();
      });

      socket.onDisconnect((_) {
        print('Socket Disconnected');
        _isConnected = false;
        _scheduleReconnect();
      });

      socket.onError((error) {
        print('Socket Error: $error');
        _isConnected = false;
        _scheduleReconnect();
      });

      socket.onReconnect((_) {
        print('Socket Reconnected');
        _isConnected = true;
        socket.emit('openCall', userId);
      });

      // Connect the socket
      socket.connect();
    } catch (e) {
      print('Socket connection error: $e');
      _scheduleReconnect();
    }
  }

  //LIVES SOCKET IMPLEMENTATION

  void _setupLiveStreamListeners() {
    socket.off('viewerCount');
    socket.on('viewerCount', (count) {
      print('👁 Viewer Count Updated: $count');
      if (onViewerCountUpdated != null) onViewerCountUpdated!(count);
    });

    socket.off('ended');
    socket.on('ended', (data) {
      if (onStreamEnded != null) onStreamEnded!();
    });

    socket.off('joined');
    socket.on('joined', (data) {
      if (onUserJoinedStream != null) onUserJoinedStream!(data);
    });
  }

  void openStream(String streamId) {
    if (!_isConnected) return;
    print('broadcaster live join kar raha hai');
    socket.emit('openStream', streamId);
  }

  void joinStream(String streamId) {
    if (!_isConnected) return;
    print('user join kar raha hai');
    socket.emit('joinStream', streamId);
  }

  void leaveStream() {
    if (!_isConnected) return;
    socket.emit('leaveStream');
  }

  void endStream(String streamId) {
    if (!_isConnected) return;
    socket.emit('endStream', {'streamId': streamId});
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isConnected) {
        socket.emit('ping');
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_isConnected) {
        connect();
      }
    });
  }

  //  void _setupCallListeners() {
  //   // Incoming call notification
  //   socket.on('pickUp', (data) {
  //     print('Incoming call: $data');
  //     if (onCallReceived != null) {
  //       onCallReceived!(data);
  //     }
  //   });

  //   // Call ended notification
  //   socket.on('callEnded', (data) {
  //     print('Call ended: $data');
  //     if (onCallEnded != null) {
  //       onCallEnded!(data);
  //     }
  //   });

  //   // New user joined the call
  //   socket.on('userJoined', (data) {
  //     print('User joined: $data');
  //     if (onUserJoined != null) {
  //       onUserJoined!(data);
  //     }
  //   });

  //   // User left the call
  //   socket.on('userLeft', (data) {
  //     print('User left: $data');
  //     if (onUserLeft != null) {
  //       onUserLeft!(data);
  //     }
  //   });
  // }

  void _setupMessageListeners() {
    print('calllll huaaaaa');
    // Remove existing listeners first to prevent duplicates
    socket.off('receiveMessage');

    socket.on('receiveMessage', (data) {
      print('✅ Socket received message: $data');
      print('Received raw message: $data');
      try {
        // Ensure data is properly parsed
        var messageData = data;
        if (data is String) {
          messageData = jsonDecode(data);
        }

        // Validate that required fields exist
        if (messageData != null) {
          print('Processing received message: $messageData');
          if (onMessageReceived != null) {
            onMessageReceived!(messageData);
          }
        }
      } catch (e) {
        print('Error processing received message: $e');
        print('❌ Error parsing received message: $e');
      }
    });
  }

  void _setupErrorHandling() {
    socket.on('error', (error) {
      print('Socket Error: $error');
      if (onSocketError != null) {
        onSocketError!(error);
      }
    });

    socket.onDisconnect((_) {
      print('Socket Disconnected');
      _isConnected = false;
      _scheduleReconnect();
    });

    socket.onError((error) {
      print('Socket Error: $error');
      _isConnected = false;
      _scheduleReconnect();
    });
  }

  void initiateCall(String callId, String userId, List<String> otherId, String type) {
    if (!_isConnected) {
      print('Socket not connected. Cannot initiate call.');
      return;
    }

    socket.emit('callInit', {'callId': callId, 'userId': userId, 'otherIds': otherId, 'type': type});
  }

  void joinCall(String callId, String userId) {
    if (!_isConnected) {
      print('Socket not connected. Cannot join call.');
      return;
    }

    socket.emit('joinCall', {'callId': callId, 'userId': userId});
  }

  void endCall(String callId, String userId) {
    if (!_isConnected) {
      print('Socket not connected. Cannot end call.');
      return;
    }

    socket.emit('endCall', {'callId': callId, 'userId': userId});
  }

  void addParticipant(String callId, String userId) {
    if (!_isConnected) {
      print('Socket not connected. Cannot add participant.');
      return;
    }

    socket.emit('add', {'callId': callId, 'userId': userId});
  }

  void joinRoom(String roomId) {
    if (!_isConnected) {
      print('Socket not connected. Cannot join room.');
      connect().then((_) {
        socket.emit('join', roomId);
        print('Joining room after reconnect: $roomId');
      });
      return;
    }
    socket.emit('join', roomId);
    print('Joining room: $roomId');
  }

  // void sendMessage(
  //   String senderId,
  //   String roomId,
  //   String content,
  //   String entity,
  //   bool isbot,
  //   bool isSpeakerOn, {
  //   String? voice,
  //   String? replyTo,
  //   String? media,
  //   String? mediaType,
  //   String? mediaName,
  //   int? mediaSize,
  //   double? latitude,
  //   double? longitude,
  // }) async {
  //   if (!_isConnected) {
  //     print('Socket not connected. Cannot send message.');
  //     return;
  //   }

  //   final prefs = await SharedPreferences.getInstance();
  //   final deviceId = prefs.getString('deviceId') ?? 'unknown';

  //   final messageData = {
  //     'senderId': senderId,
  //     'entityId': roomId,
  //     'content': content,
  //     'entity': entity,
  //     'isBot': isbot,
  //     'voice': voice,
  //     'isSpeakerOn': isSpeakerOn,
  //     'replyTo': replyTo,
  //     'deviceId': deviceId,
  //     'timestamp': DateTime.now().toIso8601String(),
  //     'location': {'latitude': latitude, 'longitude': longitude},
  //     if (media != null) 'media': media,
  //     if (mediaType != null) 'mediaType': mediaType,
  //     if (mediaName != null) 'mediaName': mediaName,
  //     if (mediaSize != null) 'mediaSize': mediaSize,
  //   };

  //   print('Sending message: $messageData');
  //   socket.emit('sendMessage', jsonEncode(messageData));
  // }
  void sendMessage(
    String senderId,
    String roomId,
    String content,
    String entity,
    bool isbot,
    bool isSpeakerOn, {
    String? voice,
    String? replyTo,
    String? media,
    String? mediaType,
    String? mediaName,
    int? mediaSize,
    double? latitude,
    double? longitude,
  }) async {
    if (!_isConnected) {
      print('Socket not connected. Cannot send message.');
      return;
    }

    // Create unique message identifier to prevent duplicates
    final messageId = '${senderId}_${roomId}_${DateTime.now().millisecondsSinceEpoch}';

    // Check if this message is already being sent
    if (_pendingMessages.contains(messageId)) {
      print('Message already being sent, skipping duplicate: $messageId');
      return;
    }

    // Add to pending messages
    _pendingMessages.add(messageId);

    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('deviceId') ?? 'unknown';

      // Parse entity if it's a JSON string, otherwise use as-is
      dynamic parsedEntity;
      try {
        parsedEntity = jsonDecode(entity);
      } catch (e) {
        parsedEntity = entity;
      }

      final messageData = {
        'messageId': messageId, // Add unique message ID
        'senderId': senderId,
        'entityId': roomId,
        'content': content,
        'entity': parsedEntity, // Use parsed entity instead of JSON string
        'isBot': isbot,
        'voice': voice,
        'isSpeakerOn': isSpeakerOn,
        'replyTo': replyTo,
        'deviceId': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
        'location': {
          'latitude': latitude,
          'longitude': longitude
        },
        if (media != null) 'media': media,
        if (mediaType != null) 'mediaType': mediaType,
        if (mediaName != null) 'mediaName': mediaName,
        if (mediaSize != null) 'mediaSize': mediaSize,
      };

      print('Sending message: $messageData');

      // Emit the message
      socket.emit('sendMessage', messageData); // Don't double-encode JSON

      // Remove from pending after a short delay to prevent rapid duplicates
      Future.delayed(Duration(milliseconds: 500), () {
        _pendingMessages.remove(messageId);
      });
    } catch (e) {
      print('Error sending message: $e');
      _pendingMessages.remove(messageId);
    }
  }

  // void sendReplyMessage({
  //   required String senderId,
  //   required String roomId,
  //   required String content,
  //   required String replyToMessageId,
  //   String? entity,
  //   bool isbot = false,
  //   bool isSpeakerOn = false,
  //   String? voice,
  //   required String time,
  //   String? media,
  //   String? mediaType,
  //   String? mediaName,
  //   int? mediaSize,
  // }) {
  //   if (!_isConnected) {
  //     print('Socket not connected. Cannot send reply.');
  //     return;
  //   }

  //   final replyData = {
  //     'senderId': senderId,
  //     'entityId': roomId,
  //     'content': content,
  //     'replyTo': replyToMessageId,
  //     'entity': entity,
  //     'isBot': isbot,
  //     'isSpeakerOn': isSpeakerOn,
  //     'voice': voice,
  //     'timestamp': DateTime.now().toIso8601String(),
  //     if (media != null) 'media': media,
  //     if (mediaType != null) 'mediaType': mediaType,
  //     if (mediaName != null) 'mediaName': mediaName,
  //     if (mediaSize != null) 'mediaSize': mediaSize,
  //   };

  //   print('Sending reply: $replyData');
  //   socket.emit('sendMessage', jsonEncode(replyData));
  // }
  void sendReplyMessage({
    required String senderId,
    required String roomId,
    required String content,
    required String replyToMessageId,
    String? entity,
    bool isbot = false,
    bool isSpeakerOn = false,
    String? voice,
    required String time,
    String? media,
    String? mediaType,
    String? mediaName,
    int? mediaSize,
  }) {
    if (!_isConnected) {
      print('Socket not connected. Cannot send reply.');
      return;
    }

    // Create unique message identifier
    final messageId = '${senderId}_${roomId}_reply_${DateTime.now().millisecondsSinceEpoch}';

    // Check if this message is already being sent
    if (_pendingMessages.contains(messageId)) {
      print('Reply message already being sent, skipping duplicate: $messageId');
      return;
    }

    // Add to pending messages
    _pendingMessages.add(messageId);

    try {
      // Parse entity if it's a JSON string
      dynamic parsedEntity;
      if (entity != null) {
        try {
          parsedEntity = jsonDecode(entity);
        } catch (e) {
          parsedEntity = entity;
        }
      }

      final replyData = {
        'messageId': messageId, // Add unique message ID
        'senderId': senderId,
        'entityId': roomId,
        'content': content,
        'replyTo': replyToMessageId,
        'entity': parsedEntity,
        'isBot': isbot,
        'isSpeakerOn': isSpeakerOn,
        'voice': voice,
        'timestamp': DateTime.now().toIso8601String(),
        if (media != null) 'media': media,
        if (mediaType != null) 'mediaType': mediaType,
        if (mediaName != null) 'mediaName': mediaName,
        if (mediaSize != null) 'mediaSize': mediaSize,
      };

      print('Sending reply: $replyData');
      socket.emit('sendMessage', replyData); // Don't double-encode JSON

      // Remove from pending after a short delay
      Future.delayed(Duration(milliseconds: 500), () {
        _pendingMessages.remove(messageId);
      });
    } catch (e) {
      print('Error sending reply: $e');
      _pendingMessages.remove(messageId);
    }
  }

  void reactToMessage({
    required String messageId,
    required String reaction,
    required String entityId,
  }) {
    if (!_isConnected) {
      print('Socket not connected. Cannot send reaction.');
      return;
    }

    final reactionData = {
      'messageId': messageId,
      'reaction': reaction,
      'entityId': entityId,
    };

    print('Sending reaction: $reactionData');
    socket.emit('reactToMessage', reactionData); // Remove jsonEncode here
  }

  // Add this to handle incoming reaction updates
  void setupReactionHandlers(void Function(String, String, String) onReactionReceived) {
    socket.on('messageReaction', (data) {
      final decoded = jsonDecode(data);
      onReactionReceived(
        decoded['messageId'],
        decoded['userId'],
        decoded['reaction'],
      );
      print("Reactions under setupReactionHandlers" + decoded.toString());
    });
  }

  void disconnect() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
  }
}
