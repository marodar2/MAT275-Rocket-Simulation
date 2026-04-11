function [value, isterminal, direction] = rocketEvents(t, S, transition_mass)

s = S(1);
h = S(2);
gamma = S(3);
v = S(4);
m = S(5);

% End simulation if mass is below the transition mass (for stage 1) or if h <= 0 (boom)
value = [m - transition_mass; h];
isterminal = [1; 1];
direction = [-1; 0];