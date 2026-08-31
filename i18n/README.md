# Translation catalogs

`Catalogs.js` is the single localization boundary used by every QML view.
English is the canonical fallback and every shipped locale should contain the
same section/key shape.

To add a language, call `registerLocale` with its BCP 47 code, native display
name and optional aliases, plus a catalog with the same sections and keys as
English. The primary language subtag is used as its internal key unless `key`
is explicitly supplied. Registration rejects incomplete catalogs. Values may
be strings or plural maps such as `{ "one": "…", "other": "…" }`.
Placeholders use `{name}` syntax. Languages with plural rules beyond
`one`/`other` can supply a rule as the third argument.

Example:

```js
registerLocale(
  { code: "fr-FR", nativeName: "Français", aliases: ["fr"] },
  frenchCatalog,
  function(count) { return Number(count) > 1 ? "other" : "one" }
)
```

The agent persists any bounded, syntactically valid BCP 47 tag. Until a catalog
for that tag ships, the frontend and native notifications fall back to English.

`CountryNames.js` is the parallel territory-name registry used for display and
search aliases. English comes from the backend's ISO 3166 catalog; each new UI
language adds a map keyed by two-letter territory code. The Spanish map was
generated from iso-codes 4.20.1's `iso_3166-1` catalog (LGPL-2.1-or-later).
Keep the canonical English fallback in every alias list so users may search in
either the selected language or English, matching Proton Android's behavior.

## Proton terminology

Labels and descriptions that have a direct equivalent in Proton's Windows
client use the `en-US` and `es-419` values from `ProtonVPN/win-app` commit
`4d9ac60d1db5d3f2908498470a9d1646723afcfd`. Omarchy-specific copy has no
upstream equivalent and remains maintained here. Keep those two groups
separate when refreshing a catalog so a coincidentally similar phrase is not
assigned the wrong UI context.
