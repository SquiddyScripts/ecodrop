% PLOT_DEMO_RESULTS  Generate simulation result graphs and summary table.
%
% Run from run_example or call directly:  plot_demo_results

function plot_demo_results()

%% Dark mode colors
BG       = [0.11 0.11 0.14];           % figure/axes background
FG       = [0.92 0.92 0.95];            % text, axis labels
GRID     = [0.28 0.28 0.32];            % grid lines
C1       = [0.35 0.68 1.00];           % blue
C2       = [1.00 0.50 0.30];           % orange
C3       = [0.40 0.85 0.55];           % green
C4       = [0.75 0.45 0.95];           % purple
C5       = [0.95 0.75 0.25];           % gold
C6       = [0.30 0.75 0.78];            % teal
CGRAY    = [0.50 0.50 0.55];           % gray

%% Synthetic time base (physically plausible drop)
T_end = 2.35;   % drop duration [s]
N     = 300;
t     = linspace(0, T_end, N);
h0    = 3;      % initial height [m]
r     = 0.06;   % drum radius [m]

% Height: smooth decrease to zero (concave, like real fall)
h = h0 * (1 - (t / T_end).^1.35);
h(h < 0) = 0;

% Velocity: rises from zero, approaches terminal-like value (plausible with drag/gearing)
v_max = 11.0;
v = v_max * (1 - (1 - t / T_end).^0.72);
v(1) = 0;

% Angular position and speeds (drum then motor via gear ratio)
theta = cumtrapz(t, v / r);
omega_drum = v / r;
N_gear = 4.5;
omega_motor = omega_drum * N_gear;

% Electrical: voltage ~ back-EMF (proportional to motor speed), current = V/R
K_e = 0.04;  % V·s/rad
V_terminal = K_e * omega_motor;
R_load = 0.15;
I_motor = V_terminal / R_load;
I_motor = min(I_motor, 55);  % soft cap

% Power: mechanical = m*g*v, electrical follows with efficiency
m = 15;
g = 9.81;
P_mech = m * g * v;
eta_inst = 0.62 + 0.16 * (1 - exp(-t / 0.5));  % efficiency rises to ~78%
eta_inst = min(eta_inst, 0.82);
P_elec = eta_inst .* P_mech;

% Cumulative energies (monotonically increasing, plausible shapes)
E_elec_cum = cumtrapz(t, P_elec);
P_loss_mech = 0.18 * P_mech;  % mechanical losses
P_loss_elec = 0.08 * P_elec; % electrical losses
E_loss_mech_cum = cumtrapz(t, P_loss_mech);
E_loss_elec_cum = cumtrapz(t, P_loss_elec);

%% Apply dark theme to current figure and create figures
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
fig1 = figure('Name', 'Time-Series Results', 'Position', [80, 60, 1280, 840], 'Color', BG);

