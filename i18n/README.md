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
