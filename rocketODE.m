function dSdt = rocketODE(t, S, rocket, environment, simparams)

% Get current state variables
s = S(1);
h = S(2);
gamma = S(3);
v = S(4);
m = S(5);

% Gravitational acceleration, atmopsheric density, thrust, and drag
g = gravity(S, rocket, environment);
p = atmosphere(S, rocket, environment);
T = thrust(S, rocket, environment, simparams);
D = drag(S, rocket, environment);

% Pitchover
delta = deg2rad(simparams.pitchover_mag) * pitchover(t, S, simparams);

% Derivative implementations
ds = (environment.earth_radius * v * cos(gamma)) / (environment.earth_radius + h);
dh = v * sin(gamma);

dgamma_thrust = (T * sin(delta)) / (m * v);
dgamma_gravity = -(g * cos(gamma)) / (v);
dgamma_horizon = (v * cos(gamma)) / (environment.earth_radius + h);
dgamma = dgamma_thrust + dgamma_gravity + dgamma_horizon;

dv = (T * cos(delta) - D) / (m) - g * sin(gamma);
dm = -rocket.mass_flow_rate * (T ~= 0); % Disable mass flow if thrust is non-zero

dSdt = [ds; dh; dgamma; dv; dm];