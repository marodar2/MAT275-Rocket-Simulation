# SpaceX Falcon 9 Rocket Simulation

Below are the simulation details of the Falcon 9 simulation, implemented in MATLAB and based off the equations of motion derived in [the derivation PDF](https://github.com/marodar2/MAT275-Rocket-Simulation/blob/main/Rocket%20Simulation%20Derivation.pdf).

## File Overviews
1. The overarching simulation code is in [simulation.m](https://github.com/marodar2/MAT275-Rocket-Simulation/blob/main/simulation.m). This file contains the initial parameter setup (including rocket, environment, and simulation parameters), the 2 ode45 calls (1 per rocket stage), data processing, and the final plotting. This is additionally where the playback speed is defined for the live simulation.
2. The main ODE function is in [rocketODE.m](https://github.com/marodar2/MAT275-Rocket-Simulation/blob/main/rocketODE.m). This implements the equations of motion defined previously as well as managing mass flow and other control parameters.
3. [rocketEvents.m](https://github.com/marodar2/MAT275-Rocket-Simulation/blob/main/rocketEvents.m) manages the failure state for ode45. This terminates ode45 integration should the stage mass fall below a given threshold or the rockets altitude go below 0.
4. The pitchover logic is handled in [pitchover.m](https://github.com/marodar2/MAT275-Rocket-Simulation/blob/main/pitchover.m). This is where much of the tuning happens in addition to the simulation parameters defined in [simulation.m](https://github.com/marodar2/MAT275-Rocket-Simulation/blob/main/simulation.m).
5. Lastly, [atmosphere.m](https://github.com/marodar2/MAT275-Rocket-Simulation/blob/main/atmosphere.m), [drag.m](https://github.com/marodar2/MAT275-Rocket-Simulation/blob/main/drag.m), [gravity.m](https://github.com/marodar2/MAT275-Rocket-Simulation/blob/main/gravity.m), and [thrust.m](https://github.com/marodar2/MAT275-Rocket-Simulation/blob/main/thrust.m) all implement the elementary functions necessary for the governing equations.

Running [simulation.m](https://github.com/marodar2/MAT275-Rocket-Simulation/blob/main/simulation.m), the 2 ode45 functions will continue followed by a live simulation of the launch at a set playback speed (if live simulation enabled). A statistics window will be displayed alongside the rocket displaying its state vector at the given point in time, in addition to the 6 side plots showing several key variables up until the current moment. The 6 side plots additionally indicate the beginning and end of the pitchover maneuver in red, as well as main engine cutoff in yellow. Once the live simulation is complete, a zoomed out view highlights the entire trajectory of the rocket, with the 6 side plots showcasing the evolution of the rockets state over the entire simulation as shown:
<img width="1533" height="862" alt="image" src="https://github.com/user-attachments/assets/2b122f3f-efe0-4f51-b2db-780e6eb79c0a" />
## Tuning
Tuning primarily occurs in the main simulation file and in the pitchover control file. The simulation parameters contain 3 variables: `simparams.pitchover_start`, `simparams.pitchover_end`, and `simparams.pitchover_mag`. The start and end variables can represent any given quantity, which can be changed in the main simulation file and the pitchover control file. For example, should the ideal pitchover last between 15km and 30km in altitude with a gimbal angle of -15deg, the following implementation would be used in `simulation.m`:
```M
simparams.pitchover_start = 15e3;
simparams.pitchover_end = 30e3;
simparams.pitchover_mag = -15;
```
Additionally, the initial main plot must be modified to respect the variables being referred to:
```M
index_tolerance = 100;
index_param = h;
```
where `index_tolerance` defines the range in which the corresponding indicies should be constrained (in this case 15km±100m and 30km±100m) and `index_param` defines the parameter to which the pitchover start and end parameters refer to (in this case the altitude `h`).
Lastly, the pitchover control file must be similarly modified:
```M
if h >= simparams.pitchover_start && h <= simparams.pitchover_end
    scale = 1;
else
    scale = 0;
end
```
The pitchover control function returns a `scale` variable which is later multiplied in `rocketODE.m` by the pitchover magnitude parameter (defined in `simulation.m`) to dictate the "true" pitchover angle:
```M
delta = deg2rad(simparams.pitchover_mag) * pitchover(t, S, simparams);
```
This allows the pitchover control function to return either a 1/0 bit for an on/off pitchover, or a more gradual/smooth pitchover. For example, the following could be implemented to ease into a 5 degree flight path angle with a "ramp length" of 60 degrees, i.e. the gimbal angle starts off at ~1.5x the pitchover magnitude and gradually decreases to zero as the flight path angle approaches 5 degrees:
```M
gamma_target = deg2rad(5);
gamma_band = deg2rad(60);

scale = (gamma - gamma_target) / gamma_band;
scale = max(0, min(1, scale));
```
