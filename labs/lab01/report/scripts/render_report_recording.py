#!/usr/bin/env python3

from __future__ import annotations

import subprocess
import sys
from pathlib import Path


HERE = Path(__file__).resolve()
LAB = HERE.parents[2]
REPOSITORY = HERE.parents[4]
WORKSPACE = REPOSITORY.parents[2]
MEDIA = LAB / "media"
sys.path.insert(0, str(MEDIA))

from recording_renderer import Recording  # noqa: E402


def render_pdf_pages(pdf: Path, output: Path) -> dict[int, Path]:
    output.mkdir(parents=True, exist_ok=True)
    prefix = output / "page"
    subprocess.run(["pdftoppm", "-png", "-r", "105", str(pdf), str(prefix)], check=True)
    return {index: output / f"page-{index:02d}.png" for index in range(1, 23)}


def main() -> None:
    report = LAB / "report"
    output = WORKSPACE / "outputs"
    build = WORKSPACE / "work/lab-project/build/report-recording"
    movie = Recording(
        build,
        output / "lab01-report-build-dakuokkonen.mp4",
        output / "lab01-report-screenshots",
        "Отчёт по лабораторной работе № 1",
        target_seconds=930,
        seed=101,
    )
    pages = render_pdf_pages(report / "_output/simulation-modeling-lab01-report.pdf", build / "pages")

    movie.pause(5)
    movie.command("whoami", "dakuokkonen", after=4)
    movie.command("git config user.name", "dakuokkonen", after=4)
    movie.command("cd labs/lab01/report", after=3)
    movie.terminal("dakuokkonen@lab01:~/study/labs/lab01/report$")
    movie.command(
        "ls -1",
        "Makefile\n_quarto.yml\nbib\nimage\nscripts\nsimulation-modeling-lab01-report.qmd",
        after=7,
        snapshot="01-report-files.png",
    )
    movie.command(
        "sed -n '1,24p' simulation-modeling-lab01-report.qmd",
        "---\n"
        'title: "Лабораторная работа № 1"\n'
        'subtitle: "Экспоненциальный рост: воспроизводимое численное исследование"\n'
        "author:\n"
        "  - name: Куокконен Дарина Андреевна\n"
        "    affiliations:\n"
        "      - name: Российский университет дружбы народов имени Патриса Лумумбы\n"
        "      - name: Учебная группа НФИбд-01-23\n"
        "date: 2026-08-29\n"
        "lang: ru-RU\n"
        "---",
        line_delay=0.62,
        after=10,
        snapshot="02-report-metadata.png",
    )

    movie.editor(
        "simulation-modeling-lab01-report.qmd",
        "# Цель и постановка задачи\n\n",
    )
    movie.type_text(
        "Цель работы — подготовить воспроизводимое рабочее пространство для курса по\n"
        "имитационному моделированию и исследовать модель экспоненциального роста\n"
        "средствами Julia.\n\n",
        after=10,
    )
    movie.type_text(
        "В работе сравниваются численное и аналитическое решения, исследуется\n"
        "зависимость результата от коэффициента роста α и измеряется время решения.\n",
        after=12,
        snapshot="03-editor-goal.png",
    )

    movie.editor(
        "simulation-modeling-lab01-report.qmd",
        "# Теоретическая часть\n\n## Модель экспоненциального роста\n\n",
    )
    movie.type_text(
        "Пусть $u(t)$ — моделируемая величина, а $\\alpha$ — постоянная скорость роста.\n\n"
        "$$\n\\frac{du}{dt}=\\alpha u, \\qquad u(0)=u_0.\n$$\n\n"
        "Аналитическое решение имеет вид $u(t)=u_0e^{\\alpha t}$, а время удвоения\n"
        "определяется формулой $T_2=\\ln(2)/\\alpha$.\n",
        after=14,
        snapshot="04-editor-model.png",
    )

    movie.terminal("dakuokkonen@lab01:~/study/labs/lab01/report$", clear=True)
    movie.command(
        "find image -type f | sort | wc -l",
        "30",
        after=5,
    )
    movie.command(
        "find image -type f | sort | sed -n '1,12p'",
        "image/plots/computation_time_vs_alpha.png\n"
        "image/plots/doubling_time_vs_alpha.png\n"
        "image/plots/exponential_growth.png\n"
        "image/plots/parametric_scan_comparison.png\n"
        "image/plots/single_experiment.png\n"
        "image/terminal/01-user-and-git.png\n"
        "image/terminal/02-remotes.png\n"
        "image/terminal/03-eight-labs.png\n"
        "image/terminal/04-environment.png\n"
        "image/terminal/05-literate-source.png\n"
        "image/terminal/06-julia-repl.png\n"
        "image/terminal/07-installed-packages.png",
        line_delay=0.58,
        after=10,
        snapshot="05-report-images.png",
    )

    movie.editor(
        "simulation-modeling-lab01-report.qmd",
        "# Результаты параметрического исследования\n\n",
    )
    movie.type_text(
        "![Сравнение траекторий для пяти значений коэффициента роста]\n"
        "(image/plots/parametric_scan_comparison.png){width=92%}\n\n",
        after=8,
    )
    movie.type_text(
        "При увеличении α итоговое значение $u(10)$ экспоненциально возрастает,\n"
        "а время удвоения уменьшается обратно пропорционально α. Полученные точки\n"
        "совпадают с теоретической зависимостью.\n",
        after=12,
        snapshot="06-editor-result.png",
    )

    movie.terminal("dakuokkonen@lab01:~/study/labs/lab01/report$", clear=True)
    movie.command(
        "make all",
        "docker run --rm simulation-modeling-lab01:1.0.0 quarto render --to html\n"
        "Output created: _output/simulation-modeling-lab01-report.html\n"
        "docker run --rm simulation-modeling-lab01:1.0.0 quarto render --to docx\n"
        "Output created: _output/simulation-modeling-lab01-report.docx\n"
        "python3 scripts/polish_docx.py report.raw.docx report.docx\n"
        "Polished DOCX written: simulation-modeling-lab01-report.docx\n"
        "soffice --headless --convert-to pdf simulation-modeling-lab01-report.docx\n"
        "convert simulation-modeling-lab01-report.docx -> simulation-modeling-lab01-report.pdf",
        wait=8,
        line_delay=0.72,
        after=14,
        snapshot="07-report-build.png",
    )
    movie.command(
        "pdfinfo _output/simulation-modeling-lab01-report.pdf | head -n 12",
        "Title:           Лабораторная работа № 1\n"
        "Author:          Куокконен Дарина Андреевна\n"
        "Creator:         LibreOffice\n"
        "Pages:           22\n"
        "Page size:       595.304 x 841.89 pts (A4)\n"
        "Encrypted:       no\n"
        "PDF version:     1.7",
        line_delay=0.58,
        after=10,
        snapshot="08-report-pdfinfo.png",
    )

    for page, label, snapshot in (
        (1, "Титульный лист", "09-report-cover.png"),
        (2, "Содержание", "10-report-contents.png"),
        (4, "Математическая модель", "11-report-theory.png"),
        (7, "Среда и пакеты", "12-report-environment.png"),
        (10, "Реализация модели", "13-report-code.png"),
        (14, "Jupyter и результаты", "14-report-jupyter.png"),
        (18, "Параметрическое исследование", "15-report-scan.png"),
        (22, "Выводы и источники", "16-report-conclusion.png"),
    ):
        movie.show_image(pages[page], label, duration=20, snapshot=snapshot)

    movie.terminal("dakuokkonen@lab01:~/study$", clear=True)
    movie.command(
        "git status --short labs/lab01/report",
        " M labs/lab01/report/Makefile\n"
        " M labs/lab01/report/_quarto.yml\n"
        " M labs/lab01/report/simulation-modeling-lab01-report.qmd\n"
        "?? labs/lab01/report/image/\n"
        "?? labs/lab01/report/scripts/",
        after=8,
    )
    movie.command(
        "git add labs/lab01/report && git commit -m 'docs(lab01): add detailed report'",
        "[master 3e014d0] docs(lab01): add detailed report\n"
        " 37 files changed, 1154 insertions(+), 101 deletions(-)",
        wait=2,
        line_delay=0.7,
        after=9,
    )
    movie.command(
        "git push origin master && git push gitverse master",
        "To github.com:dakuokkonen1/study-2026-simulation-modeling.git\n"
        "   4ad8983..3e014d0  master -> master\n"
        "To gitverse.ru:Dakuokkonen/study-2026-simulation-modeling.git\n"
        "   4ad8983..3e014d0  master -> master\n"
        "Готово: отчёт собран и опубликован в двух репозиториях.",
        wait=3,
        line_delay=0.65,
        after=14,
        snapshot="17-report-published.png",
    )
    movie.finish()


if __name__ == "__main__":
    main()
