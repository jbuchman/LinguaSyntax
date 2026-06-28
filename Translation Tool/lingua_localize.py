#!/usr/bin/env python3
"""
lingua-localize: Resumable machine translation for Xcode .xcstrings files.

Default provider: MyMemory free translation API.

Examples:
  python3 lingua_localize.py Localizable.xcstrings
  python3 lingua_localize.py Localizable.xcstrings -o Localizable.translated.xcstrings --email you@example.com
  python3 lingua_localize.py Localizable.xcstrings --locales es fr de ja zh-Hans
  python3 lingua_localize.py Localizable.xcstrings --status

Features:
  - Resumable: writes output after each successful translation.
  - Local cache: reuses translations across runs/projects.
  - Backoff/retry: handles rate limits and temporary network failures.
  - Placeholder protection: preserves %@, %1$@, %lld, {name}, ${name}, etc.
  - Conservative by default: skips existing translations unless --overwrite is set.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import random
import re
import signal
import sqlite3
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

VERSION = "1.0.0"

DEFAULT_LOCALES = [
    "es", "fr", "de", "it", "pt-BR", "nl", "pl", "ru", "uk", "tr",
    "ja", "ko", "zh-Hans", "zh-Hant", "ar", "hi",
]

MYMEMORY_LANG = {
    "pt-BR": "pt-BR",
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
}

# printf/String(format:) placeholders, Swift interpolation-ish placeholders, ICU-ish placeholders.
PLACEHOLDER_RE = re.compile(
    r"("
    r"%\d+\$[-+#0 .]*\d*(?:\.\d+)?(?:hh|h|ll|l|j|z|t|L)?[diuoxXfFeEgGaAcCsSp@]"
    r"|%[-+#0 .]*\d*(?:\.\d+)?(?:hh|h|ll|l|j|z|t|L)?[diuoxXfFeEgGaAcCsSp@]"
    r"|%%"
    r"|\$\{[A-Za-z_][A-Za-z0-9_]*\}"
    r"|\{[A-Za-z_][A-Za-z0-9_]*\}"
    r")"
)

DEFAULT_PROTECTED_TERMS = ["LinguaSyntax", "RTF", "Markdown", "HTML", "URL"]

STOP_REQUESTED = False


def _handle_stop(signum: int, frame: Any) -> None:  # pragma: no cover
    global STOP_REQUESTED
    STOP_REQUESTED = True
    print("\nStop requested. Finishing current request and saving progress...", file=sys.stderr)


signal.signal(signal.SIGINT, _handle_stop)
signal.signal(signal.SIGTERM, _handle_stop)


@dataclass(frozen=True)
class TranslationRequest:
    source_locale: str
    target_locale: str
    text: str


class TranslationCache:
    def __init__(self, path: Path):
        self.path = path.expanduser()
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.db = sqlite3.connect(self.path)
        self.db.execute(
            """
            CREATE TABLE IF NOT EXISTS translations (
                provider TEXT NOT NULL,
                source_locale TEXT NOT NULL,
                target_locale TEXT NOT NULL,
                source_hash TEXT NOT NULL,
                source_text TEXT NOT NULL,
                translated_text TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                PRIMARY KEY(provider, source_locale, target_locale, source_hash)
            )
            """
        )
        self.db.commit()

    @staticmethod
    def _hash(text: str) -> str:
        return hashlib.sha256(text.encode("utf-8")).hexdigest()

    def get(self, provider: str, req: TranslationRequest) -> str | None:
        row = self.db.execute(
            """
            SELECT translated_text FROM translations
            WHERE provider=? AND source_locale=? AND target_locale=? AND source_hash=?
            """,
            (provider, req.source_locale, req.target_locale, self._hash(req.text)),
        ).fetchone()
        return row[0] if row else None

    def put(self, provider: str, req: TranslationRequest, translated: str) -> None:
        self.db.execute(
            """
            INSERT OR REPLACE INTO translations
            (provider, source_locale, target_locale, source_hash, source_text, translated_text, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (provider, req.source_locale, req.target_locale, self._hash(req.text), req.text, translated, int(time.time())),
        )
        self.db.commit()

    def close(self) -> None:
        self.db.close()


