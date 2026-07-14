function result = run_cycle_buoyancy(eta_motor_scale, friction_scale, n_pulleys, cfg)
% run_cycle_buoyancy  System 3: Buoyancy Gravitational Energy Storage.
%   Discharge: weight descends (water drag). Charge: pump lifts water.
%   result has: E_electrical_out, E_consumed, loss_dict, t, P_mech, P_elec, PE_input (no net_energy).

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
losses = physics_core('friction_losses_rope_bearing_gearbox', cfg.m_primary, cfg.h_drop, ...
    rope_eff, eta_gearbox, n_pulleys, cfg);
motor_loss = d.E_motor_loss;

% Water drag loss
A_cross = cfg.V_weight_buoyancy^(2.0/3.0);
v_avg = mean(d.velocity);
if isempty(d.velocity), v_avg = 0.5; end
F_drag_avg = 0.5 * cfg.rho_water * cfg.Cd_water_drag * A_cross * (v_avg^2);
E_water_drag = F_drag_avg * cfg.h_drop;

E_water_drag_capped = min(E_water_drag, 0.25 * (d.E_elec + 1e-6));
E_out = max(0.0, d.E_elec - E_water_drag_capped);

E_pump = cfg.rho_water * cfg.g * cfg.h_drop * cfg.V_water_per_cycle / cfg.eta_pump;
E_consumed = E_pump;

system_specific_J = E_pump + E_water_drag_capped;

loss_dict = struct('rope_J', losses.rope_J, 'bearing_J', losses.bearing_J, 'gearbox_J', losses.gearbox_J, ...
    'motor_J', motor_loss, 'system_specific_J', system_specific_J);

PE_input = physics_core('pe_input', cfg.m_primary, cfg.h_drop);

result = struct('E_electrical_out', E_out, 'E_consumed', E_consumed, ...
    'loss_dict', loss_dict, 't', d.t, 'P_mech', d.P_mech, 'P_elec', d.P_elec, ...
    'PE_input', PE_input);
end
