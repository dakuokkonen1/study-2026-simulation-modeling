import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const modulePath = process.env.ARTIFACT_TOOL_MODULE;
if (!modulePath) {
  throw new Error("ARTIFACT_TOOL_MODULE is not set");
}
const { Presentation, PresentationFile } = await import(pathToFileURL(modulePath));

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, "..");
const OUTPUT = path.join(ROOT, "_output");
const SLIDES = path.join(OUTPUT, "slides");

const C = {
  bg: "#071923",
  bg2: "#0B2531",
  panel: "#103440",
  panel2: "#153F4B",
  text: "#F2FBFC",
  muted: "#AFC8CF",
  accent: "#36D3B5",
  blue: "#70C7EC",
  orange: "#F3A75B",
  white: "#FFFFFF",
  ink: "#102731",
  soft: "#EAF2F3",
};

const presentation = Presentation.create({ slideSize: { width: 1280, height: 720 } });

async function bytes(relativePath) {
  const data = await fs.readFile(path.join(ROOT, relativePath));
  return data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
}

async function writeBlob(destination, blob) {
  await fs.writeFile(destination, new Uint8Array(await blob.arrayBuffer()));
}

function box(slide, x, y, w, h, fill = C.panel, radius = "rounded-xl", line = "none", name) {
  const config = {
    geometry: radius === "none" ? "rect" : "roundRect",
    name,
    position: { left: x, top: y, width: w, height: h },
    fill,
    line: { style: "solid", fill: line, width: line === "none" ? 0 : 1 },
  };
  if (radius !== "none") config.borderRadius = radius;
  return slide.shapes.add(config);
}

function text(slide, value, x, y, w, h, style = {}, name) {
  const shape = slide.shapes.add({
    geometry: "textbox",
    name,
    position: { left: x, top: y, width: w, height: h },
    fill: "none",
    line: { style: "solid", fill: "none", width: 0 },
  });
  shape.text = value;
  shape.text.style = {
    fontFamily: "Aptos",
    fontSize: 20,
    color: C.text,
    ...style,
  };
  return shape;
}

function rule(slide, x, y, w, color = C.accent, height = 4) {
  return box(slide, x, y, w, height, color, "none", "none");
}

function title(slide, number, heading, kicker = "ЛАБОРАТОРНАЯ РАБОТА № 1") {
  text(slide, kicker, 62, 34, 520, 24, { fontSize: 12, bold: true, color: C.accent, letterSpacing: 1.2 });
  text(slide, heading, 62, 66, 1040, 58, { fontSize: 34, bold: true, color: C.text }, `title-${number}`);
  text(slide, String(number).padStart(2, "0"), 1140, 48, 70, 36, { fontSize: 18, bold: true, color: C.muted });
  rule(slide, 62, 128, 1156, C.panel2, 2);
}

function footer(slide) {
  text(slide, "Куокконен Дарина Андреевна · НФИбд-01-23", 62, 686, 720, 18, { fontSize: 10, color: C.muted });
  text(slide, "РУДН · имитационное моделирование", 940, 686, 278, 18, { fontSize: 10, color: C.muted });
}

function bullet(slide, label, detail, x, y, w, index, color = C.accent) {
  box(slide, x, y + 3, 34, 34, color, "rounded-xl", "none");
  text(slide, String(index), x, y + 7, 34, 24, { fontSize: 14, bold: true, color: C.bg });
  text(slide, label, x + 50, y, w - 50, 28, { fontSize: 19, bold: true, color: C.text });
  text(slide, detail, x + 50, y + 31, w - 50, 32, { fontSize: 13, color: C.muted });
}

function metric(slide, value, label, x, y, w, color = C.accent) {
  box(slide, x, y, w, 92, C.panel, "rounded-xl", C.panel2);
  text(slide, value, x + 16, y + 14, w - 32, 38, { fontSize: 28, bold: true, color });
  text(slide, label, x + 16, y + 57, w - 32, 20, { fontSize: 12, color: C.muted });
}

async function image(slide, relativePath, x, y, w, h, alt, fit = "contain") {
  box(slide, x, y, w, h, C.white, "rounded-xl", C.panel2);
  return slide.images.add({
    blob: await bytes(relativePath),
    contentType: "image/png",
    alt,
    fit,
    position: { left: x + 8, top: y + 8, width: w - 16, height: h - 16 },
    geometry: "roundRect",
    borderRadius: "rounded-lg",
  });
}

