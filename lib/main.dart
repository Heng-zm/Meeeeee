import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// Define the color palette
class AppColors {
  static const Color primaryColor = Color(0xFF3498db);
  static const Color secondaryColor = Color(0xFF2ecc71);
  static const Color backgroundColor = Color(0xFFf4f4f4);
  static const Color textColor = Color(0xFF2c3e50);
  static const Color buttonColor = Color(0xFF1abc9c);
  static const Color cardColor = Color(0xFFffffff);
}

// Define Typography
class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );
  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.textColor,
  );
  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}

// Define a reusable button
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  AppButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(AppColors.buttonColor),
        padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(vertical: 12, horizontal: 20)),
        shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      ),
      child: Text(label, style: AppTextStyles.buttonText),
    );
  }
}

// Define a reusable text field
class AppTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;

  AppTextField({required this.hintText, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppColors.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// Define a card component
class AppCard extends StatelessWidget {
  final String title;
  final String content;

  AppCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.heading),
            SizedBox(height: 8),
            Text(content, style: AppTextStyles.bodyText),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clock Alarm App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ClockScreen(),
    );
  }
}

class ClockScreen extends StatefulWidget {
  @override
  _ClockScreenState createState() => _ClockScreenState();
}

class _ClockScreenState extends State<ClockScreen> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  TimeOfDay _alarmTime = TimeOfDay.now();
  bool _alarmSet = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Initialize timezone
    tz.initializeTimeZones();

    final initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _setAlarm() async {
    final time = _alarmTime;

    final now = DateTime.now();
    final alarmTime =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    // Convert to TZDateTime
    final location = tz.getLocation('Asia/Phnom_Penh'); // Set your timezone
    final tzAlarmTime = tz.TZDateTime.from(alarmTime, location);

    if (tzAlarmTime.isBefore(tz.TZDateTime.now(location))) {
      // Set alarm for the next day
      _showNotification(tzAlarmTime.add(Duration(days: 1)));
    } else {
      _showNotification(tzAlarmTime);
    }

    setState(() {
      _alarmSet = true;
    });
  }

  Future<void> _showNotification(tz.TZDateTime scheduledTime) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Alarm!',
      'Time to wake up!',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Alarm Notifications',
          importance: Importance.max,
          priority: Priority.high,
          enableLights: true,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(''),
        ),
      ),
      androidAllowWhileIdle:
          true, // Allows notifications while the device is idle
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Match time for daily recurrence
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Clock App with Alarm'),
        backgroundColor: AppColors.primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to the Clock Alarm App!',
              style: AppTextStyles.heading,
            ),
            SizedBox(height: 20),
            AppCard(
              title: 'Card Title',
              content:
                  'This is the content inside the card component. You can add more details here.',
            ),
            SizedBox(height: 20),
            AppTextField(
              hintText: 'Enter your name',
              controller: _nameController,
            ),
            SizedBox(height: 20),
            AppButton(
              label: 'Submit',
              onPressed: () {
                print('Name: ${_nameController.text}');
              },
            ),
            SizedBox(height: 20),
            Text(
              'Current Time: ${DateFormat('hh:mm:ss a').format(DateTime.now())}',
              style: AppTextStyles.bodyText,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: _alarmTime,
                );
                if (picked != null && picked != _alarmTime) {
                  setState(() {
                    _alarmTime = picked;
                  });
                }
              },
              child: Text('Set Alarm Time'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _alarmSet ? null : _setAlarm,
              child: Text(_alarmSet ? 'Alarm Set' : 'Set Alarm'),
            ),
          ],
        ),
      ),
    );
  }
}
