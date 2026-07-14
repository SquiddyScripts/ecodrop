% PLOT_BUOYANCY_GRAVITY_RESULTS  Plausible simulation for Buoyancy Gravity Battery.
%
% Cycle: lift (water fill + motor) -> water transfer (drain + pump) -> drop (generation).
% Run:  plot_buoyancy_gravity_results

function plot_buoyancy_gravity_results()

%% Dark mode colors
BG   = [0.11 0.11 0.14];
FG   = [0.92 0.92 0.95];
GRID = [0.28 0.28 0.32];
C1   = [0.35 0.68 1.00];   % blue - water / reservoir
C2   = [1.00 0.50 0.30];   % orange - buoyant weight
C3   = [0.40 0.85 0.55];   % green - generation
C4   = [0.75 0.45 0.95];   % purple - consumption (motor, pump)
C5   = [0.95 0.75 0.25];   % gold
C6   = [0.30 0.75 0.78];   % teal
CGRAY = [0.50 0.50 0.55];

%% Cycle phases
% Phase 1: Lift — top tank fills, water enters chamber, buoyancy + motor raises weight (0 -> H_max)
% Phase 2: Water management — drain to bottom tank, pump from bottom to top (weight at top)
% Phase 3: Drop — weight falls, drives generator (H_max -> 0)
T_lift   = 25;   % s — lift duration
T_water  = 18;   % s — drain + pump
T_drop   = 3.2;  % s — drop duration
T_tot    = T_lift + T_water + T_drop;
N        = 500;
t        = linspace(0, T_tot, N);
H_max    = 3;    % m — tower height / drop height
g        = 9.81;

% Buoyant weight [kg] — same as analysis comparison (m_common = 50)
m_weight = 50;
% Effective "lift" from buoyancy (reduces load on motor during fill)
buoyancy_fraction = 0.55;  % fraction of weight offset by buoyancy when chamber full

%% Phase 1: Lift (0 to T_lift)
ix_lift = t <= T_lift;
t_lift  = t(ix_lift);
tau_l   = t_lift / T_lift;
% Chamber fill (water level / fill fraction) — drives buoyancy
fill_chamber = 1 - exp(-3 * tau_l);  % smooth fill
fill_chamber = min(fill_chamber, 1);
% Weight height: 0 -> H_max (motor + buoyancy)
h_weight = zeros(size(t));
h_weight(ix_lift) = H_max * (1 - (1 - tau_l).^1.1);
% Velocity (lift): peak mid-stroke
v_weight = zeros(size(t));
v_lift_max = 0.65;
v_weight(ix_lift) = v_lift_max * 4 * tau_l .* (1 - tau_l);
% Top reservoir level (draining into chamber during lift)
level_top = zeros(size(t));
level_top(ix_lift) = 1 - 0.85 * tau_l;  % depletes as water goes to chamber
% Motor power (consumed) — less when buoyancy assists
P_motor = zeros(size(t));
P_lift_base = m_weight * g * v_lift_max * 0.6;  % baseline power
P_motor(ix_lift) = P_lift_base * (1 - buoyancy_fraction * fill_chamber) .* (4 * tau_l .* (1 - tau_l) + 0.2);
P_motor(ix_lift) = max(P_motor(ix_lift), 50);

%% Phase 2: Water management (T_lift to T_lift + T_water)
ix_water = t > T_lift & t <= T_lift + T_water;
t_water  = t(ix_water) - T_lift;
tau_w    = t_water / T_water;
% Weight stays at top
h_weight(ix_water) = H_max;
v_weight(ix_water) = 0;
% Chamber drains (water to bottom tank)
tau_w = min(max(tau_w, 0), 1);
fill_chamber(ix_water) = 1 - 0.95 * (1 - (1 - tau_w).^0.9);
fill_chamber(ix_water) = max(real(fill_chamber(ix_water)), 0.05);
% Top reservoir: refill by pump (second half of phase)
level_top(ix_water) = 0.15 + 0.8 * (tau_w).^1.2;
level_top(ix_water) = min(real(level_top(ix_water)), 1);
% Pump power (consumed) — runs in second half of water phase
P_pump = zeros(size(t));
pump_frac = 0.6;
t_water_vec = t(ix_water) - T_lift;
tau_w_vec = t_water_vec / T_water;
pump_on = tau_w_vec >= (1 - pump_frac);
arg = (tau_w_vec - (1 - pump_frac)) / pump_frac;
arg = max(0, min(1, real(arg)));
P_pump(ix_water) = pump_on .* (200 + 150 * sin(pi * arg));
P_pump(ix_water) = max(0, real(P_pump(ix_water)));

