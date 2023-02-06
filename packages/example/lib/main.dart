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
          'Profile.Profile'.tr,
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
              'Choose your destiny'.tr
              ,
              style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 50,
            ),
            Text('Auth.Login.I\'m Chris\.'.tr),
            Text('Main.How are you? I\'m fine'.tr),
            Text('Would this be a problem for you to be punctual tomorrow?'.tr),
            Text('Auth.This should work'.tr),
            Text('Auth.Login.Here is another line'.tr),
            Text('Auth.AnotherKey.Check this out'.tr)
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String get tr => '';  
}
