// alerts_screen.dart
import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final alerts = [
      'High soil moisture detected!',
      'Temperature dropped below 10°C.',
      'Wind speed is high.',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: alerts.length,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, index) => ListTile(
          leading: Icon(Icons.warning, color: Colors.redAccent),
          title: Text(alerts[index]),
        ),
      ),
    );
  }
}
