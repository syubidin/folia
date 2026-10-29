final class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.species,
    this.notes,
    this.imageName,
  });

  final String id;
  final String name;
  final String? species;
  final String? notes;
  final String? imageName;
  final DateTime createdAt;
  final DateTime updatedAt;
}

final class PlantInput {
  const PlantInput({
    required this.name,
    this.species,
    this.notes,
    this.imageName,
  });

  final String name;
  final String? species;
  final String? notes;
  final String? imageName;
}
