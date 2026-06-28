# Lingua Localize

A command-line utility for automatically translating Apple's `.xcstrings` localization files using free online translation services.

Designed for developers who want an easy way to bootstrap localization without paying for commercial translation APIs.

## Features

- ✅ Translates Apple `.xcstrings` files
- ✅ Resume after interruption or API quota limits
- ✅ SQLite translation cache
- ✅ Saves progress after every translation
- ✅ Retries with exponential backoff
- ✅ Optional infinite retry mode
- ✅ Preserves format specifiers (`%@`, `%d`, `%lld`, etc.)
- ✅ Preserves variable placeholders (`${name}`)
- ✅ Skips existing translations
- ✅ Progress display
- ✅ Supports multiple target languages

---

## Requirements

- Python 3.10+
- `requests`

Install dependencies:

```bash
pip install requests
```

---

## Basic Usage

Translate a localization file:

```bash
python3 lingua_localize.py \
    Localizable.xcstrings \
    -o Localizable.translated.xcstrings
```

---

## Using an Email Address

The MyMemory API allows a higher free quota if you provide an email address.

```bash
python3 lingua_localize.py \
    Localizable.xcstrings \
    -o Localizable.translated.xcstrings \
    --email you@example.com
```

---

## Retry Forever

Useful if you expect to hit API limits.

```bash
python3 lingua_localize.py \
    Localizable.xcstrings \
    -o Localizable.translated.xcstrings \
    --retry-forever
```

The tool will automatically wait and continue translating until the file is complete.

---

## Resume Support

If the tool is interrupted:

- Internet failure
- Computer restart
- API quota exceeded
- Ctrl+C

Simply run the same command again.

Already translated strings are skipped automatically.

---

## Translation Cache

Translations are stored in a local SQLite database.

Benefits:

- Duplicate strings are translated only once.
- Future projects become faster.
- Saves API requests.
- Works across multiple applications.

---

## Status

View translation progress without performing any translations.

```bash
python3 lingua_localize.py --status
```

Example:

```
Languages: 16
Strings:   482
Translated: 451
Remaining: 31
Cache entries: 2198
```

---

## Supported Languages

Default target locales:

| Locale | Language |
|---------|----------|
| es | Spanish |
| fr | French |
| de | German |
| it | Italian |
| pt-BR | Portuguese (Brazil) |
| nl | Dutch |
| pl | Polish |
| ru | Russian |
| uk | Ukrainian |
| tr | Turkish |
| ja | Japanese |
| ko | Korean |
| zh-Hans | Simplified Chinese |
| zh-Hant | Traditional Chinese |
| ar | Arabic |
| hi | Hindi |

Additional locales can easily be added.

---

## Placeholder Protection

The tool automatically preserves common placeholders.

Examples:

```
Hello %@!
```

becomes

```
¡Hola %@!
```

instead of

```
¡Hola % @!
```

Supported placeholders include:

- `%@`
- `%d`
- `%ld`
- `%lld`
- `%f`
- `%1$@`
- `${variable}`

---

## Existing Localizations

The tool never overwrites existing translations.

If a language already exists inside the `.xcstrings` file, it is skipped.

---

## Cache Location

By default the SQLite cache is stored alongside the tool.

Example:

```
translation_cache.sqlite
```

You may safely delete this file at any time if you want to force retranslation.

---

## Notes

Machine translation is an excellent starting point, but translations should be reviewed by a native speaker before publishing.

This tool is intended to automate the repetitive work of generating initial localizations while preserving Apple's `.xcstrings` format.

---

## Future Improvements

Planned features include:

- DeepL support
- LibreTranslate support
- Google Cloud Translate support
- Parallel translation
- Multiple provider fallback
- Translation quality scoring
- Glossary support
- Project-specific translation memory
- Automatic language detection
- Batch translation optimization
- Swift Package Manager plugin