/// What shipped, per version, per language. Add a top-level entry for every
/// released version; users skipping versions see every entry between their
/// last seen version and the current one. `en-US` is the fallback language.
const Map<String, Map<String, List<String>>> kChangelog = {
  '1.0.0': {
    'en-US': ['first public release.'],
  },
};
