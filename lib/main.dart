import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:minitodo/config.dart';

import 'package:minitodo/model/data_model.dart';
import 'package:path_provider/path_provider.dart';

import 'home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  var dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
  Hive.registerAdapter(TodoModelAdapter());
  await Hive.openBox<TodoModel>('todoBox');
  await Hive.openBox('preferences');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Box pref;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    currentTheme.addListener(() {
      print('ok');
      setState(() {});
    });
    pref = Hive.box('preferences');
    currentTheme.switchTheme(pref.get('isDark', defaultValue: false));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mini Todo',
      themeMode: currentTheme.currentTheme(),
      darkTheme: ThemeData(
          primaryColorBrightness: Brightness.dark,
          brightness: Brightness.dark,
          indicatorColor: Colors.white,
          shadowColor: Colors.white,
          canvasColor: Color(0xff2d2d44),
          splashColor: Colors.white,
          unselectedWidgetColor: Colors.white,
          buttonTheme: ButtonThemeData(),
          textTheme: TextTheme(
                  button: TextStyle(),
                  bodyText1: TextStyle(),
                  bodyText2: TextStyle(),
                  subtitle1: TextStyle(),
                  subtitle2: TextStyle())
              .apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
          primaryColor: Color(0xff2d2d44),
          accentColor: Color(0xff2d2d44),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
              elevation: 4,
              backgroundColor: Color(0xffdddddd),
              foregroundColor: Color(0xff2d2d44))),
      theme: ThemeData(
          iconTheme: IconThemeData(color: Colors.black),
          textTheme: TextTheme(
                  bodyText1: TextStyle(),
                  bodyText2: TextStyle(),
                  subtitle1: TextStyle(),
                  subtitle2: TextStyle())
              .apply(
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
          splashColor: Color(0xff8f8faa),
          primaryColor: Colors.white,
          accentColor: Colors.white,
          canvasColor: Colors.white,
          floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Color(0xff2d2d44),
              foregroundColor: Colors.white)),
      home: MyHomePage(title: 'Mini Todo'),
    );
  }
}
