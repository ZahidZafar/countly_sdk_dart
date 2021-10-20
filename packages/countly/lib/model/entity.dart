abstract class Entity {
  int? id;

  Entity();

  @override
  String toString() {
    return 'Entity{id: $id}';
  }

  Map<String, dynamic> toJson();

  Entity.fromJson(Map<String, dynamic> json);
}
