import 'dart:convert';

import 'package:countly/controller/request_controller.dart';
import 'package:countly/model/configuration.dart';
import 'package:countly/repository/event_repository.dart';
import 'package:logging/logging.dart';

import '../module/base_module.dart';

class ConsentController {
  final log = Logger('ConsentModule');

  bool isInitialized = false;
  late final _requiresConsent;
  late final List<BaseModule> _listeners;

  final Configuration _configuration;
  final RequestsController _requestsModule;
  final Map<String, bool> _consents = Map();
  final Map<String, List<String>> _consentGroups = Map();

  set listeners(List<BaseModule> list) => _listeners;

  ConsentController(
      {required EventRepository eventRepository,
      required Configuration configuration,
      required RequestsController requestsModule})
      : this._requestsModule = requestsModule,
        this._configuration = configuration {
    log.fine("Initializing");

    _requiresConsent = configuration.requiresConsent;
    _consentGroups.addAll(configuration.consentGroups);
    if (configuration.enabledConsentGroups.isNotEmpty) {
      _consentGroups.forEach((key, value) {
        if (configuration.enabledConsentGroups.contains(key)) {
          setConsentInternal(value, true);
        }
      });
    }

    setConsentInternal(configuration.givenConsent, true);
  }

  /// <summary>
  ///  Check if consent for the specific feature has been given
  /// </summary>
  /// <param name="consent">The consent that should be checked</param>
  /// <returns>Returns "true" if the consent for the checked feature has been provided</returns>
  bool checkConsent(String consent) {
    log.info("checkConsent : consent = $consent");
    return checkConsentInternal(consent);
  }

  //===================== Internal helper functions =======================//

  /// <summary>
  ///  Check if consent for any feature has been given
  /// </summary>
  /// <returns>Returns "true" if consent is given for any of the possible features</returns>
  bool anyConsentGiven() {
    bool result = !_requiresConsent;

    if (result) {
      return result;
    }

    _consents.values.forEach((v) {
      if (v) {
        result = v;
        return;
      }
    });

    log.info("anyConsentGiven : result = $result");

    return result;
  }

  /// <summary>
  /// Give consent to the provided features
  /// </summary>
  /// <param name="consents">array of consents for which consent should be given</param>
  /// <returns></returns>
  void giveConsent(List<String> consents) {
    log.info("giveConsent : consents = ${consents.toString()}");

    if (!_requiresConsent) {
      log.shout(
          "giveConsent: Please set consent to be required before calling this!");
      return;
    }

    setConsentInternal(consents, true);
  }

  /// <summary>
  /// Give consent to the provided features
  /// </summary>
  /// <param name="consents">array of consents for which consent should be given</param>
  /// <returns></returns>
  void giveConsentAll() {
    log.info("giveConsentAll");

    if (!_requiresConsent) {
      log.shout(
          "giveConsent: Please set consent to be required before calling this!");
      return;
    }

    List<String> consents = Consents.values;
    setConsentInternal(consents, true);
  }

  /// <summary>
  /// Remove consent from the provided features
  /// </summary>
  /// <param name="consents">array of consents for which consent should be removed</param>
  /// <returns></returns>
  void removeConsent(List<String> consents) {
    log.info("removeConsent : consents = ${consents.toString()}");

    if (!_requiresConsent) {
      log.shout(
          "removeConsent: Please set consent to be required before calling this!");
      return;
    }

    setConsentInternal(consents, false);
  }

  /// <summary>
  /// Remove consent from all features
  /// </summary>
  /// <returns></returns>
  void removeConsentAll() {
    log.info("removeConsentAll");

    if (!_requiresConsent) {
      log.shout(
          "removeConsentAll: Please set consent to be required before calling this!");
      return;
    }
    setConsentInternal(_consents.keys.toList(), false);
  }

  /// <summary>
  /// Give consent to the provided feature groups
  /// </summary>
  /// <param name="groupName">array of consent group for which consent should be given</param>
  /// <returns></returns>
  void giveConsentToGroup(List<String> groupName) {
    log.info("giveConsentToGroup : groupName = ${groupName}");

    if (!_requiresConsent) {
      log.shout(
          "giveConsentToGroup: Please set consent to be required before calling this!");
      return;
    }

    for (String name in groupName) {
      if (_consentGroups.containsKey(name)) {
        List<String> consents = _consentGroups[name]!;
        setConsentInternal(consents, true);
      }
    }
  }