%% Phase 3: Drop (T_lift + T_water to end)
ix_drop = t > T_lift + T_water;
t_drop  = t(ix_drop) - (T_lift + T_water);
tau_d   = t_drop / T_drop;
% Weight height: H_max -> 0
tau_d = min(max(tau_d, 0), 1);
h_weight(ix_drop) = H_max * (1 - tau_d.^1.25);
h_weight(ix_drop) = max(real(h_weight(ix_drop)), 0);
% Velocity (drop): increases then constant-ish (turbine/generator load)
v_drop_max = 4.2;
v_weight(ix_drop) = -v_drop_max * (1 - (1 - tau_d).^0.7);
v_weight(ix_drop) = real(v_weight(ix_drop));
% Chamber empty; top reservoir full (for next cycle)
fill_chamber(ix_drop) = 0.02;
level_top(ix_drop) = 0.98;
P_pump(ix_drop) = 0;
% Generator power (electrical output)
eta_gen = 0.74;
P_mech_drop = m_weight * g * (-v_weight(ix_drop));
P_gen = zeros(size(t));
P_gen(ix_drop) = eta_gen * P_mech_drop;
P_gen(ix_drop) = max(P_gen(ix_drop), 0);

%% Combined electrical: consumption (motor + pump) vs generation
P_cons = P_motor + P_pump;
E_cons_cum = cumtrapz(t, P_cons);
E_gen_cum  = cumtrapz(t, P_gen);
E_net_cum  = E_gen_cum - E_cons_cum;

%% Round-trip efficiency (generated / consumed over cycle)
E_cons_end = E_cons_cum(end);
E_gen_end  = E_gen_cum(end);
round_trip_eff = 100 * E_gen_end / (E_cons_end + 1e-9);

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
fig1 = figure('Name', 'Buoyancy Gravity Battery — Time-Series', 'Position', [80, 60, 1280, 840], 'Color', BG);

