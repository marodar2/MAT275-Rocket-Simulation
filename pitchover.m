function scale = pitchover(t, S, simparams)

s = S(1);
h = S(2);
gamma = S(3);
v = S(4);
m = S(5);

% Current (failed) pitchover implementation

if h > simparams.pitchover_start && h < simparams.pitchover_end
    % gamma_target = deg2rad(5);
    % gamma_band = deg2rad(60);
    % 
    % scale = (gamma - gamma_target) / gamma_band;
    % scale = max(0, min(1, scale));
    scale = 1;
else
    scale = 0;
end