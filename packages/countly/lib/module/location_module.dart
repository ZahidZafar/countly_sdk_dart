import 'package:countly/controller/consent_controller.dart';
import 'package:countly/controller/request_controller.dart';
import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/configuration.dart';
import 'package:logging/logging.dart';

import 'base_module.dart';

class LocationModule extends BaseModule {
  final Log = Logger('LocationModule');

  String? city;
  String? location;
  String? ipAddress;
  String? countryCode;
  bool isLocationDisabled = false;

  final RequestsController _requestsModule;

  LocationModule({
    required TimeHelper timeHelper,
    required Configuration configuration,
    required RequestsController requestsModule,
    required ConsentController consents,
  })  : this._requestsModule = requestsModule,
        super(
            configuration: configuration,
            timeHelper: timeHelper,
            consents: consents) {
    Log.info("Initializing.");

    isLocationDisabled = configuration.isLocationDisabled;
    if (isLocationDisabled ||
        !consents.checkConsentInternal(Consents.Location)) {
      city = null;
      location = null;
      ipAddress = null;
      countryCode = null;
    } else {
      city = configuration.city;
      location = configuration.location;
      ipAddress = configuration.ipAddress;
      countryCode = configuration.countryCode;
    }
  }

  /// <summary>
  /// Sends a request with an empty "location" parameter.
  /// </summary>
  Future sendRequestWithEmptyLocation() async {
    Map<String, dynamic> requestParams = {
      'location': '',
    };

    await _requestsModule.addToRequestQueue(requestParams);
  }

  /// <summary>
  /// An internal function to add user's location request into request queue.
  /// </summary>
  Future sendIndependentLocationRequest() async {
    Log.fine("sendIndependentLocationRequest");

    if (!consents.checkConsent(Consents.Location)) {
      return;
    }

    Map<String, dynamic> requestParams = Map();

    /*
     * Empty country code, city and IP address can not be sent.
     */

    if (ipAddress != null || ipAddress!.isNotEmpty) {
      requestParams['ip_address'] = ipAddress;
    }

    if (countryCode != null || countryCode!.isNotEmpty) {
      requestParams['country_code'] = countryCode;
    }

    if (city != null || city!.isNotEmpty) {
      requestParams['city'] = city;
    }

    if (location != null || location!.isNotEmpty) {
      requestParams['location'] = location;
    }

    if (requestParams.isNotEmpty) {
      await _requestsModule.addToRequestQueue(requestParams);
    }
  }

  /// <summary>
  /// Disabled the location tracking on the Countly server
  /// </summary>
  Future disableLocation() async {
    Log.info("DisableLocation");

    if (!consents.checkConsentInternal(Consents.Location)) {
      return;
    }

    isLocationDisabled = true;
    city = null;
    location = null;
    ipAddress = null;
    countryCode = null;
    /*
     *If the location feature gets disabled or location consent is removed,
     *the SDK sends a request with an empty "location".
     */

    await sendRequestWithEmptyLocation();
  }

  /// <summary>
  /// Set Country code (ISO Country code), City, Location and IP address to be used for future requests.
  /// </summary>
  /// <param name="countryCode">ISO Country code for the user's country</param>
  /// <param name="city">Name of the user's city</param>
  /// <param name="gpsCoordinates">comma separate lat and lng values. For example, "56.42345,123.45325"</param>
  /// <param name="ipAddress">ipAddress like "192.168.88.33"</param>
  Future setLocation(
      {required String? countryCode,
      required String? city,
      required String? gpsCoordinates,
      required String? ipAddress}) async {
    Log.info(
        "setLocation : countryCode = $countryCode, city = $city, gpsCoordinates = $gpsCoordinates, ipAddress = $ipAddress");

    if (!consents.checkConsentInternal(Consents.Location)) {
      return;
    }

    /*If city is not paired together with country,
                 * a warning should be printed that they should be set together.
                 */
    if ((countryCode != null ||
            countryCode!.isNotEmpty && city == null ||
            city!.isEmpty) ||
        (countryCode.isEmpty && city.isNotEmpty)) {
      Log.warning(
          "In \"SetLocation\" both country code and city should be set together");
    }

    this.city = city;
    this.ipAddress = ipAddress;
    this.countryCode = countryCode;
    this.location = gpsCoordinates;

    /*
                 * If location consent is given and location gets re-enabled (previously was disabled),
                 * we send that set location information in a separate request and save it in the internal location cache.
                 */
    if (this.countryCode != null ||
        this.city != null ||
        this.location != null ||
        this.ipAddress != null) {
      isLocationDisabled = false;
      await sendIndependentLocationRequest();
    }
  }

  /// If location consent is removed, the SDK sends a request with an empty "location" parameter.
  Future onLocationConsentRemoved() async {
    city = null;
    location = null;
    ipAddress = null;
    countryCode = null;

    await sendRequestWithEmptyLocation();
  }

  @override
  void onConsentChanged(List<String> updatedConsents, bool newConsentValue) {
    if (updatedConsents.contains(Consents.Location) && !newConsentValue) {
      onLocationConsentRemoved();
    }
  }
}
