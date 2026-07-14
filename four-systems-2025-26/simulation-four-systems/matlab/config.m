function cfg = config()
% config  EcoDrop Gravity Battery — Central configuration.
%   cfg = config() returns a struct with all physical constants, motor specs,
%   run protocol, and plot styling. No file I/O.

% --- Gravity and cycle ---
cfg.g = 9.81;           % m/s^2
cfg.h_drop = 3.0;        % m, drop height for all systems
cfg.m_primary = 50.0;    % kg, primary mass (denominator for PE_input)
cfg.PE_input_nominal = cfg.m_primary * cfg.g * cfg.h_drop;  % 1471.5 J

% --- Rope / pulley friction (capstan equation) ---
cfg.mu_rope = 0.02;     % ball bearing assisted
cfg.theta_pulley = pi;   % 180° wrap, radians
cfg.rope_efficiency_per_pulley = 1.0 / exp(cfg.mu_rope * cfg.theta_pulley);  % ~0.939

% --- Bearing friction ---
cfg.mu_bearing = 0.001;
cfg.r_shaft = 0.01;      % m

% --- Gearbox ---
cfg.gear_ratio_discharge = 25;
cfg.gear_ratio_charge = 25;
cfg.eta_gear_stage = 0.94;
cfg.eta_gearbox = cfg.eta_gear_stage^2;  % 0.883 for 2-stage 1:25

% --- Motor (Turnigy SK3-5065-236KV derived; efficiency from physical calibration) ---
cfg.Kv_rpm_per_V = 236;
cfg.Kv_SI = cfg.Kv_rpm_per_V * (2*pi/60);
cfg.Ke = 1.0 / cfg.Kv_SI;
cfg.Rm = 0.019;          % Ω, phase-to-phase
cfg.Kt = 60.0 / (2*pi*cfg.Kv_rpm_per_V);  % Nm/A, ~0.0405
cfg.eta_motor_base = 0.82;

% --- Industry benchmarks for RTE ---
cfg.RTE_pumped_hydro_pct = 77.5;
cfg.RTE_lithium_ion_pct = 88.5;

% --- System 1: Dual Weight ---
cfg.m_counterweight_dual = 40.0;
cfg.m_net_imbalance_dual = cfg.m_primary - cfg.m_counterweight_dual;  % 10 kg

% --- System 2: Variable Counterweight ---
cfg.m_counterweight_min = 45.0;
cfg.m_counterweight_max = 50.0;
cfg.n_modular_modules = 5;
cfg.m_per_module = 1.0;
cfg.eta_modular_generator = 0.75;
cfg.control_power_W = 5.0;

% --- System 3: Buoyancy ---
cfg.rho_water = 1000.0;
cfg.V_weight_buoyancy = 0.06;
cfg.Cd_water_drag = 0.8;
cfg.eta_pump = 0.70;
cfg.V_water_per_cycle = 0.06;

% --- System 4: Halbach ---
cfg.n_linear_motors = 4;
cfg.eta_linear_actuator = 0.65;
cfg.eta_linear_generator = 0.70;
cfg.halbach_flux_factor = 1.4;
cfg.auxiliary_hoist_W = 20.0;
cfg.control_electronics_W = 10.0;
cfg.magnetic_drag_coeff = 0.05;

% --- Calibration (physical build) ---
cfg.m_calibration = 25.0;
cfg.h_calibration = 2.7;
cfg.gear_ratio_calibration = 25;

% --- Run protocol ---
cfg.n_runs = 10;
cfg.motor_perturb_pct = 0.02;
cfg.friction_perturb_pct = 0.05;
cfg.n_cycles_cumulative = 500;
cfg.sensitivity_friction_pct = 0.10;

% --- Plot styling (colors as RGB for MATLAB) ---
cfg.COLOR_DUAL_WEIGHT   = [0.12 0.47 0.71];   % #1f77b4 blue
cfg.COLOR_VARIABLE_CW   = [0.58 0.40 0.74];   % #9467bd purple
cfg.COLOR_BUOYANCY      = [1.0  0.50 0.05];   % #ff7f0e orange
cfg.COLOR_HALBACH      = [0.17 0.63 0.17];   % #2ca02c green
cfg.DPI = 300;
cfg.FIG_SIZE = [10 7];   % inches
end
