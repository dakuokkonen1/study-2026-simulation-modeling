# Имитационное моделирование

Учебный репозиторий лабораторных работ по дисциплине «Имитационное
моделирование».

## Лабораторные работы

| № | Тема | Материалы |
|---:|---|---|
| 1 | Подготовка стенда. Модель экспоненциального роста | [**Открыть каталог**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab01) |
| 2 | Модели SIR и Лотки–Вольтерры | [**Открыть каталог**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab02) |
| 3 | Лабораторная работа № 3 | [**Открыть каталог**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab03) |
| 4 | Лабораторная работа № 4 | [**Открыть каталог**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab04) |
| 5 | Лабораторная работа № 5 | [**Открыть каталог**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab05) |
| 6 | Лабораторная работа № 6 | [**Открыть каталог**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab06) |
| 7 | Лабораторная работа № 7 | [**Открыть каталог**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab07) |
| 8 | Лабораторная работа № 8 | [**Открыть каталог**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab08) |

## Лабораторная работа № 1

В первой работе подготовлено воспроизводимое окружение Julia и исследована
модель экспоненциального роста

\[
\frac{du}{dt}=\alpha u, \qquad u(0)=u_0.
\]

Выполнены одиночный и параметрический эксперименты, сопоставлены численное и
аналитическое решения, рассчитано время удвоения, сформированы таблицы,
графики и выполненные блокноты Jupyter.

### Состав материалов

| Каталог | Содержание |
|---|---|
| [**`project`**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab01/project) | Julia-проект, исходный код, данные, блокноты и тесты |
| [**`image`**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab01/image) | Иллюстрации, результаты расчётов и снимки ключевых этапов |
| [**`report`**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab01/report) | Исходник Quarto, отчёт DOCX и отчёт PDF |
| [**`presentation`**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab01/presentation) | Исходник Quarto и самодостаточная HTML-презентация |
| [**`CHANGELOG.md`**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/labs/lab01/CHANGELOG.md) | Подробная история лабораторной работы |

### Воспроизведение расчётов

```bash
cd labs/lab01/project
```

`julia --project=. -e 'using Pkg; Pkg.instantiate()'`

`make all`

Проверка численной реализации:

```bash
make test
```

## История и публикации

- [**Журнал изменений**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/CHANGELOG.md)
- [**Релиз v2.0.0 на GitHub**](https://github.com/dakuokkonen1/study-2026-simulation-modeling/releases/tag/v2.0.0)
- [**Релиз v2.0.0 на GitVerse**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/releases/tag/v2.0.0)

## Лицензия

Материалы распространяются на условиях [**GNU General Public License v3.0**](https://gitverse.ru/Dakuokkonen/study-2026-simulation-modeling/content/master/LICENSE).