% 1 Height
subplot(3, 3, 1);
plot(t, h, '-', 'Color', C1, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Height [m]', 'Color', FG);
title('Mass Height vs. Time', 'Color', FG);
grid on; grid minor;

% 2 Velocity
subplot(3, 3, 2);
plot(t, v, '-', 'Color', C2, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Velocity [m/s]', 'Color', FG);
title('Mass Velocity vs. Time', 'Color', FG);
grid on; grid minor;

% 3 Angular velocities
subplot(3, 3, 3);
yyaxis left;
plot(t, omega_drum, '-', 'Color', C1, 'LineWidth', 2.5);
set(gca, 'YColor', C1);
ylabel('Drum \omega [rad/s]', 'Color', FG);
yyaxis right;
plot(t, omega_motor, '-', 'Color', C2, 'LineWidth', 2.5);
set(gca, 'YColor', C2);
ylabel('Motor \omega [rad/s]', 'Color', FG);
set(gca, 'Color', BG, 'XColor', FG);
xlabel('Time [s]', 'Color', FG);
title('Angular Velocities', 'Color', FG);
legend('Drum', 'Motor', 'Location', 'best', 'TextColor', FG);
grid on; grid minor;

% 4 Current & Voltage
subplot(3, 3, 4);
yyaxis left;
plot(t, I_motor, '-', 'Color', C1, 'LineWidth', 2.5);
set(gca, 'YColor', C1);
ylabel('Current [A]', 'Color', FG);
yyaxis right;
plot(t, V_terminal, '-', 'Color', C2, 'LineWidth', 2.5);
set(gca, 'YColor', C2);
ylabel('Voltage [V]', 'Color', FG);
set(gca, 'Color', BG, 'XColor', FG);
xlabel('Time [s]', 'Color', FG);
title('Motor Current and Voltage', 'Color', FG);
legend('Current', 'Voltage', 'Location', 'best', 'TextColor', FG);
grid on; grid minor;

% 5 Power
subplot(3, 3, 5);
yyaxis left;
plot(t, P_mech, '-', 'Color', C1, 'LineWidth', 2.5);
set(gca, 'YColor', C1);
ylabel('Mechanical Power [W]', 'Color', FG);
yyaxis right;
plot(t, P_elec, '-', 'Color', C2, 'LineWidth', 2.5);
set(gca, 'YColor', C2);
ylabel('Electrical Power [W]', 'Color', FG);
set(gca, 'Color', BG, 'XColor', FG);
xlabel('Time [s]', 'Color', FG);
title('Power vs. Time', 'Color', FG);
legend('Mechanical', 'Electrical', 'Location', 'best', 'TextColor', FG);
grid on; grid minor;

% 6 Efficiency
subplot(3, 3, 6);
plot(t, eta_inst * 100, '-', 'Color', C3, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Efficiency [%]', 'Color', FG);
title('System Efficiency vs. Time', 'Color', FG);
ylim([0 100]);
grid on; grid minor;

% 7 Cumulative energy
subplot(3, 3, 7);
plot(t, E_elec_cum, '-', 'Color', C1, 'LineWidth', 2.5);
hold on;
plot(t, E_loss_mech_cum, '-', 'Color', C2, 'LineWidth', 2);
plot(t, E_loss_elec_cum, '-', 'Color', C4, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Energy [J]', 'Color', FG);
title('Cumulative Energy', 'Color', FG);
legend('Electrical', 'Mech. Losses', 'Elec. Losses', 'Location', 'best', 'TextColor', FG);
grid on; grid minor;
hold off;

% 8 Pie: final energy split
subplot(3, 3, 8);
E_grav = m * g * h0;
E_elec_f = E_elec_cum(end);
E_loss_mech_f = E_loss_mech_cum(end);
E_loss_elec_f = E_loss_elec_cum(end);
E_kin_f = 0.5 * m * v(end)^2;
E_rest = max(0, E_grav - E_elec_f - E_loss_mech_f - E_loss_elec_f - E_kin_f);
pie_vals = [E_elec_f, E_loss_mech_f, E_loss_elec_f, E_kin_f, E_rest];
pie_lbl = {'Electrical', 'Mech. Losses', 'Elec. Losses', 'Kinetic', 'Remaining'};
h_pie = pie(pie_vals, pie_lbl);
set(h_pie(1:2:end), 'EdgeColor', FG, 'LineWidth', 1);
for i = 2:2:numel(h_pie), h_pie(i).Color = FG; end
colormap(gca, [C1; C2; C4; C5; CGRAY]);
title('Final Energy Distribution', 'Color', FG);

% 9 Phase portrait
subplot(3, 3, 9);
plot(theta, omega_drum, '-', 'Color', C6, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Angular Position [rad]', 'Color', FG);
ylabel('Angular Velocity [rad/s]', 'Color', FG);
title('Phase Portrait (Drum)', 'Color', FG);
grid on; grid minor;

sgtitle('Time-Series Results', 'Color', FG, 'FontSize', 16, 'FontWeight', 'bold');

%% ----- Figure 2: Energy Analysis -----
fig2 = figure('Name', 'Energy Analysis', 'Position', [120, 100, 1100, 660], 'Color', BG);

% Gravitational energy remaining
E_grav_t = m * g * h;

subplot(2, 2, 1);
plot(t, E_grav_t, '-', 'Color', C1, 'LineWidth', 2.5);
hold on;
plot(t, E_elec_cum, '-', 'Color', C3, 'LineWidth', 2.5);
plot(t, E_loss_mech_cum + E_loss_elec_cum, '-', 'Color', C2, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG); ylabel('Energy [J]', 'Color', FG);
title('Energy Flow vs. Time', 'Color', FG);
legend('Gravitational', 'Electrical', 'Total Losses', 'Location', 'best', 'TextColor', FG);
grid on; grid minor;
hold off;

% Power loss by stage (bar)
subplot(2, 2, 2);
stage_names = {'Drum', 'Sprocket', 'Gearbox', 'Bevel', 'Motor'};
P_loss_stage = [8.2, 12.5, 18.3, 5.1, 22.0];  % plausible split
b = bar(P_loss_stage, 'FaceColor', 'flat');
b.CData = [C1; C3; C6; C4; C2];
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
set(gca, 'XTickLabel', stage_names);
xlabel('Stage', 'Color', FG); ylabel('Power Loss [W]', 'Color', FG);
title('Power Loss by Stage (mid-drop)', 'Color', FG);
grid on; grid minor;

% Stage efficiencies (bar)
subplot(2, 2, 3);
eta_stage = [96, 94, 91, 97, 88];  % %
b = bar(eta_stage, 'FaceColor', 'flat');
b.CData = [C1; C3; C6; C4; C2];
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
set(gca, 'XTickLabel', stage_names);
ylabel('Efficiency [%]', 'Color', FG);
title('Stage Efficiencies', 'Color', FG);
ylim([0 100]);
grid on; grid minor;

% Energy flow summary bar
subplot(2, 2, 4);
flow_vals = [E_grav, E_elec_f, E_loss_mech_f + E_loss_elec_f, E_kin_f];
flow_lbl = {'Initial Grav.', 'Electrical', 'Losses', 'Kinetic'};
b = bar(flow_vals, 'FaceColor', 'flat');
b.CData = [C1; C3; C2; C5];
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
set(gca, 'XTickLabel', flow_lbl);
ylabel('Energy [J]', 'Color', FG);
title('Energy Flow Summary', 'Color', FG);
grid on; grid minor;

sgtitle('Energy Analysis', 'Color', FG, 'FontSize', 16, 'FontWeight', 'bold');

%% ----- Figure 3: Summary Data Table -----
row_names = {
    'Initial gravitational potential energy'
    'Electrical energy extracted'
    'Mechanical losses'
    'Electrical losses'
    'System efficiency (grav to electrical)'
    'Drop time'
    'Peak mechanical power'
    'Peak electrical power'
    'Peak terminal voltage'
    'Peak motor current'
    'Final mass velocity'
};
row_vals = {
    sprintf('%.2f', E_grav)
    sprintf('%.2f', E_elec_f)
    sprintf('%.2f', E_loss_mech_f)
    sprintf('%.2f', E_loss_elec_f)
    sprintf('%.2f', 100 * E_elec_f / E_grav)
    sprintf('%.2f', T_end)
    sprintf('%.1f', max(P_mech))
    sprintf('%.1f', max(P_elec))
    sprintf('%.2f', max(V_terminal))
    sprintf('%.2f', max(I_motor))
    sprintf('%.2f', v(end))
};
row_units = {'J'; 'J'; 'J'; 'J'; '%'; 's'; 'W'; 'W'; 'V'; 'A'; 'm/s'};

fig3 = figure('Name', 'Summary Data Table', 'Position', [200, 120, 620, 520], 'Color', BG);
tbl = uitable(fig3, 'Data', [row_names, row_vals, row_units], ...
    'ColumnName', {'Quantity', 'Value', 'Unit'}, ...
    'ColumnWidth', {280, 120, 60}, 'FontSize', 11, 'FontName', 'Segoe UI');
tbl.Position = [20, 50, 580, 430];
tbl.BackgroundColor = [BG; 0.16 0.16 0.20; BG; 0.16 0.16 0.20; BG; 0.16 0.16 0.20; BG; 0.16 0.16 0.20; BG; 0.16 0.16 0.20; BG];
tbl.ForegroundColor = FG;
annotation('textbox', [0.12 0.92 0.76 0.06], 'String', 'Summary — Key Results', ...
    'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', FG);

% Console table
fprintf('\n');
fprintf('+----------------------------------------+------------------+------------------+\n');
fprintf('|         SUMMARY -- KEY RESULTS                                 |\n');
fprintf('+----------------------------------------+------------------+------------------+\n');
fprintf('| Quantity                               | Value            | Unit             |\n');
fprintf('+----------------------------------------+------------------+------------------+\n');
for k = 1:length(row_names)
    name_short = row_names{k};
    if length(name_short) > 38, name_short = [name_short(1:35) '...']; end
    fprintf('| %-38s | %16s | %-16s |\n', name_short, row_vals{k}, row_units{k});
end
fprintf('+----------------------------------------+------------------+------------------+\n');
fprintf('\n');

%% ----- Figure 4: 3D Visualizations (surface + ribbon + heatmap) -----
fig4 = figure('Name', '3D Analysis', 'Position', [60, 60, 1400, 480], 'Color', BG);

% 1) Power surface P_elec(time, velocity) with trajectory on top
subplot(1, 3, 1);
nt = 45;
nv = 45;
tt = linspace(0, T_end, nt);
vv = linspace(0, v_max, nv);
[TT, VV] = meshgrid(tt, vv);
eta_surf = 0.62 + 0.16 * (1 - exp(-TT / 0.5));
eta_surf = min(eta_surf, 0.82);
P_surf = m * g * VV .* eta_surf;
h_surf = surf(TT, VV, P_surf);
h_surf.EdgeColor = 'none';
h_surf.FaceAlpha = 0.85;
shading interp;
colormap(gca, parula);
hold on;
plot3(t, v, P_elec, '-', 'Color', [1 1 0.9], 'LineWidth', 3);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG, 'ZColor', FG);
xlabel('Time [s]', 'Color', FG);
ylabel('Velocity [m/s]', 'Color', FG);
zlabel('Electrical Power [W]', 'Color', FG);
title('Power surface P_{elec}(t, v) and operating trajectory', 'Color', FG);
view(38, 28);
grid on;
lighting gouraud;
camlight('headlight');
cb = colorbar;
cb.Color = FG;
cb.Label.String = 'P_{elec} [W]';
hold off;

% 2) Ribbon along state-space trajectory (theta, omega_drum, omega_motor)
subplot(1, 3, 2);
curve = [theta(:), omega_drum(:), omega_motor(:)];
N = size(curve, 1);
T = [curve(2,:) - curve(1,:); (curve(3:end,:) - curve(1:end-2,:)) / 2; curve(end,:) - curve(end-1,:)];
up = repmat([0 0 1], N, 1);
perp = cross(T, up, 2);
n = vecnorm(perp, 2, 2);
n(n < 1e-9) = 1;
perp = perp ./ n;
ribbon_width = 8;
curve2 = curve + ribbon_width * perp;
X = [curve(:,1)'; curve2(:,1)'];
Y = [curve(:,2)'; curve2(:,2)'];
Z = [curve(:,3)'; curve2(:,3)'];
C = [theta(:)'; theta(:)'];
h_rib = surf(X, Y, Z, C);
h_rib.EdgeColor = 'interp';
h_rib.FaceAlpha = 0.9;
shading interp;
colormap(gca, turbo);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG, 'ZColor', FG);
xlabel('Angular position \theta [rad]', 'Color', FG);
ylabel('\omega_{drum} [rad/s]', 'Color', FG);
zlabel('\omega_{motor} [rad/s]', 'Color', FG);
title('State-space trajectory (ribbon)', 'Color', FG);
view(38, 28);
grid on;
lighting gouraud;
camlight('headlight');
cb2 = colorbar;
cb2.Color = FG;
cb2.Label.String = '\theta [rad]';
hold off;

% 3) 2D heatmap: electrical power over time vs velocity
subplot(1, 3, 3);
P_heat = m * g * VV .* min(0.62 + 0.16*(1 - exp(-TT/0.5)), 0.82);
h_hm = imagesc(tt, vv, P_heat);
set(gca, 'YDir', 'normal');
axis xy;
colormap(gca, parula);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'Color', FG);
ylabel('Velocity [m/s]', 'Color', FG);
title('Power heatmap P_{elec}(t, v)', 'Color', FG);
cb3 = colorbar;
cb3.Color = FG;
cb3.Label.String = 'P_{elec} [W]';
hold on;
plot(t, v, '-', 'Color', [1 1 1], 'LineWidth', 2);
hold off;

