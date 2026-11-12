import 'dart:convert';

final class PlantSpecies {
  const PlantSpecies({
    required this.slug,
    required this.scientificName,
    required this.names,
    this.waterEveryDays,
    this.petToxic,
  });

 factory PlantSpecies.fromJson(String slug, Map<String, dynamic> json) {
    final rawNames = json['names'] as Map<String, dynamic>? ?? {};
    return PlantSpecies(
      slug: slug,
      scientificName: json['scientificName'] as String? ?? slug,
      names: {
        for (final e in rawNames.entries) e.key: e.value as String,
      },
      waterEveryDays: (json['waterEveryDays'] as num?)?.toInt(),
      petToxic: json['petToxic'] as bool?,
    );
  }

  factory PlantSpecies.fromSlug(String slug) {
    final text = slug.replaceAll('_', ' ').trim();
    final pretty =
        text.isEmpty ? slug : text[0].toUpperCase() + text.substring(1);
    return PlantSpecies(slug: slug, scientificName: pretty, names: const {});
  }

  final String slug;
  final String scientificName;
  final Map<String, String> names;
  final int? waterEveryDays;
  final bool? petToxic;

  String displayName(String languageCode) =>
      names[languageCode] ?? names['en'] ?? scientificName;
}

final class PlantCatalog {
  PlantCatalog(this._bySlug);

  factory PlantCatalog.fromJson(String source) {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    return PlantCatalog({
      for (final e in raw.entries)
        e.key: PlantSpecies.fromJson(e.key, e.value as Map<String, dynamic>),
    });
  }

  final Map<String, PlantSpecies> _bySlug;

  PlantSpecies lookup(String slug) =>
      _bySlug[slug] ?? PlantSpecies.fromSlug(slug);
}
