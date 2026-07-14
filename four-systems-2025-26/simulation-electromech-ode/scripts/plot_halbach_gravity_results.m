% PLOT_HALBACH_GRAVITY_RESULTS  Plausible simulation for Electromagnetic (Halbach) Gravitational Energy Storage.
%
% System: 4 tubular linear motors (6-phase, Halbach array) lift weight; hoist drum maintains rope tension.
% Cycle: lift (thrust + tension) -> brief hold -> drop (regeneration).
% Run:  plot_halbach_gravity_results

function plot_halbach_gravity_results()

%% Dark mode colors
BG   = [0.11 0.11 0.14];
FG   = [0.92 0.92 0.95];
GRID = [0.28 0.28 0.32];
C1   = [0.35 0.68 1.00];   % blue
C2   = [1.00 0.50 0.30];   % orange - weight / thrust
C3   = [0.40 0.85 0.55];   % green - generation
C4   = [0.75 0.45 0.95];   % purple - consumption
C5   = [0.95 0.75 0.25];   % gold
C6   = [0.30 0.75 0.78];   % teal
CGRAY = [0.50 0.50 0.55];

%% System parameters
% 4 tubular linear motors (Halbach array) provide thrust; hoist motor maintains rope tension
m_weight = 50;    % kg — lifted mass (same as analysis m_common)
H_max    = 3;     % m — lift height (same as analysis comparison)
g        = 9.81;
T_lift   = 6.5;   % s — lift duration (thrust phase)
T_hold   = 1.0;   % s — brief hold at top
T_drop   = 2.2;   % s — drop (regeneration)
T_tot    = T_lift + T_hold + T_drop;
N        = 400;
t        = linspace(0, T_tot, N);

%% Phase 1: Lift (0 to T_lift) — linear motors thrust, hoist maintains tension
ix_lift = t <= T_lift;
t_lift  = t(ix_lift);
tau_l   = t_lift / T_lift;
% Height: 0 -> H_max (smooth, constant thrust feel)
h_weight = zeros(size(t));
h_weight(ix_lift) = H_max * (1 - (1 - tau_l).^1.05);
% Velocity: ramp up, then steady, then ramp down (typical linear motor profile)
v_lift_max = 1.5;
v_weight = zeros(size(t));
v_weight(ix_lift) = v_lift_max * sin(pi * tau_l);  % smooth start and stop
% Thrust force (4 motors): overcome gravity + accelerate; steady mid-stroke
F_gravity = m_weight * g;
thrust = zeros(size(t));
thrust(ix_lift) = F_gravity * (1.15 + 0.25 * sin(2*pi*tau_l));  % slight variation with position (flux)
thrust(ix_lift) = max(thrust(ix_lift), F_gravity * 1.05);
% Power: linear motors (thrust * velocity) + hoist (tension maintenance, ~constant)
P_linear = zeros(size(t));
P_linear(ix_lift) = thrust(ix_lift) .* v_weight(ix_lift);
eta_lift = 0.82;  % motor efficiency
P_linear_elec = zeros(size(t));
P_linear_elec(ix_lift) = P_linear(ix_lift) / eta_lift;
% Hoist drum: maintains tension (high stall torque, low speed) — small constant draw
P_hoist = zeros(size(t));
P_hoist(ix_lift) = 45;  % W — tension only
% 6-phase "effective current" proxy (sinusoidal, phase-shifted feel — one phase shown)
phase_angle = 2*pi * 3 * tau_l;  % multiple periods over stroke
I_phase1 = zeros(size(t));
I_phase1(ix_lift) = 12 + 8 * sin(phase_angle) .* (0.7 + 0.3*sin(pi*tau_l));

%% Phase 2: Hold (T_lift to T_lift + T_hold)
ix_hold = t > T_lift & t <= T_lift + T_hold;
h_weight(ix_hold) = H_max;
v_weight(ix_hold) = 0;
thrust(ix_hold) = 0;
P_linear(ix_hold) = 0;
P_linear_elec(ix_hold) = 0;
P_hoist(ix_hold) = 40;  % still holding tension
I_phase1(ix_hold) = 5;

%% Phase 3: Drop (T_lift + T_hold to end) — weight descends, regeneration
ix_drop = t > T_lift + T_hold;
t_drop  = t(ix_drop) - (T_lift + T_hold);
tau_d   = t_drop / T_drop;
tau_d   = min(max(tau_d, 0), 1);
% Height: H_max -> 0
h_weight(ix_drop) = H_max * (1 - tau_d.^1.2);
h_weight(ix_drop) = max(real(h_weight(ix_drop)), 0);
% Velocity: increase then plateau (generator loading)
v_drop_max = 4.0;
v_weight(ix_drop) = -v_drop_max * (1 - (1 - tau_d).^0.65);
v_weight(ix_drop) = real(v_weight(ix_drop));
% Regeneration: linear motors as generators or separate generator
eta_gen = 0.78;
P_mech_drop = m_weight * g * (-v_weight(ix_drop));
P_gen = zeros(size(t));
P_gen(ix_drop) = eta_gen * P_mech_drop;
P_gen(ix_drop) = max(P_gen(ix_drop), 0);
P_hoist(ix_drop) = 0;
thrust(ix_drop) = 0;
I_phase1(ix_drop) = -8 * (1 - (1 - tau_d).^0.7);  % regenerative current (negative convention)

