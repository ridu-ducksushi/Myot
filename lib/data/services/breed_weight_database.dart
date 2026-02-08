/// Static database with breed weight ranges for dogs and cats.
///
/// Provides ideal weight ranges and weight status evaluation.
class BreedWeightDatabase {
  BreedWeightDatabase._();

  /// Find a breed entry by breed name (case-insensitive partial match).
  /// Returns null if not found.
  static BreedWeightRange? findBreed(String breedName) {
    final query = breedName.toLowerCase().trim();
    if (query.isEmpty) return null;

    // Exact match first
    for (final entry in _allBreeds) {
      if (entry.breedName.toLowerCase() == query) return entry;
    }
    // Partial match
    for (final entry in _allBreeds) {
      if (entry.breedName.toLowerCase().contains(query) ||
          query.contains(entry.breedName.toLowerCase())) {
        return entry;
      }
    }
    return null;
  }

  /// Find breeds by species.
  static List<BreedWeightRange> getBreedsForSpecies(String species) {
    final s = species.toLowerCase().trim();
    return _allBreeds.where((b) => b.species.toLowerCase() == s).toList();
  }

  /// Evaluate the weight status based on breed ideal range.
  ///
  /// Returns one of: 'underweight', 'normal', 'overweight', 'obese'.
  /// If no breed data is available, returns 'unknown'.
  static String evaluateWeightStatus({
    required double currentWeightKg,
    required BreedWeightRange range,
  }) {
    final idealMin = range.minWeightKg;
    final idealMax = range.maxWeightKg;
    final idealMid = (idealMin + idealMax) / 2;

    if (currentWeightKg < idealMin) {
      return 'underweight';
    } else if (currentWeightKg <= idealMax) {
      return 'normal';
    } else if (currentWeightKg <= idealMax * 1.2) {
      return 'overweight';
    } else {
      return 'obese';
    }
  }

  /// Evaluate weight status by breed name. Returns 'unknown' if breed not found.
  static String evaluateByBreedName({
    required String breedName,
    required double currentWeightKg,
  }) {
    final range = findBreed(breedName);
    if (range == null) return 'unknown';
    return evaluateWeightStatus(
      currentWeightKg: currentWeightKg,
      range: range,
    );
  }

  /// All breed entries.
  static List<BreedWeightRange> get allBreeds => List.unmodifiable(_allBreeds);