  /// <summary>
  /// Remove consent from the provided feature groups
  /// </summary>
  /// <param name="groupName">An array of consent group names for which consent should be removed</param>
  /// <returns></returns>
  void removeConsentToGroup(List<String> groupName) {
    log.info("removeConsentToGroup : groupName = ${groupName}");

    if (!_requiresConsent) {
      log.shout(
          "removeConsentToGroup: Please set consent to be required before calling this!");
      return;
    }

    for (String name in groupName) {
      if (_consentGroups.containsKey(name)) {
        List<String> consents = _consentGroups[name]!;
        setConsentInternal(consents, false);
      }
    }
  }

  /// <summary>
  ///  An internal function to check if consent for the specific feature has been given
  /// </summary>
  /// <param name="consent">The consent that should be checked</param>
  /// <returns>Returns "true" if the consent for the checked feature has been provided</returns>
  bool checkConsentInternal(String consent) {
    bool result = !_requiresConsent ||
        ((_consents.containsKey(consent) && _consents[consent] == true));
    log.fine("checkConsentInternal : consent = $consent, result = $result");
    return result;
  }

  /// <summary>
  /// Private method that update selected consents.
  /// </summary>
  /// <param name="consents">List of consent</param>
  /// <param name="value">value to be set</param>
  void setConsentInternal(List<String> consents, bool value) {
    List<String> updatedConsents = [];
    for (String consent in consents) {
      if (_consents.containsKey(consent) && _consents[consent] == value) {
        continue;
      }

      if (!_consents.containsKey(consent) && !value) {
        continue;
      }

      updatedConsents.add(consent);
      _consents[consent] = value;

      if (isInitialized) {
        _sendConsentChanges(updatedConsents, value);
        _notifyListeners(updatedConsents, value);
      }
    }
  }

  /// <summary>
  /// Internal method that send consent changes to server.
  /// </summary>
  /// <param name="consents">List of consent</param>
  /// <param name="value">value to be set</param>
  Future _sendConsentChanges(List<String> consents, bool value) async {
    log.fine('_sendConsentChanges: consents = $consents, value = $value');
    if (!_requiresConsent || consents.isEmpty) {
      return;
    }

    var consentParams = Map();
    for (String consent in consents) {
      consentParams[consent] = value;
    }

    Map<String, dynamic> requestParams = <String, dynamic>{
      "consent": jsonEncode(consentParams),
    };

    await _requestsModule.addToRequestQueue(requestParams);
  }

  /// <summary>
  /// On consents changed, call <code>ConsentChanged</code> on all listeners.
  /// </summary>
  /// <param name="updatedConsents">List of modified consent</param>
  /// <param name="newConsentValue">Modified Consents's new value</param>
  void _notifyListeners(List<String> updatedConsents, bool newConsentValue) {
    if (_listeners.isEmpty) {
      return;
    }

    for (BaseModule listener in _listeners) {
      listener.onConsentChanged(updatedConsents, newConsentValue);
    }
  }

  Future onInitializationCompleted() async {
    isInitialized = true;
    log.info('onInitializationCompleted');
    await _sendConsentChanges(_consents.keys.toList(), true);
  }
}

class Consents {
  static const String Push = 'push';
  static const String Views = 'views';
  static const String Users = 'users';
  static const String Events = 'events';
  static const String Clicks = 'clicks';
  static const String Crashes = 'crashes';
  static const String Location = 'location';
  static const String Sessions = 'sessions';
  static const String Feedback = 'feedback';
  static const String StarRating = 'star-rating';
  static const String RemoteConfig = 'remote-config';

  Consents._();

  static get values => <String>[
        Push,
        Views,
        Users,
        Events,
        Clicks,
        Crashes,
        Location,
        Sessions,
        Feedback,
        StarRating,
        RemoteConfig,
      ];
}
