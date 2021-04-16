import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:minitodo/category.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'model/data_model.dart';

class DetailedTodo extends StatefulWidget {
  DetailedTodo({Key key, this.todoKey, this.fnplugin}) : super(key: key);
  final int todoKey;
  final FlutterLocalNotificationsPlugin fnplugin;
  @override
  _DetailedTodoState createState() => _DetailedTodoState();
}

class _DetailedTodoState extends State<DetailedTodo> {
  Box<TodoModel> _todoBox;
  TodoModel todo;

  final _addController = TextEditingController();
  final _shortNotesController = TextEditingController();
  List<String> subtask = [];
  List<bool> isSTDone = [];
  List<TextEditingController> _ttC = [];

  final ScrollController _scrollcontroller = new ScrollController();
  final GlobalKey<ScaffoldState> _skey = new GlobalKey<ScaffoldState>();
  bool isDone = false;

  int _type = 0;
  String _alarmDate = '';
  String _alarmText = '';
  bool isAlarmDone = false;
  bool isScheduled = false;
  tz.TZDateTime tzDatetime;
  String errorText;
  @override
  initState() {
    super.initState();
    tz.initializeTimeZones();

    _todoBox = Hive.box<TodoModel>('todoBox');
    todo = _todoBox.get(widget.todoKey);
    _addController.text = todo.title;
    _shortNotesController.text = todo.shortNotes;
    isDone = todo.isDone;
    _type = todo.category;
    _alarmDate = todo.alarmDate;
    if (_alarmDate.isNotEmpty) {
      var x = DateTime.parse(_alarmDate);
      _alarmText = '${x.day}/${x.month}, ${x.hour}:${x.minute}';
      if (x.difference(DateTime.now()) < Duration.zero) {
        isAlarmDone = true;
      } else {
        isScheduled = true;
      }
    }
    subtask = todo.subtask;

    if (subtask == null) {
      subtask = [''];
    }
    isSTDone = todo.isSubTaskDone;
    if (isSTDone == null) {
      isSTDone = [false];
    }
    _ttC = List<TextEditingController>.generate(
        subtask.length, (index) => TextEditingController()).toList();
  }

