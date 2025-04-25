import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:example/constants/uuid.dart';

part 'todo.freezed.dart';
part 'todo.g.dart';

typedef TodoId = String;

@freezed
@JsonSerializable()
class Todo with _$Todo {
  @override
  final TodoId id;
  @override
  final String title;
  @override
  final bool isDone;
  @override
  final bool isDeleted;

  Todo({
    TodoId? id,
    required this.title,
    this.isDone = false,
    this.isDeleted = false,
  }) : id = id ?? uuid.v4();

  factory Todo.fromJson(Map<String, dynamic> json) => _$TodoFromJson(json);

  Map<String, dynamic> toJson() => _$TodoToJson(this);
}
