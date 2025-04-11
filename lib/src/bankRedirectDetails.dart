class BankRedirectDetails {
  String _action;
  String _url;
  String _target;
  String _responseStatus;

  BankRedirectDetails({
    required String action,
    required String url,
    required String target,
    required String responseStatus
  }) :
        _action = action,
        _url = url,
        _target = target,
        _responseStatus = responseStatus;

  // Default constructor
  BankRedirectDetails.empty() :
        _action = '',
        _url = '',
        _target = '',
        _responseStatus = '';

  // Getters
  String get action => _action;
  String get url => _url;
  String get target => _target;
  String get responseStatus => _responseStatus;

  // Setters
  set action(String value) => _action = value;
  set url(String value) => _url = value;
  set target(String value) => _target = value;
  set responseStatus(String value) => _responseStatus = value;

  // Method equivalents to Java's get* methods
  String getAction() => _action;
  String getUrl() => _url;
  String getTarget() => _target;
  String getResponseStatus() => _responseStatus;

  // Method equivalents to Java's set* methods
  void setAction(String value) => _action = value;
  void setUrl(String value) => _url = value;
  void setTarget(String value) => _target = value;
  void setResponseStatus(String value) => _responseStatus = value;
}
