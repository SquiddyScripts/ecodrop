% PLOT_VARIABLE_COUNTERWEIGHT_RESULTS  Plausible simulation for Variable Counterweight Regeneration System.
%
% Cabled mass + stackable magnetic barbell modules; main generators + module generators; supercap storage.
% Cycle: descent (main gen + module gen) -> dock/discharge -> ascent (motor, reduced load) -> add modules.
% Run:  plot_variable_counterweight_results

function plot_variable_counterweight_results()

%% Dark mode colors
BG   = [0.11 0.11 0.14];
FG   = [0.92 0.92 0.95];
GRID = [0.28 0.28 0.32];
C1   = [0.35 0.68 1.00];   % blue - cabled mass / main
C2   = [1.00 0.50 0.30];   % orange - modules
C3   = [0.40 0.85 0.55];   % green - generation
C4   = [0.75 0.45 0.95];   % purple - consumption
C5   = [0.95 0.75 0.25];   % gold - supercap / grid
C6   = [0.30 0.75 0.78];   % teal
CGRAY = [0.50 0.50 0.55];

%% Parameters
H_max = 3;      % m — travel height (same as analysis comparison)
g     = 9.81;
m_cabled = 50;  % kg — cabled barbell mass (same as analysis m_common)
m_module = 10;  % kg — one magnetic barbell module

% Cycle: descent -> dock -> ascent -> load modules
T_descent = 2.5;
T_dock   = 1.5;
T_ascent = 2.8;
T_load   = 1.2;
T_tot    = T_descent + T_dock + T_ascent + T_load;
N        = 450;
t        = linspace(0, T_tot, N);

%% Phase indices
ix_descent = t <= T_descent;
ix_dock    = t > T_descent & t <= T_descent + T_dock;
ix_ascent  = t > T_descent + T_dock & t <= T_descent + T_dock + T_ascent;
ix_load    = t > T_descent + T_dock + T_ascent;

%% Number of modules attached to cabled mass (variable counterweight effect)
n_modules = zeros(size(t));
t_d = t(ix_descent);
tau_d = t_d / T_descent;
% Start with 2 modules; release 1 at ~60% of descent (mass release mechanism)
n_modules(ix_descent) = 2;
n_modules(ix_descent) = 2 - (tau_d >= 0.6);  % step: 2 then 1
% At bottom: 1 module (other docked for discharge)
n_modules(ix_dock) = 1;
% Ascent with 1 module (lighter = less motor load)
n_modules(ix_ascent) = 1;
% At top: load 2 modules again (rotary charging station)
t_l = t(ix_load) - (T_descent + T_dock + T_ascent);
n_modules(ix_load) = 1 + (t_l >= T_load * 0.4);  % 1 then 2

%% Total mass [kg]
m_total = m_cabled + n_modules * m_module;

%% Height and velocity
h = zeros(size(t));
v = zeros(size(t));

% Descent (0 -> H_max to 0)
t1 = t(ix_descent);
tau1 = t1 / T_descent;
h(ix_descent) = H_max * (1 - tau1.^1.15);
h(ix_descent) = max(h(ix_descent), 0);
v_dn_max = 1.4;
v(ix_descent) = -v_dn_max * 4 * tau1 .* (1 - tau1);

% Dock: at bottom
h(ix_dock) = 0;
v(ix_dock) = 0;

% Ascent (0 -> H_max)
t2 = t(ix_ascent) - (T_descent + T_dock);
tau2 = t2 / T_ascent;
h(ix_ascent) = H_max * tau2.^1.1;
v_up_max = 1.2;
v(ix_ascent) = v_up_max * 4 * tau2 .* (1 - tau2);

% Load: at top
h(ix_load) = H_max;
v(ix_load) = 0;

%% Main generator (cabled mass descent) — two generators on cabled mass
eta_main_gen = 0.74;
P_main_gen = zeros(size(t));
P_mech_main = m_total(ix_descent) .* g .* (-v(ix_descent));
P_main_gen(ix_descent) = eta_main_gen * max(P_mech_main, 0);

%% Module generators (when modules move/fall along guide rails)
P_module_gen = zeros(size(t));
% Spike when module released during descent (~60% of descent)
release_idx = find(ix_descent & (n_modules == 1), 1);
if ~isempty(release_idx)
    idx_range = max(1, release_idx-15) : min(N, release_idx+25);
    t_rel = t(idx_range) - t(release_idx);
    P_module_gen(idx_range) = 80 * exp(-t_rel.^2 / 0.4.^2);  % short burst
end
P_module_gen = real(P_module_gen);