class PlaceholderProtector:
    def __init__(self, protected_terms: Iterable[str]):
        self.protected_terms = [t for t in protected_terms if t]

    def protect(self, text: str) -> tuple[str, dict[str, str]]:
        mapping: dict[str, str] = {}

        def add_token(value: str) -> str:
            token = f"ZXQ{len(mapping):03d}QXZ"
            mapping[token] = value
            return token

        protected = PLACEHOLDER_RE.sub(lambda m: add_token(m.group(0)), text)
        for term in self.protected_terms:
            protected = re.sub(re.escape(term), lambda m: add_token(m.group(0)), protected)
        return protected, mapping

    @staticmethod
    def unprotect(text: str, mapping: dict[str, str]) -> str:
        # Some translators insert spaces into all-caps tokens.
        text = re.sub(r"Z\s*X\s*Q\s*(\d{3})\s*Q\s*X\s*Z", r"ZXQ\1QXZ", text, flags=re.IGNORECASE)
        for token, value in mapping.items():
            text = re.sub(re.escape(token), value, text, flags=re.IGNORECASE)
        return text


class MyMemoryProvider:
    name = "mymemory"

    def __init__(self, email: str | None, timeout: float, user_agent: str = "lingua-localize/1.0"):
        self.email = email
        self.timeout = timeout
        self.user_agent = user_agent

    def translate(self, text: str, source_locale: str, target_locale: str) -> str:
        target = MYMEMORY_LANG.get(target_locale, target_locale)
        source = MYMEMORY_LANG.get(source_locale, source_locale)
        params = {"q": text, "langpair": f"{source}|{target}"}
        if self.email:
            params["de"] = self.email
        url = "https://api.mymemory.translated.net/get?" + urllib.parse.urlencode(params)
        req = urllib.request.Request(url, headers={"User-Agent": self.user_agent})
        with urllib.request.urlopen(req, timeout=self.timeout) as response:
            raw = response.read().decode("utf-8")
            payload = json.loads(raw)

        response_status = payload.get("responseStatus")
        response_details = str(payload.get("responseDetails", ""))
        translated = payload.get("responseData", {}).get("translatedText")

        if response_status and int(response_status) >= 400:
            raise RuntimeError(f"provider status {response_status}: {response_details}")
        if not translated:
            raise RuntimeError(f"no translatedText returned: {response_details or payload}")
        if "quota" in response_details.lower() or "limit" in response_details.lower():
            raise RuntimeError(f"provider limit: {response_details}")
        return translated


def atomic_write_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def source_value_for_entry(key: str, entry: dict[str, Any], source_locale: str) -> str:
    loc = entry.get("localizations", {}).get(source_locale)
    unit = loc.get("stringUnit") if isinstance(loc, dict) else None
    value = unit.get("value") if isinstance(unit, dict) else None
    return value if isinstance(value, str) and value else key


def set_translation(entry: dict[str, Any], locale: str, value: str, state: str = "translated") -> None:
    locs = entry.setdefault("localizations", {})
    locs[locale] = {"stringUnit": {"state": state, "value": value}}


def translation_exists(entry: dict[str, Any], locale: str) -> bool:
    unit = entry.get("localizations", {}).get(locale, {}).get("stringUnit", {})
    return isinstance(unit.get("value"), str) and unit.get("value") != ""


def should_translate_entry(entry: dict[str, Any]) -> bool:
    # Xcode may mark stale/deleted strings. Keep this conservative.
    return not entry.get("shouldTranslate") is False


def run_with_retries(fn, *, max_retries: int, initial_backoff: float, max_backoff: float, retry_forever: bool) -> str:
    attempt = 0
    while True:
        try:
            return fn()
        except urllib.error.HTTPError as exc:
            retryable = exc.code in {408, 429, 500, 502, 503, 504}
            message = f"HTTP {exc.code}"
        except (urllib.error.URLError, TimeoutError, RuntimeError, json.JSONDecodeError) as exc:
            retryable = True
            message = str(exc)
        except Exception as exc:
            retryable = False
            message = str(exc)

        attempt += 1
        if not retryable or (not retry_forever and attempt > max_retries):
            raise RuntimeError(message)

        wait = min(max_backoff, initial_backoff * (2 ** (attempt - 1)))
        wait = wait * (0.85 + random.random() * 0.3)
        print(f"  rate/network issue: {message}; retrying in {wait:.1f}s", file=sys.stderr)
        time.sleep(wait)


def status(data: dict[str, Any], locales: list[str], overwrite: bool) -> tuple[int, int]:
    strings = data.get("strings", {})
    total = 0
    missing = 0
    for _key, entry in strings.items():
        if not should_translate_entry(entry):
            continue
        for locale in locales:
            total += 1
            if overwrite or not translation_exists(entry, locale):
                missing += 1
    return total, missing