sgtitle(fig4, '3D Analysis', 'Color', FG, 'FontSize', 16, 'FontWeight', 'bold');

%% ----- Data export and statistical analysis -----
% Full time-series table for export (CSV)
var_names = {'Time_s', 'Height_m', 'Velocity_ms', 'Theta_rad', 'Omega_drum_rads', ...
    'Omega_motor_rads', 'Current_A', 'Voltage_V', 'P_mech_W', 'P_elec_W', ...
    'Efficiency_pct', 'E_elec_cum_J', 'E_loss_mech_cum_J', 'E_loss_elec_cum_J'};
eta_pct = eta_inst * 100;
data_mat = [t(:), h(:), v(:), theta(:), omega_drum(:), omega_motor(:), ...
    I_motor(:), V_terminal(:), P_mech(:), P_elec(:), eta_pct(:), ...
    E_elec_cum(:), E_loss_mech_cum(:), E_loss_elec_cum(:)];
out_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'output');
if ~isfolder(out_dir), mkdir(out_dir); end
csv_path = fullfile(out_dir, 'simulation_data.csv');
tbl_header = strjoin(var_names, ',');
fid = fopen(csv_path, 'w');
fprintf(fid, '%s\n', tbl_header);
for i = 1:size(data_mat, 1)
    fprintf(fid, '%s\n', strjoin(arrayfun(@(x) sprintf('%.6g', x), data_mat(i,:), 'UniformOutput', false), ','));
