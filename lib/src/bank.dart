class Bank {
  String _bankId;
  int _countryPriority;
  int _userPriority;
  bool _quickMethod;
  bool _userPopular;
  String _name;
  String _country;
  String _bankLogo;
  String _alias;

  Bank({
    required String bankId,
    required int countryPriority,
    required int userPriority,
    required bool quickMethod,
    required bool userPopular,
    required String name,
    required String country,
    required String bankLogo,
    required String alias
  }) :
        _bankId = bankId,
        _countryPriority = countryPriority,
        _userPriority = userPriority,
        _quickMethod = quickMethod,
        _userPopular = userPopular,
        _name = name,
        _country = country,
        _bankLogo = bankLogo,
        _alias = alias;

  // Getters
  String get bankId => _bankId;
  int get countryPriority => _countryPriority;
  int get userPriority => _userPriority;
  bool get quickMethod => _quickMethod;
  bool get userPopular => _userPopular;
  String get name => _name;
  String get country => _country;
  String get bankLogo => _bankLogo;
  String get alias => _alias;

  // Method equivalents to Java's is* methods
  bool isQuickMethod() => _quickMethod;
  bool isUserPopular() => _userPopular;

  // Method equivalents to Java's get* methods
  String getBankId() => _bankId;
  String getName() => _name;
  String getCountry() => _country;
  String getBankLogo() => _bankLogo;
  String getAlias() => _alias;
  int getCountryPriority() => _countryPriority;
  int getUserPriority() => _userPriority;
}