subplot(3, 3, 1);
plot(t, h_weight, '-', 'Color', C2, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Height [m]', 'Color', FG);
title('Buoyant weight height', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 2);
plot(t, v_weight, '-', 'Color', C2, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Velocity [m/s]', 'Color', FG);
title('Weight velocity (+ up, - down)', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 3);
yyaxis left;
plot(t, fill_chamber * 100, '-', 'Color', C1, 'LineWidth', 2);
set(gca, 'YColor', C1);
ylabel('Chamber fill [%]', 'Color', FG);
yyaxis right;
plot(t, level_top * 100, '-', 'Color', C6, 'LineWidth', 2);
set(gca, 'YColor', C6);
ylabel('Top reservoir [%]', 'Color', FG);
set(gca, 'Color', BG, 'XColor', FG);
xlabel('Time [s]', 'Color', FG);
title('Water levels (chamber and reservoir)', 'Color', FG);
legend('Chamber', 'Reservoir', 'Location', 'best', 'TextColor', FG);
grid on; grid minor;

subplot(3, 3, 4);
plot(t, P_motor, '-', 'Color', C4, 'LineWidth', 2);
hold on;
plot(t, P_pump, '-', 'Color', C5, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Power [W]', 'Color', FG);
title('Motor and pump (consumption)', 'Color', FG);
legend('Hoist motor', 'Pump', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 5);
plot(t, P_gen, '-', 'Color', C3, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Power [W]', 'Color', FG);
title('Generator output (drop phase)', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 6);
area(t(ix_lift), P_motor(ix_lift), 'FaceColor', C4, 'FaceAlpha', 0.5);
hold on;
area(t(ix_water), P_pump(ix_water), 'FaceColor', C5, 'FaceAlpha', 0.5);
area(t(ix_drop), P_gen(ix_drop), 'FaceColor', C3, 'FaceAlpha', 0.6);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Power [W]', 'Color', FG);
title('Charge vs discharge power', 'Color', FG);
legend('Motor', 'Pump', 'Generator', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 7);
plot(t, E_cons_cum, '-', 'Color', C4, 'LineWidth', 2);
hold on;
plot(t, E_gen_cum, '-', 'Color', C3, 'LineWidth', 2.5);
plot(t, E_net_cum, '-', 'Color', C5, 'LineWidth', 1.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Energy [J]', 'Color', FG);
title('Cumulative energy', 'Color', FG);
legend('Consumed', 'Generated', 'Net', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 8);
pie_vals = [real(E_cons_end), real(E_gen_end)];
pie_vals = max(abs(pie_vals), 0.1);
pie(double(pie_vals), {'Consumed (lift + pump)', 'Generated (drop)'});
colormap(gca, [C4; C3]);
title('Cycle energy split', 'Color', FG);

subplot(3, 3, 9);
plot(h_weight, v_weight, '-', 'Color', C2, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Height [m]', 'Color', FG); ylabel('Velocity [m/s]', 'Color', FG);
title('Weight phase portrait', 'Color', FG);
grid on; grid minor;

sgtitle(fig1, 'Buoyancy Gravity Battery — Time-Series', 'Color', FG, 'FontSize', 16, 'FontWeight', 'bold');

%% ----- Figure 2: Energy and water -----
fig2 = figure('Name', 'Buoyancy Gravity Battery — Energy Analysis', 'Position', [120, 100, 1000, 520], 'Color', BG);

subplot(2, 2, 1);
b = bar([E_cons_end, E_gen_end, E_net_cum(end)], 'FaceColor', 'flat');
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
title('Round-trip efficiency (generated / consumed)', 'Color', FG);
ylim([0 100]);
grid on; grid minor;

subplot(2, 2, 4);
plot(h_weight, fill_chamber * 100, '-', 'Color', C1, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Weight height [m]', 'Color', FG); ylabel('Chamber fill [%]', 'Color', FG);
title('Chamber fill vs weight position', 'Color', FG);
grid on; grid minor;

sgtitle(fig2, 'Buoyancy Gravity Battery — Energy Analysis', 'Color', FG, 'FontSize', 16, 'FontWeight', 'bold');

%% ----- Summary table -----
row_names = {
    'Buoyant weight mass'
    'Drop height (tower)'
    'Lift duration'
    'Water / pump phase'
    'Drop duration'
    'Energy consumed (motor + pump)'
    'Energy generated (drop)'
    'Net energy (cycle)'
    'Peak motor power'
    'Peak pump power'
    'Peak generator power'
    'Round-trip efficiency'
};
row_vals = {
    sprintf('%.0f', m_weight)
    sprintf('%.1f', H_max)
    sprintf('%.1f', T_lift)
    sprintf('%.1f', T_water)
    sprintf('%.2f', T_drop)
    sprintf('%.1f', E_cons_end)
    sprintf('%.1f', E_gen_end)
    sprintf('%.1f', E_net_cum(end))
    sprintf('%.0f', max(P_motor))
    sprintf('%.0f', max(P_pump))
    sprintf('%.0f', max(P_gen))
    sprintf('%.1f', round_trip_eff)
};
row_units = {'kg'; 'm'; 's'; 's'; 's'; 'J'; 'J'; 'J'; 'W'; 'W'; 'W'; '%'};

fig3 = figure('Name', 'Buoyancy Gravity Battery — Summary', 'Position', [200, 120, 640, 540], 'Color', BG);
uit = uitable(fig3, 'Data', [row_names, row_vals, row_units], ...
    'ColumnName', {'Quantity', 'Value', 'Unit'}, ...
    'ColumnWidth', {280, 120, 60}, 'FontSize', 10, 'FontName', 'Segoe UI');
uit.Position = [20, 50, 600, 450];
uit.BackgroundColor = repmat([BG; 0.16 0.16 0.20], 6, 1);
uit.ForegroundColor = FG;
annotation('textbox', [0.1 0.92 0.8 0.06], 'String', 'Buoyancy Gravity Battery — Summary', ...
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