function notes(slide, body, sources) {
  slide.speakerNotes.textFrame.setText(`${body}\n\n[Sources]\n${sources.map((source) => `- ${source}`).join("\n")}`);
  slide.speakerNotes.setVisible(true);
}

// 1 — Title
{
  const slide = presentation.slides.add();
  slide.background.fill = `linear(145deg, ${C.bg} 0%, #0B2F3A 100%)`;
  box(slide, 760, 0, 520, 720, C.panel, "none", "none");
  text(slide, "РОССИЙСКИЙ УНИВЕРСИТЕТ ДРУЖБЫ НАРОДОВ\nИМЕНИ ПАТРИСА ЛУМУМБЫ", 64, 44, 610, 54, { fontSize: 13, bold: true, color: C.muted });
  text(slide, "Лабораторная\nработа № 1", 64, 156, 650, 132, { fontSize: 52, bold: true, color: C.text }, "cover-title");
  rule(slide, 64, 308, 178, C.accent, 7);
  text(slide, "Экспоненциальный рост", 64, 342, 650, 50, { fontSize: 30, bold: true, color: C.accent });
  text(slide, "От модели du/dt = αu — к воспроизводимому Julia-проекту", 64, 400, 615, 70, { fontSize: 20, color: C.muted });
  text(slide, "Куокконен Дарина Андреевна", 64, 580, 550, 30, { fontSize: 19, bold: true, color: C.text });
  text(slide, "НФИбд-01-23 · Москва, 2026", 64, 617, 550, 26, { fontSize: 15, color: C.muted });

  text(slide, "u(t)", 820, 102, 160, 46, { fontSize: 28, bold: true, color: C.blue });
  text(slide, "=", 980, 102, 50, 46, { fontSize: 28, color: C.muted });
  text(slide, "u₀eᵅᵗ", 1034, 90, 190, 60, { fontSize: 40, bold: true, color: C.accent });
  rule(slide, 816, 176, 350, C.panel2, 2);
  text(slide, "α = 0.3", 816, 218, 164, 34, { fontSize: 22, bold: true, color: C.orange });
  text(slide, "u(10) ≈ 20.0855", 816, 278, 350, 36, { fontSize: 24, bold: true, color: C.text });
  text(slide, "T₂ = ln(2)/α ≈ 2.3105", 816, 338, 370, 34, { fontSize: 21, color: C.text });
  box(slide, 816, 430, 350, 150, C.bg2, "rounded-xl", C.panel2);
  text(slide, "Julia 1.11", 840, 456, 130, 28, { fontSize: 17, bold: true, color: C.blue });
  text(slide, "DrWatson · Literate", 840, 496, 250, 24, { fontSize: 15, color: C.muted });
  text(slide, "Jupyter · Quarto · Git", 840, 530, 250, 24, { fontSize: 15, color: C.muted });
  notes(slide, "Титульный слайд. Работа посвящена модели экспоненциального роста и воспроизводимому вычислительному конвейеру.", [
    "/Users/qxar/Downloads/simulation-modeling-lab.pdf, раздел 1.10",
    "labs/lab01/project/Project.toml",
  ]);
}

// 2 — Goal and assignment
{
  const slide = presentation.slides.add();
  slide.background.fill = C.bg;
  title(slide, 2, "Цель и логика выполнения");
  bullet(slide, "Подготовить среду", "Изолированный контейнер, Julia 1.11 и закреплённые зависимости", 70, 164, 540, 1);
  bullet(slide, "Реализовать модель", "Одиночный эксперимент и сканирование пяти значений α", 70, 252, 540, 2, C.blue);
  bullet(slide, "Сгенерировать форматы", "Чистые скрипты, QMD и выполненные Jupyter-ноутбуки", 70, 340, 540, 3, C.orange);
  bullet(slide, "Проверить результат", "Графики, таблицы, тесты, GitHub, GitVerse и релиз", 70, 428, 540, 4);
  box(slide, 680, 164, 510, 386, C.panel, "rounded-xl", C.panel2);
  text(slide, "Результат работы", 712, 194, 400, 34, { fontSize: 22, bold: true, color: C.text });
  const stages = [
    ["литературный код", C.accent],
    ["вычисления", C.blue],
    ["ноутбуки", C.orange],
    ["документация", C.accent],
    ["тесты и релиз", C.blue],
  ];
  stages.forEach(([label, color], index) => {
    const y = 252 + index * 54;
    box(slide, 714, y, 34, 34, color, "rounded-xl", "none");
    text(slide, label, 766, y + 3, 350, 28, { fontSize: 17, bold: true, color: C.text });
    if (index < stages.length - 1) box(slide, 729, y + 36, 4, 18, C.panel2, "none", "none");
  });
  text(slide, "Все этапы повторяются командами make", 712, 512, 410, 24, { fontSize: 14, color: C.muted });
  footer(slide);
  notes(slide, "Цель — не только решить ОДУ, но и получить воспроизводимые производные форматы, выполнить ноутбуки и зафиксировать результат.", [
    "/Users/qxar/Downloads/simulation-modeling-lab.pdf, с. 85–86",
  ]);
}

