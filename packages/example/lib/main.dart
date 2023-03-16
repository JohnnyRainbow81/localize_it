import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

void main() {
  runApp(const CodeGenExample());
}

class CodeGenExample extends StatelessWidget {
  const CodeGenExample({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      home: ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              color: Colors.pink,
            ),
            Text('Hallo Leute. Geht das hier auch auf englisch?'.tr),
            Text('Auth.Login.Wie wird hiermit umgegangen? www\.gehdahin\.de'.tr),
            Text('Beispiel Idioten Apostroph: Stefan\'s Laden'.tr),
            Text('Brinkmann\'s Stube'.tr),
            Text('Moni\'s Bar'.tr)


          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String get tr => '';
}

