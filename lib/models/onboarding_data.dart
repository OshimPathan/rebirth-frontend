class OnboardingData {
  String name;
  String age;
  String location;
  String occupation;
  String gender;
  String antiVision;
  String idealSelf;
  String qualitiesToBuild;
  String negativeHabits;

  OnboardingData({
    this.name = '',
    this.age = '',
    this.location = '',
    this.occupation = '',
    this.gender = '',
    this.antiVision = '',
    this.idealSelf = '',
    this.qualitiesToBuild = '',
    this.negativeHabits = '',
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'location': location,
      'occupation': occupation,
      'gender': gender,
      'anti_vision': antiVision,
      'ideal_self': idealSelf,
      'qualities_to_build': qualitiesToBuild,
      'negative_habits': negativeHabits,
    };
  }

  // Create from JSON
  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      name: json['name'] ?? '',
      age: json['age'] ?? '',
      location: json['location'] ?? '',
      occupation: json['occupation'] ?? '',
      gender: json['gender'] ?? '',
      antiVision: json['anti_vision'] ?? '',
      idealSelf: json['ideal_self'] ?? '',
      qualitiesToBuild: json['qualities_to_build'] ?? '',
      negativeHabits: json['negative_habits'] ?? '',
    );
  }

  // Check if all required fields are filled
  bool isComplete() {
    return name.isNotEmpty &&
        age.isNotEmpty &&
        location.isNotEmpty &&
        occupation.isNotEmpty &&
        gender.isNotEmpty &&
        antiVision.isNotEmpty &&
        idealSelf.isNotEmpty &&
        qualitiesToBuild.isNotEmpty &&
        negativeHabits.isNotEmpty;
  }

  // Get formatted data for AI summary
  String getFormattedDataForAI() {
    return '''
User Profile:
- Name: $name
- Age: $age
- Location: $location
- Occupation: $occupation
- Gender: $gender

Personal Development Goals:
- Things to remove from life: $antiVision
- Ideal self description: $idealSelf
- Qualities to build: $qualitiesToBuild
- Negative habits to avoid: $negativeHabits
''';
  }

  @override
  String toString() {
    return 'OnboardingData(name: $name, age: $age, location: $location, occupation: $occupation, gender: $gender)';
  }
}
