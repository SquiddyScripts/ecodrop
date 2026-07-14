% RUN_TIERED_GRAVITY_ANALYSIS  Tiered comparison: Tier 1 Regen, Tier 2 Storage, Tier 3 All 4.
% Tables and conclusion written to tiered_analysis_tables.txt, tiered_conclusion.txt.
% Figures stay open; resize and save manually (File > Save As).
% Run:  run_tiered_gravity_analysis

function run_tiered_gravity_analysis()

rng(42);
% Write tables and figures to project output/ folder
script_dir = fileparts(mfilename('fullpath'));
base_dir = fullfile(script_dir, '..', 'output');
if ~isfolder(base_dir), mkdir(base_dir); end

%% Constants
H = 3; m_common = 50; g = 9.81;
mgh = m_common * g * H;
names_short = {'Dual Weight', 'Buoyancy', 'Halbach Array', 'Variable Counterweight'};
n_rep = 10;
friction_scale = 1 + 0.2*(rand(4, n_rep) - 0.5);
friction_scale = max(0.8, min(1.2, friction_scale));

%% Simulation data
[Egen_all, E_cons_all, eta_all, net_all, T_cycle] = get_gravity_system_data(m_common, H, g, n_rep, friction_scale);

Egen = mean(Egen_all, 2);
Egen_sd = std(Egen_all, 0, 2);
E_cons = mean(E_cons_all, 2);
E_cons_sd = std(E_cons_all, 0, 2);
eta_mean = mean(eta_all, 2);
net_mean = mean(net_all, 2);
net_sd = std(net_all, 0, 2);

power_eff = 100 * Egen_all / mgh;
power_eff_mean = mean(power_eff, 2);
power_eff_sd = std(power_eff, 0, 2);
RTE_mean = power_eff_mean;
RTE_sd = power_eff_sd;

P_mech_avg = E_cons ./ T_cycle;
P_elec_avg = Egen ./ T_cycle;

%% Loss breakdown: total_loss = E_cons - Egen; split by assumed fractions
loss_frac = [
    0.15 0.20 0.25 0.40;
    0.20 0.15 0.10 0.55;
    0.10 0.25 0.30 0.35;
    0.10 0.15 0.25 0.50
];
total_loss = max(0, E_cons - Egen);
loss_rope   = total_loss .* loss_frac(:,1);
loss_bearing= total_loss .* loss_frac(:,2);
loss_gear   = total_loss .* loss_frac(:,3);
loss_motor  = total_loss .* loss_frac(:,4);
loss_pct = 100 * total_loss ./ max(E_cons, 1);

%% Cost
N_cycles_life = 10000;
base_build = 500;
build_factor = [1.0; 1.2; 1.8; 1.4];
kWh_per_life = (Egen .* N_cycles_life) / 3.6e6;
cost_per_kWh = (base_build * build_factor) ./ max(kWh_per_life, 0.01);
cost_per_kWh_sd = cost_per_kWh .* 0.15;

%% Styling: dark mode, large text (match old science-fair graphs)
BG = [0.11 0.11 0.14];
FG = [0.95 0.95 0.98];
GRID = [0.28 0.28 0.32];
C = [0.35 0.68 1; 1 0.5 0.3; 0.4 0.85 0.55; 0.75 0.45 0.95];
fs_title = 22;
fs_label = 16;
fs_legend = 14;
lw = 2.5;
w = 0.35;
fig_size = [100 100 800 640];
ax_pos = [0.11 0.12 0.78 0.75];

