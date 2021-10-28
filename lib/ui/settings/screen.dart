import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('General'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.bug_report),
              title: Text('Bug Report'),
              subtitle: Text('File a new Issue'),
              onTap: () => launch(
                'https://github.com/AppleEducate/flutter_piano/issues/new',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsSubView extends StatelessWidget {
  SettingsSubView({
    required this.children,
    this.title = 'Settings',
  });
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: Column(children: children),
      ),
    );
  }
}