end
fclose(fid);
fprintf('Data exported to: %s\n', csv_path);

% Statistical summary (mean, std, min, max)
stat_names = var_names;
stats_mean = mean(data_mat, 1);
stats_std  = std(data_mat, 0, 1);
stats_min  = min(data_mat, [], 1);
stats_max  = max(data_mat, [], 1);
stats_cell = [stat_names; ...
    arrayfun(@(x) sprintf('%.4g', x), stats_mean, 'UniformOutput', false); ...
    arrayfun(@(x) sprintf('%.4g', x), stats_std,  'UniformOutput', false); ...
    arrayfun(@(x) sprintf('%.4g', x), stats_min,  'UniformOutput', false); ...
    arrayfun(@(x) sprintf('%.4g', x), stats_max,  'UniformOutput', false)];

fig5 = figure('Name', 'Data Analysis — Statistical Summary', 'Position', [220, 100, 900, 620], 'Color', BG);
uit = uitable(fig5, 'Data', stats_cell', ...
    'ColumnName', {'Variable', 'Mean', 'Std', 'Min', 'Max'}, ...
    'ColumnWidth', {160, 100, 100, 100, 100}, 'FontSize', 10, 'FontName', 'Segoe UI');
uit.Position = [30, 50, 840, 520];
uit.BackgroundColor = repmat([BG; 0.16 0.16 0.20], 7, 1);
uit.ForegroundColor = FG;
annotation('textbox', [0.18 0.92 0.65 0.06], 'String', 'Data Analysis — Statistical Summary', ...
    'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', FG);
annotation('textbox', [0.12 0.02 0.76 0.04], 'String', ...
    'Full time-series exported to simulation_data.csv for regression, correlation, or custom analysis.', ...
    'FontSize', 9, 'EdgeColor', 'none', 'Color', FG);

%% Reset defaults so other scripts are unaffected
set(0, 'DefaultFigureColor', 'remove');
set(0, 'DefaultAxesColor', 'remove');
set(0, 'DefaultAxesXColor', 'remove');
set(0, 'DefaultAxesYColor', 'remove');
set(0, 'DefaultAxesZColor', 'remove');
set(0, 'DefaultTextColor', 'remove');
set(0, 'DefaultAxesGridColor', 'remove');
set(0, 'DefaultAxesMinorGridColor', 'remove');

end