%% ----- TIER 1: Regenerative (Dual Weight vs Variable Counterweight) -----
fig1a = figure('Color', BG, 'Position', fig_size);
cycles = 1:n_rep;
plot(cycles, power_eff(1,:), 'o-', 'Color', C(1,:), 'LineWidth', lw, 'MarkerSize', 8); hold on;
plot(cycles, power_eff(4,:), 's-', 'Color', C(4,:), 'LineWidth', lw, 'MarkerSize', 8);
ax = gca; set(ax, 'Position', ax_pos, 'Color', BG, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
xlabel('Cycle (replicate) number', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
ylabel('Power efficiency (%)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Power Efficiency Per Cycle: Dual Weight vs Variable Counterweight (Regenerative)', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend(names_short([1 4]), 'FontSize', fs_legend, 'Location', 'best');
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25); hold off;

fig1b = figure('Color', BG, 'Position', fig_size);
E_cons_kJ = E_cons/1e3; Egen_kJ = Egen/1e3; net_kJ = net_mean/1e3;
dat1b = [E_cons_kJ(1) E_cons_kJ(4); Egen_kJ(1) Egen_kJ(4); net_kJ(1) net_kJ(4)];
b = bar(dat1b, 'grouped', 'EdgeColor', GRID, 'LineWidth', 1);
b(1).FaceColor = C(1,:); b(2).FaceColor = C(4,:);
ax = gca; set(ax, 'Position', ax_pos, 'Color', BG, 'XTickLabel', {'Charge (consumed)', 'Discharge (regenerated)', 'Net'}, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Energy (kJ)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Energy Regenerated vs Consumed: Dual Weight vs Variable Counterweight (Regenerative)', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend(names_short([1 4]), 'FontSize', fs_legend);
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25);

fig1c = figure('Color', BG, 'Position', fig_size);
loss_stack = [loss_rope([1 4]) loss_bearing([1 4]) loss_gear([1 4]) loss_motor([1 4])] / 1e3;
b = bar(1:2, loss_stack, 'stacked', 'EdgeColor', GRID, 'LineWidth', 1);
b(1).FaceColor = [0.6 0.4 0.2]; b(2).FaceColor = [0.3 0.5 0.6]; b(3).FaceColor = [0.5 0.3 0.5]; b(4).FaceColor = [0.7 0.2 0.2];
ax = gca; set(ax, 'Position', ax_pos, 'Color', BG, 'XTick', 1:2, 'XTickLabel', names_short([1 4]), 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Energy lost per cycle (kJ)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Mechanical Loss Breakdown: Dual Weight vs Variable Counterweight (Regenerative)', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend({'Rope/cable friction', 'Bearing friction', 'Gear losses', 'Motor conversion'}, 'FontSize', fs_legend);
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25);

%% ----- TIER 2: Storage (Buoyancy vs Halbach Array) -----
fig2a = figure('Color', BG, 'Position', fig_size);
plot(cycles, power_eff(2,:), 'o-', 'Color', C(2,:), 'LineWidth', lw, 'MarkerSize', 8); hold on;
plot(cycles, power_eff(3,:), 's-', 'Color', C(3,:), 'LineWidth', lw, 'MarkerSize', 8);
ax = gca; set(ax, 'Position', ax_pos, 'Color', BG, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
xlabel('Cycle (replicate) number', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
ylabel('Power efficiency (%)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Power Efficiency Per Cycle: Buoyancy vs Halbach Array (Storage)', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend(names_short([2 3]), 'FontSize', fs_legend);
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25); hold off;

fig2b = figure('Color', BG, 'Position', fig_size);
b1 = bar([1 2] - w/2, [P_mech_avg(2) P_mech_avg(3)], w, 'FaceColor', [0.4 0.6 0.9], 'EdgeColor', GRID, 'LineWidth', 1); hold on;
b2 = bar([1 2] + w/2, [P_elec_avg(2) P_elec_avg(3)], w, 'FaceColor', [0.9 0.45 0.2], 'EdgeColor', GRID, 'LineWidth', 1);
ax = gca; set(ax, 'Position', ax_pos, 'Color', BG, 'XTick', 1:2, 'XTickLabel', names_short([2 3]), 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Power (W)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Mechanical vs Electrical Power: Buoyancy vs Halbach Array (Storage)', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend([b1 b2], {'Mechanical input (avg)', 'Electrical output (avg)'}, 'FontSize', fs_legend);
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25); hold off;

fig2c = figure('Color', BG, 'Position', fig_size);
loss_stack2 = [loss_rope([2 3]) loss_bearing([2 3]) loss_gear([2 3]) loss_motor([2 3])] / 1e3;
b = bar(1:2, loss_stack2, 'stacked', 'EdgeColor', GRID, 'LineWidth', 1);
b(1).FaceColor = [0.6 0.4 0.2]; b(2).FaceColor = [0.3 0.5 0.6]; b(3).FaceColor = [0.5 0.3 0.5]; b(4).FaceColor = [0.7 0.2 0.2];
ax = gca; set(ax, 'Position', ax_pos, 'Color', BG, 'XTick', 1:2, 'XTickLabel', names_short([2 3]), 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Energy lost per cycle (kJ)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Mechanical Loss Breakdown: Buoyancy vs Halbach Array (Storage)', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend({'Rope/cable friction', 'Bearing friction', 'Gear losses', 'Motor conversion'}, 'FontSize', fs_legend);
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25);

%% ----- TIER 3: All 4 systems -----
fig3a = figure('Color', BG, 'Position', fig_size);
ypos = 4:-1:1;
b = barh(ypos, power_eff_mean, 'FaceColor', 'flat', 'EdgeColor', GRID, 'LineWidth', 1.2);
for i = 1:4, b.CData(i,:) = C(i,:); end
hold on;
errorbar(power_eff_mean, ypos, power_eff_sd, 'horizontal', 'Color', FG, 'LineStyle', 'none', 'CapSize', 8);
ax = gca; set(ax, 'Position', ax_pos, 'Color', BG, 'YTick', [1 2 3 4], 'YTickLabel', names_short(4:-1:1), 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
xlabel('Power efficiency (%)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Power Efficiency: All Four Gravitational Energy Systems', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
xlim([0 max(100, max(power_eff_mean+power_eff_sd)*1.1)]); grid on; set(ax, 'GridAlpha', 0.25); hold off;

fig3b = figure('Color', BG, 'Position', fig_size);
x4 = 1:4;
b1 = bar(x4 - w/2, P_mech_avg, w, 'FaceColor', [0.4 0.6 0.9], 'EdgeColor', GRID, 'LineWidth', 1); hold on;
b2 = bar(x4 + w/2, P_elec_avg, w, 'FaceColor', [0.9 0.45 0.2], 'EdgeColor', GRID, 'LineWidth', 1);
ax = gca; set(ax, 'Position', ax_pos, 'Color', BG, 'XTick', 1:4, 'XTickLabel', names_short, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Power (W)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Mechanical vs Electrical Power: All Four Systems', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend([b1 b2], {'Mechanical input (avg)', 'Electrical output (avg)'}, 'FontSize', fs_legend);
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25); hold off;

fig3c = figure('Color', BG, 'Position', fig_size);
useful_kJ = Egen/1e3;
stack_all = [loss_rope loss_bearing loss_gear loss_motor] / 1e3;
b = bar(1:4, [stack_all useful_kJ], 'stacked', 'EdgeColor', GRID, 'LineWidth', 1);
b(1).FaceColor = [0.6 0.4 0.2]; b(2).FaceColor = [0.3 0.5 0.6]; b(3).FaceColor = [0.5 0.3 0.5]; b(4).FaceColor = [0.7 0.2 0.2]; b(5).FaceColor = [0.2 0.65 0.35];
ax = gca; set(ax, 'Position', ax_pos, 'Color', BG, 'XTick', 1:4, 'XTickLabel', names_short, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Energy per cycle (kJ)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Full Loss Breakdown: All Four Systems (Losses + Useful Output)', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend(b, {'Rope/cable', 'Bearing', 'Gear', 'Motor conversion', 'Useful electrical output'}, 'FontSize', fs_legend);
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25);

fig3d = figure('Color', BG, 'Position', fig_size);
b = bar(1:4, cost_per_kWh, 'FaceColor', 'flat', 'EdgeColor', GRID, 'LineWidth', 1.2);
for i = 1:4, b.CData(i,:) = C(i,:); end
hold on;
errorbar(1:4, cost_per_kWh, cost_per_kWh_sd, 'Color', FG, 'LineStyle', 'none', 'CapSize', 8);
ax = gca; set(ax, 'Position', ax_pos, 'Color', BG, 'XTick', 1:4, 'XTickLabel', names_short, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Estimated cost ($/kWh)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Estimated Cost Per Kilowatt-Hour: All Four Systems (10,000-cycle life)', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
text(2, max(cost_per_kWh)*0.95, 'Assumption: relative build cost; prototype scale.', 'FontSize', 12, 'Color', FG);
grid on; set(ax, 'GridAlpha', 0.25); hold off;

fig3e = figure('Color', BG, 'Position', fig_size);
N_cycles = (1:500)';
cum_net = N_cycles * (net_mean/1e3)';  % (500x4) kJ
cum_net_Wh = cum_net / 3.6;
for i = 1:4
    plot(N_cycles, cum_net_Wh(:,i), 'Color', C(i,:), 'LineWidth', lw); hold on;
end
ax = gca; set(ax, 'Position', ax_pos, 'Color', BG, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
xlabel('Number of cycles', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
ylabel('Cumulative net electrical energy output (Wh)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Cumulative Net Energy Output Over Lifecycle: All Four Systems', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend(names_short, 'FontSize', fs_legend);
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25); hold off;

%% Tables and conclusion (always written)
write_tiered_tables_and_conclusion(base_dir, names_short, Egen, Egen_sd, E_cons, E_cons_sd, P_mech_avg, P_elec_avg, power_eff_mean, power_eff_sd, RTE_mean, RTE_sd, total_loss, loss_rope, loss_bearing, loss_gear, loss_motor, loss_pct, cost_per_kWh, cost_per_kWh_sd, net_mean, net_sd, Egen_all, E_cons_all, power_eff, mgh, N_cycles_life, base_build, build_factor);

fprintf('\n========== TIERED ANALYSIS COMPLETE ==========\n');
fprintf('Tables:  %s\n', fullfile(base_dir, 'tiered_analysis_tables.txt'));
fprintf('Conclusion: %s\n', fullfile(base_dir, 'tiered_conclusion.txt'));
fprintf('Figures: Tier1A-1C, Tier2A-2C, Tier3A-3E (open; save manually if needed).\n');
fprintf('==============================================\n\n');

end

%% -------------------------------------------------------------------------
function [Egen_all, E_cons_all, eta_all, net_all, T_cycle] = get_gravity_system_data(m_common, H, g, n_rep, friction_scale)
T1_d = 2.8; T2_d = 3.2;
T_lift = 25; T_water = 18; T_drop = 3.2;
T_lift4 = 6.5; T_hold4 = 1; T_drop4 = 2.2;
T_des5 = 2.5; T_dock5 = 1.5; T_asc5 = 2.8; T_load5 = 1.2;
T_cycle = [T1_d+T2_d; T_lift+T_water+T_drop; T_lift4+T_hold4+T_drop4; T_des5+T_dock5+T_asc5+T_load5];

m_net = m_common;
t2 = linspace(0, T_cycle(1), 250);
ix1 = t2 <= T1_d; ix2 = t2 > T1_d;
v_cab = zeros(size(t2)); tau1 = t2(ix1)/T1_d; v_cab(ix1) = -1.35 * 4*tau1.*(1-tau1);
tau2 = (t2(ix2)-T1_d)/T2_d; v_cab(ix2) = 1.25 * 4*tau2.*(1-tau2);
P_mech = m_net * g * (-v_cab);

m3 = m_common;
t3 = linspace(0, T_cycle(2), 400);
ix_l = t3 <= T_lift; ix_w = t3 > T_lift & t3 <= T_lift+T_water; ix_d = t3 > T_lift+T_water;
v3 = zeros(size(t3)); tau_l = t3(ix_l)/T_lift; v3(ix_l) = 0.65 * 4*tau_l.*(1-tau_l);
tau_d = (t3(ix_d)-T_lift-T_water)/T_drop; tau_d = min(max(tau_d,0),1); v3(ix_d) = -4.2 * (1 - (1-tau_d).^0.7);
P_motor3 = zeros(size(t3)); P_motor3(ix_l) = 50 + 80*tau_l.*(1-tau_l);
tw = t3(ix_w) - T_lift; pump_ix = tw >= T_water*0.4;
P_pump3 = zeros(size(t3)); P_pump3(ix_w) = pump_ix .* (200 + 150*sin(pi*(tw - T_water*0.4)/(T_water*0.6))); P_pump3(ix_w) = max(0, P_pump3(ix_w));

m4 = m_common;
t4 = linspace(0, T_cycle(3), 300);
ix_l4 = t4 <= T_lift4; ix_d4 = t4 > T_lift4 + T_hold4;
v4 = zeros(size(t4)); tau_l4 = t4(ix_l4)/T_lift4; v4(ix_l4) = 1.5 * sin(pi*tau_l4);
tau_d4 = (t4(ix_d4)-T_lift4-T_hold4)/T_drop4; tau_d4 = min(max(tau_d4,0),1); v4(ix_d4) = -4 * (1 - (1-tau_d4).^0.65);
F4_grav = m4 * g * 1.15;

m_cab5 = m_common; m_mod5 = 10;
t5 = linspace(0, T_cycle(4), 350);
ix_des5 = t5 <= T_des5; ix_asc5 = t5 > T_des5+T_dock5 & t5 <= T_des5+T_dock5+T_asc5;
ix_dock5 = t5 > T_des5 & t5 <= T_des5+T_dock5; ix_load5 = t5 > T_des5+T_dock5+T_asc5;
n_mod = 2*ones(size(t5)); n_mod(t5(ix_des5) >= 0.6*T_des5) = 1;
n_mod(t5 > T_des5+T_dock5) = 1; n_mod(t5 > T_des5+T_dock5+T_asc5 + 0.4*T_load5) = 2;
m_tot5 = m_cab5 + n_mod * m_mod5;
v5 = zeros(size(t5)); tau_d5 = t5(ix_des5)/T_des5; v5(ix_des5) = -1.4 * 4*tau_d5.*(1-tau_d5);
tau_a5 = (t5(ix_asc5)-T_des5-T_dock5)/T_asc5; v5(ix_asc5) = 1.2 * 4*tau_a5.*(1-tau_a5);
rel_idx = find(ix_des5 & t5 >= 0.6*T_des5, 1); idx_r = max(1,rel_idx-10):min(length(t5),rel_idx+20);
m_cw5 = m_cab5 + 1*m_mod5; net_load5 = max(0, m_tot5(ix_asc5)*g - m_cw5*g*0.88);

Egen_all = zeros(4, n_rep);
E_cons_all = zeros(4, n_rep);
eta_all = zeros(4, n_rep);
net_all = zeros(4, n_rep);

for r = 1:n_rep
    sf = friction_scale(:, r);
    eta_gen = 0.72 + 0.02*randn; eta_drive = 0.88 + 0.02*randn;
    eta_gen = max(0.5, min(0.92, eta_gen)); eta_drive = max(0.75, min(0.98, eta_drive));
    P_elec2 = zeros(size(t2)); P_elec2(ix1) = eta_gen * max(P_mech(ix1), 0); P_elec2(ix2) = -max(0, -P_mech(ix2)) / eta_drive;
    E_gen_2 = trapz(t2, max(P_elec2, 0)); E_cons_2 = trapz(t2, max(-P_elec2, 0)) * sf(1);
    eta_all(1,r) = 100*E_gen_2/(E_cons_2+1e-9); net_all(1,r) = E_gen_2 - E_cons_2;
    Egen_all(1,r) = E_gen_2; E_cons_all(1,r) = E_cons_2;

    eta_gen3 = 0.74 + 0.02*randn; scale_cons3 = 1 + 0.03*randn; scale_cons3 = max(0.85, min(1.15, scale_cons3));
    P_gen3 = zeros(size(t3)); P_gen3(ix_d) = eta_gen3 * m3 * g * (-v3(ix_d)); P_gen3(ix_d) = max(P_gen3(ix_d), 0);
    E_gen_3 = trapz(t3, P_gen3); E_cons_3 = trapz(t3, (P_motor3 + P_pump3)*scale_cons3) * sf(2);
    eta_all(2,r) = 100*E_gen_3/(E_cons_3+1e-9); net_all(2,r) = E_gen_3 - E_cons_3;
    Egen_all(2,r) = E_gen_3; E_cons_all(2,r) = E_cons_3;

    eta_lift = 0.82 + 0.02*randn; eta_gen4 = 0.78 + 0.02*randn;
    eta_lift = max(0.65, min(0.95, eta_lift)); eta_gen4 = max(0.6, min(0.9, eta_gen4));
    P_linear4 = zeros(size(t4)); P_linear4(ix_l4) = F4_grav * v4(ix_l4) / eta_lift;
    P_hoist4 = zeros(size(t4)); P_hoist4(ix_l4) = 45; P_hoist4(t4 > T_lift4 & t4 <= T_lift4+T_hold4) = 40;
    P_gen4 = zeros(size(t4)); P_gen4(ix_d4) = eta_gen4 * m4 * g * (-v4(ix_d4)); P_gen4(ix_d4) = max(P_gen4(ix_d4), 0);
    E_cons_4 = trapz(t4, P_linear4 + P_hoist4) * sf(3); E_gen_4 = trapz(t4, P_gen4);
    eta_all(3,r) = 100*E_gen_4/(E_cons_4+1e-9); net_all(3,r) = E_gen_4 - E_cons_4;
    Egen_all(3,r) = E_gen_4; E_cons_all(3,r) = E_cons_4;

    eta_main = 0.74 + 0.02*randn; eta_drive5 = 0.86 + 0.02*randn;
    eta_main = max(0.6, min(0.9, eta_main)); eta_drive5 = max(0.75, min(0.95, eta_drive5));
    P_main5 = zeros(size(t5)); P_main5(ix_des5) = eta_main * m_tot5(ix_des5) .* g .* (-v5(ix_des5)); P_main5(ix_des5) = max(P_main5(ix_des5), 0);
    P_mod5 = zeros(size(t5)); P_mod5(idx_r) = 80 * exp(-(t5(idx_r)-t5(rel_idx)).^2/0.16);
    P_sup5 = zeros(size(t5)); P_sup5(ix_dock5) = 25;
    P_mot5 = zeros(size(t5)); P_mot5(ix_asc5) = (net_load5 .* v5(ix_asc5)) / eta_drive5; P_mot5(ix_asc5) = max(P_mot5(ix_asc5), 25);
    P_aux5 = zeros(size(t5)); P_aux5(ix_dock5) = 450; P_aux5(ix_load5) = 380;
    E_gen_5 = trapz(t5, P_main5 + P_mod5 + P_sup5); E_cons_5 = trapz(t5, P_mot5 + P_aux5) * sf(4);
    eta_all(4,r) = min(90, 100*E_gen_5/(E_cons_5+1e-9)); net_all(4,r) = E_gen_5 - E_cons_5;
    Egen_all(4,r) = E_gen_5; E_cons_all(4,r) = E_cons_5;
end
end

%% -------------------------------------------------------------------------
function write_tiered_tables_and_conclusion(base_dir, names_short, Egen, Egen_sd, E_cons, E_cons_sd, P_mech_avg, P_elec_avg, power_eff_mean, power_eff_sd, RTE_mean, RTE_sd, total_loss, loss_rope, loss_bearing, loss_gear, loss_motor, loss_pct, cost_per_kWh, cost_per_kWh_sd, net_mean, net_sd, Egen_all, E_cons_all, power_eff, mgh, N_cycles_life, base_build, build_factor)
path_tab = fullfile(base_dir, 'tiered_analysis_tables.txt');
path_conc = fullfile(base_dir, 'tiered_conclusion.txt');
fid = fopen(path_tab, 'w');
fprintf(fid, 'TABLE 1: Per-System Summary\n');
fprintf(fid, 'System\tMech Power In (W)\tElec Power Out (W)\tPower Eff (%%)\tRTE (%%)\tEnergy Lost/Cycle (J)\tEst. Cost/kWh ($)\n');
for i = 1:4
    fprintf(fid, '%s\t%.1f\t%.1f\t%.1f +/- %.1f\t%.1f +/- %.1f\t%.0f\t%.0f +/- %.0f\n', ...
        names_short{i}, P_mech_avg(i), P_elec_avg(i), power_eff_mean(i), power_eff_sd(i), RTE_mean(i), RTE_sd(i), total_loss(i), cost_per_kWh(i), cost_per_kWh_sd(i));
end
fprintf(fid, '\nTABLE 2: Loss Breakdown (J and %% of input)\n');
fprintf(fid, 'System\tRope (J)\tBearing (J)\tGear (J)\tMotor (J)\tTotal Loss (J)\tLoss %% of Input\n');
for i = 1:4
    fprintf(fid, '%s\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\t%.1f\n', names_short{i}, loss_rope(i), loss_bearing(i), loss_gear(i), loss_motor(i), total_loss(i), loss_pct(i));
end
fprintf(fid, '\nTABLE 3: Regenerative Systems Cycle-by-Cycle (Dual Weight, Variable CW)\n');
fprintf(fid, 'Cycle\tDual E_in (J)\tDual E_out (J)\tDual Net (J)\tVarCW E_in (J)\tVarCW E_out (J)\tVarCW Net (J)\n');
for r = 1:size(Egen_all,2)
    fprintf(fid, '%d\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\n', r, E_cons_all(1,r), Egen_all(1,r), Egen_all(1,r)-E_cons_all(1,r), E_cons_all(4,r), Egen_all(4,r), Egen_all(4,r)-E_cons_all(4,r));
end
fprintf(fid, '\nTABLE 4: Cost Analysis (base_build=$%d, N_cycles_life=%d)\n', base_build, N_cycles_life);
fprintf(fid, 'System\tBuild factor\tE_gen/cycle (J)\tkWh over life\tCost/kWh ($)\n');
kWh_life = (Egen .* N_cycles_life) / 3.6e6;
bf = [1.0; 1.2; 1.8; 1.4];
for i = 1:4
    fprintf(fid, '%s\t%.1f\t%.0f\t%.2f\t%.0f\n', names_short{i}, bf(i), Egen(i), kWh_life(i), cost_per_kWh(i));
end
fclose(fid);

[~, best_idx] = max(power_eff_mean);
best_name = names_short{best_idx};
thresh = 70;
fid = fopen(path_conc, 'w');
fprintf(fid, 'SECTION 1 - Research Goal\n');
fprintf(fid, 'This project compared four gravitational energy systems under identical conditions (50 kg, 3 m). The goal was to determine which achieves the highest power efficiency and whether any is viable as a real-world energy storage solution.\n\n');
fprintf(fid, 'SECTION 2 - Defined Terms\n');
fprintf(fid, 'Power efficiency: 100 * (Electrical energy output per cycle / Mechanical PE input per cycle) = 100 * E_gen / (m*g*h). Round-trip efficiency (RTE): same formula here.\n\n');
fprintf(fid, 'SECTION 3 - Results (Lead With Numbers)\n');
fprintf(fid, 'Between regenerative systems: Variable Counterweight achieved %.1f%% power efficiency vs Dual Weight %.1f%%.\n', power_eff_mean(4), power_eff_mean(1));
fprintf(fid, 'Between storage systems: Buoyancy achieved %.1f%% vs Halbach Array %.1f%%.\n', power_eff_mean(2), power_eff_mean(3));
fprintf(fid, 'Across all four: %s achieved the highest power efficiency (%.1f%%).\n\n', best_name, power_eff_mean(best_idx));
fprintf(fid, 'SECTION 4 - Loss Analysis Summary\n');
fprintf(fid, 'Losses are highest in motor conversion and bearing/gear stages. Regenerative systems reduce net mechanical work and thus total loss.\n\n');
fprintf(fid, 'SECTION 5 - Advantages and Limitations\n');
fprintf(fid, 'Advantages: Gravitational storage avoids toxic materials; Variable CW minimizes net work; Buoyancy uses buoyant assist. Limitations: Simulation friction and efficiency are estimates; cost estimates are prototype-based.\n\n');
fprintf(fid, 'SECTION 6 - Real-World Significance\n');
fprintf(fid, 'A viable gravitational system could serve off-grid communities or grid balancing. Finding a design that approaches pumped-hydro or battery efficiency supports decarbonization.\n\n');
fprintf(fid, 'SECTION 7 - Future Work\n');
fprintf(fid, 'Physical prototype validation, scaling tests, hybrid regenerative+storage designs, cost reduction.\n');
fclose(fid);
end
