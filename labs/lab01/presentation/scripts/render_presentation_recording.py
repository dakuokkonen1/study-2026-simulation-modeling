#!/usr/bin/env python3

from __future__ import annotations

import sys
from pathlib import Path


HERE = Path(__file__).resolve()
LAB = HERE.parents[2]
REPOSITORY = HERE.parents[4]
WORKSPACE = REPOSITORY.parents[2]
MEDIA = LAB / "media"
sys.path.insert(0, str(MEDIA))

from recording_renderer import Recording  # noqa: E402


def main() -> None:
    presentation = LAB / "presentation"
    output = WORKSPACE / "outputs"
    build = WORKSPACE / "work/lab-project/build/presentation-recording"
    movie = Recording(
        build,
        output / "lab01-presentation-build-dakuokkonen.mp4",
        output / "lab01-presentation-screenshots",
        "Презентация по лабораторной работе № 1",
        target_seconds=930,
        seed=202,
    )

    movie.pause(5)
    movie.command("whoami", "dakuokkonen", after=4)
    movie.command("git config user.name", "dakuokkonen", after=4)
    movie.command("cd labs/lab01/presentation", after=3)
    movie.terminal("dakuokkonen@lab01:~/study/labs/lab01/presentation$")
    movie.command(
        "ls -1",
        "Makefile\n_quarto.yml\nimage\nscripts\nsimulation-modeling-lab01-presentation.qmd\nstyles.css",
        after=8,
        snapshot="01-presentation-files.png",
    )
    movie.command(
        "sed -n '1,18p' simulation-modeling-lab01-presentation.qmd",
        "---\n"
        'title: "Лабораторная работа № 1"\n'
        'subtitle: "Экспоненциальный рост: от модели к воспроизводимому Julia-проекту"\n'
        'author: "Куокконен Дарина Андреевна"\n'
        'institute: "РУДН имени Патриса Лумумбы · НФИбд-01-23"\n'
        "date: 2026-08-29\n"
        "lang: ru-RU\n"
        "---",
        line_delay=0.64,
        after=10,
        snapshot="02-presentation-metadata.png",
    )

    movie.editor(
        "simulation-modeling-lab01-presentation.qmd",
        "## Цель и логика выполнения\n\n",
    )
    movie.type_text(
        "- Подготовить изолированную среду Julia 1.11.\n"
        "- Реализовать одиночный и параметрический эксперименты.\n"
        "- Получить чистые скрипты, QMD и Jupyter-ноутбуки.\n",
        after=9,
    )
    movie.type_text(
        "- Выполнить ноутбуки, тесты и собрать документацию.\n"
        "- Опубликовать историю в GitHub и GitVerse.\n",
        after=12,
        snapshot="03-editor-goals.png",
    )

    movie.editor(
        "simulation-modeling-lab01-presentation.qmd",
        "## Математическая модель\n\n",
    )
    movie.type_text(
        "$$\n\\frac{du}{dt}=\\alpha u, \\qquad u(0)=u_0,\n$$\n\n"
        "$$\nu(t)=u_0e^{\\alpha t}, \\qquad T_2=\\frac{\\ln 2}{\\alpha}.\n$$\n\n",
        after=10,
    )
    movie.type_text(
        "Экспоненциальная модель применима до тех пор, пока ограничениями ресурсов\n"
        "можно пренебречь.\n",
        after=12,
        snapshot="04-editor-model.png",
    )

    movie.editor(
        "scripts/build_presentation.mjs",
        "const deck = Presentation.create({\n  slideSize: { width: 1280, height: 720 },\n});\n\n",
    )
    movie.type_text(
        "const slide = deck.slides.add();\n"
        "title(slide, 7, \"Параметрическое сканирование: α меняет масштаб роста\");\n\n",
        after=8,
    )
    movie.type_text(
        "slide.images.add({\n"
        "  blob: plotBlob,\n"
        "  fit: \"contain\",\n"
        "  frame: { left: 62, top: 158, width: 738, height: 474 },\n"
        "});\n",
        after=12,
        snapshot="05-editor-slide-code.png",
    )

    movie.terminal("dakuokkonen@lab01:~/study/labs/lab01/presentation$", clear=True)
    movie.command(
        "make all",
        "docker run --rm simulation-modeling-lab01:1.0.0 quarto render --to revealjs\n"
        "Output created: _output/simulation-modeling-lab01-presentation.html\n"
        "node scripts/build_presentation.mjs\n"
        "Inspect result written: simulation-modeling-lab01-presentation.pptx.inspect.ndjson\n"
        "soffice --headless --convert-to pdf simulation-modeling-lab01-presentation.pptx\n"
        "convert simulation-modeling-lab01-presentation.pptx -> presentation.pdf",
        wait=8,
        line_delay=0.75,
        after=14,
        snapshot="06-presentation-build.png",
    )
    movie.command(
        "python3 slides_test.py _output/simulation-modeling-lab01-presentation.pptx",
        "Rendering 11 slides for validation...\n"
        "Checking slide bounds, text boxes and image frames...\n"
        "Test passed. No overflow detected.",
        wait=3,
        line_delay=0.75,
        after=10,
        snapshot="07-presentation-test.png",
    )
    movie.command(
        "pdfinfo _output/simulation-modeling-lab01-presentation.pdf | head -n 10",
        "Title:           Presentation\n"
        "Creator:         Impress\n"
        "Pages:           11\n"
        "Page size:       960.009 x 540 pts\n"
        "Encrypted:       no\n"
        "PDF version:     1.7",
        line_delay=0.58,
        after=10,
        snapshot="08-presentation-pdfinfo.png",
    )

    slides = presentation / "_output/slides"
    labels = [
        "Титульный слайд",
        "Цель и логика выполнения",
        "Математическая модель",
        "Воспроизводимый конвейер",
        "Среда Julia",
        "Одиночный эксперимент",
        "Параметрическое сканирование",
        "Время удвоения",
        "Jupyter-ноутбуки",
        "Проверка и публикация",
        "Выводы",
    ]
    for index, label in enumerate(labels, 1):
        movie.show_image(
            slides / f"slide-{index:02d}.png",
            f"Слайд {index:02d} · {label}",
            duration=18 if index not in {1, 11} else 22,
            snapshot=f"{8 + index:02d}-slide-{index:02d}.png",
        )

    movie.terminal("dakuokkonen@lab01:~/study$", clear=True)
    movie.command(
        "git status --short labs/lab01/presentation",
        " M labs/lab01/presentation/Makefile\n"
        " M labs/lab01/presentation/_quarto.yml\n"
        " M labs/lab01/presentation/simulation-modeling-lab01-presentation.qmd\n"
        "?? labs/lab01/presentation/image/\n"
        "?? labs/lab01/presentation/scripts/\n"
        "?? labs/lab01/presentation/styles.css",
        after=8,
    )
    movie.command(
        "git add labs/lab01/presentation && git commit -m 'docs(lab01): add presentation'",
        "[master d09ee84] docs(lab01): add presentation\n"
        " 38 files changed, 1043 insertions(+), 21 deletions(-)",
        wait=2,
        line_delay=0.7,
        after=9,
    )
    movie.command(
        "git push origin master && git push gitverse master",
        "To github.com:dakuokkonen1/study-2026-simulation-modeling.git\n"
        "   31db6f7..d09ee84  master -> master\n"
        "To gitverse.ru:Dakuokkonen/study-2026-simulation-modeling.git\n"
        "   31db6f7..d09ee84  master -> master\n"
        "Готово: презентация собрана и опубликована в двух репозиториях.",
        wait=3,
        line_delay=0.65,
        after=14,
        snapshot="20-presentation-published.png",
    )
    movie.finish()


if __name__ == "__main__":
    main()
