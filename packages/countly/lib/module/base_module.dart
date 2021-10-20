import 'package:countly/helper/time_helper.dart';
import 'package:countly/model/configuration.dart';
import 'package:logging/logging.dart';

import '../controller/consent_controller.dart';

abstract class BaseModule {
  final Log = Logger('[BaseModule]');
  final TimeHelper timeHelper;
  final Configuration configuration;
  late final ConsentController consents;

  late final List<BaseModule> listeners;

  BaseModule({
    required this.configuration,
    required this.timeHelper,
    required this.consents,
  });

  Map<String, dynamic>? removeSegmentInvalidDataTypes(
      Map<String, dynamic>? segments) {
    if (segments == null || segments.isEmpty) {
      return segments;
    }

    int i = 0;
    List<String> toRemove = [];
    segments.forEach((k, v) {
      if (++i > configuration.maxSegmentationValues) {
        toRemove.add(k);
      } else {
        bool isValidDataType = (v != null) &&
            (v is int || v is bool || v is double || v is String);

        if (!isValidDataType) {
          toRemove.add(k);
          Log.warning(
              'removeSegmentInvalidDataTypes: In segmentation Data type ${v.runtimeType} of item $k is not valid.');
        }
      }
    });

    for (String k in toRemove) {
      segments.remove(k);
    }

    return segments;
  }

  String trimKey(String k) {
    if (k.length > configuration.maxKeyLength) {
      Log.warning(
          'TrimKey : Max allowed key length is ${configuration.maxKeyLength}. $k will be truncated.');
      k = k.substring(0, configuration.maxKeyLength);
    }

    return k;
  }

  List<String> trimValues(List<String> values) {
    for (int i = 0; i < values.length; ++i) {
      if (values[i].length > configuration.maxValueSize) {
        Log.warning(
            'TrimValues : Max allowed value length is ${configuration.maxKeyLength}". ${values[i]} will be truncated.');
        values[i] = values[i].substring(0, configuration.maxValueSize);
      }
    }

    return values;
  }

  String? trimValue(String fieldName, String? v) {
    if (v != null && v.length > configuration.maxValueSize) {
      Log.warning(
          'trimValue : Max allowed $fieldName length is ${configuration.maxValueSize}. v will be truncated');
      v = v.substring(0, configuration.maxValueSize);
    }

    return v;
  }

  Map<String, dynamic>? fixSegmentKeysAndValues(
      Map<String, dynamic>? segments) {
    if (segments == null || segments.isEmpty) {
      return segments;
    }

    Map<String, dynamic> segmentation = {};
    segments.forEach((k, v) {
      k = trimKey(k);

      if (v is String) {
        v = trimValue(k, v);
      }

      segmentation[k] = v;
    });

    return segmentation;
  }

  Future onInitializationCompleted() async {}
  void onDeviceIdChanged(String? deviceId, bool merged) {}
  void onConsentChanged(List<String> updatedConsents, bool newConsentValue) {}
}
