import matplotlib.pyplot as plt

x = 0
history = [] # 空列表，按顺序装值
for step in range(10):
    x = x + 1
    history.append(x)

print(history)

plt.plot(history)
plt.xlabel("step")
plt.ylabel("x")
plt.show()
    