function [value, isterminal, direction] = rocketEvents(t, S, transition_mass)

s = S(1);
h = S(2);
gamma = S(3);
v = S(4);
m = S(5);

value = [m - transition_mass; h];
isterminal = [1; 1];
direction = [-1; 0];