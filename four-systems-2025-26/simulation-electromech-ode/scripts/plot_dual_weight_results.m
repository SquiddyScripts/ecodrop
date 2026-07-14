% PLOT_DUAL_WEIGHT_RESULTS  Plausible simulation plots for dual-weight regeneration system.
%
% Elevator-style: cab + counterweight, two hoist drums, regeneration on descent.
% Run:  plot_dual_weight_results

function plot_dual_weight_results()

%% Dark mode colors
BG   = [0.11 0.11 0.14];
FG   = [0.92 0.92 0.95];
GRID = [0.28 0.28 0.32];
C1   = [0.35 0.68 1.00];   % blue - cab
C2   = [1.00 0.50 0.30];   % orange - counterweight
C3   = [0.40 0.85 0.55];   % green - generation
C4   = [0.75 0.45 0.95];   % purple - consumption / losses
C5   = [0.95 0.75 0.25];   % gold
C6   = [0.30 0.75 0.78];   % teal
CGRAY = [0.50 0.50 0.55];

%% Scenario: one full cycle (descent then ascent)
% Phase 1: Cab descends 3 m, counterweight rises (regeneration)
% Phase 2: Cab ascends 3 m, counterweight descends (motor consumption)
T1 = 2.8;   % descent duration [s]
T2 = 3.2;   % ascent duration [s]
T_tot = T1 + T2;
N = 400;
t = linspace(0, T_tot, N);
h0 = 3;     % travel height [m] (same as analysis comparison)
g = 9.81;

% Cab and counterweight masses [kg] — net imbalance = 50 kg (same as analysis m_common)
m_net = 50;    % effective storage mass (cab - counterweight)
m_cw  = 200;   % counterweight
m_cab = m_cw + m_net;   % cab + load (250 kg so net = 50)

% --- Phase 1: Cab down, CW up (ropes opposite: cab unwinds, CW winds) ---
ix1 = t <= T1;
t1 = t(ix1);
% Cab height: h0 -> 0
h_cab = zeros(size(t));
h_cab(ix1) = h0 * (1 - (t1 / T1).^1.2);
% Counterweight height: 0 -> h0 (opposite)
h_cw = zeros(size(t));
h_cw(ix1) = h0 * (t1 / T1).^1.2;

% Velocities (magnitude peaks mid-stroke, smooth)
v_max_dn = 1.35;  % m/s typical elevator
v_cab = zeros(size(t));
tau1 = t1 / T1;
v_cab(ix1) = -v_max_dn * 4 * tau1 .* (1 - tau1);  % negative = down

v_cw = zeros(size(t));
v_cw(ix1) = v_max_dn * 4 * tau1 .* (1 - tau1);   % positive = up

% --- Phase 2: Cab up, CW down ---
ix2 = t > T1;
t2 = t(ix2) - T1;
h_cab(ix2) = h0 * (t2 / T2).^1.15;
h_cw(ix2)  = h0 * (1 - (t2 / T2).^1.15);
v_max_up = 1.25;
tau2 = t2 / T2;
v_cab(ix2) = v_max_up * 4 * tau2 .* (1 - tau2);
v_cw(ix2)  = -v_max_up * 4 * tau2 .* (1 - tau2);

% Mechanical power at drum (from cab/CW motion; sign: + when system receives work)
% Descent: cab heavier -> gravitational power delivered to drum (drives generator)
P_mech_drum = zeros(size(t));
P_mech_drum(ix1) = m_net * g * (-v_cab(ix1));  % cab down: positive into system
P_mech_drum(ix2) = m_net * g * (-v_cab(ix2));  % cab up: negative (motor does work)

% Electrical: regeneration (phase 1) and consumption (phase 2)
eta_gen = 0.72;   % regeneration efficiency (motor as generator)
eta_drive = 0.88; % drive efficiency (motor lifting)
P_elec = zeros(size(t));
P_elec(ix1) = eta_gen * max(0, P_mech_drum(ix1));           % generated [W]
P_elec(ix2) = -max(0, -P_mech_drum(ix2)) / eta_drive;        % consumed [W] (negative convention: consumed)

