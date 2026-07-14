function result = run_cycle_dual_weight(eta_motor_scale, friction_scale, n_pulleys, cfg)
% run_cycle_dual_weight  System 1: Dual Weight Regeneration.
%   One full cycle: primary descent + counterweight descent.
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

% Half-cycle 1: primary (50 kg) descends
d1 = physics_core('run_descent_integration', cfg.m_primary, cfg.h_drop, F_friction_const, ...
    rope_eff, eta_gearbox, eta_motor, cfg);
E_out_primary = d1.E_elec;
losses_primary = physics_core('friction_losses_rope_bearing_gearbox', cfg.m_primary, cfg.h_drop, ...
    rope_eff, eta_gearbox, n_pulleys, cfg);
motor_loss_primary = d1.E_motor_loss;

% Half-cycle 2: counterweight (40 kg) descends
d2 = physics_core('run_descent_integration', cfg.m_counterweight_dual, cfg.h_drop, F_friction_const, ...
    rope_eff, eta_gearbox, eta_motor, cfg);
E_out_counter = d2.E_elec;
losses_counter = physics_core('friction_losses_rope_bearing_gearbox', cfg.m_counterweight_dual, cfg.h_drop, ...
    rope_eff, eta_gearbox, n_pulleys, cfg);
motor_loss_counter = d2.E_motor_loss;

E_electrical_out = E_out_primary + E_out_counter;

% Return (lift) energy: motor lifts net imbalance 10 kg
PE_lift_net = cfg.m_net_imbalance_dual * cfg.g * cfg.h_drop;
E_mech_lift = PE_lift_net / rope_eff;
E_elec_for_lift = physics_core('gearbox_power_in', E_mech_lift, eta_gearbox) / eta_motor;
E_consumed = E_elec_for_lift;

% Loss breakdown
rope_J = losses_primary.rope_J + losses_counter.rope_J;
bearing_J = losses_primary.bearing_J + losses_counter.bearing_J;
gearbox_J = losses_primary.gearbox_J + losses_counter.gearbox_J;
motor_J = motor_loss_primary + motor_loss_counter;
system_specific_J = E_consumed;

% Time series: concatenate both half-cycles
t1 = d1.t; t2 = d2.t;
t2_shifted = t2 + (t1(end) + 0.1);
t_full = [t1(:); t2_shifted(:)];
P_mech_full = [d1.P_mech(:); d2.P_mech(:)];
P_elec_full = [d1.P_elec(:); d2.P_elec(:)];

cycle_PE = physics_core('pe_input', cfg.m_primary, cfg.h_drop) + ...
    physics_core('pe_input', cfg.m_counterweight_dual, cfg.h_drop);
net_energy = E_electrical_out - cycle_PE;

loss_dict = struct('rope_J', rope_J, 'bearing_J', bearing_J, 'gearbox_J', gearbox_J, ...
    'motor_J', motor_J, 'system_specific_J', system_specific_J);

result = struct('E_electrical_out', E_electrical_out, 'E_consumed', E_consumed, ...
    'loss_dict', loss_dict, 't', t_full, 'P_mech', P_mech_full, 'P_elec', P_elec_full, ...
    'PE_input', cycle_PE, 'net_energy', net_energy);
end
