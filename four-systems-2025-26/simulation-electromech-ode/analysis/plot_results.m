function plot_results(results, opt_results)
% PLOT_RESULTS Create comprehensive visualization of simulation results
%
% Generates time-series plots, energy analysis charts, summary data table,
% and optimization result visualizations.
%
% Inputs:
%   results - Simulation results structure (from main_simulation.m)
%   opt_results - Optional optimization results (from optimize_gearbox.m)

if nargin < 2
    opt_results = [];
end

%% Shared style: dark mode + bright palette
BG_DARK   = [0.11 0.11 0.14];
FG_DARK   = [0.92 0.92 0.95];
GRID_DARK = [0.28 0.28 0.32];
COLORS = struct(...
    'primary',   [0.35 0.68 1.00], ...   % blue (bright on dark)
    'secondary', [1.00 0.50 0.30], ...   % orange
    'accent',    [0.40 0.85 0.55], ...   % green
    'purple',    [0.75 0.45 0.95], ...   % purple
    'gold',      [0.95 0.75 0.25], ...   % gold
    'teal',      [0.30 0.75 0.78], ...   % teal
    'gray',      [0.50 0.50 0.55]);      % gray

%% Time-Series Plots
if ~isempty(results)
    plot_time_series(results, COLORS);
end

%% Energy Analysis
if ~isempty(results)
    plot_energy_analysis(results, COLORS);
end

%% Summary Data Table (figure + console)
if ~isempty(results)
    plot_summary_table(results, COLORS);
end

%% Optimization Results
if ~isempty(opt_results)
    plot_optimization_results(opt_results, COLORS);
end

end

function plot_time_series(results, COLORS)
% Plot time-series data with professional styling

if nargin < 2
    COLORS = struct('primary', [0.35 0.68 1], 'secondary', [1 0.5 0.3], ...
        'accent', [0.4 0.85 0.55], 'purple', [0.75 0.45 0.95], ...
        'gold', [0.95 0.75 0.25], 'teal', [0.3 0.75 0.78], 'gray', [0.5 0.5 0.55]);
end
BG = [0.11 0.11 0.14]; FG = [0.92 0.92 0.95]; GRID = [0.28 0.28 0.32];

fig = figure('Name', 'Time-Series Results', 'Position', [80, 60, 1280, 840], 'Color', BG);
set(fig, 'DefaultAxesFontSize', 11, 'DefaultAxesFontName', 'Segoe UI');
set(fig, 'DefaultAxesLineWidth', 1.0);
set(fig, 'DefaultAxesBox', 'on');
set(fig, 'DefaultAxesXGrid', 'on', 'DefaultAxesYGrid', 'on');
set(fig, 'DefaultAxesColor', BG);
set(fig, 'DefaultAxesXColor', FG);
set(fig, 'DefaultAxesYColor', FG);
set(fig, 'DefaultAxesGridColor', GRID);
set(fig, 'DefaultAxesMinorGridColor', GRID);
set(fig, 'DefaultTextColor', FG);

