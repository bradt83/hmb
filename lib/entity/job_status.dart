// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'dart:ui';

import '../util/hex_to_color.dart';
import 'entity.dart';

class JobStatus extends Entity<JobStatus> {
  JobStatus({
    required super.id,
    required this.name,
    required this.description,
    required this.colorCode,
    required this.hidden,
    required super.createdDate,
    required super.modifiedDate,
  }) : super();

  JobStatus.forInsert({
    required this.name,
    required this.description,
    required this.colorCode,
    this.hidden = 0, // Default value for new entries
  }) : super.forInsert();

  JobStatus.forUpdate({
    required super.entity,
    required this.name,
    required this.description,
    required this.colorCode,
    required this.hidden,
  }) : super.forUpdate();

  factory JobStatus.fromMap(Map<String, dynamic> map) => JobStatus(
        id: map['id'] as int,
        name: map['name'] as String,
        description: map['description'] as String,
        colorCode: map['color_code'] as String,
        hidden: map['hidden'] as int,
        createdDate: DateTime.parse(map['createdDate'] as String),
        modifiedDate: DateTime.parse(map['modifiedDate'] as String),
      );

  String name;
  String description;
  String colorCode;
  int hidden;

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'color_code': colorCode,
        'hidden': hidden,
        'createdDate': createdDate.toIso8601String(),
        'modifiedDate': modifiedDate.toIso8601String(),
      };

  Color getColour() => hexToColor(colorCode);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is JobStatus &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.colorCode == colorCode &&
        other.hidden == hidden &&
        other.createdDate == createdDate &&
        other.modifiedDate == modifiedDate;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      colorCode.hashCode ^
      hidden.hashCode ^
      createdDate.hashCode ^
      modifiedDate.hashCode;

  @override
  String toString() => 'id: $id, name: $name, description: $description';
}
