class ModifierOption {
  final String id;
  final String name;
  final double extraPrice;

  ModifierOption({
    required this.id,
    required this.name,
    required this.extraPrice,
  });

  factory ModifierOption.fromJson(Map<String, dynamic> json) {
    return ModifierOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      extraPrice: (json['extraPrice'] ?? json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'extraPrice': extraPrice,
    };
  }
}

class ModifierGroup {
  final String id;
  final String title;
  final bool isRequired;
  final bool allowsMultiple;
  final List<ModifierOption> options;

  ModifierGroup({
    required this.id,
    required this.title,
    this.isRequired = false,
    this.allowsMultiple = false,
    required this.options,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    var rawOptions = json['options'] as List? ?? json['modifierOptions'] as List? ?? [];
    return ModifierGroup(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? json['name']?.toString() ?? '',
      isRequired: json['isRequired'] ?? json['required'] ?? false,
      allowsMultiple: json['allowsMultiple'] ?? json['multiple'] ?? false,
      options: rawOptions.map((opt) => ModifierOption.fromJson(opt)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isRequired': isRequired,
      'allowsMultiple': allowsMultiple,
      'options': options.map((opt) => opt.toJson()).toList(),
    };
  }
}