%% Main motor (ascent) — load reduced by variable counterweight (closer to balance)
% Ideal counterweight = cabled + 1 module; we ascend with 1 module so net load is small
m_ideal_cw = m_cabled + 1 * m_module;
net_load = max(0, m_total(ix_ascent) * g - m_ideal_cw * g * 0.95);  % slight imbalance
P_motor_mech = zeros(size(t));
P_motor_mech(ix_ascent) = net_load .* v(ix_ascent);
eta_drive = 0.86;
P_motor = zeros(size(t));
P_motor(ix_ascent) = P_motor_mech(ix_ascent) / eta_drive;
P_motor(ix_ascent) = max(P_motor(ix_ascent), 20);

%% Supercapacitor discharge (when modules docked at storage checkpoint)
P_supercap = zeros(size(t));
P_supercap(ix_dock) = 25 + 15 * sin(2*pi*(t(ix_dock) - T_descent) / T_dock);  % regulated discharge to grid
P_supercap(ix_dock) = max(P_supercap(ix_dock), 10);

%% Combined energy
P_cons = P_motor;
P_gen_total = P_main_gen + P_module_gen + P_supercap;
E_cons_cum = cumtrapz(t, P_cons);
E_gen_cum  = cumtrapz(t, P_gen_total);
E_net_cum  = E_gen_cum - E_cons_cum;
round_trip_eff = 100 * E_gen_cum(end) / (E_cons_cum(end) + 1e-9);

%% Apply dark theme
set(0, 'DefaultFigureColor', BG);
set(0, 'DefaultAxesColor', BG);
set(0, 'DefaultAxesXColor', FG);
set(0, 'DefaultAxesYColor', FG);
set(0, 'DefaultAxesZColor', FG);
set(0, 'DefaultTextColor', FG);
set(0, 'DefaultAxesFontSize', 11);
set(0, 'DefaultAxesFontName', 'Segoe UI');
set(0, 'DefaultAxesGridColor', GRID);
set(0, 'DefaultAxesMinorGridColor', GRID);

%% ----- Figure 1: Time-Series -----
fig1 = figure('Name', 'Variable Counterweight — Time-Series', 'Position', [80, 60, 1280, 840], 'Color', BG);

