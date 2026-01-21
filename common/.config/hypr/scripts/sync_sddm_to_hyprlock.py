#!/usr/bin/env python3
"""Generate Hyprlock color/font variables from the active SDDM theme."""

from __future__ import annotations

import configparser
import os
import pwd
import re
import socket
from pathlib import Path
from typing import Dict, Optional, Tuple


HOME = Path.home()
HYPR_DIR = HOME / ".config" / "hypr"
OUTPUT_FILE = HYPR_DIR / "sddm-lock-vars.conf"


def clamp(value: float, min_value: float, max_value: float) -> float:
    return max(min_value, min(max_value, value))


def sanitize_locale(value: Optional[str]) -> str:
    locale = (value or "").strip().strip('"')
    if not locale:
        return "C"
    if "." not in locale:
        locale = f"{locale}.UTF-8"
    return locale


def sanitize_qt_format(value: Optional[str], fallback: str) -> str:
    fmt = (value or fallback or "").strip()
    if fmt.startswith('"') and fmt.endswith('"') and len(fmt) >= 2:
        fmt = fmt[1:-1]
    fmt = fmt.replace("''", "'")
    return fmt.replace("'", "")


def multi_replace(fmt: str, replacements: Dict[str, str]) -> str:
    if not fmt:
        return ""
    pattern = re.compile("|".join(re.escape(k) for k in sorted(replacements, key=len, reverse=True)))
    return pattern.sub(lambda m: replacements[m.group(0)], fmt)


def qt_time_to_strftime(fmt: Optional[str]) -> str:
    sanitized = sanitize_qt_format(fmt, "hh:mm")
    use_12h = any(token in sanitized for token in ("AP", "ap"))
    mapping: Dict[str, str] = {
        "AP": "%p",
        "ap": "%P",
        "mm": "%M",
        "m": "%-M",
        "ss": "%S",
        "s": "%-S",
    }
    hour_tokens = {"hh": "%H", "h": "%-H"}
    if use_12h:
        hour_tokens = {"hh": "%I", "h": "%-I"}
    mapping.update(hour_tokens)
    return multi_replace(sanitized, mapping)


def qt_date_to_strftime(fmt: Optional[str]) -> str:
    sanitized = sanitize_qt_format(fmt, "dddd, MMMM dd, yyyy")
    mapping = {
        "yyyy": "%Y",
        "yy": "%y",
        "MMMM": "%B",
        "MMM": "%b",
        "MM": "%m",
        "M": "%-m",
        "dddd": "%A",
        "ddd": "%a",
        "dd": "%d",
        "d": "%-d",
    }
    return multi_replace(sanitized, mapping)