% Mass position and velocity
subplot(3, 3, 1);
plot(results.time, results.h, '-', 'Color', COLORS.primary, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'FontWeight', 'bold', 'Color', FG);
ylabel('Height [m]', 'FontWeight', 'bold', 'Color', FG);
title('Mass Height vs. Time', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
grid on; grid minor;

subplot(3, 3, 2);
plot(results.time, results.v_linear, '-', 'Color', COLORS.secondary, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'FontWeight', 'bold', 'Color', FG);
ylabel('Velocity [m/s]', 'FontWeight', 'bold', 'Color', FG);
title('Mass Velocity vs. Time', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
grid on; grid minor;

% Angular velocities
subplot(3, 3, 3);
yyaxis left;
plot(results.time, results.omega_mass, '-', 'Color', COLORS.primary, 'LineWidth', 2.5);
set(gca, 'YColor', COLORS.primary);
ylabel('Drum \omega [rad/s]', 'FontWeight', 'bold', 'Color', FG);
yyaxis right;
plot(results.time, results.omega_motor, '-', 'Color', COLORS.secondary, 'LineWidth', 2.5);
set(gca, 'YColor', COLORS.secondary);
ylabel('Motor \omega [rad/s]', 'FontWeight', 'bold', 'Color', FG);
set(gca, 'Color', BG, 'XColor', FG);
xlabel('Time [s]', 'FontWeight', 'bold', 'Color', FG);
title('Angular Velocities', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
legend('Drum', 'Motor', 'Location', 'best', 'FontSize', 9, 'TextColor', FG);
grid on; grid minor;

% Electrical quantities
subplot(3, 3, 4);
V_terminal = zeros(size(results.time));
for i = 1:length(results.time)
    if ~isempty(results.component_history{i})
        V_terminal(i) = results.component_history{i}.V_terminal;
    end
end
yyaxis left;
plot(results.time, results.I_motor, '-', 'Color', COLORS.primary, 'LineWidth', 2.5);
set(gca, 'YColor', COLORS.primary);
ylabel('Current [A]', 'FontWeight', 'bold', 'Color', FG);
yyaxis right;
plot(results.time, V_terminal, '-', 'Color', COLORS.secondary, 'LineWidth', 2.5);
set(gca, 'YColor', COLORS.secondary);
ylabel('Voltage [V]', 'FontWeight', 'bold', 'Color', FG);
set(gca, 'Color', BG, 'XColor', FG);
xlabel('Time [s]', 'FontWeight', 'bold', 'Color', FG);
title('Motor Current and Voltage', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
legend('Current', 'Voltage', 'Location', 'best', 'FontSize', 9, 'TextColor', FG);
grid on; grid minor;

% Power
subplot(3, 3, 5);
P_mech_plot = results.P_mechanical;
P_mech_plot(isnan(P_mech_plot) | isinf(P_mech_plot) | P_mech_plot < 0) = 0;
valid_power_idx = results.h > 0.01;
if ~any(valid_power_idx), valid_power_idx = 1:length(results.time); end
yyaxis left;
plot(results.time(valid_power_idx), P_mech_plot(valid_power_idx), '-', 'Color', COLORS.primary, 'LineWidth', 2.5);
set(gca, 'YColor', COLORS.primary);
ylabel('Mechanical Power [W]', 'FontWeight', 'bold', 'Color', FG);
yyaxis right;
P_elec_plot = results.P_electrical;
P_elec_plot(isnan(P_elec_plot) | isinf(P_elec_plot) | P_elec_plot < 0) = 0;
plot(results.time(valid_power_idx), P_elec_plot(valid_power_idx), '-', 'Color', COLORS.secondary, 'LineWidth', 2.5);
set(gca, 'YColor', COLORS.secondary);
ylabel('Electrical Power [W]', 'FontWeight', 'bold', 'Color', FG);
set(gca, 'Color', BG, 'XColor', FG);
xlabel('Time [s]', 'FontWeight', 'bold', 'Color', FG);
title('Power vs. Time', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
legend('Mechanical', 'Electrical', 'Location', 'best', 'FontSize', 9, 'TextColor', FG);
grid on; grid minor;

% Efficiency
subplot(3, 3, 6);
eta_plot = results.eta_system;
eta_plot(isnan(eta_plot) | isinf(eta_plot) | eta_plot > 1 | eta_plot < 0) = 0;
valid_eta_idx = results.h > 0.01;
if ~any(valid_eta_idx), valid_eta_idx = 1:length(results.time); end
plot(results.time(valid_eta_idx), 100 * eta_plot(valid_eta_idx), '-', 'Color', COLORS.accent, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'FontWeight', 'bold', 'Color', FG);
ylabel('Efficiency [%]', 'FontWeight', 'bold', 'Color', FG);
title('System Efficiency vs. Time', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
ylim([0, 100]);
grid on; grid minor;

% Energy (cumulative)
subplot(3, 3, 7);
plot(results.time, results.E_electrical_cumulative, '-', 'Color', COLORS.primary, 'LineWidth', 2.5);
hold on;
plot(results.time, results.E_loss_mechanical_cumulative, '-', 'Color', COLORS.secondary, 'LineWidth', 2);
plot(results.time, results.E_loss_electrical_cumulative, '-', 'Color', COLORS.purple, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'FontWeight', 'bold', 'Color', FG);
ylabel('Energy [J]', 'FontWeight', 'bold', 'Color', FG);
title('Cumulative Energy', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
legend('Electrical', 'Mech. Losses', 'Elec. Losses', 'Location', 'best', 'FontSize', 9, 'TextColor', FG);
grid on; grid minor;
hold off;

% Energy breakdown (pie chart)
subplot(3, 3, 8);
E_grav_initial = results.params.physical.mass * results.params.physical.g * ...
                 results.params.physical.initial_height;
E_elec_final = results.E_electrical_cumulative(end);
E_loss_mech_final = results.E_loss_mechanical_cumulative(end);
E_loss_elec_final = results.E_loss_electrical_cumulative(end);
E_kin_final = 0.5 * results.params.physical.mass * results.v_linear(end)^2;
E_remaining = max(0, E_grav_initial - E_elec_final - E_loss_mech_final - E_loss_elec_final - E_kin_final);
pie_data = [E_elec_final, E_loss_mech_final, E_loss_elec_final, E_kin_final, E_remaining];
pie_labels = {'Electrical', 'Mech. Losses', 'Elec. Losses', 'Kinetic', 'Remaining'};
h_pie = pie(pie_data, pie_labels);
set(h_pie(1:2:end), 'LineWidth', 1.2, 'EdgeColor', FG);
for i = 2:2:numel(h_pie), h_pie(i).Color = FG; end
colormap(gca, [COLORS.primary; COLORS.secondary; COLORS.purple; COLORS.gold; COLORS.gray]);
title('Final Energy Distribution', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);

% Phase portrait
subplot(3, 3, 9);
plot(results.theta_mass, results.omega_mass, '-', 'Color', COLORS.teal, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Angular Position [rad]', 'FontWeight', 'bold', 'Color', FG);
ylabel('Angular Velocity [rad/s]', 'FontWeight', 'bold', 'Color', FG);
title('Phase Portrait (Drum)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
grid on; grid minor;

sgtitle('Time-Series Simulation Results', 'FontSize', 16, 'FontWeight', 'bold', 'Color', FG);
end

function plot_energy_analysis(results, COLORS)
% Plot detailed energy analysis with professional styling

if nargin < 2
    COLORS = struct('primary', [0.35 0.68 1], 'secondary', [1 0.5 0.3], ...
        'accent', [0.4 0.85 0.55], 'purple', [0.75 0.45 0.95], ...
        'gold', [0.95 0.75 0.25], 'teal', [0.3 0.75 0.78], 'gray', [0.5 0.5 0.55]);
end
BG = [0.11 0.11 0.14]; FG = [0.92 0.92 0.95]; GRID = [0.28 0.28 0.32];

fig = figure('Name', 'Energy Analysis', 'Position', [120, 100, 1100, 660], 'Color', BG);
set(fig, 'DefaultAxesFontSize', 11, 'DefaultAxesFontName', 'Segoe UI');
set(fig, 'DefaultAxesBox', 'on');
set(fig, 'DefaultAxesXGrid', 'on', 'DefaultAxesYGrid', 'on');
set(fig, 'DefaultAxesColor', BG);
set(fig, 'DefaultAxesXColor', FG);
set(fig, 'DefaultAxesYColor', FG);
set(fig, 'DefaultAxesGridColor', GRID);
set(fig, 'DefaultAxesMinorGridColor', GRID);
set(fig, 'DefaultTextColor', FG);

% Energy vs. time
subplot(2, 2, 1);
E_grav_initial = results.params.physical.mass * results.params.physical.g * ...
                 results.params.physical.initial_height;
E_grav = E_grav_initial - results.params.physical.mass * results.params.physical.g * ...
         (results.params.physical.initial_height - results.h);
valid_time_idx = results.h > 0.01;
if ~any(valid_time_idx), valid_time_idx = 1:length(results.time); end

plot(results.time(valid_time_idx), E_grav(valid_time_idx), '-', 'Color', COLORS.primary, 'LineWidth', 2.5);
hold on;
plot(results.time(valid_time_idx), results.E_electrical_cumulative(valid_time_idx), '-', 'Color', COLORS.accent, 'LineWidth', 2.5);
plot(results.time(valid_time_idx), results.E_loss_mechanical_cumulative(valid_time_idx) + ...
     results.E_loss_electrical_cumulative(valid_time_idx), '-', 'Color', COLORS.secondary, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Time [s]', 'FontWeight', 'bold', 'Color', FG);
ylabel('Energy [J]', 'FontWeight', 'bold', 'Color', FG);
title('Energy Flow vs. Time', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
legend('Gravitational', 'Electrical', 'Total Losses', 'Location', 'best', 'FontSize', 9, 'TextColor', FG);
grid on; grid minor;
hold off;

% Power breakdown by stage
subplot(2, 2, 2);
last_valid_idx = length(results.energy_history);
for i = length(results.energy_history):-1:1
    if ~isempty(results.energy_history{i}) && results.energy_history{i}.P_mechanical > 1e-3
        last_valid_idx = i;
        break;
    end
end

if last_valid_idx > 0 && ~isempty(results.energy_history{last_valid_idx})
    stages = results.energy_history{last_valid_idx}.stages;
    stage_names = fieldnames(stages);
    P_losses = zeros(length(stage_names), 1);
    for i = 1:length(stage_names)
        stage = stages.(stage_names{i});
        if isfield(stage, 'P_loss')
            P_losses(i) = abs(stage.P_loss);
        end
    end
    if any(P_losses > 1e-6)
        b = bar(P_losses, 'FaceColor', 'flat');
        b.CData = repmat(COLORS.primary, length(stage_names), 1);
        set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG, 'XTickLabel', stage_names);
        xlabel('Stage', 'FontWeight', 'bold', 'Color', FG);
        ylabel('Power Loss [W]', 'FontWeight', 'bold', 'Color', FG);
        title(sprintf('Power Loss by Stage (t=%.2f s)', results.time(last_valid_idx)), 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
        grid on; grid minor;
    else
        text(0.5, 0.5, 'No significant losses detected', 'HorizontalAlignment', 'center', 'Units', 'normalized', 'FontSize', 11, 'Color', FG);
        title('Power Loss by Stage', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
    end
end

% Efficiency by stage
subplot(2, 2, 3);
last_valid_idx = length(results.energy_history);
for i = length(results.energy_history):-1:1
    if ~isempty(results.energy_history{i}) && results.energy_history{i}.P_mechanical > 1e-3
        last_valid_idx = i;
        break;
    end
end

if last_valid_idx > 0 && ~isempty(results.energy_history{last_valid_idx})
    eta_sprocket = max(0, min(1, results.energy_history{last_valid_idx}.eta_sprocket));
    eta_gearbox = max(0, min(1, results.energy_history{last_valid_idx}.eta_gearbox));
    eta_bevel = max(0, min(1, results.energy_history{last_valid_idx}.eta_bevel));
    eta_motor = max(0, min(1, results.energy_history{last_valid_idx}.eta_motor));
    eta_data = [eta_sprocket, eta_gearbox, eta_bevel, eta_motor] * 100;
    eta_names = {'Sprocket', 'Gearbox', 'Bevel', 'Motor'};
    b = bar(eta_data, 'FaceColor', 'flat');
    b.CData = [COLORS.primary; COLORS.accent; COLORS.teal; COLORS.secondary];
    set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG, 'XTickLabel', eta_names);
    ylabel('Efficiency [%]', 'FontWeight', 'bold', 'Color', FG);
    title(sprintf('Stage Efficiencies (t=%.2f s)', results.time(last_valid_idx)), 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
    ylim([0, 100]);
    grid on; grid minor;
end

% Energy flow summary bar
subplot(2, 2, 4);
E_grav_initial = results.params.physical.mass * results.params.physical.g * ...
                 results.params.physical.initial_height;
E_elec_final = results.E_electrical_cumulative(end);
E_loss_total = results.E_loss_mechanical_cumulative(end) + results.E_loss_electrical_cumulative(end);
E_kin_linear = 0.5 * results.params.physical.mass * results.v_linear(end)^2;
omega_mass_final = results.omega_mass(end);
omega_motor_final = results.omega_motor(end);
E_kin_drum = 0.5 * results.params.physical.drum_inertia * omega_mass_final^2;
E_kin_motor = 0.5 * results.params.motor.J_rotor * omega_motor_final^2;
N_sprocket = results.params.physical.sprocket_ratio;
N_gearbox = prod(results.params.gearbox.ratios);
omega_sprocket = omega_mass_final / N_sprocket;
omega_gearbox_out = omega_mass_final / (N_sprocket * N_gearbox);
E_kin_sprocket = 0.5 * results.params.physical.sprocket_inertia * omega_sprocket^2;
E_kin_gearbox = 0.5 * (results.params.gearbox.inertia_input + results.params.gearbox.inertia_output) * omega_gearbox_out^2;
E_kin_bevel = 0.5 * results.params.bevel.inertia * omega_motor_final^2;
E_kin_rotational = E_kin_drum + E_kin_sprocket + E_kin_gearbox + E_kin_bevel + E_kin_motor;
E_kin_final = E_kin_linear + E_kin_rotational;

energy_flow = [E_grav_initial, E_elec_final, E_loss_total, E_kin_final];
energy_labels = {'Initial Grav.', 'Electrical', 'Losses', 'Kinetic'};
b = bar(energy_flow, 'FaceColor', 'flat');
b.CData = [COLORS.primary; COLORS.accent; COLORS.secondary; COLORS.gold];
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG, 'XTickLabel', energy_labels);
ylabel('Energy [J]', 'FontWeight', 'bold', 'Color', FG);
title('Energy Flow Summary', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
grid on; grid minor;

sgtitle('Energy Analysis', 'FontSize', 16, 'FontWeight', 'bold', 'Color', FG);
end

function plot_summary_table(results, COLORS)
% Create an impressive summary data table figure and print to console

if nargin < 2
    COLORS = struct('primary', [0 0.45 0.74], 'secondary', [0.85 0.33 0.1], 'accent', [0.47 0.67 0.19]);
end

E_grav = results.params.physical.mass * results.params.physical.g * results.params.physical.initial_height;
E_elec = results.E_electrical_cumulative(end);
E_loss_mech = results.E_loss_mechanical_cumulative(end);
E_loss_elec = results.E_loss_electrical_cumulative(end);
eta_pct = 100 * results.final.efficiency;
P_peak_mech = max(results.P_mechanical);
P_peak_elec = max(results.P_electrical);
v_final = results.v_linear(end);
V_terminal = zeros(size(results.time));
for i = 1:length(results.time)
    if ~isempty(results.component_history{i})
        V_terminal(i) = results.component_history{i}.V_terminal;
    end
end
V_peak = max(V_terminal);
I_peak = max(results.I_motor);

% Build table data (formatted for display)
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
row_vals_num = [E_grav; E_elec; E_loss_mech; E_loss_elec; eta_pct; results.final.drop_time; ...
    P_peak_mech; P_peak_elec; V_peak; I_peak; v_final];
row_vals = cell(length(row_vals_num), 1);
for k = 1:length(row_vals_num)
    if k == 5
        row_vals{k} = sprintf('%.2f', row_vals_num(k));
    elseif any(k == [1 2 3 4])
        row_vals{k} = sprintf('%.2f', row_vals_num(k));
    else
        row_vals{k} = sprintf('%.4g', row_vals_num(k));
    end
end
row_units = {'J'; 'J'; 'J'; 'J'; '%'; 's'; 'W'; 'W'; 'V'; 'A'; 'm/s'};

% Figure with uitable (dark mode)
BG = [0.11 0.11 0.14]; FG = [0.92 0.92 0.95];
fig = figure('Name', 'Summary Data Table', 'Position', [200, 120, 620, 520], 'Color', BG);
t = uitable(fig, 'Data', [row_names, row_vals, row_units], ...
    'ColumnName', {'Quantity', 'Value', 'Unit'}, ...
    'ColumnWidth', {280, 120, 60}, ...
    'RowName', [], 'FontSize', 11, 'FontName', 'Segoe UI');
t.Position = [20, 50, 580, 430];
t.BackgroundColor = [BG; 0.16 0.16 0.20; BG; 0.16 0.16 0.20; BG; 0.16 0.16 0.20; BG; 0.16 0.16 0.20; BG; 0.16 0.16 0.20; BG];
t.ForegroundColor = FG;
annotation('textbox', [0.15 0.92 0.7 0.06], 'String', 'Simulation Summary — Key Results', ...
    'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none', 'HorizontalAlignment', 'center', 'Color', FG);

% Console print (ASCII box for compatibility)
fprintf('\n');
fprintf('+----------------------------------------+------------------+------------------+\n');
fprintf('|           SIMULATION SUMMARY -- KEY RESULTS                         |\n');
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
end

function plot_optimization_results(opt_results, COLORS)
% Plot optimization results with professional styling

if nargin < 2
    COLORS = struct('primary', [0.35 0.68 1], 'secondary', [1 0.5 0.3], 'accent', [0.4 0.85 0.55], 'purple', [0.75 0.45 0.95], 'gray', [0.5 0.5 0.55]);
end
BG = [0.11 0.11 0.14]; FG = [0.92 0.92 0.95]; GRID = [0.28 0.28 0.32];

fig = figure('Name', 'Gearbox Optimization Results', 'Position', [180, 80, 1240, 820], 'Color', BG);
set(fig, 'DefaultAxesFontSize', 11, 'DefaultAxesFontName', 'Segoe UI');
set(fig, 'DefaultAxesBox', 'on');
set(fig, 'DefaultAxesXGrid', 'on', 'DefaultAxesYGrid', 'on');
set(fig, 'DefaultAxesColor', BG);
set(fig, 'DefaultAxesXColor', FG);
set(fig, 'DefaultAxesYColor', FG);
set(fig, 'DefaultAxesGridColor', GRID);
set(fig, 'DefaultAxesMinorGridColor', GRID);
set(fig, 'DefaultTextColor', FG);

% Efficiency vs. gearbox ratio
subplot(2, 3, 1);
plot(opt_results.ratios_valid, 100 * opt_results.efficiencies_valid, '-', 'Color', COLORS.primary, 'LineWidth', 2.5);
hold on;
plot(opt_results.optimal_ratio, 100 * opt_results.optimal_value, 'o', 'Color', COLORS.secondary, ...
     'MarkerSize', 12, 'MarkerFaceColor', COLORS.secondary, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Gearbox Ratio', 'FontWeight', 'bold', 'Color', FG);
ylabel('Efficiency [%]', 'FontWeight', 'bold', 'Color', FG);
title('Efficiency vs. Gearbox Ratio', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
legend('Efficiency', 'Optimal', 'Location', 'best', 'FontSize', 9, 'TextColor', FG);
grid on; grid minor;
hold off;

% Energy extracted vs. gearbox ratio
subplot(2, 3, 2);
plot(opt_results.ratios_valid, opt_results.E_electrical_valid, '-', 'Color', COLORS.accent, 'LineWidth', 2.5);
hold on;
plot(opt_results.optimal_ratio, opt_results.E_electrical_valid(opt_results.optimal_idx), ...
     'o', 'Color', COLORS.secondary, 'MarkerSize', 12, 'MarkerFaceColor', COLORS.secondary, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Gearbox Ratio', 'FontWeight', 'bold', 'Color', FG);
ylabel('Electrical Energy [J]', 'FontWeight', 'bold', 'Color', FG);
title('Energy Extracted vs. Gearbox Ratio', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
legend('Energy', 'Optimal', 'Location', 'best', 'FontSize', 9, 'TextColor', FG);
grid on; grid minor;
hold off;

% Losses vs. gearbox ratio
subplot(2, 3, 3);
plot(opt_results.ratios_valid, opt_results.E_losses_valid, '-', 'Color', COLORS.secondary, 'LineWidth', 2.5);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Gearbox Ratio', 'FontWeight', 'bold', 'Color', FG);
ylabel('Total Losses [J]', 'FontWeight', 'bold', 'Color', FG);
title('Losses vs. Gearbox Ratio', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
grid on; grid minor;

% Drop time vs. gearbox ratio
subplot(2, 3, 4);
plot(opt_results.ratios_valid, opt_results.drop_times_valid, '-', 'Color', COLORS.purple, 'LineWidth', 2.5);
hold on;
plot(opt_results.optimal_ratio, opt_results.drop_times_valid(opt_results.optimal_idx), ...
     'o', 'Color', COLORS.secondary, 'MarkerSize', 12, 'MarkerFaceColor', COLORS.secondary, 'LineWidth', 2);
set(gca, 'Color', BG, 'XColor', FG, 'YColor', FG);
xlabel('Gearbox Ratio', 'FontWeight', 'bold', 'Color', FG);
ylabel('Drop Time [s]', 'FontWeight', 'bold', 'Color', FG);
title('Drop Time vs. Gearbox Ratio', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
legend('Drop Time', 'Optimal', 'Location', 'best', 'FontSize', 9, 'TextColor', FG);
grid on; grid minor;
hold off;

% Energy breakdown at optimal ratio
subplot(2, 3, 5);
if ~isempty(opt_results.optimal_simulation)
    E_grav_initial = opt_results.params.physical.mass * opt_results.params.physical.g * ...
                     opt_results.params.physical.initial_height;
    E_elec = opt_results.optimal_simulation.final.E_electrical;
    E_losses = opt_results.optimal_simulation.final.E_losses;
    E_kin = 0.5 * opt_results.params.physical.mass * opt_results.optimal_simulation.v_linear(end)^2;
    E_remaining = max(0, E_grav_initial - E_elec - E_losses - E_kin);
    pie_data = [E_elec, E_losses, E_kin, E_remaining];
    pie_labels = {'Electrical', 'Losses', 'Kinetic', 'Remaining'};
    h_pie = pie(pie_data, pie_labels);
    set(h_pie(1:2:end), 'LineWidth', 1.2, 'EdgeColor', FG);
    for i = 2:2:numel(h_pie), h_pie(i).Color = FG; end
    colormap(gca, [COLORS.primary; COLORS.secondary; COLORS.accent; COLORS.gray]);
    title(sprintf('Energy at Optimal Ratio (%.2f)', opt_results.optimal_ratio), 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
end

% Combined metric plot
subplot(2, 3, 6);
yyaxis left;
plot(opt_results.ratios_valid, 100 * opt_results.efficiencies_valid, '-', 'Color', COLORS.primary, 'LineWidth', 2.5);
set(gca, 'YColor', COLORS.primary);
ylabel('Efficiency [%]', 'FontWeight', 'bold', 'Color', FG);
yyaxis right;
plot(opt_results.ratios_valid, opt_results.E_electrical_valid, '-', 'Color', COLORS.accent, 'LineWidth', 2.5);
set(gca, 'YColor', COLORS.accent);
ylabel('Energy [J]', 'FontWeight', 'bold', 'Color', FG);
set(gca, 'Color', BG, 'XColor', FG);
xlabel('Gearbox Ratio', 'FontWeight', 'bold', 'Color', FG);
title('Efficiency and Energy vs. Ratio', 'FontSize', 12, 'FontWeight', 'bold', 'Color', FG);
hold on;
xline(opt_results.optimal_ratio, '--', 'Color', COLORS.secondary, 'LineWidth', 2, 'DisplayName', 'Optimal');
legend('Efficiency', 'Energy', 'Optimal', 'Location', 'best', 'FontSize', 9, 'TextColor', FG);
grid on; grid minor;
hold off;

sgtitle('Gearbox Optimization Results', 'FontSize', 16, 'FontWeight', 'bold', 'Color', FG);

% Print summary
fprintf('\n=== Optimization Summary ===\n');
fprintf('Optimal gearbox ratio: %.2f\n', opt_results.optimal_ratio);
fprintf('Optimal efficiency: %.2f%%\n', 100 * opt_results.optimal_value);
fprintf('Energy extracted: %.2f J\n', opt_results.E_electrical_valid(opt_results.optimal_idx));
fprintf('Drop time: %.2f s\n', opt_results.drop_times_valid(opt_results.optimal_idx));
fprintf('===========================\n\n');

end
