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
  // ProfileModel profile = ProfileModel();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green[600],
        title: Text(
          'Profile'.tr,
          style: TextStyle(
              fontSize: 44,
              color: Colors.green[100],
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              // ignore: prefer_single_quotes
              'Das ist ein ewig langer Text der nervt. Er geht sogar über mehrere Zeilen. Wenn das funktioniert, freue ich mich sehr.'.tr
              ,
              style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 50,
            ),
            Text("I\'m Chris.".tr),
            Text("Wie geht\'s? Mir geht\'s gut.".tr),
            Text('Funktioniert das hier auch?'.tr)
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String get tr => '';
}
