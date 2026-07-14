function result = run_cycle_variable_cw(eta_motor_scale, friction_scale, n_pulleys, cfg)
% run_cycle_variable_cw  System 2: Variable Counterweight Regeneration.
%   Primary 50 kg descent + 5×1 kg modular; lift residual 1 kg + control.
%   result has: E_electrical_out, E_consumed, loss_dict, t, P_mech, P_elec, PE_input, net_energy.

if nargin < 1 || isempty(eta_motor_scale), eta_motor_scale = 1.0; end
if nargin < 2 || isempty(friction_scale), friction_scale = 1.0; end
if nargin < 3 || isempty(n_pulleys), n_pulleys = 1; end
if nargin < 4 || isempty(cfg), cfg = config(); end

eta_motor = cfg.eta_motor_base * eta_motor_scale;
mu_rope_eff = cfg.mu_rope * friction_scale;
rope_eff = (1.0 / exp(mu_rope_eff * cfg.theta_pulley))^n_pulleys;
eta_gearbox = cfg.eta_gearbox;
F_friction_const = 0.5;

% Primary descent: 50 kg
d = physics_core('run_descent_integration', cfg.m_primary, cfg.h_drop, F_friction_const, ...
    rope_eff, eta_gearbox, eta_motor, cfg);
E_out_main = d.E_elec;
losses = physics_core('friction_losses_rope_bearing_gearbox', cfg.m_primary, cfg.h_drop, ...
    rope_eff, eta_gearbox, n_pulleys, cfg);
motor_loss_main = d.E_motor_loss;

% Modular: 5 × 1 kg descend, eta_modular
E_modular_per_module = cfg.m_per_module * cfg.g * cfg.h_drop * cfg.eta_modular_generator;
E_out_modular = cfg.n_modular_modules * E_modular_per_module;
E_electrical_out = E_out_main + E_out_modular;

% Return: motor lifts residual 1 kg + control
m_residual = 1.0;
PE_lift = m_residual * cfg.g * cfg.h_drop;
E_mech_lift = PE_lift / rope_eff;
E_consumed_motor = physics_core('gearbox_power_in', E_mech_lift, eta_gearbox) / eta_motor;
cycle_time_s = d.duration * 2;
E_control = cfg.control_power_W * cycle_time_s;
E_consumed = E_consumed_motor + E_control;

E_modular_loss = cfg.n_modular_modules * (cfg.m_per_module * cfg.g * cfg.h_drop * (1.0 - cfg.eta_modular_generator));
system_specific_J = E_consumed + E_modular_loss;

cycle_PE = physics_core('pe_input', cfg.m_primary, cfg.h_drop) + ...
    cfg.n_modular_modules * cfg.m_per_module * cfg.g * cfg.h_drop;
net_energy = E_electrical_out - cycle_PE;

loss_dict = struct('rope_J', losses.rope_J, 'bearing_J', losses.bearing_J, 'gearbox_J', losses.gearbox_J, ...
    'motor_J', motor_loss_main, 'system_specific_J', E_consumed + E_modular_loss);

result = struct('E_electrical_out', E_electrical_out, 'E_consumed', E_consumed, ...
    'loss_dict', loss_dict, 't', d.t, 'P_mech', d.P_mech, 'P_elec', d.P_elec, ...
    'PE_input', cycle_PE, 'net_energy', net_energy);
end
