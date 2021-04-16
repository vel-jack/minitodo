import 'package:hive/hive.dart';
part 'data_model.g.dart';

@HiveType(typeId: 1)
class TodoModel {
  @HiveField(0)
  String title;
  @HiveField(1)
  bool isDone;
  @HiveField(2)
  int category;
  @HiveField(3)
  String alarmDate;
  @HiveField(4)
  String shortNotes;
  @HiveField(5)
  List<String> subtask;
  @HiveField(6)
  List<bool> isSubTaskDone;

  TodoModel(
      {this.title,
      this.isDone,
      this.category,
      this.alarmDate,
      this.shortNotes,
      this.subtask,
      this.isSubTaskDone});
}
