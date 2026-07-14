% PLOT_SCIENCE_FAIR_GRAPHS  Six comparison graphs (all 4 systems), dark mode, large text.
% Uses same physics as analysis_compare_systems. Saves PNGs to script folder.
% Run:  plot_science_fair_graphs

function plot_science_fair_graphs()

rng(42);
H = 3; m_common = 50; g = 9.81;

%% Precompute time and mechanical quantities (same as analysis_compare_systems)
m_net = m_common; T1_d = 2.8; T2_d = 3.2;
t2 = linspace(0, T1_d + T2_d, 250);
ix1 = t2 <= T1_d; ix2 = t2 > T1_d;
v_cab = zeros(size(t2)); tau1 = t2(ix1)/T1_d; v_cab(ix1) = -1.35 * 4*tau1.*(1-tau1);
tau2 = (t2(ix2)-T1_d)/T2_d; v_cab(ix2) = 1.25 * 4*tau2.*(1-tau2);
P_mech = m_net * g * (-v_cab);

m3 = m_common; T_lift = 25; T_water = 18; T_drop = 3.2;
t3 = linspace(0, T_lift + T_water + T_drop, 400);
ix_l = t3 <= T_lift; ix_w = t3 > T_lift & t3 <= T_lift+T_water; ix_d = t3 > T_lift+T_water;
v3 = zeros(size(t3)); tau_l = t3(ix_l)/T_lift; v3(ix_l) = 0.65 * 4*tau_l.*(1-tau_l);
tau_d = (t3(ix_d)-T_lift-T_water)/T_drop; tau_d = min(max(tau_d,0),1); v3(ix_d) = -4.2 * (1 - (1-tau_d).^0.7);
P_motor3 = zeros(size(t3)); P_motor3(ix_l) = 50 + 80*tau_l.*(1-tau_l);
tw = t3(ix_w) - T_lift; pump_ix = tw >= T_water*0.4;
P_pump3 = zeros(size(t3)); P_pump3(ix_w) = pump_ix .* (200 + 150*sin(pi*(tw - T_water*0.4)/(T_water*0.6))); P_pump3(ix_w) = max(0, P_pump3(ix_w));

m4 = m_common; T_lift4 = 6.5; T_hold4 = 1; T_drop4 = 2.2;
t4 = linspace(0, T_lift4 + T_hold4 + T_drop4, 300);
ix_l4 = t4 <= T_lift4; ix_d4 = t4 > T_lift4 + T_hold4;
v4 = zeros(size(t4)); tau_l4 = t4(ix_l4)/T_lift4; v4(ix_l4) = 1.5 * sin(pi*tau_l4);
tau_d4 = (t4(ix_d4)-T_lift4-T_hold4)/T_drop4; tau_d4 = min(max(tau_d4,0),1); v4(ix_d4) = -4 * (1 - (1-tau_d4).^0.65);
F4_grav = m4 * g * 1.15;

m_cab5 = m_common; m_mod5 = 10; T_des5 = 2.5; T_dock5 = 1.5; T_asc5 = 2.8; T_load5 = 1.2;
t5 = linspace(0, T_des5 + T_dock5 + T_asc5 + T_load5, 350);
ix_des5 = t5 <= T_des5; ix_asc5 = t5 > T_des5+T_dock5 & t5 <= T_des5+T_dock5+T_asc5;
ix_dock5 = t5 > T_des5 & t5 <= T_des5+T_dock5; ix_load5 = t5 > T_des5+T_dock5+T_asc5;
n_mod = 2*ones(size(t5)); n_mod(t5(ix_des5) >= 0.6*T_des5) = 1;
n_mod(t5 > T_des5+T_dock5) = 1; n_mod(t5 > T_des5+T_dock5+T_asc5 + 0.4*T_load5) = 2;
m_tot5 = m_cab5 + n_mod * m_mod5;
v5 = zeros(size(t5)); tau_d5 = t5(ix_des5)/T_des5; v5(ix_des5) = -1.4 * 4*tau_d5.*(1-tau_d5);
tau_a5 = (t5(ix_asc5)-T_des5-T_dock5)/T_asc5; v5(ix_asc5) = 1.2 * 4*tau_a5.*(1-tau_a5);
rel_idx = find(ix_des5 & t5 >= 0.6*T_des5, 1); idx_r = max(1,rel_idx-10):min(length(t5),rel_idx+20);
m_cw5 = m_cab5 + 1*m_mod5; net_load5 = max(0, m_tot5(ix_asc5)*g - m_cw5*g*0.88);

