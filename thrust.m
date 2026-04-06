function thrust = thrust(S, rocket, environment, simparams)

s = S(1);
h = S(2);
gamma = S(3);
v = S(4);
m = S(5);
density = atmosphere(S, rocket, environment);

target_velocity = sqrt((environment.gravitational_constant * environment.earth_mass) ./ (simparams.target_altitude + environment.earth_radius));
target_angle = 0;
target_height = simparams.target_altitude;

goldilocks = abs(v - target_velocity) <= 10 && abs(gamma - target_angle) <= 0.01 && abs(h - target_height) <= 500;
% goldilocks = v > target_velocity;

if goldilocks || m <= rocket.dry_mass
    thrust = 0;
else
    thrust = rocket.thrust_vac - (density ./ environment.atm_density_sea) .* (rocket.thrust_vac - rocket.thrust_sea);
end