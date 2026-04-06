function g = gravity(S, rocket, environment)

h = S(2);
g = (environment.gravitational_constant .* environment.earth_mass) ./ (environment.earth_radius + h).^2;