n_rep = 10;
eta_all = zeros(4, n_rep);
net_all = zeros(4, n_rep);
for r = 1:n_rep
    eta_gen = 0.72 + 0.02*randn; eta_drive = 0.88 + 0.02*randn;
    eta_gen = max(0.5, min(0.92, eta_gen)); eta_drive = max(0.75, min(0.98, eta_drive));
    P_elec2 = zeros(size(t2)); P_elec2(ix1) = eta_gen * max(P_mech(ix1), 0); P_elec2(ix2) = -max(0, -P_mech(ix2)) / eta_drive;
    E_gen_2 = trapz(t2, max(P_elec2, 0)); E_cons_2 = trapz(t2, max(-P_elec2, 0));
    eta_all(1,r) = 100*E_gen_2/(E_cons_2+1e-9); net_all(1,r) = E_gen_2 - E_cons_2;

    eta_gen3 = 0.74 + 0.02*randn; eta_gen3 = max(0.5, min(0.9, eta_gen3));
    scale_cons3 = 1 + 0.03*randn; scale_cons3 = max(0.85, min(1.15, scale_cons3));
    P_gen3 = zeros(size(t3)); P_gen3(ix_d) = eta_gen3 * m3 * g * (-v3(ix_d)); P_gen3(ix_d) = max(P_gen3(ix_d), 0);
    E_gen_3 = trapz(t3, P_gen3); E_cons_3 = trapz(t3, (P_motor3 + P_pump3)*scale_cons3);
    eta_all(2,r) = 100*E_gen_3/(E_cons_3+1e-9); net_all(2,r) = E_gen_3 - E_cons_3;

    eta_lift = 0.82 + 0.02*randn; eta_gen4 = 0.78 + 0.02*randn;
    eta_lift = max(0.65, min(0.95, eta_lift)); eta_gen4 = max(0.6, min(0.9, eta_gen4));
    P_linear4 = zeros(size(t4)); P_linear4(ix_l4) = F4_grav * v4(ix_l4) / eta_lift;
    P_hoist4 = zeros(size(t4)); P_hoist4(ix_l4) = 45; P_hoist4(t4 > T_lift4 & t4 <= T_lift4+T_hold4) = 40;
    P_gen4 = zeros(size(t4)); P_gen4(ix_d4) = eta_gen4 * m4 * g * (-v4(ix_d4)); P_gen4(ix_d4) = max(P_gen4(ix_d4), 0);
    E_cons_4 = trapz(t4, P_linear4 + P_hoist4); E_gen_4 = trapz(t4, P_gen4);
    eta_all(3,r) = 100*E_gen_4/(E_cons_4+1e-9); net_all(3,r) = E_gen_4 - E_cons_4;

    eta_main = 0.74 + 0.02*randn; eta_drive5 = 0.86 + 0.02*randn;
    eta_main = max(0.6, min(0.9, eta_main)); eta_drive5 = max(0.75, min(0.95, eta_drive5));
    P_main5 = zeros(size(t5)); P_main5(ix_des5) = eta_main * m_tot5(ix_des5) .* g .* (-v5(ix_des5)); P_main5(ix_des5) = max(P_main5(ix_des5), 0);
    P_mod5 = zeros(size(t5)); P_mod5(idx_r) = 80 * exp(-(t5(idx_r)-t5(rel_idx)).^2/0.16);
    P_sup5 = zeros(size(t5)); P_sup5(ix_dock5) = 25;
    P_mot5 = zeros(size(t5)); P_mot5(ix_asc5) = (net_load5 .* v5(ix_asc5)) / eta_drive5; P_mot5(ix_asc5) = max(P_mot5(ix_asc5), 25);
    P_aux5 = zeros(size(t5)); P_aux5(ix_dock5) = 450; P_aux5(ix_load5) = 380;
    E_gen_5 = trapz(t5, P_main5 + P_mod5 + P_sup5); E_cons_5 = trapz(t5, P_mot5 + P_aux5);
    eta_all(4,r) = min(90, 100*E_gen_5/(E_cons_5+1e-9)); net_all(4,r) = E_gen_5 - E_cons_5;
