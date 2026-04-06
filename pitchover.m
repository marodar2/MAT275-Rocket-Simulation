function bit = pitchover(t, S, simparams)

s = S(1);
h = S(2);
gamma = S(3);
v = S(4);
m = S(5);

if h < simparams.pitchover_start || v < 300
    bit = 0;
    return;
end

gamma_target = deg2rad(5);
gamma_band = deg2rad(60);

bit = (gamma - gamma_target) / gamma_band;
bit = max(0, min(1, bit));