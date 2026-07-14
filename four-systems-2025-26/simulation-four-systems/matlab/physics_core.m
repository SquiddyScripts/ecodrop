function varargout = physics_core(fcn, varargin)
% physics_core  EcoDrop Gravity Battery — Core physics shared by all systems.
%   Dispatcher: call with function name and args, e.g.
%   PE = physics_core('pe_input', m_kg, h_m);
%   rope_eff = physics_core('rope_tension_efficiency', n_pulleys, mu, theta);
%   T_b = physics_core('bearing_torque', F_radial, mu, r);
%   P_out = physics_core('gearbox_power_out', P_in, eta_gearbox);
%   P_in = physics_core('gearbox_power_in', P_out, eta_gearbox);
%   P_elec = physics_core('motor_electrical_from_mechanical', P_mech, eta_motor);
%   P_mech = physics_core('motor_mechanical_from_electrical', P_elec, eta_motor);
%   P_elec_in = physics_core('motor_electrical_input_for_mechanical', P_mech_out, eta_motor);
%   out = physics_core('run_descent_integration', m_kg, h_m, F_friction_const, rope_eff, eta_gearbox, eta_motor, cfg, varargin{:});
%   losses = physics_core('friction_losses_rope_bearing_gearbox', m_kg, h_m, rope_eff, eta_gearbox, n_pulleys, cfg);

cfg = config();
switch fcn
    case 'pe_input'
        [m_kg, h_m] = parse_pe_input(varargin, cfg);
        varargout{1} = m_kg * cfg.g * h_m;
    case 'rope_tension_efficiency'
        [n_pulleys, mu, theta] = parse_rope(varargin, cfg);
        varargout{1} = (1.0 / exp(mu * theta))^n_pulleys;
    case 'bearing_torque'
        [F_radial, mu, r] = parse_bearing(varargin, cfg);
        varargout{1} = mu * F_radial * r;
    case 'gearbox_power_out'
        [P_mech_in, eta_gearbox] = parse_gearbox_out(varargin, cfg);
        varargout{1} = P_mech_in * eta_gearbox;
    case 'gearbox_power_in'
        [P_mech_out, eta_gearbox] = parse_gearbox_in(varargin, cfg);
        varargout{1} = P_mech_out / eta_gearbox;
    case 'motor_electrical_from_mechanical'
        varargout{1} = varargin{1} * varargin{2};  % P_mech * eta_motor
    case 'motor_mechanical_from_electrical'
        varargout{1} = varargin{1} * varargin{2};  % P_elec * eta_motor
    case 'motor_electrical_input_for_mechanical'
        varargout{1} = varargin{1} / varargin{2};  % P_mech_out / eta_motor
    case 'run_descent_integration'
        [m_kg, h_m, F_friction_const, rope_eff, eta_gearbox, eta_motor, c] = parse_descent(varargin, cfg);
        varargout{1} = run_descent_integration(m_kg, h_m, F_friction_const, rope_eff, eta_gearbox, eta_motor, c);
    case 'friction_losses_rope_bearing_gearbox'
        [m_kg, h_m, rope_eff, eta_gearbox, n_pulleys, c] = parse_friction_losses(varargin, cfg);
        varargout{1} = friction_losses_rope_bearing_gearbox(m_kg, h_m, rope_eff, eta_gearbox, c);
    otherwise
        error('physics_core:unknown', 'Unknown function %s', fcn);
end
end

%% Parsers (minimal; cfg passed where needed)
function [m_kg, h_m] = parse_pe_input(v, cfg)
m_kg = v{1};
if isempty(v) || length(v) < 2 || isempty(v{2})
    h_m = cfg.h_drop;
else
    h_m = v{2};
end
end

function [n_pulleys, mu, theta] = parse_rope(v, cfg)
n_pulleys = 1; mu = cfg.mu_rope; theta = cfg.theta_pulley;
if length(v) >= 1 && ~isempty(v{1}), n_pulleys = v{1}; end
if length(v) >= 2 && ~isempty(v{2}), mu = v{2}; end
if length(v) >= 3 && ~isempty(v{3}), theta = v{3}; end
end

function [F_radial, mu, r] = parse_bearing(v, cfg)
F_radial = v{1}; mu = cfg.mu_bearing; r = cfg.r_shaft;
if length(v) >= 2 && ~isempty(v{2}), mu = v{2}; end
if length(v) >= 3 && ~isempty(v{3}), r = v{3}; end
end

