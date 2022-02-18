import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late AndroidNotificationChannel channel;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  TextEditingController _controller = TextEditingController();
  TextEditingController _bodyController = TextEditingController();
  TextEditingController _titleController = TextEditingController();
  String? mToken;
  @override
  void initState() {
    super.initState();
    requestPermission();
    loadFCM();
    listenFCM();
    getToken();

    FirebaseMessaging.instance.subscribeToTopic("Animal");
  }

  void sendPushMessage(String token, String body, String title) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAAO_HNQG4:APA91bEqF53YwGlht9daD5YXlBCE6qhQjaWsnU27Dl04-O7ocrsdVQtu0wyQkhfDIGujccVnsmBo2VJqDNEoIRk6CY3Gn9Jb_0idp0DzWFZfch-ebdFV8l31cXflWI7F3eNbb3n3HT20',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'body': body,
              'title': title,
            },
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done'
            },
            "to": token
          },
        ),
      );
    } catch (e) {
      print("error push notification");
    }
  }

  void getTokenFromFirestore() async {}

  void getToken() async {
    await FirebaseMessaging.instance.getToken().then((value) {
      setState(() {
        mToken = value;
      });
      saveToken(value!);
    });
  }

  void saveToken(String token) async {
    await FirebaseFirestore.instance.collection("UserToken").doc("User1").set({
      'token': token,
    });
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void listenFCM() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null && !kIsWeb) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              icon: 'launch_background',
            ),
          ),
        );
      }
    });
  }

  void loadFCM() async {
    if (!kIsWeb) {
      channel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        importance: Importance.high,
        enableVibration: true,
      );

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _controller,
            ),
            TextFormField(
              controller: _bodyController,
            ),
            TextFormField(
              controller: _titleController,
            ),
            GestureDetector(
              onTap: () async {
                String name = _controller.text.trim();
                String body = _bodyController.text;
                String title = _titleController.text;
                if (name != '') {
                  DocumentSnapshot snapshot = await FirebaseFirestore.instance
                      .collection("UserToken")
                      .doc(name)
                      .get();
                  print(snapshot['token']);
                  sendPushMessage(snapshot['token'],body,title);
                }
              },
              child: Container(
                height: 40,
                width: 200,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
