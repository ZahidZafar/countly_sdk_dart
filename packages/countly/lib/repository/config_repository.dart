import 'package:countly/model/remote_config.dart';
import 'package:sembast/sembast.dart';

import 'base_repository.dart';

class RemoteConfigRepository extends Repository<RemoteConfig> {
  RemoteConfigRepository({required Database db})
      : super(db: db, storeName: "remote-config");
}
