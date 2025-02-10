enum UpgradeCardType { boostAtk, heal, effectShield }

extension UpgradeCardTypeExtension on UpgradeCardType {
  // Convert a string to an enum value
  static UpgradeCardType fromString(String str) {
    return UpgradeCardType.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == str.toLowerCase(),
      orElse: () => UpgradeCardType.boostAtk, // Default value
    );
  }
}