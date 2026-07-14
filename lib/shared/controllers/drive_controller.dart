import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/drive_item.dart';
import '../services/index/drive_index.dart';

enum DriveSortField { name, size, modified }

class DriveCrumb {
  final String? id;
  final String name;

  const DriveCrumb({required this.id, required this.name});
}

List<DriveItem> sortDriveItems(
    List<DriveItem> items, DriveSortField field, bool ascending) {
  final sorted = [...items];
  sorted.sort((a, b) {
    if (a.isFolder != b.isFolder) return a.isFolder ? -1 : 1;
    final c = switch (field) {
      DriveSortField.size => a.size.compareTo(b.size),
      DriveSortField.modified => a.modified.compareTo(b.modified),
      DriveSortField.name =>
        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    };
    return ascending ? c : -c;
  });
  return sorted;
}

class DriveState {
  final List<DriveCrumb> stack;
  final List<DriveItem> items;
  final List<DriveItem> results;
  final List<DriveItem> recent;
  final String query;
  final DriveSortField sortField;
  final bool sortAsc;
  final bool loading;

  const DriveState({
    this.stack = const [DriveCrumb(id: null, name: 'My Drive')],
    this.items = const [],
    this.results = const [],
    this.recent = const [],
    this.query = '',
    this.sortField = DriveSortField.name,
    this.sortAsc = true,
    this.loading = true,
  });

  String? get folderId => stack.last.id;

  bool get searching => query.trim().isNotEmpty;

  List<DriveItem> get visible =>
      sortDriveItems(searching ? results : items, sortField, sortAsc);

  DriveState copyWith({
    List<DriveCrumb>? stack,
    List<DriveItem>? items,
    List<DriveItem>? results,
    List<DriveItem>? recent,
    String? query,
    DriveSortField? sortField,
    bool? sortAsc,
    bool? loading,
  }) {
    return DriveState(
      stack: stack ?? this.stack,
      items: items ?? this.items,
      results: results ?? this.results,
      recent: recent ?? this.recent,
      query: query ?? this.query,
      sortField: sortField ?? this.sortField,
      sortAsc: sortAsc ?? this.sortAsc,
      loading: loading ?? this.loading,
    );
  }
}

final driveIndexProvider = Provider<DriveIndex>((ref) {
  final index = DriveIndex();
  ref.onDispose(index.close);
  return index;
});

final driveControllerProvider =
    StateNotifierProvider<DriveController, DriveState>((ref) {
  return DriveController(ref.watch(driveIndexProvider));
});

class DriveController extends StateNotifier<DriveState> {
  DriveController(this._index, {bool seed = true})
      : super(const DriveState()) {
    _init(seed);
  }

  final DriveIndex _index;
  int _seq = 0;

  Future<void> _init(bool seed) async {
    if (seed) await _index.seedIfEmpty();
    await _refresh();
  }

  Future<void> _refresh() async {
    final items = await _index.children(state.folderId);
    final recent = await _index.recent();
    final results =
        state.searching ? await _index.search(state.query) : const <DriveItem>[];
    if (!mounted) return;
    state = state.copyWith(
        items: items, recent: recent, results: results, loading: false);
  }

  Future<void> open(String folderId) async {
    final item = await _index.item(folderId);
    if (item == null || !item.isFolder) return;
    final chain = <DriveCrumb>[];
    DriveItem? cur = item;
    while (cur != null) {
      chain.insert(0, DriveCrumb(id: cur.id, name: cur.name));
      cur = cur.parentId == null ? null : await _index.item(cur.parentId!);
    }
    if (!mounted) return;
    state = state.copyWith(
      stack: [state.stack.first, ...chain],
      query: '',
      results: const [],
    );
    await _refresh();
  }

  Future<void> up() async {
    if (state.stack.length <= 1) return;
    state = state.copyWith(
      stack: state.stack.sublist(0, state.stack.length - 1),
      query: '',
      results: const [],
    );
    await _refresh();
  }

  Future<void> navigateTo(int pathIndex) async {
    if (pathIndex < 0 || pathIndex >= state.stack.length) return;
    state = state.copyWith(
      stack: state.stack.sublist(0, pathIndex + 1),
      query: '',
      results: const [],
    );
    await _refresh();
  }

  void setSort(DriveSortField field, {bool? ascending}) {
    if (ascending != null) {
      state = state.copyWith(sortField: field, sortAsc: ascending);
    } else if (state.sortField == field) {
      state = state.copyWith(sortAsc: !state.sortAsc);
    } else {
      state = state.copyWith(sortField: field, sortAsc: true);
    }
  }

  Future<void> setQuery(String query) async {
    state = state.copyWith(query: query);
    final results =
        query.trim().isEmpty ? const <DriveItem>[] : await _index.search(query);
    if (!mounted || state.query != query) return;
    state = state.copyWith(results: results);
  }

  Future<void> createFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _index.insert(DriveItem(
      id: _newId(),
      name: trimmed,
      isFolder: true,
      modified: DateTime.now(),
      parentId: state.folderId,
    ));
    await _refresh();
  }

  Future<void> rename(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _index.rename(id, trimmed);
    await _refresh();
  }

  Future<void> delete(String id) async {
    await _index.delete(id);
    await _refresh();
  }

  Future<void> addUploaded({
    required String name,
    required int sizeBytes,
    String? parentId,
  }) async {
    await _index.insert(DriveItem(
      id: _newId(),
      name: name,
      size: sizeBytes,
      modified: DateTime.now(),
      ext: extOf(name),
      parentId: parentId,
    ));
    await _refresh();
  }

  String _newId() =>
      'it-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
}