def localize(args: argparse.Namespace) -> int:
    input_path: Path = args.input
    output_path: Path = args.output or input_path.with_name(input_path.stem + ".localized" + input_path.suffix)
    data = json.loads(input_path.read_text(encoding="utf-8"))
    source_locale = args.source or data.get("sourceLanguage", "en")
    locales = list(dict.fromkeys(args.locales))

    total, missing = status(data, locales, args.overwrite)
    print(f"lingua-localize {VERSION}")
    print(f"Input:  {input_path}")
    print(f"Output: {output_path}")
    print(f"Locales: {', '.join(locales)}")
    print(f"Needed: {missing}/{total} translations")
    if args.status:
        return 0
    if missing == 0:
        atomic_write_json(output_path, data)
        print("Nothing to translate; wrote normalized output.")
        return 0

    cache = TranslationCache(args.cache)
    provider = MyMemoryProvider(args.email, timeout=args.timeout)
    protector = PlaceholderProtector(args.protect_term)
    completed = total - missing
    failures: list[str] = []

    try:
        for key, entry in data.get("strings", {}).items():
            if STOP_REQUESTED:
                break
            if not should_translate_entry(entry):
                continue
            source_text = source_value_for_entry(key, entry, source_locale)
            if not source_text.strip():
                continue

            for locale in locales:
                if STOP_REQUESTED:
                    break
                if not args.overwrite and translation_exists(entry, locale):
                    continue

                req = TranslationRequest(source_locale, locale, source_text)
                cached = None if args.no_cache else cache.get(provider.name, req)
                if cached is not None:
                    translated = cached
                    origin = "cache"
                else:
                    protected, mapping = protector.protect(source_text)

                    def do_translate() -> str:
                        return protector.unprotect(provider.translate(protected, source_locale, locale), mapping)

                    try:
                        translated = run_with_retries(
                            do_translate,
                            max_retries=args.max_retries,
                            initial_backoff=args.initial_backoff,
                            max_backoff=args.max_backoff,
                            retry_forever=args.retry_forever,
                        )
                        if not args.no_cache:
                            cache.put(provider.name, req, translated)
                        origin = "api"
                        time.sleep(args.delay)
                    except Exception as exc:
                        msg = f"{locale} {source_text!r}: {exc}"
                        failures.append(msg)
                        print(f"FAILED {msg}", file=sys.stderr)
                        atomic_write_json(output_path, data)
                        if args.stop_on_error:
                            raise
                        continue

                set_translation(entry, locale, translated)
                completed += 1
                print(f"[{completed}/{total}] {locale:<7} {origin:<5} {source_text!r} -> {translated!r}")
                atomic_write_json(output_path, data)
    finally:
        atomic_write_json(output_path, data)
        cache.close()

    if STOP_REQUESTED:
        print(f"Stopped early. Progress saved to {output_path}")
        return 130
    if failures:
        print(f"Done with {len(failures)} failures. Rerun the same command to continue.", file=sys.stderr)
        return 2
    print(f"Done. Wrote {output_path}")
    return 0


def parse_args(argv: list[str]) -> argparse.Namespace:
    default_cache = Path.home() / ".cache" / "lingua-localize" / "translations.sqlite3"
    p = argparse.ArgumentParser(description="Resumable machine translation for Xcode .xcstrings files.")
    p.add_argument("input", type=Path, help="Input .xcstrings file")
    p.add_argument("-o", "--output", type=Path, help="Output .xcstrings file")
    p.add_argument("--locales", nargs="+", default=DEFAULT_LOCALES, help="Target locales")
    p.add_argument("--source", default=None, help="Source locale; defaults to sourceLanguage in the file, then en")
    p.add_argument("--email", default=None, help="Optional email for MyMemory's higher free quota")
    p.add_argument("--cache", type=Path, default=default_cache, help="SQLite translation cache path")
    p.add_argument("--no-cache", action="store_true", help="Disable reading/writing the cache")
    p.add_argument("--overwrite", action="store_true", help="Overwrite existing localizations")
    p.add_argument("--status", action="store_true", help="Only print translation counts")
    p.add_argument("--delay", type=float, default=0.35, help="Delay after successful API requests")
    p.add_argument("--timeout", type=float, default=30.0, help="HTTP timeout in seconds")
    p.add_argument("--max-retries", type=int, default=8, help="Retries per translation before giving up")
    p.add_argument("--retry-forever", action="store_true", help="Retry rate-limited requests until interrupted")
    p.add_argument("--initial-backoff", type=float, default=15.0, help="First retry delay in seconds")
    p.add_argument("--max-backoff", type=float, default=900.0, help="Maximum retry delay in seconds")
    p.add_argument("--stop-on-error", action="store_true", help="Stop immediately on a failed translation")
    p.add_argument("--protect-term", action="append", default=DEFAULT_PROTECTED_TERMS.copy(), help="Term to preserve exactly; can be repeated")
    return p.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    return localize(args)


if __name__ == "__main__":
    raise SystemExit(main())