// 3 — Model
{
  const slide = presentation.slides.add();
  slide.background.fill = C.bg;
  title(slide, 3, "Математическая модель");
  box(slide, 68, 168, 550, 210, C.panel, "rounded-xl", C.panel2);
  text(slide, "du/dt = αu", 108, 198, 470, 58, { fontSize: 42, bold: true, color: C.accent });
  text(slide, "u(0) = u₀", 108, 270, 470, 38, { fontSize: 26, color: C.text });
  text(slide, "u(t) = u₀eᵅᵗ", 108, 324, 470, 40, { fontSize: 30, bold: true, color: C.blue });
  box(slide, 664, 168, 526, 210, C.panel, "rounded-xl", C.panel2);
  text(slide, "Время удвоения", 700, 198, 430, 30, { fontSize: 20, bold: true, color: C.text });
  text(slide, "T₂ = ln(2) / α", 700, 246, 430, 48, { fontSize: 34, bold: true, color: C.orange });
  text(slide, "α > 0 — рост\nα = 0 — постоянное значение\nα < 0 — затухание", 700, 306, 430, 66, { fontSize: 16, color: C.muted });
  box(slide, 68, 414, 1122, 190, C.bg2, "rounded-xl", C.panel2);
  text(slide, "Где модель полезна", 96, 442, 310, 30, { fontSize: 20, bold: true, color: C.text });
  text(slide, "популяции · сложный процент · ранняя стадия эпидемии", 96, 484, 490, 44, { fontSize: 17, color: C.muted });
  text(slide, "Ключевое ограничение", 652, 442, 310, 30, { fontSize: 20, bold: true, color: C.text });
  text(slide, "Неограниченные ресурсы; на больших временах рост переоценивается", 652, 484, 480, 58, { fontSize: 17, color: C.muted });
  text(slide, "Источник: методические указания, раздел 1.10", 96, 570, 500, 18, { fontSize: 10, color: C.muted });
  footer(slide);
  notes(slide, "Показано уравнение, аналитическое решение и время удвоения. Экспоненциальная модель идеализирована и применима только пока ограничения ресурсов несущественны.", [
    "/Users/qxar/Downloads/simulation-modeling-lab.pdf, с. 70–71",
  ]);
}

// 4 — Reproducible workflow
{
  const slide = presentation.slides.add();
  slide.background.fill = C.bg;
  title(slide, 4, "Воспроизводимый вычислительный конвейер");
  const nodes = [
    ["01", "Literate.jl", "литературный код", C.accent],
    ["02", "Julia", "численное решение", C.blue],
    ["03", "Jupyter", "интерактивный запуск", C.orange],
    ["04", "Quarto", "HTML и документы", C.accent],
    ["05", "Git", "тесты и релиз", C.blue],
  ];
  nodes.forEach(([num, label, detail, color], index) => {
    const x = 62 + index * 235;
    box(slide, x, 212, 190, 170, C.panel, "rounded-xl", C.panel2);
    text(slide, num, x + 18, 230, 48, 28, { fontSize: 13, bold: true, color });
    text(slide, label, x + 18, 274, 154, 34, { fontSize: 22, bold: true, color: C.text });
    text(slide, detail, x + 18, 322, 154, 40, { fontSize: 13, color: C.muted });
    if (index < nodes.length - 1) {
      const arrow = slide.shapes.add({
        geometry: "rightArrow",
        position: { left: x + 194, top: 274, width: 38, height: 34 },
        fill: C.panel2,
        line: { style: "solid", fill: "none", width: 0 },
      });
    }
  });
  box(slide, 62, 426, 1126, 132, C.bg2, "rounded-xl", C.panel2);
  text(slide, "Одна команда", 92, 454, 210, 26, { fontSize: 18, bold: true, color: C.text });
  text(slide, "make all", 92, 492, 210, 34, { fontSize: 25, bold: true, color: C.accent });
  text(slide, "→ скрипты  → данные  → графики  → ноутбуки  → HTML  → тесты", 334, 480, 800, 42, { fontSize: 18, bold: true, color: C.text });
  footer(slide);
  notes(slide, "Конвейер начинается с литературного исходника и заканчивается проверенным релизом. Каждый этап запускается отдельно или общей целью make all.", [
    "labs/lab01/project/Makefile",
    "labs/lab01/project/scripts/tangle.jl",
  ]);
}