end

eta_mean = mean(eta_all, 2);
eta_sd = std(eta_all, 0, 2);
net_mean = mean(net_all, 2);
Egen = zeros(4,1);
for s = 1:4
    denom = 1 - 100./eta_all(s,:);
    denom(denom >= -0.01) = -0.01;
    Egen(s) = mean(net_all(s,:) ./ denom);
end

names = {'Dual Weight', 'Buoyancy', 'Electromagnetic', 'Variable Counterweight'};
T_cycle = [T1_d+T2_d; T_lift+T_water+T_drop; T_lift4+T_hold4+T_drop4; T_des5+T_dock5+T_asc5+T_load5];
E_cons = Egen .* (100 ./ eta_mean);
P_mech_avg = E_cons ./ T_cycle;
P_elec_avg = Egen ./ T_cycle;

%% Styling: dark mode, large text (ASCII-only titles)
BG = [0.11 0.11 0.14];
FG = [0.95 0.95 0.98];
GRID = [0.28 0.28 0.32];
C = [0.35 0.68 1; 1 0.5 0.3; 0.4 0.85 0.55; 0.75 0.45 0.95];
fs_title = 22;
fs_label = 16;
fs_legend = 14;
lw = 2.5;
w = 0.35;
% Save figures to project output/ folder
script_dir = fileparts(mfilename('fullpath'));
base_dir = fullfile(script_dir, '..', 'output');
if ~isfolder(base_dir), mkdir(base_dir); end

%% 1. Mechanical vs Electrical Power - All 4 Systems
fig1 = figure('Color', BG, 'Position', [100 100 800 520]);
x = 1:4;
b1 = bar(x - w/2, P_mech_avg, w, 'FaceColor', [0.4 0.6 0.9], 'EdgeColor', GRID, 'LineWidth', 1);
hold on;
b2 = bar(x + w/2, P_elec_avg, w, 'FaceColor', [0.9 0.45 0.2], 'EdgeColor', GRID, 'LineWidth', 1);
ax = gca; set(ax, 'Color', BG, 'XTick', 1:4, 'XTickLabel', names, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Power (W)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Mechanical vs. Electrical Power Output - All 4 Systems', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend([b1 b2], {'Mechanical input (avg)', 'Electrical output (avg)'}, 'FontSize', fs_legend, 'Location', 'northeast');
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25); hold off;
print(fig1, fullfile(base_dir, 'graph1_mechanical_vs_electrical_power.png'), '-dpng', '-r300');
close(fig1);

%% 2. Regeneration vs Consumption - All 4 Systems
fig2 = figure('Color', BG, 'Position', [100 100 800 520]);
b1 = bar(x - w/2, E_cons/1e3, w, 'FaceColor', [0.7 0.35 0.2], 'EdgeColor', GRID, 'LineWidth', 1);
hold on;
b2 = bar(x + w/2, Egen/1e3, w, 'FaceColor', [0.2 0.65 0.45], 'EdgeColor', GRID, 'LineWidth', 1);
ax = gca; set(ax, 'Color', BG, 'XTick', 1:4, 'XTickLabel', names, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Energy per cycle (kJ)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Regeneration vs. Consumption - All 4 Systems', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend([b1 b2], {'Energy consumed', 'Energy regenerated'}, 'FontSize', fs_legend, 'Location', 'northeast');
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25); hold off;
print(fig2, fullfile(base_dir, 'graph2_regeneration_vs_consumption.png'), '-dpng', '-r300');
close(fig2);

