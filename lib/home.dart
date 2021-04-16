import 'package:backdrop/backdrop.dart';
import 'package:backdrop/scaffold.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:minitodo/category.dart';
import 'package:minitodo/config.dart';
import 'package:url_launcher/url_launcher.dart';

import 'DetailedTodo.dart';
import 'model/data_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Box<TodoModel> _todoBox;
  Box pref;
  bool isDark = false;
  bool isSort = false;
  final _addController = TextEditingController();
  List<int> _selectedTiles = [];
  List<int> _selectedKeys = [];
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String errorText;

  tz.TZDateTime tzDatetime;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _todoBox = Hive.box<TodoModel>('todoBox');
    pref = Hive.box('preferences');
    isDark = pref.get('isDark', defaultValue: false);
    var initSettingsAndroid = AndroidInitializationSettings('dot');
    var initSettingsIOS = IOSInitializationSettings();
    var initSettings = InitializationSettings(
        android: initSettingsAndroid, iOS: initSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initSettings);
    checkRemember();
  }

  @override
  void dispose() {
    _addController.dispose();
    Hive.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropScaffold(
      frontLayerBorderRadius: BorderRadius.zero,
      appBar: BackdropAppBar(
          automaticallyImplyLeading: false,
          primary: false,
          title: SafeArea(
            child: Text(
              'Mini Todo',
            ),
          ),
          actions: _selectedTiles.length > 0
              ? [
                  SafeArea(
                      child: IconButton(
                          tooltip: 'Delete Selected',
                          icon: Icon(Icons.delete_outline),
                          onPressed: () {
                            _selectedKeys.forEach((element) {
                              if (_todoBox.get(element).alarmDate.isNotEmpty) {
                                _cancelNotification(element);
                              }
                              _todoBox.delete(element);
                            });
                            setState(() {
                              _selectedTiles.clear();
                              _selectedKeys.clear();
                            });
                          })),
                  SafeArea(
                      child: Theme(
                    data: Theme.of(context).copyWith(
                      cardColor: Theme.of(context).primaryColor,
                    ),
                    child: PopupMenuButton(
                      tooltip: 'More',
                      elevation: isDark ? 2 : 8,
                      onSelected: (value) {
                        switch (value) {
                          case 1:
                            setState(() {
                              _selectedTiles.clear();
                              _selectedKeys.clear();
                              List<int> keys =
                                  _todoBox.keys.cast<int>().toList();
                              _selectedKeys = keys;
                              _selectedTiles =
                                  List<int>.generate(keys.length, (i) => i);
                            });
                            break;
                          case 2:
                            setState(() {
                              _selectedTiles.clear();
                              _selectedKeys.clear();
                            });
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem<int>(
                              child: Text('Select All'), value: 1),
                          PopupMenuItem<int>(
                              child: Text('Exit selection'), value: 2)
                        ];
                      },
                    ),
                  ))
                ]
              : [
                  SafeArea(
                    child: BackdropToggleButton(
                        color: Theme.of(context).shadowColor),
                  )
                ]),
      stickyFrontLayer: true,
      backLayer: Container(
          child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            onTap: () {
              List<int> keys = _todoBox.keys.cast<int>().toList();
              keys.forEach((element) {
                if (_todoBox.get(element).isDone) {
                  if (_todoBox.get(element).alarmDate.isNotEmpty) {
                    _cancelNotification(element);
                  }
                  _todoBox.delete(element);
                }
              });
              ScaffoldMessenger.of(context)
                  .showSnackBar(new SnackBar(content: Text('Done')));
            },
            title: Text('Delete completed'),
          ),
          ListTile(
            onTap: () {
              isDark = !isDark;

              pref.put('isDark', isDark);
              currentTheme.switchTheme(isDark);
            },
            title: isDark ? Text('Light mode') : Text('Dark mode'),
            trailing: isDark
                ? Icon(
                    Icons.lightbulb_outlined,
                    color: Theme.of(context).shadowColor,
                  )
                : Icon(
                    Icons.lightbulb,
                    color: Theme.of(context).shadowColor,
                  ),
          ),
          ListTile(
              onTap: () {
                setState(() {
                  isSort = !isSort;
                });
              },
              title: Text('Sort by category'),
              trailing: isSort
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).shadowColor,
                    )
                  : SizedBox()),
          ListTile(
            onTap: () async {
              const url =
                  'https://play.google.com/store/apps/details?id=com.emptybox.minitodo';
              if (await canLaunch(url)) {
                await launch(
                  url,
                  forceSafariVC: false,
                  forceWebView: false,
                );
              } else {
                throw 'Could not launch $url';
              }
            },
            title: Text('Rate on Google Play'),
            trailing: Icon(Icons.shop, color: Theme.of(context).shadowColor),
          ),
          ListTile(
            onTap: () async {
              const url =
                  'https://vel-jack.github.io/nothingbox/policy/minitodo';
              if (await canLaunch(url)) {
                await launch(url);
              } else {
                throw 'Could not launch $url';
              }
            },
            title: Text('Privacy Policy'),
            trailing:
                Icon(Icons.privacy_tip, color: Theme.of(context).shadowColor),
          )
        ],
      )),
      frontLayer: ValueListenableBuilder(
        valueListenable: _todoBox.listenable(),
        builder: (BuildContext context, Box<TodoModel> value, Widget child) {
          List<int> keys = value.keys.cast<int>().toList();
          List<int> keysSorted = [];
          if (isSort) {
            for (var k = 0; k < 8; k++) {
              keys.forEach((element) {
                if (_todoBox.get(element).category == k) {
                  keysSorted.add(element);
                }
              });
            }
            keys = keysSorted;
          }
          return _todoBox.length > 0
              ? Container(
                  child: ListView(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: ClampingScrollPhysics(),
                        itemCount: _todoBox.length,
                        itemBuilder: (BuildContext context, int index) {
                          int key = keys[index];
                          TodoModel t = value.get(key);
                          return Container(
                            color: (_selectedTiles.contains(index))
                                ? Colors.blue.withOpacity(0.1)
                                : Theme.of(context).primaryColor,
                            child: ListTile(
                              onLongPress: () {
                                if (!_selectedTiles.contains(index)) {
                                  setState(() {
                                    _selectedTiles.add(index);
                                    _selectedKeys.add(key);
                                  });
                                }
                              },
                              onTap: () {
                                if (_selectedTiles.isEmpty) {
                                  Navigator.push(context, MaterialPageRoute(
                                      builder: (BuildContext context) {
                                    return DetailedTodo(
                                        todoKey: key,
                                        fnplugin:
                                            flutterLocalNotificationsPlugin);
                                  }));
                                } else if (_selectedTiles.contains(index)) {
                                  setState(() {
                                    _selectedTiles.removeWhere(
                                        (element) => element == index);
                                    _selectedKeys.removeWhere(
                                        (element) => element == key);
                                  });
                                } else {
                                  setState(() {
                                    _selectedTiles.add(index);
                                    _selectedKeys.add(key);
                                  });
                                }
                              },
                              title: Text(t.title,
                                  style: t.isDone
                                      ? TextStyle(
                                          fontSize: 18,
                                          decoration:
                                              TextDecoration.lineThrough,
                                          fontStyle: FontStyle.italic)
                                      : TextStyle(
                                          fontSize: 18,
                                        )),
                              leading: Checkbox(
                                activeColor: GroupColor.getColor(t.category),
                                onChanged: (bool va) {
                                  TodoModel a = TodoModel(
                                      title: t.title,
                                      isDone: va,
                                      alarmDate: t.alarmDate,
                                      category: t.category,
                                      shortNotes: t.shortNotes,
                                      subtask: t.subtask,
                                      isSubTaskDone: t.isSubTaskDone);
                                  _todoBox.put(key, a);
                                },
                                value: t.isDone,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (t.alarmDate.isNotEmpty)
                                    Icon(
                                      Icons.alarm,
                                      size: 20.0,
                                      // color: Color(0xff9a9a9a),
                                      color: Theme.of(context).shadowColor,
                                    ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.fiber_manual_record_outlined,
                                    color: GroupColor.getColor(t.category),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 100.0)
                    ],
                  ),
                )
              : Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 100,
                        ),
                        Text(
                          'Tap + to add',
                        )
                      ]),
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(
          Icons.add,
        ),
        onPressed: () {
          int _type = 0;
          // _todoBox.deleteAll(_todoBox.keys);
          // addTodo(_addController.text);
          _selectedKeys.clear();
          _selectedTiles.clear();
          showModalBottomSheet(
              isScrollControlled: true,
              builder: (builder) {
                return Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: TextField(
                                controller: _addController,
                                autofocus: true,
                                maxLength: 40,
                                decoration: InputDecoration(
                                  counterStyle: TextStyle(
                                      color: Color.alphaBlend(
                                          Theme.of(context).shadowColor,
                                          Theme.of(context).primaryColor)),
                                ),
                              ),
                            ),
                            IconButton(
                                icon: Icon(
                                  Icons.fiber_manual_record_outlined,
                                  color: GroupColor.getColor(_type),
                                ),
                                onPressed: () {
                                  showDialog<int>(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          SimpleDialog(
                                              elevation: 0,
                                              backgroundColor: Theme.of(context)
                                                  .primaryColor,
                                              children: List.generate(2, (i) {
                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children:
                                                      List.generate(4, (j) {
                                                    var n = (i * 4) + j;
                                                    return IconButton(
                                                      icon: Icon(Icons.circle,
                                                          color: GroupColor
                                                              .getColor(n)),
                                                      onPressed: () {
                                                        Navigator.pop(
                                                            context, n);
                                                      },
                                                    );
                                                  }),
                                                );
                                              }))).then((value) {
                                    if (value != null)
                                      setState(() {
                                        _type = value;
                                      });
                                  });
                                }),
                          ],
                        ),
                      ),
                      ButtonBar(
                        children: [
                          TextButton(
                              child: Text(
                                'Cancel',
                                style: TextStyle(),
                              ),
                              onPressed: () {
                                _addController.clear();
                                Navigator.pop(context);
                              }),
                          TextButton(
                              child: Text(
                                'Add',
                              ),
                              onPressed: () {
                                if (_addController.text.isNotEmpty) {
                                  addTodo(_addController.text, _type);
                                  Navigator.pop(context);
                                }
                              })
                        ],
                      )
                    ],
                  ),
                );
              },
              context: context);
        },
      ),
    );
  }

  void addTodo(String text, int type) {
    text = text.length > 40 ? text.substring(0, 40) : text;
    _addController.clear();
    TodoModel t = TodoModel(
        title: text,
        isDone: false,
        category: type,
        alarmDate: '',
        shortNotes: '',
        subtask: [],
        isSubTaskDone: []);
    _todoBox.add(t);
  }

  void _cancelNotification(int element) {
    flutterLocalNotificationsPlugin.cancel(element);
  }

  void checkRemember() {
    DateTime x = DateTime.now().add(Duration(days: 3));
    tzDatetime = tz.TZDateTime.from(x, tz.local);
    print(tzDatetime);
    _showNotification(
        10000, tzDatetime, 'Have you completed all tasks?', Colors.red);
  }

  Future<void> _showNotification(id, date, reminderbody, color) async {
    var android = new AndroidNotificationDetails(
        'mt', 'minitodo', 'hellofromminitodo',
        priority: Priority.high, importance: Importance.max, color: color);
    var iOS = new IOSNotificationDetails();
    var platform = new NotificationDetails(android: android, iOS: iOS);
    await flutterLocalNotificationsPlugin.zonedSchedule(
        id, 'Reminder', reminderbody, date, platform,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }
}
