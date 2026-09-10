import matplotlib.pyplot as plt


def simulate_fs(I=10.0, T=300.0, dt=0.1):
    a, b, c, d = 0.1, 0.2, -65.0, 2.0
    v = -65.0
    u = b * v

    ts, vs = [], []
    for k in range(int(T / dt)):
        v = v + 0.5 * dt * (0.04 * v * v + 5 * v + 140 - u + I)  # 半步①
        v = v + 0.5 * dt * (0.04 * v * v + 5 * v + 140 - u + I)  # 半步②
        u = u + dt * a * (b * v - u)

        fired = v >= 30
        ts.append(k * dt)
        vs.append(30.0 if fired else v)
        if fired:
            v = c        # 摔回底部
            u = u + d    # 刹车加力
    return ts, vs


t, h = simulate_fs(I=10.0, T=300.0)
plt.plot(t, h)
plt.xlabel("t (ms)")
plt.ylabel("v (mV)")
plt.title("FS neuron")
plt.savefig("fs_neuron.png", dpi=150, bbox_inches="tight")
plt.show()