%% 3. Regeneration Efficiency - All 4 Systems
fig3 = figure('Color', BG, 'Position', [100 100 800 520]);
b = bar(1:4, eta_mean, 'FaceColor', 'flat', 'EdgeColor', GRID, 'LineWidth', 1.2);
for i = 1:4, b.CData(i,:) = C(i,:); end
hold on;
errorbar(1:4, eta_mean, eta_sd, 'Color', FG, 'LineStyle', 'none', 'LineWidth', 1.5, 'CapSize', 8);
ax = gca; set(ax, 'Color', BG, 'XTick', 1:4, 'XTickLabel', names, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Round-trip efficiency (%)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Regeneration Efficiency - All 4 Systems', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
ylim([0 max(eta_mean + eta_sd)*1.15]);
grid on; set(ax, 'GridAlpha', 0.25); hold off;
print(fig3, fullfile(base_dir, 'graph3_regeneration_efficiency.png'), '-dpng', '-r300');
close(fig3);

%% 4. Cycle Energy Split - All 4 Systems
fig4 = figure('Color', BG, 'Position', [100 100 800 520]);
regen = Egen / 1e3;
losses = (E_cons - Egen) / 1e3;
b = bar(1:4, [regen, losses], 'stacked', 'EdgeColor', GRID, 'LineWidth', 1);
b(1).FaceColor = [0.2 0.65 0.45];
b(2).FaceColor = [0.75 0.35 0.2];
ax = gca; set(ax, 'Color', BG, 'XTick', 1:4, 'XTickLabel', names, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Energy per cycle (kJ)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Cycle Energy Split - Regenerated vs. Losses (All 4 Systems)', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend(b, {'Regenerated (electrical out)', 'Losses (consumed - regenerated)'}, 'FontSize', fs_legend, 'Location', 'northeast');
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25);
print(fig4, fullfile(base_dir, 'graph4_cycle_energy_split.png'), '-dpng', '-r300');
close(fig4);

%% 5. Cost Per Kilowatt-Hour - All 4 Systems
N_cycles_life = 10000;
base_build = 500;
build_factor = [1.0; 1.2; 1.8; 1.4];
kWh_per_life = (Egen .* N_cycles_life) / 3.6e6;
cost_per_kWh = (base_build * build_factor) ./ max(kWh_per_life, 0.01);
fig5 = figure('Color', BG, 'Position', [100 100 800 520]);
b = bar(1:4, cost_per_kWh, 'FaceColor', 'flat', 'EdgeColor', GRID, 'LineWidth', 1.2);
for i = 1:4, b.CData(i,:) = C(i,:); end
ax = gca; set(ax, 'Color', BG, 'XTick', 1:4, 'XTickLabel', names, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
ylabel('Estimated cost ($/kWh)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Cost Per Kilowatt-Hour - All 4 Systems (Estimated, Amortized Over Lifecycle)', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
text(0.5, max(cost_per_kWh)*0.92, 'Assumption: relative build cost and 10,000-cycle life', 'FontSize', 12, 'Color', FG);
grid on; set(ax, 'GridAlpha', 0.25);
print(fig5, fullfile(base_dir, 'graph5_cost_per_kWh.png'), '-dpng', '-r300');
close(fig5);

%% 6. Lifecycle Energy Performance - Cumulative Net Energy
N_cycles = (1:1000)';
cum_net = N_cycles * net_mean';
fig6 = figure('Color', BG, 'Position', [100 100 800 520]);
for i = 1:4
    plot(N_cycles, cum_net(:,i)/1e3, 'Color', C(i,:), 'LineWidth', lw); hold on;
end
ax = gca; set(ax, 'Color', BG, 'FontSize', fs_label, 'XColor', FG, 'YColor', FG);
xlabel('Number of cycles', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
ylabel('Cumulative net energy (kJ)', 'FontSize', fs_label, 'FontWeight', 'bold', 'Color', FG);
title('Lifecycle Energy Performance - Cumulative Net Energy (All 4 Systems)', 'FontSize', fs_title, 'FontWeight', 'bold', 'Color', FG);
lg = legend(names, 'FontSize', fs_legend, 'Location', 'southwest');
set(lg, 'Color', BG, 'TextColor', FG, 'EdgeColor', GRID);
grid on; set(ax, 'GridAlpha', 0.25); hold off;
print(fig6, fullfile(base_dir, 'graph6_lifecycle_energy_performance.png'), '-dpng', '-r300');
close(fig6);

fprintf('Science fair graphs saved to: %s\n', base_dir);
fprintf('  graph1_mechanical_vs_electrical_power.png\n');
fprintf('  graph2_regeneration_vs_consumption.png\n');
fprintf('  graph3_regeneration_efficiency.png\n');
fprintf('  graph4_cycle_energy_split.png\n');
fprintf('  graph5_cost_per_kWh.png\n');
fprintf('  graph6_lifecycle_energy_performance.png\n');

end
