enum BuiltinColumnId {
  event,
  person,
  url,
  library,
  time,
}

enum ColumnKind {
  builtin,
  property,
}

enum ColumnCategory {
  event,
  person,
  session,
  flags,
}

class ColumnSpec {
  const ColumnSpec._({
    required this.key,
    required this.label,
    required this.flex,
    required this.kind,
    this.id,
    this.propertyKey,
    this.category,
  });

  final String key;
  final String label;
  final int flex;
  final ColumnKind kind;
  final BuiltinColumnId? id;
  final String? propertyKey;
  final ColumnCategory? category;

  factory ColumnSpec.builtin({
    required BuiltinColumnId id,
    required String label,
    required int flex,
  }) {
    return ColumnSpec._(
      key: 'builtin:${id.name}',
      label: label,
      flex: flex,
      kind: ColumnKind.builtin,
      id: id,
    );
  }

  factory ColumnSpec.property({
    required String propertyKey,
    required String label,
    required ColumnCategory category,
  }) {
    return ColumnSpec._(
      key: 'prop:${category.name}:$propertyKey',
      label: label,
      flex: 2,
      kind: ColumnKind.property,
      propertyKey: propertyKey,
      category: category,
    );
  }

  factory ColumnSpec.fallback(String key) {
    return ColumnSpec._(
      key: key,
      label: key,
      flex: 2,
      kind: ColumnKind.property,
      propertyKey: key,
      category: ColumnCategory.event,
    );
  }
}

class ColumnOption {
  const ColumnOption._({
    required this.key,
    required this.label,
    required this.category,
    required this.propertyKey,
  });

  final String key;
  final String label;
  final ColumnCategory category;
  final String propertyKey;

  factory ColumnOption.property({
    required ColumnCategory category,
    required String propertyKey,
  }) {
    final label = propertyKey;
    return ColumnOption._(
      key: 'prop:${category.name}:$propertyKey',
      label: label,
      category: category,
      propertyKey: propertyKey,
    );
  }
}
