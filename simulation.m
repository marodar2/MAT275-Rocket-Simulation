%% Environment and Rocket Properties
% First stage
booster.dry_mass = 22200;
booster.wet_mass = 433100;
booster.thrust_sea = 7607000;
booster.thrust_vac = 8227000;
booster.mass_flow_rate = 2250;
booster.cross_section = pi * (3.7 / 2)^2;
booster.drag_coefficient = 0.3;
% Second stage
stage2.dry_mass = 4000;
stage2.wet_mass = 111500;
stage2.thrust_sea = 981000;
stage2.thrust_vac = 981000;
stage2.mass_flow_rate = 270;
stage2.cross_section = 10.8;
stage2.drag_coefficient = 0.3;

environment.gravitational_constant = 6.67408*10^-11;
environment.earth_mass = 5.972*10^24;
environment.earth_radius = 6378137;
environment.atm_density_sea = 1.225;
environment.atm_scale_height = 8500;

%% Simulation Parameters
simparams.pitchover_start = 100e3;
simparams.pitchover_end = 1000e3;
simparams.pitchover_mag = -50;
simparams.target_altitude = 2000e3;

%% Simulation stages
% First Stage
S0_1 = [0; 0.1; pi / 2; 0.1; booster.wet_mass + stage2.wet_mass];
time_span_1 = [0 1000];
options1 = odeset("MaxStep", 0.1, "Events", @(t, s) rocketEvents(t, s, booster.dry_mass + stage2.wet_mass), "RelTol", 1e-8);
[t1, S1, te1, Se1, ie1] = ode45(@(t, S) rocketODE(t, S, booster, environment, simparams), time_span_1, S0_1, options1);
disp("Stage 1 completed at t = " + t1(end) + " seconds.");

% Handle failed first stage, second stage if else
if S1(end, 2) <= 0
    disp("Stage 1 Failed");
    t = t1;
    S = S1;
else
%% Second Stage Simulation
    % Same state as end of first stage, remove booster mass
    S0_2 = [S1(end, 1); S1(end, 2); S1(end, 3); S1(end, 4); stage2.wet_mass];
    time_span_2 = [t1(end) 10000];
    options2 = odeset("MaxStep", 0.1, "Events", @(t, s) rocketEvents(t, s, 0), "RelTol", 1e-6);
    [t2, S2] = ode45(@(t, S) rocketODE(t, S, stage2, environment, simparams), time_span_2, S0_2, options2);
    disp("Stage 2 completed at t = " + t2(end) + " seconds.");

    % Combine simulation data matrices
    t = [t1; t2(2:end, :)];
    S = [S1; S2(2:end, :)];
end

%% Simulation Data
s = S(:, 1);
h = S(:, 2);
gamma = rad2deg(S(:, 3));
v = S(:, 4);
m = S(:, 5);

% Others
e = v.^2 ./ 2 - (environment.gravitational_constant * environment.earth_mass) ./ (environment.earth_radius + h); % Specific energy for tuning pitchover parameters
dt = [0; diff(t)];

% Rocket position to cartesian coordiantes
x = (environment.earth_radius + h) .* sin(s ./ environment.earth_radius);
y = (environment.earth_radius + h) .* cos(s ./ environment.earth_radius);

% Earth circle
angle = linspace(0, 2 * pi, 500);
earth_x = environment.earth_radius * cos(angle);
earth_y = environment.earth_radius * sin(angle);

target_x = (environment.earth_radius + simparams.target_altitude) * cos(angle);
target_y = (environment.earth_radius + simparams.target_altitude) * sin(angle);

pitchover_start_x = (environment.earth_radius + simparams.pitchover_start) * cos(angle);
pitchover_start_y = (environment.earth_radius + simparams.pitchover_start) * sin(angle);

pitchover_end_x = (environment.earth_radius + simparams.pitchover_end) * cos(angle);
pitchover_end_y = (environment.earth_radius + simparams.pitchover_end) * sin(angle);

% Find pitchover + main engine cutoff indices
index_tolerance = 100;
index_param = h;
pitchover_start_index = find(abs(index_param - simparams.pitchover_start) <= index_tolerance, 1, "first"); % Find pitchover start index
pitchover_end_index = find(abs(index_param - simparams.pitchover_end) <= index_tolerance, 1, "first"); % Repeat for pitchover end
meco_index = find(abs(m - (booster.dry_mass + stage2.wet_mass)) <= 1, 1, "first"); % Repeat for main engine cutoff

%% Plotting
close all force

fig = figure("Units", "normalized", "Position", [0.1 0.1 0.8 0.8]);
tiled = tiledlayout(3, 5);