% Cumulative energy: generated (positive) and consumed (positive count)
P_gen = max(0, P_elec);
P_cons = max(0, -P_elec);
E_gen_cum = cumtrapz(t, P_gen);
E_cons_cum = cumtrapz(t, P_cons);
E_net_cum = E_gen_cum - E_cons_cum;

% Regeneration "efficiency" over cycle (when generating, instantaneous)
eta_inst = zeros(size(t));
eta_inst(ix1) = eta_gen * (0.85 + 0.12 * (1 - exp(-t1/0.6)));
eta_inst(ix1) = min(eta_inst(ix1), 0.78);
eta_inst(ix2) = NaN;  % not generating

% Motor current (proxy: proportional to torque / power)
I_motor = zeros(size(t));
I_motor(ix1) = min(35, 8 + 28 * (t1/T1) .* (1 - t1/T1));   % generating
I_motor(ix2) = min(42, 10 + 32 * (t2/T2) .* (1 - t2/T2)); % motoring

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
fig1 = figure('Name', 'Dual Weight — Time-Series', 'Position', [80, 60, 1280, 840], 'Color', BG);

subplot(3, 3, 1);
plot(t, h_cab, '-', 'Color', C1, 'LineWidth', 2.5);
hold on;
plot(t, h_cw, '-', 'Color', C2, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Height [m]', 'Color', FG);
title('Cab and counterweight height', 'Color', FG);
legend('Cab', 'Counterweight', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 2);
plot(t, v_cab, '-', 'Color', C1, 'LineWidth', 2.5);
hold on;
plot(t, v_cw, '-', 'Color', C2, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Velocity [m/s]', 'Color', FG);
title('Cab and counterweight velocity', 'Color', FG);
legend('Cab', 'Counterweight', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 3);
yyaxis left;
plot(t, P_mech_drum, '-', 'Color', C5, 'LineWidth', 2);
set(gca, 'YColor', C5);
ylabel('Mechanical power at drum [W]', 'Color', FG);
yyaxis right;
plot(t, P_elec, '-', 'Color', C3, 'LineWidth', 2);
set(gca, 'YColor', C3);
ylabel('Electrical power [W]', 'Color', FG);
set(gca, 'Color', BG, 'XColor', FG);
xlabel('Time [s]', 'Color', FG);
title('Mechanical and electrical power', 'Color', FG);
legend('P_{mech}', 'P_{elec} (gen > 0, cons < 0)', 'Location', 'best', 'TextColor', FG);
grid on; grid minor;

subplot(3, 3, 4);
area(t(ix1), P_elec(ix1), 'FaceColor', C3, 'FaceAlpha', 0.6);
hold on;
area(t(ix2), -P_elec(ix2), 'FaceColor', C4, 'FaceAlpha', 0.6);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Power [W]', 'Color', FG);
title('Regeneration vs consumption', 'Color', FG);
legend('Generated', 'Consumed', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 5);
plot(t(ix1), 100*eta_inst(ix1), '-', 'Color', C3, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Efficiency [%]', 'Color', FG);
title('Regeneration efficiency (descent phase)', 'Color', FG);
ylim([0 100]);
grid on; grid minor;

subplot(3, 3, 6);
plot(t, I_motor, '-', 'Color', C6, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Motor current [A]', 'Color', FG);
title('Motor / generator current', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 7);
plot(t, E_gen_cum, '-', 'Color', C3, 'LineWidth', 2.5);
hold on;
plot(t, E_cons_cum, '-', 'Color', C4, 'LineWidth', 2);
plot(t, E_net_cum, '-', 'Color', C5, 'LineWidth', 1.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Energy [J]', 'Color', FG);
title('Cumulative energy', 'Color', FG);
legend('Generated', 'Consumed', 'Net', 'Location', 'best', 'TextColor', FG);
grid on; grid minor; hold off;

subplot(3, 3, 8);
pie_vals = [E_gen_cum(end), E_cons_cum(end)];
pie_vals = max(pie_vals, 0.1);
pie(pie_vals, {'Regenerated', 'Consumed'});
colormap(gca, [C3; C4]);
title('Cycle energy split', 'Color', FG);

subplot(3, 3, 9);
plot(h_cab, v_cab, '-', 'Color', C1, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Cab height [m]', 'Color', FG); ylabel('Cab velocity [m/s]', 'Color', FG);
title('Cab phase portrait (h vs v)', 'Color', FG);
grid on; grid minor;

sgtitle(fig1, 'Dual Weight Regeneration System — Time-Series', 'Color', FG, 'FontSize', 16, 'FontWeight', 'bold');

%% ----- Figure 2: Energy summary -----
fig2 = figure('Name', 'Dual Weight — Energy Analysis', 'Position', [120, 100, 1000, 520], 'Color', BG);

subplot(2, 2, 1);
b = bar([E_gen_cum(end), E_cons_cum(end), E_net_cum(end)], 'FaceColor', 'flat');
b.CData = [C3; C4; C5];
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
set(gca, 'XTickLabel', {'Generated', 'Consumed', 'Net'});
ylabel('Energy [J]', 'Color', FG);
title('One-cycle energy balance', 'Color', FG);
grid on; grid minor;

subplot(2, 2, 2);
plot(t, E_net_cum, '-', 'Color', C5, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Net energy [J]', 'Color', FG);
title('Net cumulative energy (gen - cons)', 'Color', FG);
grid on; grid minor;

subplot(2, 2, 3);
% Power vs cab height (2D heatmap style: scatter or simple plot)
plot(h_cab, P_elec, '-', 'Color', C6, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Cab height [m]', 'Color', FG); ylabel('Electrical power [W]', 'Color', FG);
title('Electrical power vs cab position', 'Color', FG);
grid on; grid minor;

subplot(2, 2, 4);
regen_eff_pct = 100 * E_gen_cum(end) / (E_cons_cum(end) + 1e-6);
bar(1, regen_eff_pct, 'FaceColor', C3);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
set(gca, 'XTick', 1, 'XTickLabel', 'Regen / Cons');
ylabel('Ratio [%]', 'Color', FG);
title('Regeneration ratio (gen ÷ cons)', 'Color', FG);
grid on; grid minor;

sgtitle(fig2, 'Dual Weight Regeneration System — Energy Analysis', 'Color', FG, 'FontSize', 16, 'FontWeight', 'bold');

%% ----- Summary table -----
row_names = {
    'Cab mass'
    'Counterweight mass'
    'Travel height'
    'Descent time'
    'Ascent time'
    'Energy regenerated (descent)'
    'Energy consumed (ascent)'
    'Net energy (cycle)'
    'Peak regen power'
    'Peak motor current'
    'Regeneration ratio (gen/cons)'
};
row_vals = {
    sprintf('%.0f', m_cab)
    sprintf('%.0f', m_cw)
    sprintf('%.1f', h0)
    sprintf('%.2f', T1)
    sprintf('%.2f', T2)
    sprintf('%.1f', E_gen_cum(end))
    sprintf('%.1f', E_cons_cum(end))
    sprintf('%.1f', E_net_cum(end))
    sprintf('%.0f', max(P_elec))
    sprintf('%.1f', max(I_motor))
    sprintf('%.1f', regen_eff_pct)
};
row_units = {'kg'; 'kg'; 'm'; 's'; 's'; 'J'; 'J'; 'J'; 'W'; 'A'; '%'};

fig3 = figure('Name', 'Dual Weight — Summary', 'Position', [200, 120, 620, 520], 'Color', BG);
uit = uitable(fig3, 'Data', [row_names, row_vals, row_units], ...
    'ColumnName', {'Quantity', 'Value', 'Unit'}, ...
    'ColumnWidth', {260, 120, 60}, 'FontSize', 11, 'FontName', 'Segoe UI');
uit.Position = [20, 50, 580, 430];
uit.BackgroundColor = repmat([BG; 0.16 0.16 0.20], 6, 1);
uit.ForegroundColor = FG;
annotation('textbox', [0.12 0.92 0.76 0.06], 'String', 'Dual Weight Regeneration System — Summary', ...
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
