final class Prediction {
  const Prediction({required this.label, required this.confidence});

  final String label;
  final double confidence;

  bool get isBackground => label.startsWith('_');
}

final class IdentificationPolicy {
  const IdentificationPolicy({
    this.accept = 0.70,
    this.minMargin = 0.25,
    this.reject = 0.10,
  });

  factory IdentificationPolicy.fromJson(Map<String, dynamic> json) =>
      IdentificationPolicy(
        accept: (json['accept'] as num?)?.toDouble() ?? 0.70,
        minMargin: (json['minMargin'] as num?)?.toDouble() ?? 0.25,
        reject: (json['reject'] as num?)?.toDouble() ?? 0.10,
      );

  final double accept;
  final double minMargin;
  final double reject;
}

sealed class IdentificationOutcome {
  const IdentificationOutcome();
}

final class Confident extends IdentificationOutcome {
  const Confident({required this.best, required this.alternatives});
  final Prediction best;
  final List<Prediction> alternatives;
}

final class Uncertain extends IdentificationOutcome {
  const Uncertain(this.candidates);
  final List<Prediction> candidates;
}

final class NoPlant extends IdentificationOutcome {
  const NoPlant();
}

IdentificationOutcome interpretScores({
  required List<double> scores,
  required List<String> labels,
  required IdentificationPolicy policy,
  int topK = 3,
}) {
  if (scores.length != labels.length || scores.isEmpty) {
    throw ArgumentError('scores and labels must have the same non-zero length');
  }
  final order = List<int>.generate(scores.length, (i) => i)
    ..sort((a, b) => scores[b].compareTo(scores[a]));
  final top = [
    for (final i in order.take(topK))
      Prediction(label: labels[i], confidence: scores[i]),
  ];

  final best = top.first;
  if (best.isBackground || best.confidence < policy.reject) {
    return const NoPlant();
  }
  final second = top.length > 1 ? top[1].confidence : 0.0;
  final plants = top.where((p) => !p.isBackground).toList(growable: false);

  if (best.confidence >= policy.accept &&
      best.confidence - second >= policy.minMargin) {
    return Confident(best: best, alternatives: plants.skip(1).toList());
  }
  return Uncertain(plants);
}
