# # Daisyworld: численность
#
# Проследим численность чёрных и белых растений на 1000 шагах.
#
# ## Окружение и модель
using DrWatson
@quickactivate "project"
include(srcdir("experiments.jl"))

# ## Расчёт
model = daisyworld(; solar_luminosity = 1.0)
df = savehistory(history(model, 1000), "daisyworld-count")
# ## График и вывод
figure = countfigure(df)
save(imagefile("04-plot.png"), figure)
display(figure)
last(df, 5)
