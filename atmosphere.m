function p = atmosphere(S, rocket, environment)

h = S(2);
p = environment.atm_density_sea .* exp(-h ./ environment.atm_scale_height);