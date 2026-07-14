function result = run_cycle_halbach(eta_motor_scale, friction_scale, n_pulleys, cfg)
% run_cycle_halbach  System 4: Halbach Array Gravitational Storage.
%   Discharge: same rope/drum/gearbox/BLDC as others; linear motors do NOT generate on descent.
%   Charge: linear motors lift; aux + control. result: E_electrical_out, E_consumed, loss_dict, etc.

if nargin < 1 || isempty(eta_motor_scale), eta_motor_scale = 1.0; end
if nargin < 2 || isempty(friction_scale), friction_scale = 1.0; end
if nargin < 3 || isempty(n_pulleys), n_pulleys = 1; end
if nargin < 4 || isempty(cfg), cfg = config(); end

eta_motor = cfg.eta_motor_base * eta_motor_scale;
mu_rope_eff = cfg.mu_rope * friction_scale;
rope_eff = (1.0 / exp(mu_rope_eff * cfg.theta_pulley))^n_pulleys;
eta_gearbox = cfg.eta_gearbox;
F_friction_const = 0.5;

d = physics_core('run_descent_integration', cfg.m_primary, cfg.h_drop, F_friction_const, ...
    rope_eff, eta_gearbox, eta_motor, cfg);
E_electrical_out = d.E_elec;

losses = physics_core('friction_losses_rope_bearing_gearbox', cfg.m_primary, cfg.h_drop, ...
    rope_eff, eta_gearbox, n_pulleys, cfg);
rope_J = losses.rope_J;
bearing_J = losses.bearing_J;
gearbox_J = losses.gearbox_J;
motor_loss = d.E_motor_loss;

v_avg = mean(d.velocity);
if isempty(d.velocity), v_avg = 0.5; end
t_discharge = d.duration;
if t_discharge <= 0, t_discharge = 6.0; end
E_magnetic_drag = cfg.magnetic_drag_coeff * v_avg * 10.0 * cfg.h_drop;
E_electrical_out = max(0.0, E_electrical_out - E_magnetic_drag);

PE_lift = cfg.m_primary * cfg.g * cfg.h_drop;
E_elec_lift = PE_lift / (cfg.eta_linear_actuator * cfg.halbach_flux_factor);
E_aux = (cfg.auxiliary_hoist_W + cfg.control_electronics_W) * t_discharge * 2;
E_consumed = E_elec_lift + E_aux;

system_specific_J = E_elec_lift * (1 - cfg.eta_linear_actuator) + E_magnetic_drag + E_aux;

loss_dict = struct('rope_J', rope_J, 'bearing_J', bearing_J, 'gearbox_J', gearbox_J, ...
    'motor_J', motor_loss, 'system_specific_J', system_specific_J);

PE_input = physics_core('pe_input', cfg.m_primary, cfg.h_drop);

result = struct('E_electrical_out', E_electrical_out, 'E_consumed', E_consumed, ...
    'loss_dict', loss_dict, 't', d.t, 'P_mech', d.P_mech, 'P_elec', d.P_elec, ...
    'PE_input', PE_input);
end
