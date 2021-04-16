// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TodoModelAdapter extends TypeAdapter<TodoModel> {
  @override
  final int typeId = 1;

  @override
  TodoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoModel(
      title: fields[0] as String,
      isDone: fields[1] as bool,
      category: fields[2] as int,
      alarmDate: fields[3] as String,
      shortNotes: fields[4] as String,
      subtask: (fields[5] as List)?.cast<String>(),
      isSubTaskDone: (fields[6] as List)?.cast<bool>(),
    );
  }

  @override
  void write(BinaryWriter writer, TodoModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.isDone)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.alarmDate)
      ..writeByte(4)
      ..write(obj.shortNotes)
      ..writeByte(5)
      ..write(obj.subtask)
      ..writeByte(6)
      ..write(obj.isSubTaskDone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
