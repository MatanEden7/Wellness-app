/// Where a template came from, so regeneration can replace what it generated
/// without touching anything the user made or edited.
///
/// Lives in `core/` rather than under either feature because meal templates
/// and workout templates both need it, and neither feature should have to
/// depend on the other to express it.
///
/// Without this, "your equipment changed -- regenerate your workouts?" has no
/// safe implementation: it would either skip regeneration entirely or wipe
/// hand-built templates along with the generated ones.
enum TemplateOrigin {
  /// Seeded by `AppDatabase` on first launch, before any profile exists.
  /// Replaceable, but only ever by a regeneration the user agreed to.
  builtin,

  /// Produced by a generator from the user's profile. Safe to replace when
  /// the profile changes.
  generated,

  /// Created or edited by the user. Never replaced automatically.
  user;

  String get key => name;

  /// Rows written before this field existed decode to [user] -- the one
  /// origin regeneration never touches -- so an unlabelled template can
  /// never be destroyed by a regeneration it predates.
  static TemplateOrigin fromKey(Object? raw) {
    if (raw is String) {
      for (final o in TemplateOrigin.values) {
        if (o.name == raw) return o;
      }
    }
    return TemplateOrigin.user;
  }
}