// 5 — Environment
{
  const slide = presentation.slides.add();
  slide.background.fill = C.bg;
  title(slide, 5, "Среда Julia и закреплённые пакеты");
  await image(slide, "image/terminal/07-installed-packages.png", 62, 166, 706, 446, "Состояние Julia-проекта и установленные пакеты");
  box(slide, 802, 166, 386, 446, C.panel, "rounded-xl", C.panel2);
  text(slide, "Основа", 832, 196, 300, 26, { fontSize: 18, bold: true, color: C.text });
  text(slide, "Julia 1.11.9\nDifferentialEquations 8.1.1\nDrWatson 2.19.1", 832, 238, 310, 92, { fontSize: 18, color: C.blue });
  rule(slide, 832, 350, 310, C.panel2, 2);
  text(slide, "Производные форматы", 832, 374, 310, 26, { fontSize: 18, bold: true, color: C.text });
  text(slide, "Literate 2.21.0\nIJulia 1.34.4\nQuarto 1.0.0", 832, 416, 310, 92, { fontSize: 18, color: C.accent });
  text(slide, "Manifest.toml фиксирует транзитивные версии", 832, 548, 310, 40, { fontSize: 13, color: C.muted });
  footer(slide);
  notes(slide, "Показан фактический вывод Pkg.status(). Зависимости изолированы в контейнере и закреплены Manifest.toml.", [
    "labs/lab01/project/Manifest.toml",
    "labs/lab01/presentation/image/terminal/07-installed-packages.png",
  ]);
}

// 6 — Base experiment
{
  const slide = presentation.slides.add();
  slide.background.fill = C.bg;
  title(slide, 6, "Одиночный эксперимент: численное решение совпадает с точным");
  await image(slide, "image/plots/exponential_growth.png", 62, 158, 760, 474, "Сравнение численного и аналитического решений");
  metric(slide, "20.0854485", "u(10), численно", 860, 174, 300, C.blue);
  metric(slide, "4.40 × 10⁻⁶", "относительная ошибка", 860, 284, 300, C.accent);
  metric(slide, "2.31049", "теоретическое T₂", 860, 394, 300, C.orange);
  text(slide, "u₀ = 1 · α = 0.3 · t ∈ [0, 10]", 860, 520, 300, 30, { fontSize: 16, bold: true, color: C.text });
  text(slide, "101 сохранённая точка", 860, 562, 300, 24, { fontSize: 13, color: C.muted });
  footer(slide);
  notes(slide, "Сплошная численная и пунктирная аналитическая кривые практически неразличимы. Относительная ошибка порядка 10^-6 подтверждает корректность реализации.", [
    "labs/lab01/project/data/01_exponential_growth/trajectory.csv",
    "labs/lab01/project/plots/01_exponential_growth/exponential_growth.png",
  ]);
}

