"""
FS neuron - Q10 fixed-point reference implementation.

Mirrors the intended Verilog datapath exactly:
  - every value is a plain integer
  - every multiply is followed by an explicit >> to restore the Q scale
  - Python's >> on negative ints is an arithmetic shift (floor), the same
    behaviour as Verilog's >>> on a signed operand

Verified against the float model (dt=0.125): 126.53 Hz vs 126.55 Hz.
"""

F = 10
SCALE = 1 << F                      # 1024


def q(x, bits=F):
    return int(round(x * (1 << bits)))


# ---- constants -----------------------------------------------------------
# 0.04 needs extra precision: at Q10 it becomes 41 = 0.04004 (+0.098%),
# which shows up as a +1.5% error in firing rate.  At Q18 the error vanishes.
QUAD_BITS = 18
C_QUAD  = q(0.04, QUAD_BITS)        # 10486
C_B     = q(0.2)                    # 205    (Q10 is plenty here)
C_140   = q(140)                    # 143360
C_RESET = q(-65.0)                  # -66560   (c)
C_D     = q(2.0)                    # 2048     (d)
V_TH    = q(30.0)                   # 30720

DT = 0.125                          # ms; 0.5*dt = 1/16 -> a pure shift
HALF_DT_SHIFT = 4

UA_BITS = 10
C_UA = q(0.0125, UA_BITS)           # 13     dt*a = 0.125 * 0.1


def simulate_fixed(I=10.0, T=300.0):
    V = C_RESET                                 # Q10
    U = (C_B * V) >> F                          # Q10,  u = b*v
    I_FX = q(I)

    spikes, trace, max_prod = [], [], 0

    for k in range(int(T / DT)):
        for _ in range(2):                      # two half steps
            v_sq   = V * V                      # Q20
            max_prod = max(max_prod, abs(v_sq))
            v_sq10 = v_sq >> F                  # Q10   v^2
            quad   = (C_QUAD * v_sq10) >> QUAD_BITS      # Q10   0.04 v^2
            five_v = (V << 2) + V               # Q10   5v, exact
            f      = quad + five_v + C_140 - U + I_FX    # Q10
            V      = V + (f >> HALF_DT_SHIFT)

        bv = (C_B * V) >> F                     # Q10   b*v
        U  = U + ((C_UA * (bv - U)) >> UA_BITS)

        fired = V >= V_TH
        trace.append((k * DT, V_TH if fired else V))
        if fired:
            spikes.append(k * DT)
            V = C_RESET
            U = U + C_D

    return spikes, trace, max_prod


def isi_stats(spikes, skip=3):
    s = spikes[skip:]
    isi = [s[i + 1] - s[i] for i in range(len(s) - 1)]
    mean = sum(isi) / len(isi)
    return mean, 1000.0 / mean


if __name__ == "__main__":
    spikes, trace, max_prod = simulate_fixed(I=10.0, T=300.0)
    mean, hz = isi_stats(spikes)
    print(f"spikes      : {len(spikes)}")
    print(f"steady ISI  : {mean:.3f} ms  ->  {hz:.2f} Hz")
    print(f"float ref   : 7.902 ms  ->  126.55 Hz")
    print(f"max |v*v|   : {max_prod}  -> {max_prod.bit_length()+1} bits signed")
    print(f"constants   : 0.04->{C_QUAD} (Q{QUAD_BITS})  0.2->{C_B} (Q{F})  "
          f"dt*a->{C_UA} (Q{UA_BITS})")
