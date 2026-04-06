function drag = drag(S, rocket, environment)

v = S(4);
pressure = atmosphere(S, rocket, environment);
drag = 0.5 .* pressure .* v.^2 .* rocket.drag_coefficient.* rocket.cross_section;