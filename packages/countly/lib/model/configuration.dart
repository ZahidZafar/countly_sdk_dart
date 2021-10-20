class Configuration {
  final String sdkName = 'csharp-unity-editor';
  final String sdkVersion = '20.11.5';

  /// URL of the Countly server to submit data to.
  /// Mandatory field.
  final String serverUrl;

  /// App key for the application being tracked.
  /// Mandatory field.
  final String appKey;

  /// Unique ID for the device the app is running on.
  final String? deviceId;

  /// Set to prevent parameter tampering.
  final String? salt;

  /// Set to send all requests made to the Countly server using HTTP POST.
  final bool enablePost;

  /// Set to true if you want the SDK to pretend that it's functioning.
  final bool enableTestMode;

  /// Set to true if you want to enable countly internal debugging logs.
  final bool enableConsoleLogging;

  /// Set to true to enable manual session handling.
  final bool enableManualSessionHandling;

  /// The interval for the automatic update calls
  /// min value 1 (1 second), max value 600 (10 minutes)
  final int sessionDuration;

  /// Maximum size of all string keys
  final int maxKeyLength;

  /// Maximum size of all values in our key-value pairs
  final int maxValueSize;

  /// <summary>
  /// Max amount of custom (dev provided) segmentation in one event
  /// </summary>
  final int maxSegmentationValues;

  ///Limits how many stack trace lines would be recorded per thread
  final int maxStackTraceLinesPerThread;

  /// <summary>
  ///Limits how many characters are allowed per stack trace line
  /// </summary>
  final int maxStackTraceLineLength;

  /// Set threshold value for the number of events that can be stored locally.
  final int eventQueueThreshold;

  /// Set limit for the number of requests that can be stored locally.
  final int storedRequestLimit;

  /// Set the maximum amount of breadcrumbs.
  final int totalBreadcrumbsAllowed;

  /// Set true to enable uncaught crash reporting.
  final bool enableAutomaticCrashReporting;

  /// Set if consent should be required.
  final bool requiresConsent;
  late List<String> _givenConsent = [];
  late List<String> _enabledConsentGroups = [];
  final Map<String, List<String>> _consentGroups = Map();

  List<String> get givenConsent => _givenConsent;
  Map<String, List<String>> get consentGroups => _consentGroups;
  List<String> get enabledConsentGroups => _enabledConsentGroups;

  String? _city;
  get city => _city;
  String? _location;
  get location => _location;
  String? _ipAddress;
  get ipAddress => _ipAddress;
  String? _countryCode;
  get countryCode => _countryCode;

  bool _isLocationDisabled = false;
  bool get isLocationDisabled => _isLocationDisabled;

  bool _isAutomaticSessionTrackingDisabled = false;
  bool get isAutomaticSessionTrackingDisabled =>
      _isAutomaticSessionTrackingDisabled;

//
//   internal Consents[] GivenConsent { get; private set; }
// internal string[] EnabledConsentGroups { get; private set; }
// internal List<INotificationListener> NotificationEventListeners;
// internal Dictionary<string, Consents[]> ConsentGroups { get; private set; }

  Configuration({
    required this.serverUrl,
    required this.appKey,
    this.salt,
    this.deviceId,
    this.maxKeyLength = 128,
    this.maxValueSize = 256,
    this.sessionDuration = 60,
    this.eventQueueThreshold = 100,
    this.storedRequestLimit = 1000,
    this.maxSegmentationValues = 30,
    this.maxStackTraceLineLength = 200,
    this.totalBreadcrumbsAllowed = 100,
    this.maxStackTraceLinesPerThread = 30,
    this.enablePost = false,
    this.requiresConsent = false,
    this.enableTestMode = false,
    this.enableConsoleLogging = false,
    this.enableManualSessionHandling = false,
    this.enableAutomaticCrashReporting = true,
  });

  ///Disabled the automatic session tracking.
  void disableAutomaticSessionTracking() {
    this._isAutomaticSessionTrackingDisabled = true;
  }

  /// Disabled the location tracking on the Countly server
  void disableLocation() {
    _isLocationDisabled = true;
  }

  /// <summary>
  /// Set location parameters that will be used during init.
  /// </summary>
  /// <param name="countryCode">ISO Country code for the user's country</param>
  /// <param name="city">Name of the user's city</param>
  /// <param name="gpsCoordinates">comma separate lat and lng values.<example>"56.42345,123.45325"</example> </param>
  /// <param name="ipAddress">user's IP Address</param>
  void setLocation(
      {required String countryCode,
      required String city,
      required String gpsCoordinates,
      required String ipAddress}) {
    _city = city;
    _ipAddress = ipAddress;
    _countryCode = countryCode;
    _location = gpsCoordinates;
  }

  /// <summary>
  /// Give consent to features in case consent is required.
  /// </summary>
  /// <param name="consents">array of consent for which consent should be given</param>
  void GiveConsent(List<String> consents) {
    _givenConsent = consents;
  }

  /// <summary>
  /// Group multiple consents into a consent group
  /// </summary>
  /// <param name="groupName">name of the consent group that will be created</param>
  /// <param name="consents">array of consent to be added to the consent group</param>
  /// <returns></returns>
  void CreateConsentGroup(
      {required String groupName, required List<String> consents}) {
    _consentGroups[groupName] = consents;
  }

  /// <summary>
  /// Give consent to the provided consent groups
  /// </summary>
  /// <param name="groupName">array of consent group for which consent should be given</param>
  /// <returns></returns>
  void giveConsentToGroup({required List<String> groupName}) {
    _enabledConsentGroups = groupName;
  }

  @override
  String toString() {
    return 'Configuration{sdkName: $sdkName, sdkVersion: $sdkVersion, serverUrl: $serverUrl, appKey: $appKey, deviceId: $deviceId, salt: $salt, enablePost: $enablePost, enableTestMode: $enableTestMode, enableConsoleLogging: $enableConsoleLogging, enableManualSessionHandling: $enableManualSessionHandling, sessionDuration: $sessionDuration, maxKeyLength: $maxKeyLength, maxValueSize: $maxValueSize, maxSegmentationValues: $maxSegmentationValues, maxStackTraceLinesPerThread: $maxStackTraceLinesPerThread, maxStackTraceLineLength: $maxStackTraceLineLength, eventQueueThreshold: $eventQueueThreshold, storedRequestLimit: $storedRequestLimit, totalBreadcrumbsAllowed: $totalBreadcrumbsAllowed, enableAutomaticCrashReporting: $enableAutomaticCrashReporting, requiresConsent: $requiresConsent, _city: $_city, _location: $_location, _ipAddress: $_ipAddress, _countryCode: $_countryCode, _isLocationDisabled: $_isLocationDisabled, _isAutomaticSessionTrackingDisabled: $_isAutomaticSessionTrackingDisabled}';
  }
}
