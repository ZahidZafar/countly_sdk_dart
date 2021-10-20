class TimeHelper {
  late int _lastTimestamp = DateTime.now().millisecond;
  TimeHelper();

  int getUniqueTimestamp() {
    int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    _lastTimestamp = currentTimestamp > _lastTimestamp
        ? currentTimestamp
        : currentTimestamp + 1;
    return _lastTimestamp;
  }
}
