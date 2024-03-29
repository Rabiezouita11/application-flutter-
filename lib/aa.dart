import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:connectivity/connectivity.dart';
import 'package:intl/intl.dart';
import 'package:mailer/mailer.dart';
import 'dart:async';

import 'package:mailer/smtp_server/gmail.dart';

String getCurrentDateTime() {
  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
  return formatter.format(now);
}

sendMail() async {
  String username = 'rabie.zouita@esprit.tn';
  String password = '120997rabie';

  final smtpServer = gmail(username, password);
  // Use the SmtpServer class to configure an SMTP server:
  // final smtpServer = SmtpServer('smtp.domain.com');
  // See the named arguments of SmtpServer for further configuration
  // options.

  // Create our message.
  final message = Message()
    ..from = Address(username, 'Rabie Zouita')
    ..recipients.add('rabie.zouita@esprit.tn')
    //..ccRecipients.addAll(['destCc1@example.com', 'destCc2@example.com'])
    // ..bccRecipients.add(Address('bccAddress@example.com'))
    ..subject = 'Alert  :: 😀 :: ${DateTime.now()}'
    ..text = 'This is the plain text.\nThis is line 2 of the text part.'
    ..html = "<h1>Serre </h1>\n<p>En panne</p>";

  try {
    final sendReport = await send(message, smtpServer);
    print('Message sent: ' + sendReport.toString());
    exit(0);
  } on MailerException catch (e) {
    print('Message not sent.');
    for (var p in e.problems) {
      print('Problem: ${p.code}: ${p.msg}');
    }
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  Timer _timer;
  String currentTime;
  var _connectivityResult = ConnectivityResult.none;
  String counter;
  bool ledOn = true;
  bool ventil = true;
  String sensorReading;
  double temperature = 0;
  int battrie = 21;
  double humidity;
  double temperatureMax = 0;
  double temperatureMin = 0;

  final dataBase = FirebaseDatabase.instance.reference();

  @override
  void initState() {
    super.initState();

    currentTime = getCurrentDateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        currentTime = getCurrentDateTime();
      });
    });
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _connectivityResult = result;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  _MainScreenState() {
    dataBase.child('Air/humidity').once().then((snap) {}).then((value) {
      setState(() {});
    });
    dataBase.child('wifi/-Mq60v5w68GZEKuKEN7D').onChildChanged.listen((event) {
      DataSnapshot snap = event.snapshot;
      if (snap.key == 'time') {
        sensorReading = snap.value;
        setState(() {});
      }
    });


       dataBase.child('culture/air/temperature').onChildChanged.listen((event) {
      DataSnapshot snap = event.snapshot;
      if (snap.key == 'MaxT') {
        temperatureMax = snap.value;
        setState(() {});
      }
    });

      dataBase.child('culture/air/temperature').onChildChanged.listen((event) {
      DataSnapshot snap = event.snapshot;
      if (snap.key == 'MinT') {
        temperatureMin = snap.value;
        setState(() {});
      }
    });




       dataBase.child('EtatBattrie/').onChildChanged.listen((event) {
      DataSnapshot snap = event.snapshot;
      if (snap.key == 'Status') {
        battrie = snap.value;
        setState(() {});
      }
    });



    dataBase.child('Air/').onChildChanged.listen((event) {
      DataSnapshot snap = event.snapshot;
      if (snap.key == 'humidity') {
        humidity = snap.value;
        setState(() {});
      }
      if (snap.key == 'temperature') {
        temperature = snap.value;
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_connectivityResult == ConnectivityResult.none) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("No internet connection"),
              SizedBox(height: 16),
              Image(
                  image: AssetImage('assets/images/no_internet.gif'),
                  fit: BoxFit.cover),
            ],
          ),
        ),
      );
    }
    if (sensorReading == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("System is off ",
                  style: TextStyle(fontSize: 20, color: Colors.red)),
              Image(
                  image: AssetImage('assets/images/a.gif'), fit: BoxFit.cover),
              SizedBox(height: 40, width: 40),
              TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                ),
                onPressed: () async {
                  sendMail();
                },
                child: Text(
                  'Contact Administrateur',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
    DateTime sensorDateTime = DateTime.parse(sensorReading);
    Duration difference =
        DateTime.parse(currentTime).difference(sensorDateTime);
    if (difference.inSeconds >= 20) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text("System is off ",
                  style: TextStyle(fontSize: 20, color: Colors.red)),
              Image(
                  image: AssetImage('assets/images/a.gif'), fit: BoxFit.cover),
              SizedBox(height: 40, width: 40),
              TextButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                ),
                onPressed: () async {
                  sendMail();
                },
                child: Text(
                  'Contact Administrateur',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (temperature >= temperatureMax) {
      return Container(
        child: Image(
          image: AssetImage('assets/images/tempMax.gif'),
          
        ),
        
      );
    }
    
    if (temperature <= temperatureMin) {
      return Container(
        child: Image(
          image: AssetImage('assets/images/tempLow.gif'),
          
        ),
        
      );
    }
    if (battrie < 20) {
      return Container(
        child: Image(
          image: AssetImage('assets/images/battry.png'),
          
        ),
        
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.home),
        title: Text('Serre intillegente'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // image de la serre 
          Image(
            image: AssetImage('assets/images/0.png'),
            fit: BoxFit.cover,
          ),
          Text(
            'AgroControl',
            style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 35,
                fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 20,
          ),
       
        
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'time : ',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 10,
              ),
              Text(
                '$sensorReading',
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 30,
                    fontWeight: FontWeight.bold),
              )
            ],
          ),
        
        
        ],
      ),
    );
  }
}
