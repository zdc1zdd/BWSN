import matplotlib.pyplot as plt

def simulate_chain(I_drive=10.0, w=40.0, ms=300):
    a, b, c, d = 0.1, 0.2, -65.0, 2.0 
    N = 3 # N表示有几个神经元相连
    # w = 40.0 # 神经元之间的连接权重

    I_ext = [I_drive, 0, 0] # 外部电流
    W = [[0,0,0],[w,0,0],[0,w,0]] # W[i][j]表示「从 j 到 i 的权重」

    v = [-65.0]*N
    u = [b*x for x in v]
    count = [0]*N # 记录各发几次火
    spike_prev = [0]*N

    history = [[],[],[]]

    for step in range(ms):
        spike_now=[0]*N # 谁这拍发火就把对应位置标成1
        I = [I_ext[i] + sum(W[i][j]*spike_prev[j] for j in range(N)) for i in range(N)]

        for i in range(N):
            v[i] += 0.5*(0.04*v[i]*v[i] + 5*v[i] + 140 - u[i] + I[i]) # 半步①
            v[i] += 0.5*(0.04*v[i]*v[i] + 5*v[i] + 140 - u[i] + I[i]) # 半步②
            fired = v[i] >= 30
            if fired:
                v[i] = 30.0
            u[i] += a * (b*v[i] - u[i])
            history[i].append(v[i])
            if fired:
                v[i] = c # 摔回底部
                u[i] += d # 刹车加力
                spike_now[i] = 1
                count[i] += 1
        spike_prev = spike_now

    return count, history

for w in [0,10,20,40,80]:
    print(simulate_chain(w=w))

count, h = simulate_chain()
fig, ax = plt.subplots(3, 1, sharex=True, figsize=(9,6))
for i in range(3):
    ax[i].plot(h[i])
    ax[i].set_ylabel("v (mV)")
    ax[i].set_title("neuron %d" % i, loc="left")
    ax[i].set_ylim(-95, 40)
ax[2].set_xlabel("t (step)")
plt.tight_layout()
plt.show()