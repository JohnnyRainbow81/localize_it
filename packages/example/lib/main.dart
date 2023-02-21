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
          'Profile.Lea.This is another case\.'.tr,
          style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),  
      body: Center(
        child: Column(  
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(height: 100,
             width: 100, color:  Colors.pink,),
             Text('General.How are you doing all?'.tr),
            Text(
              // ignore: prefer_single_quotes
              'Choose your destiny'.tr
              ,
              style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 50,
            ),
            Text('Auth.JustAnotherKey.Hey People! How are you?'.tr),
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