// 7 — Parameter scan
{
  const slide = presentation.slides.add();
  slide.background.fill = C.bg;
  title(slide, 7, "Параметрическое сканирование: α меняет масштаб роста");
  await image(slide, "image/plots/parametric_scan_comparison.png", 62, 158, 738, 474, "Сравнение траекторий пяти значений коэффициента роста");
  box(slide, 834, 158, 354, 474, C.panel, "rounded-xl", C.panel2);
  text(slide, "α", 860, 188, 60, 24, { fontSize: 15, bold: true, color: C.muted });
  text(slide, "u(10)", 948, 188, 120, 24, { fontSize: 15, bold: true, color: C.muted });
  text(slide, "T₂", 1090, 188, 70, 24, { fontSize: 15, bold: true, color: C.muted });
  rule(slide, 858, 220, 302, C.panel2, 2);
  const rows = [
    ["0.1", "2.7183", "6.9315"],
    ["0.3", "20.0854", "2.3105"],
    ["0.5", "148.4086", "1.3863"],
    ["0.8", "2 980.5736", "0.8664"],
    ["1.0", "22 021.0156", "0.6931"],
  ];
  rows.forEach((row, index) => {
    const y = 240 + index * 54;
    if (index % 2 === 0) box(slide, 852, y - 4, 316, 42, C.bg2, "rounded-xl", "none");
    text(slide, row[0], 860, y, 70, 26, { fontSize: 16, bold: true, color: C.accent });
    text(slide, row[1], 948, y, 130, 26, { fontSize: 16, color: C.text });
    text(slide, row[2], 1090, y, 78, 26, { fontSize: 16, color: C.text });
  });
  text(slide, "При α = 1 итог больше базового результата примерно в 1 096 раз", 858, 540, 306, 54, { fontSize: 14, bold: true, color: C.orange });
  footer(slide);
  notes(slide, "При фиксированном начальном условии итоговое значение экспоненциально зависит от α. Таблица взята из фактического CSV параметрического эксперимента.", [
    "labs/lab01/project/data/02_exponential_growth/parameter_summary.csv",
    "labs/lab01/project/plots/02_exponential_growth/parametric_scan_comparison.png",
  ]);
}

// 8 — Time and performance
{
  const slide = presentation.slides.add();
  slide.background.fill = C.bg;
  title(slide, 8, "Время удвоения и стоимость решения");
  await image(slide, "image/plots/doubling_time_vs_alpha.png", 62, 164, 550, 372, "Зависимость времени удвоения от коэффициента роста");
  await image(slide, "image/plots/computation_time_vs_alpha.png", 646, 164, 550, 372, "Время численного решения для разных коэффициентов роста");
  box(slide, 62, 558, 550, 80, C.panel, "rounded-xl", C.panel2);
  text(slide, "T₂ = ln(2)/α", 84, 576, 190, 30, { fontSize: 22, bold: true, color: C.accent });
  text(slide, "точки лежат на теоретической кривой", 282, 581, 300, 24, { fontSize: 14, color: C.muted });
  box(slide, 646, 558, 550, 80, C.panel, "rounded-xl", C.panel2);
  text(slide, "6–8 мкс", 670, 576, 150, 30, { fontSize: 22, bold: true, color: C.blue });
  text(slide, "устойчивого тренда по α нет", 830, 581, 320, 24, { fontSize: 14, color: C.muted });
  footer(slide);
  notes(slide, "Левая диаграмма подтверждает формулу времени удвоения. Правая показывает, что при одинаковом интервале и настройках решателя изменение α почти не влияет на время вычисления.", [
    "labs/lab01/project/data/02_exponential_growth/benchmark_summary.csv",
    "labs/lab01/project/plots/02_exponential_growth/doubling_time_vs_alpha.png",
    "labs/lab01/project/plots/02_exponential_growth/computation_time_vs_alpha.png",
  ]);
}

// 9 — Notebooks
{
  const slide = presentation.slides.add();
  slide.background.fill = C.bg;
  title(slide, 9, "Оба Jupyter-ноутбука выполнены в интерфейсе");
  await image(slide, "image/terminal/jupyter-03-notebook-01-complete.png", 62, 164, 550, 430, "Завершённый ноутбук одиночного эксперимента", "cover");
  await image(slide, "image/terminal/jupyter-06-notebook-02-results.png", 646, 164, 550, 430, "Результаты параметрического ноутбука", "cover");
  text(slide, "01 · одиночный эксперимент", 82, 610, 430, 22, { fontSize: 15, bold: true, color: C.blue });
  text(slide, "02 · пять значений α", 666, 610, 430, 22, { fontSize: 15, bold: true, color: C.accent });
  footer(slide);
  notes(slide, "Первый ноутбук содержит 7 выполненных ячеек, второй — 15. Выводы и графики сохранены непосредственно в ipynb.", [
    "labs/lab01/project/notebooks/01_exponential_growth/01_exponential_growth.ipynb",
    "labs/lab01/project/notebooks/02_exponential_growth/02_exponential_growth.ipynb",
    "labs/lab01/presentation/image/terminal/jupyter-03-notebook-01-complete.png",
    "labs/lab01/presentation/image/terminal/jupyter-06-notebook-02-results.png",
  ]);
}

