import matplotlib.pyplot as plt

a, b, c, d = 0.1, 0.2, -65.0, 2.0 # FS
# a, b, c, d = 0.02, 0.2, -65.0, 8.0 # RS
I = 10.0 # 输入电流

v = -65.0
u = b * v
history = []

for step in range(300):
    v = v + 0.5*(0.04*v*v + 5*v + 140 - u + I) # 半步①
    v = v + 0.5*(0.04*v*v + 5*v + 140 - u + I) # 半步②
    fired = v >= 30
    if fired:
        v = 30.0
    u = u + a * (b*v - u)
    history.append(v)
    if fired:
        v = c # 摔回底部
        u = u + d # 刹车加力

print(history)
plt.plot(history)
plt.xlabel("t (ms)")
plt.ylabel("v (mV)")
plt.show()

