#!/usr/bin/env python3

"""Deterministic, cursor-free renderer for calm laboratory recordings."""

from __future__ import annotations

import random
import shutil
import subprocess
import textwrap
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


WIDTH = 1920
HEIGHT = 1080
MONO_PATH = "/System/Library/Fonts/SFNSMono.ttf"
FONT_SIZE = 29
LINE_HEIGHT = 39
LEFT = 58
TOP = 91
MAX_ROWS = 24
COLS = 104

BG = "#0d1117"
BAR = "#161b22"
PANEL = "#111923"
TEXT = "#d8dee9"
DIM = "#8b949e"
GREEN = "#7ee787"
CYAN = "#79c0ff"
YELLOW = "#e3b341"
RED = "#ff7b72"
PURPLE = "#d2a8ff"


class Recording:
    def __init__(
        self,
        build_dir: Path,
        output_video: Path,
        screenshots_dir: Path,
        title: str,
        target_seconds: float = 930.0,
        seed: int = 20260829,
    ) -> None:
        self.build_dir = build_dir
        self.output_video = output_video
        self.screenshots_dir = screenshots_dir
        self.title = title
        self.target_seconds = target_seconds
        self.rng = random.Random(seed)
        self.font = ImageFont.truetype(MONO_PATH, FONT_SIZE)
        self.small = ImageFont.truetype(MONO_PATH, 22)
        self.tiny = ImageFont.truetype(MONO_PATH, 18)
        self.lines: list[tuple[str, str]] = []
        self.prompt = "dakuokkonen@lab01:~/study$"
        self.current = ""
        self.editor_file = ""
        self.editor_text = ""
        self.mode = "terminal"
        self.frames: list[tuple[Path, float]] = []
        self.counter = 0

        if self.build_dir.exists():
            shutil.rmtree(self.build_dir)
        self.build_dir.mkdir(parents=True)
        self.screenshots_dir.mkdir(parents=True, exist_ok=True)
        self.output_video.parent.mkdir(parents=True, exist_ok=True)

    def _save(self, image: Image.Image, duration: float, snapshot: str | None = None) -> None:
        path = self.build_dir / f"frame-{self.counter:05d}.png"
        image.save(path, compress_level=3)
        self.frames.append((path, duration))
        self.counter += 1
        if snapshot:
            image.save(self.screenshots_dir / snapshot, compress_level=3)

    def _chrome(self, subtitle: str) -> tuple[Image.Image, ImageDraw.ImageDraw]:
        image = Image.new("RGB", (WIDTH, HEIGHT), BG)
        draw = ImageDraw.Draw(image)
        draw.rectangle((0, 0, WIDTH, 61), fill=BAR)
        for x, color in ((31, "#ff5f56"), (61, "#ffbd2e"), (91, "#27c93f")):
            draw.ellipse((x - 8, 22, x + 8, 38), fill=color)
        title = f"{self.title} — {subtitle}"
        tw = draw.textlength(title, font=self.small)
        draw.text(((WIDTH - tw) / 2, 18), title, font=self.small, fill=DIM)
        return image, draw

    def _terminal_rows(self) -> list[tuple[str, str]]:
        rows: list[tuple[str, str]] = []
        for kind, value in self.lines:
            chunks = textwrap.wrap(
                value,
                width=COLS,
                replace_whitespace=False,
                drop_whitespace=False,
                subsequent_indent="  ",
            ) or [""]
            rows.extend((kind, chunk.rstrip()) for chunk in chunks)
        if self.current:
            value = f"{self.prompt} {self.current}"
            chunks = textwrap.wrap(value, width=COLS, subsequent_indent="  ") or [""]
            rows.extend(("typing", chunk.rstrip()) for chunk in chunks)
        return rows[-MAX_ROWS:]

    def _terminal_color(self, kind: str, value: str) -> str:
        lower = value.lower()
        if kind in {"command", "typing"}:
            return TEXT
        if any(word in lower for word in ("error", "failed", "fatal")):
            return RED
        if any(word in lower for word in ("passed", "готов", "created", "успеш", "written")):
            return GREEN
        if value.startswith(("#", "===", "---", "Output created")):
            return YELLOW
        if value.startswith(("[master", "Pages:", "Page size:", "Test passed")):
            return CYAN
        if value.startswith(("hint:", "remote:")):
            return DIM
        return TEXT

    def _render_terminal(self) -> Image.Image:
        image, draw = self._chrome("Terminal · dakuokkonen")
        y = TOP
        for kind, value in self._terminal_rows():
            color = self._terminal_color(kind, value)
            if kind in {"command", "typing"} and "$" in value:
                prefix, command = value.split("$", 1)
                prompt = prefix + "$"
                draw.text((LEFT, y), prompt, font=self.font, fill=GREEN)
                draw.text((LEFT + draw.textlength(prompt, font=self.font), y), command, font=self.font, fill=TEXT)
            else:
                draw.text((LEFT, y), value, font=self.font, fill=color)
            y += LINE_HEIGHT
        if self.current:
            row = self._terminal_rows()[-1][1]
            cursor_x = LEFT + draw.textlength(row, font=self.font)
            cursor_y = TOP + (len(self._terminal_rows()) - 1) * LINE_HEIGHT
            draw.rectangle((cursor_x + 2, cursor_y + 4, cursor_x + 14, cursor_y + 32), fill=TEXT)
        return image

    def _editor_color(self, value: str) -> str:
        stripped = value.lstrip()
        if stripped.startswith(("#", "---")):
            return CYAN
        if stripped.startswith(("title:", "subtitle:", "author:", "institute:", "date:", "format:")):
            return PURPLE
        if stripped.startswith(("![", "```", ":::")):
            return YELLOW
        if stripped.startswith(("- ", "1. ", "2. ", "3. ")):
            return GREEN
        return TEXT

    def _render_editor(self) -> Image.Image:
        image, draw = self._chrome(f"Editor · {self.editor_file}")
        gutter = 104
        draw.rectangle((0, 61, gutter, HEIGHT - 35), fill=PANEL)
        draw.rectangle((0, HEIGHT - 35, WIDTH, HEIGHT), fill="#0b5d71")
        draw.text((20, HEIGHT - 29), "QMD", font=self.tiny, fill="#ffffff")
        draw.text((WIDTH - 500, HEIGHT - 29), "UTF-8   LF   Русский", font=self.tiny, fill="#ffffff")

        logical: list[tuple[int, str]] = []
        for number, line in enumerate(self.editor_text.splitlines() or [""], 1):
            chunks = textwrap.wrap(
                line,
                width=94,
                replace_whitespace=False,
                drop_whitespace=False,
                subsequent_indent="    ",
            ) or [""]
            logical.extend((number if idx == 0 else 0, chunk.rstrip()) for idx, chunk in enumerate(chunks))
        logical = logical[-22:]
        y = 88
        for number, value in logical:
            if number:
                label = str(number)
                draw.text((78 - draw.textlength(label, font=self.small), y + 2), label, font=self.small, fill="#56606c")
            draw.text((128, y), value, font=self.font, fill=self._editor_color(value))
            y += 42
        return image

    def frame(self, duration: float, snapshot: str | None = None) -> None:
        image = self._render_terminal() if self.mode == "terminal" else self._render_editor()
        self._save(image, duration, snapshot)

    def pause(self, seconds: float, snapshot: str | None = None) -> None:
        self.frame(seconds, snapshot)

    def terminal(self, prompt: str | None = None, clear: bool = False) -> None:
        self.mode = "terminal"
        if prompt:
            self.prompt = prompt
        if clear:
            self.lines.clear()
            self.current = ""

    def command(
        self,
        command: str,
        output: str = "",
        wait: float = 1.2,
        line_delay: float = 0.42,
        after: float = 5.0,
        snapshot: str | None = None,
    ) -> None:
        self.mode = "terminal"
        self.current = ""
        for char in command:
            self.current += char
            delay = self.rng.uniform(0.055, 0.11)
            if char == " ":
                delay += self.rng.uniform(0.03, 0.09)
            self.frame(delay)
        self.lines.append(("command", f"{self.prompt} {command}"))
        self.current = ""
        self.frame(wait)
        for line in output.splitlines():
            self.lines.append(("output", line))
            self.frame(max(0.16, line_delay + self.rng.uniform(-0.07, 0.10)))
        self.frame(after, snapshot)

    def editor(self, filename: str, initial_text: str = "") -> None:
        self.mode = "editor"
        self.editor_file = filename
        self.editor_text = initial_text
        self.frame(2.5)

    def type_text(self, text: str, after: float = 8.0, snapshot: str | None = None) -> None:
        self.mode = "editor"
        for char in text:
            self.editor_text += char
            delay = self.rng.uniform(0.05, 0.115)
            if char in " \n":
                delay += self.rng.uniform(0.03, 0.11)
            if char in ".,:;":
                delay += self.rng.uniform(0.03, 0.08)
            self.frame(delay)
        self.frame(after, snapshot)

    def show_image(
        self,
        source: Path,
        label: str,
        duration: float = 18.0,
        snapshot: str | None = None,
    ) -> None:
        image, draw = self._chrome(f"Preview · {label}")
        source_image = Image.open(source).convert("RGB")
        canvas = (WIDTH - 120, HEIGHT - 130)
        fitted = ImageOps.contain(source_image, canvas, Image.Resampling.LANCZOS)
        x = (WIDTH - fitted.width) // 2
        y = 82 + (HEIGHT - 130 - fitted.height) // 2
        draw.rounded_rectangle((x - 8, y - 8, x + fitted.width + 8, y + fitted.height + 8), radius=14, fill="#ffffff")
        image.paste(fitted, (x, y))
        self._save(image, duration, snapshot)

    def finish(self) -> None:
        base_duration = sum(duration for _, duration in self.frames)
        scale = max(1.0, self.target_seconds / base_duration)
        timeline = self.build_dir / "timeline.ffconcat"
        with timeline.open("w", encoding="utf-8") as stream:
            stream.write("ffconcat version 1.0\n")
            for path, duration in self.frames:
                safe = str(path).replace("'", "'\\''")
                stream.write(f"file '{safe}'\n")
                stream.write(f"duration {duration * scale:.6f}\n")
            safe = str(self.frames[-1][0]).replace("'", "'\\''")
            stream.write(f"file '{safe}'\n")

        subprocess.run(
            [
                "ffmpeg", "-y", "-hide_banner", "-loglevel", "warning",
                "-f", "concat", "-safe", "0", "-i", str(timeline),
                "-vf", "fps=30,format=yuv420p", "-c:v", "libx264",
                "-preset", "medium", "-crf", "19", "-movflags", "+faststart",
                "-an", str(self.output_video),
            ],
            check=True,
        )
        print(f"frames: {len(self.frames)}")
        print(f"base duration: {base_duration:.1f} s")
        print(f"final duration: {base_duration * scale:.1f} s")
        print(f"video: {self.output_video}")
