import matplotlib.pyplot as plt

xs = list(range(0, 40, 2))
ys_1 =   [
  1.00,
  1.00,
  1.00,
  0.98,
  1.00,
  1.00,
  0.73,
  0.65,
  0.55,
  0.51,
  0.48,
  0.32,
  0.31,
  0.12,
  0.08,
  0.09,
  0.05,
  0.05,
  0.02,
  0.03
]
ys_2 = [
  1.00,
  1.00,
  1.00,
  1.00,
  1.00,
  1.00,
  0.93,
  0.82,
  0.59,
  0.58,
  0.53,
  0.41,
  0.39,
  0.25,
  0.10,
  0.10,
  0.09,
  0.04,
  0.03,
  0.02
]

ys_3 = [
  1.00,
  1.00,
  1.00,
  1.00,
  1.00,
  1.00,
  1.00,
  1.00,
  0.78,
  0.65,
  0.49,
  0.50,
  0.49,
  0.37,
  0.29,
  0.16,
  0.14,
  0.09,
  0.06,
  0.06
]


plt.plot(xs, ys_1, label="P30")
plt.plot(xs, ys_2, label="P60")
plt.plot(xs, ys_3, label="P90")
plt.xlabel("Количество мутаций")
plt.ylabel("Среднее значение полноты (recall)")
plt.title("Динамика изменения полноты при увеличении количества мутаций")

plt.legend()

plt.savefig("plot")