% Main plot
sim_tile = nexttile([3 3]); % 3x3 tile for live window
hold(sim_tile, "on");
axis(sim_tile, "equal");
grid(sim_tile, "on");
plot(earth_x, earth_y, "g"); % Plot earth circle
plot(target_x, target_y, "white"); % Plot target circle

plot(pitchover_start_x, pitchover_start_y, "white"); % Plot target circle
plot(pitchover_end_x, pitchover_end_y, "y--"); % Plot target circle

plot(x(1:pitchover_start_index), y(1:pitchover_start_index), "b--"); % Plot rocket's trail pre-pitchover
plot(x(pitchover_start_index:pitchover_end_index), y(pitchover_start_index:pitchover_end_index), "r--"); % Plot rocket's trail during pitchover
plot(x(pitchover_end_index:meco_index), y(pitchover_end_index:meco_index), "b--"); % Plot rocket's trail post-pitchover-pre-meco
plot(x(meco_index:end), y(meco_index:end), "y--"); % Plot rocket's trail post-meco

rocket_point = plot(x(1), y(1), "o", MarkerSize = 8, MarkerFaceColor = [1 0 0], MarkerEdgeColor = "none"); % Create point for rocket
statistics_box = text(0, 0, "", FontSize = 10, FontName = "FixedWidth", BackgroundColor = "black", EdgeColor = [0.2 0.2 0.2], Margin = 5); % Create statistics box
title(sim_tile, "Live Simulation");

% Side plots
plot_titles = ["Downrange (m)", "Altitude (m)", "Flight Path Angle (deg)", "Velocity (m/s)", "Mass (kg)", "Time Step (s)"]; % Plot names
data = [s, h, gamma, v, m, dt]; % Which data each plot uses
plots = gobjects(6, 1);
tiles = gobjects(6, 1);

for i = 1:length(plot_titles)

    tiles(i) = nexttile;
    hold(tiles(i), "on");
    grid(tiles(i), "on");
    title(tiles(i), plot_titles(i));
    plots(i) = plot(t, data(:, i), "MarkerSize", 1.5);

    % Markers for pitchover start/end + main engine cutoff
    if ~isempty(pitchover_start_index)
        xline(tiles(i), t(pitchover_start_index), "r--");
    end
    if ~isempty(pitchover_end_index)
        xline(tiles(i), t(pitchover_end_index), "r--");
    end
    if ~isempty(meco_index)
        xline(tiles(i), t(meco_index), "y--");
    end

    % Mark target altitude and velocity
    if i == 2
        yline(tiles(i), simparams.target_altitude);
    end
    if i == 4
        target_velocity = sqrt((environment.gravitational_constant * environment.earth_mass) / (environment.earth_radius + simparams.target_altitude));
        yline(tiles(i), target_velocity);
    end

end

% Link the time axis for side plots
linkaxes(tiles, "X");

%% Live Simulation

% Set to true to disable live simulation and skip to full plots, set to false for life simulation
% if true
%     return;
% end

drawnow;
playback_speed = 100;
real_time = t(end) / playback_speed;
start_time = tic;

while toc(start_time) < real_time

    sim_time = toc(start_time) * playback_speed;
    i = find(t >= sim_time, 1, "first");
    if isempty(i)
        i = numel(t);
    end

    % Main Window
    set(rocket_point, "XData", x(i), "YData", y(i));

    % Update colors during pitchover + MECO
    is_pitchover = pitchover(t(i), S(i, :), simparams);
    if ~isempty(pitchover_start_index) && ~isempty(pitchover_end_index)
        if i > pitchover_start_index && i < pitchover_end_index
            set(rocket_point, "MarkerFaceColor", "red");
        else
            set(rocket_point, "MarkerFaceColor", "blue");
        end
    end

    if ~isempty(meco_index)
        if i >= meco_index
            set(rocket_point, "MarkerFaceColor", "yellow");
            set(rocket_point, "MarkerSize", 6);
        end
    end

    % Adjust window size to fit everything
    window_size = h(i) + 500000;
    xlim(sim_tile, [x(i) - window_size, x(i) + window_size]);
    ylim(sim_tile, [y(i) - window_size, y(i) + window_size]);

    % Update statistics box to follow rocket
    statistics = sprintf("T: %.1fs\nS: %.1fkm\nH: %.1fkm\nγ: %.1fdeg\nV: %.1fm/s\nM: %.1fkg", ...
    t(i), s(i) / 1000, h(i) / 1000, gamma(i), v(i), m(i));

    x_pos = x(i) - window_size / 2;
    y_pos = y(i); 
    set(statistics_box, "Position", [x_pos, y_pos], "String", statistics);

    % Update side plots x-axes to include up to current point
    xlim(tiles(1), [0 max(1, t(i))]);

    drawnow;

end

% Center statistics box when done
set(statistics_box, "Position", [0, 0], "String", statistics);