// 10 — Verification and release
{
  const slide = presentation.slides.add();
  slide.background.fill = C.bg;
  title(slide, 10, "Проверка, версионирование и публикация");
  await image(slide, "image/terminal/14-tests-passed.png", 62, 164, 550, 360, "Успешный запуск тестов");
  await image(slide, "image/terminal/16-pushed-to-both-remotes.png", 646, 164, 550, 360, "Отправка ветки и тега в два удалённых репозитория");
  metric(slide, "3 / 3", "теста пройдены", 62, 552, 260, C.accent);
  metric(slide, "GitHub", "origin", 352, 552, 260, C.blue);
  metric(slide, "GitVerse", "gitverse", 646, 552, 260, C.orange);
  metric(slide, "v1.0.0", "исходный релиз", 936, 552, 260, C.accent);
  footer(slide);
  notes(slide, "Тесты проверяют правую часть ОДУ, аналитические формулы и численную точность. Одна и та же история отправлена в GitHub и GitVerse через отдельные SSH-псевдонимы.", [
    "labs/lab01/project/test/runtests.jl",
    "labs/lab01/presentation/image/terminal/14-tests-passed.png",
    "labs/lab01/presentation/image/terminal/16-pushed-to-both-remotes.png",
  ]);
}

// 11 — Conclusions
{
  const slide = presentation.slides.add();
  slide.background.fill = `linear(145deg, ${C.bg} 0%, #0B2F3A 100%)`;
  title(slide, 11, "Выводы");
  bullet(slide, "Модель проверена", "Численное решение совпало с аналитическим с ошибкой порядка 10⁻⁶", 70, 168, 530, 1);
  bullet(slide, "Параметр исследован", "Рост u(10) экспоненциальный, а T₂ уменьшается как 1/α", 70, 264, 530, 2, C.blue);
  bullet(slide, "Результат воспроизводим", "Скрипты, данные, графики, QMD, IPYNB, тесты и документы собираются командами", 70, 360, 530, 3, C.orange);
  bullet(slide, "История опубликована", "GitHub и GitVerse изолированы от настроек других проектов", 70, 456, 530, 4);
  box(slide, 670, 168, 520, 430, C.panel, "rounded-xl", C.panel2);
  text(slide, "du/dt = αu", 720, 218, 420, 54, { fontSize: 38, bold: true, color: C.accent });
  rule(slide, 720, 296, 420, C.panel2, 2);
  text(slide, "код", 720, 336, 100, 28, { fontSize: 18, bold: true, color: C.blue });
  text(slide, "→", 830, 334, 40, 28, { fontSize: 20, color: C.muted });
  text(slide, "данные", 880, 336, 100, 28, { fontSize: 18, bold: true, color: C.orange });
  text(slide, "→", 990, 334, 40, 28, { fontSize: 20, color: C.muted });
  text(slide, "релиз", 1040, 336, 100, 28, { fontSize: 18, bold: true, color: C.accent });
  text(slide, "Куокконен Дарина Андреевна", 720, 456, 420, 28, { fontSize: 20, bold: true, color: C.text });
  text(slide, "НФИбд-01-23", 720, 498, 420, 26, { fontSize: 16, color: C.muted });
  text(slide, "Лабораторная работа № 1", 720, 548, 420, 24, { fontSize: 14, color: C.muted });
  footer(slide);
  notes(slide, "Итог: математическая модель проверена, параметрическое исследование выполнено, а полный вычислительный и документальный конвейер воспроизводим.", [
    "labs/lab01/report/simulation-modeling-lab01-report.qmd",
    "labs/lab01/project/data/02_exponential_growth/parameter_summary.csv",
  ]);
}

await fs.mkdir(SLIDES, { recursive: true });
for (const [index, slide] of presentation.slides.items.entries()) {
  const stem = `slide-${String(index + 1).padStart(2, "0")}`;
  await writeBlob(path.join(SLIDES, `${stem}.png`), await presentation.export({ slide, format: "png", scale: 1 }));
  const layout = await slide.export({ format: "layout" });
  await fs.writeFile(path.join(SLIDES, `${stem}.layout.json`), await layout.text());
}
await writeBlob(path.join(OUTPUT, "presentation-montage.webp"), await presentation.export({ format: "webp", montage: true, scale: 1 }));
const pptx = await PresentationFile.exportPptx(presentation);
await pptx.save(path.join(OUTPUT, "simulation-modeling-lab01-presentation.pptx"));