def blur_values_from_radius(blur: int) -> Tuple[int, int]:
    if blur <= 0:
        return 1, 0
    passes = max(1, min(8, blur // 8 or 1))
    size = max(2, min(20, blur // 2))
    return size, passes


def resolve_asset(
    name: Optional[str], theme_dir: Optional[Path], config_file: Optional[Path], subdir: str
) -> Optional[str]:
    if not name:
        return None
    raw = Path(name)
    candidates = []
    if raw.is_absolute():
        candidates.append(raw)
    if config_file is not None:
        candidates.append(config_file.parent.parent / subdir / raw)
    if theme_dir is not None:
        candidates.append(theme_dir / subdir / raw)
    for candidate in candidates:
        if candidate.exists():
            return str(candidate)
    return None


def anchor_from_position(position: str) -> Tuple[str, str]:
    mapping = {
        "top-left": ("left", "top"),
        "top-center": ("center", "top"),
        "top-right": ("right", "top"),
        "center-left": ("left", "center"),
        "center": ("center", "center"),
        "center-right": ("right", "center"),
        "bottom-left": ("left", "bottom"),
        "bottom-center": ("center", "bottom"),
        "bottom-right": ("right", "bottom"),
    }
    return mapping.get(position, ("center", "center"))


def anchor_offsets(
    halign: str, valign: str, padding: Tuple[int, int, int, int]
) -> Tuple[int, int]:
    top, right, bottom, left = padding
    if halign == "left":
        x = left
    elif halign == "right":
        x = -right
    else:
        x = 0

    if valign == "top":
        y = top
    elif valign == "bottom":
        y = -bottom
    else:
        y = 0

    return x, y


def build_date_command(locale: str, fmt: str) -> str:
    safe_fmt = fmt.replace("'", "")
    return f"env LC_TIME={locale} date +'{safe_fmt}'"


def read_theme_name() -> str:
    paths = [Path("/etc/sddm.conf")]
    confd = Path("/etc/sddm.conf.d")
    if confd.is_dir():
        paths.extend(sorted(confd.glob("*.conf")))

    theme: Optional[str] = None
    for path in paths:
        if not path.exists():
            continue
        parser = configparser.ConfigParser()
        parser.optionxform = str
        try:
            parser.read(path, encoding="utf-8")
        except Exception:
            continue
        if parser.has_option("Theme", "Current"):
            candidate = parser.get("Theme", "Current").strip()
            if candidate:
                theme = candidate
    return theme or "silent"


def find_theme_dir(theme_name: str) -> Optional[Path]:
    candidates = [
        Path("/usr/share/sddm/themes") / theme_name,
        Path("/usr/local/share/sddm/themes") / theme_name,
        HOME / ".local/share/sddm/themes" / theme_name,
        HOME / f"{theme_name}-theme",
        HOME / theme_name,
    ]
    if theme_name.lower() == "silent":
        candidates.append(HOME / "silent-theme")

    for cand in candidates:
        if cand.exists():
            return cand
    return None


def parse_metadata(theme_dir: Path) -> Optional[Path]:
    metadata = theme_dir / "metadata.desktop"
    if not metadata.exists():
        return None

    config_rel: Optional[str] = None
    for raw in metadata.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith(";") or line.startswith("#"):
            continue
        if line.startswith("ConfigFile="):
            config_rel = line.split("=", 1)[1].strip()
            break

    if not config_rel:
        config_rel = "configs/default.conf"

    candidate = (theme_dir / config_rel).resolve()
    return candidate if candidate.exists() else None


def color_to_rgba(value: str, opacity: Optional[float] = None) -> str:
    value = (value or "").strip()
    if not value:
        value = "#ffffff"
    if value.lower().startswith("rgba"):
        return value

    if value.startswith("#"):
        value = value[1:]

    if len(value) in (3, 4):
        value = "".join(ch * 2 for ch in value)

    r = int(value[0:2], 16)
    g = int(value[2:4], 16)
    b = int(value[4:6], 16)
    if opacity is None and len(value) == 8:
        opacity = int(value[6:8], 16) / 255
    alpha = 1.0 if opacity is None else max(0.0, min(1.0, opacity))
    return f"rgba({r},{g},{b},{alpha:.3f})"


def get_display_name() -> str:
    user = pwd.getpwuid(os.getuid())
    gecos = user.pw_gecos.split(",")[0].strip()
    return gecos or user.pw_name


def parse_config(config_file: Path, theme_dir: Optional[Path]) -> Dict[str, str]:
    parser = configparser.ConfigParser(interpolation=None)
    parser.optionxform = str
    parser.read(config_file, encoding="utf-8")

    def cfg_get(section: str, option: str, fallback: Optional[str] = None) -> Optional[str]:
        try:
            return parser.get(section, option, fallback=fallback)
        except configparser.NoSectionError:
            return fallback

    def cfg_getint(section: str, option: str, fallback: int) -> int:
        try:
            return parser.getint(section, option, fallback=fallback)
        except (configparser.NoSectionError, ValueError):
            return fallback

    def cfg_getfloat(section: str, option: str, fallback: float) -> float:
        try:
            return parser.getfloat(section, option, fallback=fallback)
        except (configparser.NoSectionError, ValueError):
            return fallback

    def cfg_getbool(section: str, option: str, fallback: bool) -> bool:
        try:
            return parser.getboolean(section, option, fallback=fallback)
        except (configparser.NoSectionError, ValueError):
            return fallback

    login_bg_name = (cfg_get("LoginScreen", "background", fallback="") or "").strip()
    lock_bg_name = (cfg_get("LockScreen", "background", fallback=login_bg_name) or login_bg_name).strip()
    background_path = resolve_asset(lock_bg_name, theme_dir, config_file, "backgrounds")

    lock_use_color = cfg_getbool("LockScreen", "use-background-color", False)
    bg_color = color_to_rgba(cfg_get("LockScreen", "background-color", fallback="#000000"))
    lock_blur = max(0, cfg_getint("LockScreen", "blur", fallback=0))
    brightness = cfg_getfloat("LockScreen", "brightness", fallback=0.0)
    saturation = cfg_getfloat("LockScreen", "saturation", fallback=0.0)

    padding_raw = (
        cfg_getint("LockScreen", "padding-top", 0),
        cfg_getint("LockScreen", "padding-right", 0),
        cfg_getint("LockScreen", "padding-bottom", 0),
        cfg_getint("LockScreen", "padding-left", 0),
    )
    fallback_margin = 100
    padding = tuple(value if value != 0 else fallback_margin for value in padding_raw)

    username_font = cfg_get("LoginScreen.LoginArea.Username", "font-family", fallback="RedHatDisplay") or "RedHatDisplay"
    username_size = cfg_getint("LoginScreen.LoginArea.Username", "font-size", fallback=16)
    username_color = color_to_rgba(cfg_get("LoginScreen.LoginArea.Username", "color", fallback="#ffffff"))

    pw_section = "LoginScreen.LoginArea.PasswordInput"
    pw_width = cfg_getint(pw_section, "width", fallback=260)
    pw_height = cfg_getint(pw_section, "height", fallback=38)
    pw_font = cfg_get(pw_section, "font-family", fallback=username_font) or username_font
    pw_font_size = cfg_getint(pw_section, "font-size", fallback=12)
    pw_content = color_to_rgba(cfg_get(pw_section, "content-color", fallback="#ffffff"))
    pw_bg = color_to_rgba(
        cfg_get(pw_section, "background-color", fallback="#ffffff"),
        cfg_getfloat(pw_section, "background-opacity", fallback=0.15),
    )
    pw_border = color_to_rgba(cfg_get(pw_section, "border-color", fallback="#ffffff"))
    pw_border_size = cfg_getint(pw_section, "border-size", fallback=0)
    pw_round_left = cfg_getint(pw_section, "border-radius-left", fallback=10)
    pw_round_right = cfg_getint(pw_section, "border-radius-right", fallback=10)
    pw_rounding = max(pw_round_left, pw_round_right)

    btn_section = "LoginScreen.LoginArea.LoginButton"
    accent = color_to_rgba(
        cfg_get(btn_section, "active-background-color", fallback="#ffffff"),
        cfg_getfloat(btn_section, "active-background-opacity", fallback=0.3),
    )
    accent_content = color_to_rgba(cfg_get(btn_section, "active-content-color", fallback="#ffffff"))

    msg_section = "LockScreen.Message"
    message_text = (cfg_get(msg_section, "text", fallback="Press Enter to unlock") or "Press Enter to unlock").strip() or "Press Enter to unlock"
    message_font_size = cfg_getint(msg_section, "font-size", fallback=12)
    message_font_family = cfg_get(msg_section, "font-family", fallback=username_font) or username_font
    message_color = color_to_rgba(cfg_get(msg_section, "color", fallback="#ffffff"))

    message_position = (cfg_get(msg_section, "position", fallback="bottom-center") or "bottom-center").strip().lower()
    msg_halign, msg_valign = anchor_from_position(message_position)
    msg_pos_x, msg_pos_y = anchor_offsets(msg_halign, msg_valign, padding)

    display_name = get_display_name()
    username = pwd.getpwuid(os.getuid()).pw_name
    hostname = socket.gethostname()
    session = os.environ.get("XDG_SESSION_DESKTOP") or os.environ.get("XDG_CURRENT_DESKTOP") or "Hyprland"

    placeholder = f"Password for {display_name}" if display_name else "Password"

    blur_size, blur_passes = blur_values_from_radius(lock_blur)
    brightness_factor = clamp(1.0 + brightness, 0.0, 2.0)
    vibrancy = clamp(saturation, 0.0, 1.0) * 0.6
    display_font_size = max(36, username_size * 4)
    sub_font_size = max(18, max(12, username_size - 4) * 3)
    input_font_scaled = max(16, pw_font_size * 2)
    hint_font_scaled = max(14, message_font_size * 2)

    date_locale = sanitize_locale(cfg_get("LockScreen.Date", "locale", fallback=""))
    clock_position = (cfg_get("LockScreen.Clock", "position", fallback="top-center") or "top-center").strip().lower()
    clock_halign, clock_valign = anchor_from_position(clock_position)
    clock_pos_x, clock_pos_y = anchor_offsets(clock_halign, clock_valign, padding)
    clock_font_family = cfg_get("LockScreen.Clock", "font-family", fallback=username_font) or username_font
    clock_font_size = max(24, cfg_getint("LockScreen.Clock", "font-size", fallback=70))
    clock_font_size_scaled = max(32, clock_font_size * 2)
    clock_color = color_to_rgba(cfg_get("LockScreen.Clock", "color", fallback="#ffffff"))
    clock_format = qt_time_to_strftime(cfg_get("LockScreen.Clock", "format", fallback="hh:mm"))
    clock_cmd = build_date_command(date_locale, clock_format)
    clock_update_ms = 1000
    if not cfg_getbool("LockScreen.Clock", "display", True):
        clock_cmd = "printf ''"
        clock_color = "rgba(0,0,0,0.0)"
        clock_font_size_scaled = 1

    date_font_family = cfg_get("LockScreen.Date", "font-family", fallback=clock_font_family) or clock_font_family
    date_font_size = max(10, cfg_getint("LockScreen.Date", "font-size", fallback=14))
    date_font_size_scaled = max(18, date_font_size * 2)
    date_color = color_to_rgba(cfg_get("LockScreen.Date", "color", fallback="#ffffff"))
    date_margin_top = cfg_getint("LockScreen.Date", "margin-top", fallback=0)
    date_format = qt_date_to_strftime(cfg_get("LockScreen.Date", "format", fallback="dddd, MMMM dd, yyyy"))
    date_cmd = build_date_command(date_locale, date_format)
    vertical_dir = -1 if clock_valign == "bottom" else 1
    date_pos_x = clock_pos_x
    date_pos_y = clock_pos_y + vertical_dir * (clock_font_size_scaled + date_margin_top)
    date_update_ms = 60000
    if not cfg_getbool("LockScreen.Date", "display", True):
        date_cmd = "printf ''"
        date_color = "rgba(0,0,0,0.0)"
        date_font_size_scaled = 1

    return {
        "sddm_background_path": background_path if background_path and not lock_use_color else "screenshot",
        "sddm_background_color": bg_color,
        "sddm_background_blur_size": str(blur_size),
        "sddm_background_blur_passes": str(blur_passes),
        "sddm_background_brightness": f"{brightness_factor:.3f}",
        "sddm_background_vibrancy": f"{vibrancy:.3f}",
        "sddm_login_font": username_font,
        "sddm_username_font_size": str(username_size),
        "sddm_username_color": username_color,
        "sddm_username_sub_font_size": str(max(12, username_size - 4)),
        "sddm_username_sub_color": message_color,
        "sddm_input_width": str(pw_width),
        "sddm_input_height": str(pw_height),
        "sddm_input_font": pw_font,
        "sddm_input_font_size": str(pw_font_size),
        "sddm_input_font_color": pw_content,
        "sddm_input_inner_color": pw_bg,
        "sddm_input_outline_color": pw_border,
        "sddm_input_outline_thickness": str(pw_border_size),
        "sddm_input_rounding": str(pw_rounding),
        "sddm_input_placeholder": placeholder,
        "sddm_accent_color": accent,
        "sddm_accent_text_color": accent_content,
        "sddm_hint_text": message_text,
        "sddm_hint_font_size": str(message_font_size),
        "sddm_hint_color": message_color,
        "sddm_hint_font_family": message_font_family,
        "sddm_hint_halign": msg_halign,
        "sddm_hint_valign": msg_valign,
        "sddm_hint_pos_x": str(msg_pos_x),
        "sddm_hint_pos_y": str(msg_pos_y),
        "sddm_display_name": display_name,
        "sddm_username": username,
        "sddm_host_label": f"{session} - {hostname}",
        "sddm_display_font_size": str(display_font_size),
        "sddm_sub_display_font_size": str(sub_font_size),
        "sddm_input_font_size_scaled": str(input_font_scaled),
        "sddm_hint_font_size_scaled": str(hint_font_scaled),
        "sddm_lock_clock_cmd": clock_cmd,
        "sddm_lock_clock_color": clock_color,
        "sddm_lock_clock_font": clock_font_family,
        "sddm_lock_clock_font_size": str(clock_font_size_scaled),
        "sddm_lock_clock_pos_x": str(clock_pos_x),
        "sddm_lock_clock_pos_y": str(clock_pos_y),
        "sddm_lock_clock_halign": clock_halign,
        "sddm_lock_clock_valign": clock_valign,
        "sddm_lock_clock_update_ms": str(clock_update_ms),
        "sddm_lock_date_cmd": date_cmd,
        "sddm_lock_date_color": date_color,
        "sddm_lock_date_font": date_font_family,
        "sddm_lock_date_font_size": str(date_font_size_scaled),
        "sddm_lock_date_pos_x": str(date_pos_x),
        "sddm_lock_date_pos_y": str(date_pos_y),
        "sddm_lock_date_halign": clock_halign,
        "sddm_lock_date_valign": clock_valign,
        "sddm_lock_date_update_ms": str(date_update_ms),
    }


def default_values() -> Dict[str, str]:
    user = pwd.getpwuid(os.getuid())
    return {
        "sddm_background_path": "screenshot",
        "sddm_background_color": "rgba(0,0,0,1.000)",
        "sddm_background_blur_size": "1",
        "sddm_background_blur_passes": "0",
        "sddm_background_brightness": "1.000",
        "sddm_background_vibrancy": "0.000",
        "sddm_login_font": "RedHatDisplay",
        "sddm_username_font_size": "16",
        "sddm_username_color": "rgba(255,255,255,1.000)",
        "sddm_username_sub_font_size": "14",
        "sddm_username_sub_color": "rgba(255,255,255,1.000)",
        "sddm_input_width": "260",
        "sddm_input_height": "38",
        "sddm_input_font": "RedHatDisplay",
        "sddm_input_font_size": "12",
        "sddm_input_font_color": "rgba(255,255,255,1.000)",
        "sddm_input_inner_color": "rgba(255,255,255,0.150)",
        "sddm_input_outline_color": "rgba(255,255,255,1.000)",
        "sddm_input_outline_thickness": "0",
        "sddm_input_rounding": "12",
        "sddm_input_placeholder": f"Password for {get_display_name()}",
        "sddm_accent_color": "rgba(255,255,255,0.300)",
        "sddm_accent_text_color": "rgba(255,255,255,1.000)",
        "sddm_hint_text": "Press Enter to unlock",
        "sddm_hint_font_size": "12",
        "sddm_hint_color": "rgba(255,255,255,1.000)",
        "sddm_hint_font_family": "RedHatDisplay",
        "sddm_hint_halign": "center",
        "sddm_hint_valign": "bottom",
        "sddm_hint_pos_x": "0",
        "sddm_hint_pos_y": "-80",
        "sddm_display_name": get_display_name(),
        "sddm_username": user.pw_name,
        "sddm_host_label": f"Hyprland - {socket.gethostname()}",
        "sddm_display_font_size": "64",
        "sddm_sub_display_font_size": "36",
        "sddm_input_font_size_scaled": "24",
        "sddm_hint_font_size_scaled": "24",
        "sddm_lock_clock_cmd": "env LC_TIME=C date +'%H:%M'",
        "sddm_lock_clock_color": "rgba(255,255,255,1.000)",
        "sddm_lock_clock_font": "RedHatDisplay",
        "sddm_lock_clock_font_size": "120",
        "sddm_lock_clock_pos_x": "0",
        "sddm_lock_clock_pos_y": "80",
        "sddm_lock_clock_halign": "center",
        "sddm_lock_clock_valign": "top",
        "sddm_lock_clock_update_ms": "1000",
        "sddm_lock_date_cmd": "env LC_TIME=C date +'%A, %d %B %Y'",
        "sddm_lock_date_color": "rgba(255,255,255,1.000)",
        "sddm_lock_date_font": "RedHatDisplay",
        "sddm_lock_date_font_size": "40",
        "sddm_lock_date_pos_x": "0",
        "sddm_lock_date_pos_y": "200",
        "sddm_lock_date_halign": "center",
        "sddm_lock_date_valign": "top",
        "sddm_lock_date_update_ms": "60000",
    }


def write_output(theme: str, values: Dict[str, str]) -> None:
    HYPR_DIR.mkdir(parents=True, exist_ok=True)
    lines = ["# Auto-generated from SDDM theme. Do not edit manually."]
    lines.append(f"$sddm_theme_name = {theme}")
    for key, val in sorted(values.items()):
        safe_val = val.replace("\"", '\\"') if isinstance(val, str) else str(val)
        lines.append(f"${key} = {safe_val}")
    OUTPUT_FILE.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    theme = read_theme_name()
    theme_dir = find_theme_dir(theme)
    config_file = parse_metadata(theme_dir) if theme_dir else None

    values = parse_config(config_file, theme_dir) if config_file else default_values()
    write_output(theme, values)


if __name__ == "__main__":
    main()