subplot(3, 3, 1);
plot(t, h, '-', 'Color', C1, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Height [m]', 'Color', FG);
title('Cabled mass position', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 2);
plot(t, v, '-', 'Color', C1, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Velocity [m/s]', 'Color', FG);
title('Cabled mass velocity', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 3);
stairs(t, n_modules, 'Color', C2, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Modules attached', 'Color', FG);
title('Variable mass (modules on cabled mass)', 'Color', FG);
ylim([0 3]);
grid on; grid minor;

subplot(3, 3, 4);
plot(t, m_total, '-', 'Color', C2, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Total mass [kg]', 'Color', FG);
title('Total moving mass', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 5);
plot(t, P_main_gen, '-', 'Color', C3, 'LineWidth', 2);
hold on;
plot(t, P_module_gen, '-', 'Color', C6, 'LineWidth', 1.5);
plot(t, P_supercap, '-', 'Color', C5, 'LineWidth', 1.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Power [W]', 'Color', FG);
title('Generation: main, module, supercap', 'Color', FG);
legend('Main gen', 'Module gen', 'Supercap to grid', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 6);
plot(t, P_motor, '-', 'Color', C4, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Power [W]', 'Color', FG);
title('Main motor (ascent)', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 7);
area(t(ix_descent), P_main_gen(ix_descent), 'FaceColor', C3, 'FaceAlpha', 0.5);
hold on;
area(t(ix_descent), P_module_gen(ix_descent), 'FaceColor', C6, 'FaceAlpha', 0.5);
area(t(ix_dock), P_supercap(ix_dock), 'FaceColor', C5, 'FaceAlpha', 0.5);
area(t(ix_ascent), P_motor(ix_ascent), 'FaceColor', C4, 'FaceAlpha', 0.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Power [W]', 'Color', FG);
title('Charge vs discharge power', 'Color', FG);
legend('Main gen', 'Module gen', 'Supercap', 'Motor', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 8);
plot(t, E_cons_cum, '-', 'Color', C4, 'LineWidth', 2);
hold on;
plot(t, E_gen_cum, '-', 'Color', C3, 'LineWidth', 2.5);
plot(t, E_net_cum, '-', 'Color', C5, 'LineWidth', 1.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Energy [J]', 'Color', FG);
title('Cumulative energy', 'Color', FG);
legend('Consumed', 'Generated', 'Net', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 9);
pie_vals = [real(E_cons_cum(end)), real(E_gen_cum(end))];
pie_vals = max(abs(pie_vals), 0.1);
pie(double(pie_vals), {'Consumed (motor)', 'Generated (main+module+supercap)'});
colormap(gca, [C4; C3]);
title('Cycle energy split', 'Color', FG);

sgtitle(fig1, 'Variable Counterweight Regeneration System — Time-Series', 'Color', FG, 'FontSize', 16, 'FontWeight', 'bold');

%% ----- Figure 2: Energy and mass -----
fig2 = figure('Name', 'Variable Counterweight — Energy Analysis', 'Position', [120, 100, 1000, 520], 'Color', BG);

subplot(2, 2, 1);
b = bar([E_cons_cum(end), E_gen_cum(end), E_net_cum(end)], 'FaceColor', 'flat');
b.CData = [C4; C3; C5];
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
set(gca, 'XTickLabel', {'Consumed', 'Generated', 'Net'});
ylabel('Energy [J]', 'Color', FG);
title('One-cycle energy balance', 'Color', FG);
grid on; grid minor;

subplot(2, 2, 2);
plot(t, E_net_cum, '-', 'Color', C5, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Net energy [J]', 'Color', FG);
title('Net cumulative energy', 'Color', FG);
grid on; grid minor;

subplot(2, 2, 3);
bar(1, round_trip_eff, 'FaceColor', C3);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
set(gca, 'XTick', 1, 'XTickLabel', 'Round-trip');
ylabel('Efficiency [%]', 'Color', FG);
title('Round-trip efficiency', 'Color', FG);
ylim([0 100]);
grid on; grid minor;

subplot(2, 2, 4);
plot(h, m_total, '-', 'Color', C2, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Height [m]', 'Color', FG); ylabel('Total mass [kg]', 'Color', FG);
title('Mass vs position (variable counterweight)', 'Color', FG);
grid on; grid minor;

sgtitle(fig2, 'Variable Counterweight Regeneration System — Energy Analysis', 'Color', FG, 'FontSize', 16, 'FontWeight', 'bold');

%% ----- Summary table -----
row_names = {
    'Cabled mass'
    'Mass per module'
    'Travel height'
    'Descent / ascent / dock / load times'
    'Energy consumed (motor)'
    'Energy generated (main gen)'
    'Energy from module gen'
    'Energy from supercap to grid'
    'Net energy (cycle)'
    'Peak main gen power'
    'Peak module gen power'
    'Round-trip efficiency'
};
E_main = trapz(t, P_main_gen);
E_mod  = trapz(t, P_module_gen);
E_sc   = trapz(t, P_supercap);
row_vals = {
    sprintf('%.0f', m_cabled)
    sprintf('%.0f', m_module)
    sprintf('%.1f', H_max)
    sprintf('%.1f / %.1f / %.1f / %.1f', T_descent, T_ascent, T_dock, T_load)
    sprintf('%.1f', E_cons_cum(end))
    sprintf('%.1f', E_main)
    sprintf('%.1f', E_mod)
    sprintf('%.1f', E_sc)
    sprintf('%.1f', E_net_cum(end))
    sprintf('%.0f', max(P_main_gen))
    sprintf('%.0f', max(P_module_gen))
    sprintf('%.1f', round_trip_eff)
};
row_units = {'kg'; 'kg'; 'm'; 's'; 'J'; 'J'; 'J'; 'J'; 'J'; 'W'; 'W'; '%'};

fig3 = figure('Name', 'Variable Counterweight — Summary', 'Position', [200, 120, 640, 560], 'Color', BG);
uit = uitable(fig3, 'Data', [row_names, row_vals, row_units], ...
    'ColumnName', {'Quantity', 'Value', 'Unit'}, ...
    'ColumnWidth', {300, 140, 50}, 'FontSize', 10, 'FontName', 'Segoe UI');
uit.Position = [20, 50, 600, 460];
uit.BackgroundColor = repmat([BG; 0.16 0.16 0.20], 6, 1);
uit.ForegroundColor = FG;
annotation('textbox', [0.08 0.92 0.84 0.06], 'String', 'Variable Counterweight Regeneration System — Summary', ...
    'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', FG);

%% Reset defaults
set(0, 'DefaultFigureColor', 'remove');
set(0, 'DefaultAxesColor', 'remove');
set(0, 'DefaultAxesXColor', 'remove');
set(0, 'DefaultAxesYColor', 'remove');
set(0, 'DefaultAxesZColor', 'remove');
set(0, 'DefaultTextColor', 'remove');
set(0, 'DefaultAxesGridColor', 'remove');
set(0, 'DefaultAxesMinorGridColor', 'remove');

end