  // ---------------------------------------------------------------------------
  // Dog Breeds (40+)
  // ---------------------------------------------------------------------------
  static final List<BreedWeightRange> _allBreeds = [
    // Small dogs
    const BreedWeightRange(species: 'Dog', breedName: 'Chihuahua', minWeightKg: 1.5, maxWeightKg: 3.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Yorkshire Terrier', minWeightKg: 2.0, maxWeightKg: 3.2),
    const BreedWeightRange(species: 'Dog', breedName: 'Pomeranian', minWeightKg: 1.8, maxWeightKg: 3.5),
    const BreedWeightRange(species: 'Dog', breedName: 'Maltese', minWeightKg: 1.8, maxWeightKg: 3.6),
    const BreedWeightRange(species: 'Dog', breedName: 'Toy Poodle', minWeightKg: 2.0, maxWeightKg: 4.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Papillon', minWeightKg: 2.3, maxWeightKg: 4.5),
    const BreedWeightRange(species: 'Dog', breedName: 'Miniature Pinscher', minWeightKg: 3.5, maxWeightKg: 5.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Shih Tzu', minWeightKg: 4.0, maxWeightKg: 7.3),
    const BreedWeightRange(species: 'Dog', breedName: 'Cavalier King Charles Spaniel', minWeightKg: 5.4, maxWeightKg: 8.2),
    const BreedWeightRange(species: 'Dog', breedName: 'Miniature Poodle', minWeightKg: 5.0, maxWeightKg: 8.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Miniature Schnauzer', minWeightKg: 5.4, maxWeightKg: 8.2),
    const BreedWeightRange(species: 'Dog', breedName: 'Dachshund', minWeightKg: 4.5, maxWeightKg: 14.5),
    const BreedWeightRange(species: 'Dog', breedName: 'Pug', minWeightKg: 6.3, maxWeightKg: 8.2),
    const BreedWeightRange(species: 'Dog', breedName: 'French Bulldog', minWeightKg: 8.0, maxWeightKg: 14.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Jack Russell Terrier', minWeightKg: 5.0, maxWeightKg: 8.0),
    const BreedWeightRange(species: 'Dog', breedName: 'West Highland White Terrier', minWeightKg: 6.8, maxWeightKg: 9.1),
    const BreedWeightRange(species: 'Dog', breedName: 'Boston Terrier', minWeightKg: 4.5, maxWeightKg: 11.3),

    // Medium dogs
    const BreedWeightRange(species: 'Dog', breedName: 'Beagle', minWeightKg: 9.0, maxWeightKg: 11.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Cocker Spaniel', minWeightKg: 12.0, maxWeightKg: 15.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Corgi', minWeightKg: 10.0, maxWeightKg: 14.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Shetland Sheepdog', minWeightKg: 6.4, maxWeightKg: 12.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Border Collie', minWeightKg: 14.0, maxWeightKg: 20.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Australian Shepherd', minWeightKg: 18.0, maxWeightKg: 29.0),
    const BreedWeightRange(species: 'Dog', breedName: 'English Bulldog', minWeightKg: 18.0, maxWeightKg: 25.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Standard Poodle', minWeightKg: 20.0, maxWeightKg: 32.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Bull Terrier', minWeightKg: 22.0, maxWeightKg: 32.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Samoyed', minWeightKg: 16.0, maxWeightKg: 30.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Siberian Husky', minWeightKg: 16.0, maxWeightKg: 27.0),

    // Large dogs
    const BreedWeightRange(species: 'Dog', breedName: 'Labrador Retriever', minWeightKg: 25.0, maxWeightKg: 36.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Golden Retriever', minWeightKg: 25.0, maxWeightKg: 34.0),
    const BreedWeightRange(species: 'Dog', breedName: 'German Shepherd', minWeightKg: 22.0, maxWeightKg: 40.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Boxer', minWeightKg: 25.0, maxWeightKg: 32.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Doberman Pinscher', minWeightKg: 27.0, maxWeightKg: 45.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Rottweiler', minWeightKg: 36.0, maxWeightKg: 60.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Akita', minWeightKg: 32.0, maxWeightKg: 59.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Dalmatian', minWeightKg: 20.0, maxWeightKg: 32.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Weimaraner', minWeightKg: 25.0, maxWeightKg: 40.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Rhodesian Ridgeback', minWeightKg: 29.0, maxWeightKg: 41.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Belgian Malinois', minWeightKg: 20.0, maxWeightKg: 34.0),

    // Giant dogs
    const BreedWeightRange(species: 'Dog', breedName: 'Great Dane', minWeightKg: 45.0, maxWeightKg: 80.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Saint Bernard', minWeightKg: 54.0, maxWeightKg: 82.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Bernese Mountain Dog', minWeightKg: 35.0, maxWeightKg: 55.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Newfoundland', minWeightKg: 45.0, maxWeightKg: 70.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Mastiff', minWeightKg: 54.0, maxWeightKg: 100.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Irish Wolfhound', minWeightKg: 48.0, maxWeightKg: 70.0),
    const BreedWeightRange(species: 'Dog', breedName: 'Leonberger', minWeightKg: 41.0, maxWeightKg: 77.0),

    // Korean breeds
    const BreedWeightRange(species: 'Dog', breedName: 'Jindo', minWeightKg: 15.0, maxWeightKg: 23.0),

    // ---------------------------------------------------------------------------
    // Cat Breeds (20+)
    // ---------------------------------------------------------------------------
    const BreedWeightRange(species: 'Cat', breedName: 'Singapura', minWeightKg: 1.8, maxWeightKg: 3.6),
    const BreedWeightRange(species: 'Cat', breedName: 'Munchkin', minWeightKg: 2.7, maxWeightKg: 4.1),
    const BreedWeightRange(species: 'Cat', breedName: 'Devon Rex', minWeightKg: 2.3, maxWeightKg: 4.5),
    const BreedWeightRange(species: 'Cat', breedName: 'Cornish Rex', minWeightKg: 2.7, maxWeightKg: 4.5),
    const BreedWeightRange(species: 'Cat', breedName: 'Abyssinian', minWeightKg: 2.7, maxWeightKg: 5.4),
    const BreedWeightRange(species: 'Cat', breedName: 'Siamese', minWeightKg: 3.0, maxWeightKg: 5.5),
    const BreedWeightRange(species: 'Cat', breedName: 'Russian Blue', minWeightKg: 3.0, maxWeightKg: 5.5),
    const BreedWeightRange(species: 'Cat', breedName: 'Burmese', minWeightKg: 3.6, maxWeightKg: 5.4),
    const BreedWeightRange(species: 'Cat', breedName: 'American Shorthair', minWeightKg: 3.2, maxWeightKg: 5.5),
    const BreedWeightRange(species: 'Cat', breedName: 'Scottish Fold', minWeightKg: 2.7, maxWeightKg: 6.0),
    const BreedWeightRange(species: 'Cat', breedName: 'British Shorthair', minWeightKg: 3.2, maxWeightKg: 7.7),
    const BreedWeightRange(species: 'Cat', breedName: 'Persian', minWeightKg: 3.2, maxWeightKg: 5.4),
    const BreedWeightRange(species: 'Cat', breedName: 'Bengal', minWeightKg: 3.6, maxWeightKg: 6.8),
    const BreedWeightRange(species: 'Cat', breedName: 'Ragdoll', minWeightKg: 4.5, maxWeightKg: 9.1),
    const BreedWeightRange(species: 'Cat', breedName: 'Norwegian Forest Cat', minWeightKg: 3.6, maxWeightKg: 9.1),
    const BreedWeightRange(species: 'Cat', breedName: 'Maine Coon', minWeightKg: 5.4, maxWeightKg: 11.3),
    const BreedWeightRange(species: 'Cat', breedName: 'Birman', minWeightKg: 3.6, maxWeightKg: 6.8),
    const BreedWeightRange(species: 'Cat', breedName: 'Sphynx', minWeightKg: 3.0, maxWeightKg: 5.4),
    const BreedWeightRange(species: 'Cat', breedName: 'Exotic Shorthair', minWeightKg: 3.2, maxWeightKg: 6.0),
    const BreedWeightRange(species: 'Cat', breedName: 'Turkish Angora', minWeightKg: 2.5, maxWeightKg: 5.0),
    const BreedWeightRange(species: 'Cat', breedName: 'Tonkinese', minWeightKg: 2.7, maxWeightKg: 5.4),
    const BreedWeightRange(species: 'Cat', breedName: 'Domestic Shorthair', minWeightKg: 3.0, maxWeightKg: 5.5),
    const BreedWeightRange(species: 'Cat', breedName: 'Domestic Longhair', minWeightKg: 3.0, maxWeightKg: 6.0),
    const BreedWeightRange(species: 'Cat', breedName: 'Korean Shorthair', minWeightKg: 3.0, maxWeightKg: 5.5),
    const BreedWeightRange(species: 'Cat', breedName: 'Somali', minWeightKg: 2.7, maxWeightKg: 5.0),
  ];
}

/// Represents the ideal weight range for a specific breed.
class BreedWeightRange {
  const BreedWeightRange({
    required this.species,
    required this.breedName,
    required this.minWeightKg,
    required this.maxWeightKg,
  });

  final String species;
  final String breedName;
  final double minWeightKg;
  final double maxWeightKg;

  double get midWeightKg => (minWeightKg + maxWeightKg) / 2;
}
