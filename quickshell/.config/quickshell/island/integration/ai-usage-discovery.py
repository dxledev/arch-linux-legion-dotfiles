#!/usr/bin/python3

import json
import os
import re
import subprocess
import sys
import tomllib
from pathlib import Path


MAX_CATALOG_SECONDS = 8
CUSTOM_ID = re.compile(r"^[a-z0-9][a-z0-9_-]{0,31}$")


def emit_failure(message):
    sys.stdout.write(json.dumps({"ok": False, "message": message}) + "\n")
    return 1


def read_config(config_path):
    if not config_path.is_file():
        return {}

    with config_path.open("rb") as config_file:
        value = tomllib.load(config_file)
    return value if isinstance(value, dict) else {}


def path_is_configured(value):
    if not isinstance(value, str) or not value.strip():
        return False

    candidate = Path(value.strip()).expanduser()
    if not candidate.is_absolute():
        candidate = Path.home() / candidate
    return candidate.is_file() and os.access(candidate, os.R_OK)


def key_is_configured(section):
    environment_name = section.get("api_key_env")
    if isinstance(environment_name, str) and environment_name.strip():
        if os.environ.get(environment_name.strip(), ""):
            return True

    key = section.get("api_key")
    return isinstance(key, str) and bool(key.strip())


def credential_is_configured(section):
    if key_is_configured(section):
        return True

    return any(
        path_is_configured(section.get(field))
        for field in ("credentials_path", "codex_auth_path", "auth_path", "secrets_path")
    )


def valid_label(value):
    if not isinstance(value, str):
        return ""

    label = value.strip()
    if not label or len(label) > 128 or any(ord(character) < 32 for character in label):
        return ""
    return label


def add_named_accounts(provider_id, section, provider_enabled, provider_ids):
    if not provider_enabled or not isinstance(section, dict):
        return

    accounts = section.get("accounts", [])
    explicit_labels = set()
    if isinstance(accounts, list):
        for account in accounts:
            if not isinstance(account, dict):
                continue

            label = valid_label(account.get("label"))
            if label:
                explicit_labels.add(label)
            if not label or account.get("enabled", True) is not True:
                continue
            if label and credential_is_configured(account):
                provider_ids.add(f"{provider_id}@{label}")

    accounts_directory = section.get("accounts_dir")
    if isinstance(accounts_directory, str) and accounts_directory.strip():
        directory = Path(accounts_directory.strip()).expanduser()
        if not directory.is_absolute():
            directory = Path.home() / directory
        try:
            account_directories = sorted(directory.iterdir(), key=lambda item: item.name)
        except OSError:
            return

        for account_directory in account_directories:
            label = valid_label(account_directory.name)
            if not label or label in explicit_labels or not account_directory.is_dir():
                continue
            if path_is_configured(str(account_directory / ".credentials.json")):
                provider_ids.add(f"{provider_id}@{label}")


def configured_provider_ids(catalog, config):
    if not isinstance(catalog, dict):
        raise ValueError

    rows = catalog.get("vendors")
    if not isinstance(rows, list) or not rows:
        raise ValueError

    provider_ids = set()
    enabled_by_id = {}

    for row in rows:
        if not isinstance(row, dict):
            continue
        provider_id = row.get("id")
        if not isinstance(provider_id, str) or not provider_id:
            continue

        enabled = row.get("enabled") is True
        configured = row.get("configured") is True
        enabled_by_id[provider_id] = enabled
        if enabled and configured:
            provider_ids.add(provider_id)

    for provider_id, enabled in enabled_by_id.items():
        section = config.get(provider_id)
        add_named_accounts(provider_id, section, enabled, provider_ids)

    custom_providers = config.get("custom", [])
    if isinstance(custom_providers, list):
        for custom in custom_providers:
            if not isinstance(custom, dict) or custom.get("enabled") is not True:
                continue

            custom_id = custom.get("id")
            if isinstance(custom_id, str) and CUSTOM_ID.fullmatch(custom_id) and key_is_configured(custom):
                provider_ids.add(f"custom:{custom_id}")

    return sorted(provider_ids)


def main(arguments):
    if len(arguments) not in (2, 3):
        return emit_failure("Configured AI providers could not be checked.")

    binary = Path(arguments[1])
    if not binary.is_absolute() or not os.access(binary, os.X_OK):
        return emit_failure("Configured AI providers could not be checked.")

    config_path = Path(arguments[2]).expanduser() if len(arguments) == 3 else Path.home() / ".config/ai-usagebar/config.toml"
    if not config_path.is_absolute():
        return emit_failure("Configured AI providers could not be checked.")

    command = [str(binary), "vendors", "--json"]
    if len(arguments) == 3:
        command.extend(("--config", str(config_path)))

    try:
        completed = subprocess.run(command, capture_output=True, text=True, timeout=MAX_CATALOG_SECONDS, check=False)
        if completed.returncode != 0:
            return emit_failure("Configured AI providers could not be checked.")

        catalog = json.loads(completed.stdout)
        config = read_config(config_path)
        provider_ids = configured_provider_ids(catalog, config)
    except (OSError, UnicodeError, subprocess.TimeoutExpired, json.JSONDecodeError, tomllib.TOMLDecodeError, ValueError):
        return emit_failure("Configured AI providers could not be checked.")

    sys.stdout.write(json.dumps({"ok": True, "providerIds": provider_ids}, separators=(",", ":")) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