  @override
  void dispose() {
    _addController.dispose();
    _shortNotesController.dispose();
    _ttC.forEach((element) {
      element.dispose();
    });
    _ttC.clear();
    subtask.clear();
    isSTDone.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _skey,
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: Icon(Icons.delete_outline),
            onPressed: () {
              _todoBox.delete(widget.todoKey);
              Navigator.pop(context);
            },
          ),
          IconButton(
              icon: Icon(Icons.done),
              tooltip: 'Update changes',
              onPressed: () {
                List<String> lst = [];
                List<bool> ldone = [];
                for (var i = 0; i < subtask.length; i++) {
                  if (subtask[i].isNotEmpty) {
                    lst.add(subtask[i]);
                    ldone.add(isSTDone[i]);
                  }
                }

                if (_alarmDate.isNotEmpty) {
                  var x = DateTime.parse(_alarmDate);
                  if (x.difference(DateTime.now()) > Duration.zero) {
                    print('added');
                    tzDatetime = tz.TZDateTime.from(x, tz.local);
                    print(tzDatetime);
                    _showNotification(widget.todoKey, tzDatetime,
                        _addController.text, GroupColor.getColor(_type));
                  } else {
                    _alarmDate = '';
                  }
                } else if (isScheduled) {
                  print('cancelled');
                  _cancelNotifcation(widget.todoKey);
                }
                TodoModel a = TodoModel(
                    title: _addController.text,
                    isDone: isDone,
                    alarmDate: _alarmDate,
                    category: _type,
                    subtask: lst,
                    shortNotes: _shortNotesController.text,
                    isSubTaskDone: ldone);
                _todoBox.put(widget.todoKey, a);
                Navigator.pop(context);
              }),
        ],
        elevation: 0.0,
      ),
      body: Container(
        child: ListView(
          controller: _scrollcontroller,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 20),
              child: Row(
                children: [
                  Checkbox(
                      activeColor: GroupColor.getColor(_type),
                      onChanged: (bool value) {
                        setState(() {
                          isDone = value;
                        });
                        // _todoBox.put(widget.todoKey, todo);
                      },
                      value: isDone),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        if (_addController.text.length > 40) {
                          setState(() {
                            errorText = 'maximum character reached';
                          });
                        } else {
                          if (errorText != null) {
                            setState(() {
                              errorText = null;
                            });
                          }
                        }
                      },
                      style: isDone
                          ? TextStyle(
                              fontSize: 18,
                              decoration: TextDecoration.lineThrough,
                              fontStyle: FontStyle.italic)
                          : TextStyle(fontSize: 18),
                      controller: _addController,
                      maxLength: 40,
                      decoration: InputDecoration(
                        errorText: errorText,
                        counterText: '',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                          // borderRadius:
                          // BorderRadius.all(Radius.circular(10))
                        ),
                        // filled: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  color: Color.alphaBlend(
                      Color(0x08000000), Theme.of(context).accentColor),
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              padding: EdgeInsets.fromLTRB(20, 5, 20, 5),
              margin: EdgeInsets.fromLTRB(20, 5, 20, 5),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Catagory',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton.icon(
                          onPressed: () {
                            showDialog<int>(
                                context: context,
                                builder: (BuildContext context) => SimpleDialog(
                                    elevation: 0,
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    children: List.generate(2, (i) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(4, (j) {
                                          var n = (i * 4) + j;
                                          return IconButton(
                                            icon: Icon(Icons.circle,
                                                color: GroupColor.getColor(n)),
                                            onPressed: () {
                                              Navigator.pop(context, n);
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
                          },
                          icon: Icon(
                            Icons.fiber_manual_record_outlined,
                            color: GroupColor.getColor(_type),
                          ),
                          label: Text(
                            'Change',
                            style:
                                TextStyle(color: Theme.of(context).shadowColor),
                          ))
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Reminder',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: _alarmDate.isNotEmpty
                                    ? GroupColor.getColor(_type)
                                    : Colors.transparent),
                            onPressed: _alarmDate.isNotEmpty
                                ? () {
                                    setState(() {
                                      _alarmDate = '';
                                      isAlarmDone = false;
                                    });
                                  }
                                : null,
                          ),
                          TextButton.icon(
                            onPressed: () {
                              DateTime now = DateTime.now();
                              showDatePicker(
                                      builder: (context, child) => Theme(
                                          data: MyTheme.isDark
                                              ? ThemeData.dark()
                                              : ThemeData.light(),
                                          child: child),
                                      context: context,
                                      firstDate: now,
                                      initialDate: now,
                                      lastDate: DateTime(now.year + 3))
                                  .then((DateTime day) {
                                if (day != null) {
                                  now = DateTime.now();
                                  showTimePicker(
                                          builder: (context, child) => Theme(
                                              data: MyTheme.isDark
                                                  ? ThemeData.dark()
                                                  : ThemeData.light(),
                                              child: child),
                                          context: context,
                                          initialTime: TimeOfDay(
                                              hour: now.hour,
                                              minute: now.minute))
                                      .then((TimeOfDay time) {
                                    if (time != null) {
                                      var x = day.add(Duration(
                                          hours: time.hour,
                                          minutes: time.minute));
                                      if (x.difference(DateTime.now()) >
                                          Duration(microseconds: 0)) {
                                        setState(() {
                                          _alarmDate = x.toString();
                                          _alarmText =
                                              '${x.day}/${x.month}, ${x.hour}:${x.minute}';
                                          isAlarmDone = false;
                                        });

                                        // _showNotification(tzDatetime);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(new SnackBar(
                                                content: Text(
                                                    'Choose time in future')));
                                      }
                                    }
                                  });
                                }
                              });
                            },
                            label: _alarmDate.isNotEmpty
                                ? Text(
                                    _alarmText,
                                    style: TextStyle(
                                        color: Theme.of(context).shadowColor),
                                  )
                                : Text(
                                    'Add',
                                    style: TextStyle(
                                        color: Theme.of(context).shadowColor),
                                  ),
                            icon: isAlarmDone
                                ? Icon(
                                    Icons.alarm_on,
                                    size: 20,
                                    color: GroupColor.getColor(_type),
                                  )
                                : _alarmDate.isNotEmpty
                                    ? Icon(
                                        Icons.alarm,
                                        size: 20,
                                        color: GroupColor.getColor(_type),
                                      )
                                    : Icon(
                                        Icons.alarm_add,
                                        size: 20,
                                        color: GroupColor.getColor(_type),
                                      ),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: TextField(
                  controller: _shortNotesController,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: 100,
                  decoration: InputDecoration(
                    counterStyle: TextStyle(
                        color: Color.alphaBlend(Theme.of(context).shadowColor,
                            Theme.of(context).primaryColor)),
                    hintText: 'Add short notes here...',
                    hintStyle: TextStyle(color: Theme.of(context).shadowColor),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    filled: true,
                    // fillColor: Color(0xff2d2d44),
                  ),
                )),
            if (subtask != null)
              ListView(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                children: subtask
                    .asMap()
                    .map((key, value) {
                      _ttC[key].text = value;
                      return MapEntry(key, subtaskTile(key));
                    })
                    .values
                    .toList(),

                // children: subtask.map((e) {
                //   return subtaskTile(e, false);
                // }).toList(),
              ),
            TextButton(
                child: Text('+ Add subtask'),
                // textColor: Theme.of(context).shadowColor,
                onPressed: () {
                  _ttC.add(TextEditingController());
                  setState(() {
                    subtask.add('');
                    isSTDone.add(false);
                  });
                  _scrollcontroller.animateTo(
                      _scrollcontroller.position.maxScrollExtent,
                      duration: Duration(milliseconds: 100),
                      curve: Curves.fastOutSlowIn);
                }),
            SizedBox(
              height: 100,
            )
          ],
        ),
      ),
    );
  }

  Widget subtaskTile(int index) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Checkbox(
            activeColor: GroupColor.getColor(_type),
            onChanged: (bool value) {
              setState(() {
                isSTDone[index] = value;
              });
            },
            value: isSTDone[index],
            // value: false,
          ),
          Flexible(
            child: TextField(
              style: isSTDone[index]
                  ? TextStyle(
                      decoration: TextDecoration.lineThrough,
                      fontStyle: FontStyle.italic)
                  : TextStyle(),
              onChanged: (value) {
                subtask[index] = value;
              },
              controller: _ttC[index],
              maxLength: 40,
              decoration: InputDecoration(
                  hintText: 'subtask',
                  counterText: '',
                  hintStyle: TextStyle(color: Theme.of(context).shadowColor),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.transparent),
                  )),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
            ),
            onPressed: () {
              setState(() {
                _ttC.removeAt(index);
                isSTDone.removeAt(index);
                subtask.removeAt(index);
              });
            },
          )
        ],
      ),
    );
  }

  Future<void> _showNotification(id, date, reminderbody, color) async {
    var android = new AndroidNotificationDetails(
        'mt', 'minitodo', 'hellofromminitodo',
        priority: Priority.high, importance: Importance.max, color: color);
    var iOS = new IOSNotificationDetails();
    var platform = new NotificationDetails(android: android, iOS: iOS);
    await widget.fnplugin.zonedSchedule(
        id, 'Reminder', reminderbody, date, platform,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }

  void _cancelNotifcation(int todoKey) {
    widget.fnplugin.cancel(todoKey);
  }
}