function [P_mech_in, eta_gearbox] = parse_gearbox_out(v, cfg)
P_mech_in = v{1}; eta_gearbox = cfg.eta_gearbox;
if length(v) >= 2 && ~isempty(v{2}), eta_gearbox = v{2}; end
end

function [P_mech_out, eta_gearbox] = parse_gearbox_in(v, cfg)
P_mech_out = v{1}; eta_gearbox = cfg.eta_gearbox;
if length(v) >= 2 && ~isempty(v{2}), eta_gearbox = v{2}; end
end

function [m_kg, h_m, F_friction_const, rope_eff, eta_gearbox, eta_motor, c] = parse_descent(v, cfg)
m_kg = v{1}; h_m = v{2}; F_friction_const = v{3}; rope_eff = v{4}; eta_gearbox = v{5}; eta_motor = v{6};
if length(v) >= 7 && ~isempty(v{7}), c = v{7}; else, c = cfg; end
end

function [m_kg, h_m, rope_eff, eta_gearbox, n_pulleys, c] = parse_friction_losses(v, cfg)
m_kg = v{1}; h_m = v{2}; rope_eff = v{3}; eta_gearbox = v{4};
n_pulleys = 1; c = cfg;
if length(v) >= 5 && ~isempty(v{5}), n_pulleys = v{5}; end
if length(v) >= 6 && ~isempty(v{6}), c = v{6}; end
end

%% Descent ODE: dy/dt = [v; a], a = g - (F_friction_const + b_load*v)/m
function dydt = descent_rhs(t, y, m, g, F_friction_const, b_load, h_drop)
pos = y(1); v = y(2);
if v <= 0, v = 0; end
b_load_val = 30.0;
F_resist = F_friction_const + b_load_val * v;
a = g - F_resist / m;
if pos >= h_drop && v > 0
    a = 0; v = 0;
end
dydt = [v; a];
end

%% Run descent integration (ode45, trim at h_m, trapz for energy)
function out = run_descent_integration(m_kg, h_m, F_friction_const, rope_eff, eta_gearbox, eta_motor, cfg)
t_span = [0 20];
n_points = 200;
t_eval = linspace(t_span(1), t_span(2), n_points);
y0 = [0.0; 0.0];
odefun = @(t,y) descent_rhs(t, y, m_kg, cfg.g, F_friction_const, 30.0, cfg.h_drop);
[~, y_sol] = ode45(odefun, t_eval, y0);
pos = y_sol(:,1);
v = max(y_sol(:,2), 0);

% Trim to first time position >= h_m
idx_end = find(pos >= h_m, 1, 'first');
if isempty(idx_end), idx_end = length(pos); end
t = t_eval(1:idx_end)';
pos = pos(1:idx_end);
v = v(1:idx_end);

F_grav = m_kg * cfg.g;
P_mech = F_grav * v(:) * rope_eff;
P_mech_after_gear = P_mech * eta_gearbox;
P_elec = P_mech_after_gear * eta_motor;

E_elec = trapz(t, P_elec);
E_mech_into_gear = trapz(t, P_mech);
E_mech_after_gear = E_mech_into_gear * eta_gearbox;
E_motor_loss = E_mech_after_gear - E_elec;
duration = t(end) - t(1);
if length(t) < 2, duration = 0; end

out = struct('t', t, 'position', pos, 'velocity', v, 'P_mech', P_mech, 'P_elec', P_elec, ...
    'E_elec', E_elec, 'E_mech_into_gear', E_mech_into_gear, 'E_mech_after_gear', E_mech_after_gear, ...
    'E_motor_loss', E_motor_loss, 'duration', duration);
end

%% Friction losses (rope, bearing, gearbox) over drop h_m
function losses = friction_losses_rope_bearing_gearbox(m_kg, h_m, rope_eff, eta_gearbox, cfg)
r_drum = 0.05;
theta_drum = h_m / r_drum;
E_rope = (1.0 - rope_eff) * m_kg * cfg.g * h_m;
T_b = cfg.mu_bearing * (m_kg * cfg.g) * cfg.r_shaft;
E_bearing = T_b * theta_drum;
E_gear_in = m_kg * cfg.g * h_m * rope_eff;
E_gearbox_loss = (1.0 - eta_gearbox) * E_gear_in;
losses = struct('rope_J', E_rope, 'bearing_J', E_bearing, 'gearbox_J', E_gearbox_loss);
end