%% Combined electrical
P_cons = P_linear_elec + P_hoist;
E_cons_cum = cumtrapz(t, P_cons);
E_gen_cum  = cumtrapz(t, P_gen);
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
fig1 = figure('Name', 'Halbach Gravity Storage — Time-Series', 'Position', [80, 60, 1280, 840], 'Color', BG);

subplot(3, 3, 1);
plot(t, h_weight, '-', 'Color', C2, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Height [m]', 'Color', FG);
title('Weight position (linear travel)', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 2);
plot(t, v_weight, '-', 'Color', C2, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Velocity [m/s]', 'Color', FG);
title('Weight velocity (+ up, - down)', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 3);
plot(t, thrust, '-', 'Color', C5, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Thrust [N]', 'Color', FG);
title('Linear motor thrust (4 motors combined)', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 4);
plot(t, P_linear_elec, '-', 'Color', C4, 'LineWidth', 2);
hold on;
plot(t, P_hoist, '-', 'Color', C6, 'LineWidth', 1.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Power [W]', 'Color', FG);
title('Consumption: linear motors and hoist', 'Color', FG);
legend('Linear motors', 'Hoist (tension)', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 5);
plot(t, P_gen, '-', 'Color', C3, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Power [W]', 'Color', FG);
title('Regeneration (drop phase)', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 6);
plot(t, I_phase1, '-', 'Color', C1, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Current [A]', 'Color', FG);
title('Phase current (6-phase, one phase shown)', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 7);
area(t(ix_lift), P_linear_elec(ix_lift), 'FaceColor', C4, 'FaceAlpha', 0.5);
hold on;
area(t(ix_lift), P_hoist(ix_lift), 'FaceColor', C6, 'FaceAlpha', 0.5);
area(t(ix_drop), P_gen(ix_drop), 'FaceColor', C3, 'FaceAlpha', 0.6);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Power [W]', 'Color', FG);
title('Charge vs discharge power', 'Color', FG);
legend('Linear motors', 'Hoist', 'Regeneration', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 8);
pie_vals = [real(E_cons_cum(end)), real(E_gen_cum(end))];
pie_vals = max(abs(pie_vals), 0.1);
pie(double(pie_vals), {'Consumed (lift + hoist)', 'Generated (drop)'});
colormap(gca, [C4; C3]);
title('Cycle energy split', 'Color', FG);

subplot(3, 3, 9);
plot(h_weight, v_weight, '-', 'Color', C2, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Position [m]', 'Color', FG); ylabel('Velocity [m/s]', 'Color', FG);
title('Phase portrait (position vs velocity)', 'Color', FG);
grid on; grid minor;

sgtitle(fig1, 'Electromagnetic (Halbach) Gravitational Energy Storage — Time-Series', 'Color', FG, 'FontSize', 16, 'FontWeight', 'bold');

%% ----- Figure 2: Energy and thrust -----
fig2 = figure('Name', 'Halbach Gravity Storage — Energy Analysis', 'Position', [120, 100, 1000, 520], 'Color', BG);

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
plot(h_weight(ix_lift), thrust(ix_lift), '-', 'Color', C5, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Position [m]', 'Color', FG); ylabel('Thrust [N]', 'Color', FG);
title('Thrust vs position (lift phase)', 'Color', FG);
grid on; grid minor;

sgtitle(fig2, 'Electromagnetic (Halbach) Gravitational Energy Storage — Energy Analysis', 'Color', FG, 'FontSize', 16, 'FontWeight', 'bold');

%% ----- Summary table -----
row_names = {
    'Weight mass'
    'Lift height (travel)'
    'Lift duration'
    'Hold duration'
    'Drop duration'
    'Energy consumed (motors + hoist)'
    'Energy generated (drop)'
    'Net energy (cycle)'
    'Peak linear motor power'
    'Hoist power (tension)'
    'Peak regeneration power'
    'Round-trip efficiency'
};
row_vals = {
    sprintf('%.0f', m_weight)
    sprintf('%.1f', H_max)
    sprintf('%.2f', T_lift)
    sprintf('%.2f', T_hold)
    sprintf('%.2f', T_drop)
    sprintf('%.1f', E_cons_cum(end))
    sprintf('%.1f', E_gen_cum(end))
    sprintf('%.1f', E_net_cum(end))
    sprintf('%.0f', max(P_linear_elec))
    sprintf('%.0f', max(P_hoist))
    sprintf('%.0f', max(P_gen))
    sprintf('%.1f', round_trip_eff)
};
row_units = {'kg'; 'm'; 's'; 's'; 's'; 'J'; 'J'; 'J'; 'W'; 'W'; 'W'; '%'};

fig3 = figure('Name', 'Halbach Gravity Storage — Summary', 'Position', [200, 120, 640, 540], 'Color', BG);
uit = uitable(fig3, 'Data', [row_names, row_vals, row_units], ...
    'ColumnName', {'Quantity', 'Value', 'Unit'}, ...
    'ColumnWidth', {280, 120, 60}, 'FontSize', 10, 'FontName', 'Segoe UI');
uit.Position = [20, 50, 600, 450];
uit.BackgroundColor = repmat([BG; 0.16 0.16 0.20], 6, 1);
uit.ForegroundColor = FG;
annotation('textbox', [0.1 0.92 0.8 0.06], 'String', 'Electromagnetic (Halbach) Gravitational Energy Storage — Summary', ...
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
