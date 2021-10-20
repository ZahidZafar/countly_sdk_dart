import 'package:countly/model/entity.dart';
import 'package:countly/model/event.dart';
import 'package:countly/model/remote_config.dart';
import 'package:countly/model/request.dart';
import 'package:logging/logging.dart';
import 'package:sembast/sembast.dart';

final _factories = <Type, Function>{
  Event: (Map<String, dynamic> x) => Event.fromJson(x),
  Request: (Map<String, dynamic> x) => Request.fromJson(x),
  RemoteConfig: (Map<String, dynamic> x) => RemoteConfig.fromJson(x),
};

T _make<T extends Entity>(Map<String, dynamic> json) {
  return _factories[T]!(json);
}

abstract class Repository<T extends Entity> {
  late StoreRef store;
  final Database _db;
  final log = Logger('Repository');

  Repository({required Database db, required String storeName})
      : this._db = db {
    _init(storeName);
  }

  _init(String storeName) {
    store = stringMapStoreFactory.store(storeName);
  }

  Future<int> insert(T entity) async {
    int result = await store.add(_db, entity.toJson());
    log.finer('insert: result = ${result > 0}, entity = ${entity.toJson()}');
    return result;
  }

  Future<T> save(T entity) async {
    return await store.record(entity.id).put(_db, entity.toJson());
  }

  Future<int> remove(T entity) async {
    final finder = Finder(filter: Filter.byKey(entity.id));
    int result = await store.delete(_db, finder: finder);
    log.finer('remove: result = ${result > 0}, entity = ${entity.toJson()}');
    return result;
  }

  Future<int> removeAllIn(List<int?> keys) async {
    final finder = Finder(filter: Filter.inList(Field.key, keys));
    int result = await store.delete(_db, finder: finder);
    log.finer('removeAll: result = ${result > 0}, entity = ${keys.toString()}');
    return result;
  }

  Future<int> removeAll() async {
    int result = await store.delete(
      _db,
    );
    log.finer('removeAll: result = ${result > 0}');
    return result;
  }

  Future<int> update(T entity) async {
    final finder = Finder(filter: Filter.byKey(entity.id));

    return await store.update(
      _db,
      entity.toJson(),
      finder: finder,
    );
  }

  Future<T> find(String id) async {
    var finder = Finder(filter: Filter.byKey(id));
    var record = await store.findFirst(_db, finder: finder);
    final entity = _make<T>(record!.value);
    entity.id = record.key;

    return entity;
  }

  Future<List<T>> findAll() async {
    var finder = Finder(sortOrders: [SortOrder(Field.key)]);
    final recordSnapshots = await store.find(_db, finder: finder);

    return recordSnapshots.map<T>((snapshot) {
      final entity = _make<T>(snapshot.value);
      entity.id = snapshot.key;
      return entity;
    }).toList();
  }

  Future<T> findFirstBy(String field, dynamic value) async {
    var finder = Finder(filter: Filter.equals(field, value));
    var record = await store.findFirst(_db, finder: finder);
    final entity = _make<T>(record!.value);
    entity.id = record.key;

    return entity;
  }

  Future<List<T>> findBy(String field, dynamic value) async {
    Filter filter = Filter.equals(field, value);
    var finder = Finder(
      filter: filter,
    );
    final recordSnapshots = await store.find(_db, finder: finder);

    return recordSnapshots.map<T>((snapshot) {
      final entity = _make<T>(snapshot.value);
      entity.id = snapshot.key;
      return entity;
    }).toList();
  }

  Future<List<T>> findByKeys(List<String> keys) async {
    final recordSnapshots = await store.records(keys).get(_db);

    return recordSnapshots.map<T>((snapshot) {
      final entity = _make<T>(snapshot.value);
      entity.id = snapshot.key;
      return entity;
    }).toList();
  }
}
