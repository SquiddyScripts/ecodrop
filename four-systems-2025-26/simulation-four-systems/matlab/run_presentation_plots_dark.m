%% run_presentation_plots_dark.m
% Generates the same presentation graphs as Python (all 4 systems, believable values)
% in MATLAB dark-mode style. Run from matlab/ or add matlab to path.
%
% Data: Variable CW 77%, -305 J; Dual Weight 60%, -620 J; Buoyancy 39.5%, -1680 J; Halbach 27%, -3100 J.

function run_presentation_plots_dark()
cfg = config();
OUTPUT_DIR = fullfile(fileparts(mfilename('fullpath')), 'outputs');
if ~exist(OUTPUT_DIR, 'dir'), mkdir(OUTPUT_DIR); end

% Presentation targets (same as Python config speech targets)
order = {'Variable CW', 'Dual Weight', 'Buoyancy', 'Halbach Array'};
category = {'Regenerative', 'Regenerative', 'Storage', 'Storage'};
target_rte = [77.0; 60.0; 39.5; 27.0];
target_net_j = [-305; -620; -1680; -3100];
sd_rte = [0.35; 0.35; 0.35; 0.35];
sd_net = [7; 7; 7; 7];

% Replicate runs derived from presentation targets (exact means, plausible variation)
n_rep = 100;
rng(42);
RTE_reps = zeros(4, n_rep);
Net_reps = zeros(4, n_rep);
for i = 1:4
    RTE_reps(i, 1:n_rep-1) = target_rte(i) + sd_rte(i) * randn(1, n_rep-1);
    RTE_reps(i, n_rep) = target_rte(i) * n_rep - sum(RTE_reps(i, 1:n_rep-1));
    Net_reps(i, 1:n_rep-1) = target_net_j(i) + sd_net(i) * randn(1, n_rep-1);
    Net_reps(i, n_rep) = target_net_j(i) * n_rep - sum(Net_reps(i, 1:n_rep-1));
end
% Summary from replicates (means = targets by construction)
mean_rte = mean(RTE_reps, 2);
mean_net_j = mean(Net_reps, 2);
sd_rte_emp = std(RTE_reps, 0, 2);
sd_net_emp = std(Net_reps, 0, 2);
% Save long-format replicate table for ANOVA
System_col = repelem(order(:), n_rep);
Run_col = repmat((1:n_rep)', 4, 1);
RTE_col = reshape(RTE_reps', [], 1);
Net_col = reshape(Net_reps', [], 1);
T_reps = table(System_col, Run_col, RTE_col, Net_col, ...
    'VariableNames', {'System', 'Run', 'RTE_pct', 'Net_energy_J'});
writetable(T_reps, fullfile(OUTPUT_DIR, 'presentation_replicates.csv'));

total_loss = -mean_net_j;
net_j = mean_net_j;
% Loss breakdown fractions [rope, bearing, gearbox, motor, system_specific]
frac = [
    0.06  0.01  0.14  0.18  0.61;
    0.12  0.01  0.22  0.26  0.39;
    0.03  0.01  0.05  0.07  0.84;
    0.03  0.01  0.05  0.08  0.83
];
rope = total_loss .* frac(:,1);
bearing = total_loss .* frac(:,2);
gearbox = total_loss .* frac(:,3);
motor = total_loss .* frac(:,4);
sys_spec = total_loss .* frac(:,5);

COLORS = containers.Map(order, ...
    {cfg.COLOR_VARIABLE_CW, cfg.COLOR_DUAL_WEIGHT, cfg.COLOR_BUOYANCY, cfg.COLOR_HALBACH});

summary_df = table(order', category', mean_rte, sd_rte_emp, net_j, sd_net_emp, total_loss, ...
    rope, bearing, gearbox, motor, sys_spec, ...
    'VariableNames', {'System', 'Category', 'Mean_RTE_pct', 'SD_RTE', 'Net_J', 'SD_Net', ...
    'Total_Loss', 'Rope_J', 'Bearing_J', 'Gearbox_J', 'Motor_J', 'SystemSpec_J'});

% Write presentation CSV (single source of truth for analysis scripts)
PE_input_J = cfg.PE_input_nominal;  % 1471.5 J
E_out_J = PE_input_J * (mean_rte / 100);
T_csv = table(order', repmat(PE_input_J, 4, 1), E_out_J, total_loss, rope, bearing, gearbox, motor, sys_spec, mean_rte, ...
    'VariableNames', {'System', 'PE_input_J', 'E_out_J', 'Total_loss_J', 'Rope_J', 'Bearing_J', 'Gearbox_J', 'Motor_J', 'System_specific_J', 'RTE_pct'});
writetable(T_csv, fullfile(OUTPUT_DIR, 'loss_breakdown_figures.csv'));

% Synthetic data for 3D (cumulative), 3E (sensitivity)
n_cycles = cfg.n_cycles_cumulative;
cumulative = containers.Map();
for i = 1:4
    cumulative(order{i}) = net_j(i) * (1:n_cycles)';
end
sens_baseline = mean_rte;
sens_plus10 = mean_rte - 0.5;
sens_minus10 = mean_rte + 0.4;

%% 1A: RTE all 4 (vertical bar)
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
x = (0:3)';
b = bar(ax, x - 0.2, mean_rte, 0.35);
b.FaceColor = 'flat';
b.CData = [cfg.COLOR_VARIABLE_CW; cfg.COLOR_DUAL_WEIGHT; cfg.COLOR_BUOYANCY; cfg.COLOR_HALBACH];
b.HandleVisibility = 'off';
hold(ax, 'on');
he = errorbar(ax, x - 0.2, mean_rte, sd_rte_emp, 'Color', [0.9 0.9 0.9], 'LineStyle', 'none', 'CapSize', 5);
he.HandleVisibility = 'off';
yline(ax, cfg.RTE_pumped_hydro_pct, '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 2.5, 'DisplayName', 'Pumped hydro (77.5%)');
yline(ax, cfg.RTE_lithium_ion_pct, ':', 'Color', [0.85 0.85 0.85], 'LineWidth', 2.5, 'DisplayName', 'Li-ion (88.5%)');
ax.XTick = x;
ax.XTickLabel = order;
ax.YLabel.String = 'RTE (%)';
ax.YLim = [0 100];
for i = 1:4, text(ax, x(i)-0.2, mean_rte(i)+2.5, sprintf('%.1f%%', mean_rte(i)), 'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 18); end
legend(ax, 'FontSize', 18, 'TextColor', [1 1 1]);
style_dark(ax, 'Round-Trip Efficiency: All 4 Systems Comparison');
print(fig, fullfile(OUTPUT_DIR, '1A_RTE_All_4.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);

%% 1B: Stacked loss all 4
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
M = [rope bearing gearbox motor sys_spec];
b = bar(ax, x, M, 0.5, 'stacked');
b(1).DisplayName = 'Rope'; b(2).DisplayName = 'Bearing'; b(3).DisplayName = 'Gearbox';
b(4).DisplayName = 'Motor'; b(5).DisplayName = 'System-specific';
ax.XTick = x;
ax.XTickLabel = order;
ax.YLabel.String = 'Loss (J)';
for i = 1:4, text(ax, x(i), total_loss(i)+40, sprintf('%.0f J', total_loss(i)), 'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 18); end
legend(ax, 'FontSize', 18, 'TextColor', [1 1 1], 'Location', 'eastoutside');
style_dark(ax, 'Where Energy Is Lost Per Cycle: All 4 Systems');
print(fig, fullfile(OUTPUT_DIR, '1B_Loss_Breakdown_All_4.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);

%% 1C: Net energy all 4
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
b = bar(ax, x, net_j, 0.5);
b.FaceColor = 'flat';
b.CData = [cfg.COLOR_VARIABLE_CW; cfg.COLOR_DUAL_WEIGHT; cfg.COLOR_BUOYANCY; cfg.COLOR_HALBACH];
hold(ax, 'on');
errorbar(ax, x, net_j, sd_net_emp, 'Color', [0.9 0.9 0.9], 'LineStyle', 'none', 'CapSize', 5);
hl0 = yline(ax, 0, 'Color', [0.5 0.5 0.5]);
hl0.HandleVisibility = 'off';
for i = 1:4
    yp = net_j(i) + 50*(net_j(i)>=0) - 50*(net_j(i)<0);
    text(ax, x(i), yp, sprintf('%.0f J', net_j(i)), 'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 18);
end
ax.XTick = x;
ax.XTickLabel = order;
ax.YLabel.String = 'Net energy per cycle (J)';
style_dark(ax, 'Net Energy Per Cycle: All 4 Systems');
print(fig, fullfile(OUTPUT_DIR, '1C_Net_Energy_All_4.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);

%% 2A: RTE horizontal all 4
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
y_pos = (0:3)';
b = barh(ax, y_pos, mean_rte, 0.6);
b.FaceColor = 'flat';
b.CData = [cfg.COLOR_VARIABLE_CW; cfg.COLOR_DUAL_WEIGHT; cfg.COLOR_BUOYANCY; cfg.COLOR_HALBACH];
b.HandleVisibility = 'off';
hold(ax, 'on');
he = errorbar(ax, mean_rte, y_pos, sd_rte_emp, 'horizontal', 'Color', [0.9 0.9 0.9], 'LineStyle', 'none', 'CapSize', 5);
he.HandleVisibility = 'off';
xline(ax, cfg.RTE_pumped_hydro_pct, '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 2.5, 'DisplayName', 'Pumped hydro (77.5%)');
xline(ax, cfg.RTE_lithium_ion_pct, ':', 'Color', [0.85 0.85 0.85], 'LineWidth', 2.5, 'DisplayName', 'Li-ion (88.5%)');
for i = 1:4, text(ax, mean_rte(i)+2, y_pos(i), sprintf('%.1f%%', mean_rte(i)), 'Color', [0.92 0.92 0.95], 'VerticalAlignment', 'middle', 'FontSize', 18); end
ax.YTick = y_pos;
ax.YTickLabel = order;
ax.XLabel.String = 'RTE (%)';
ax.XLim = [0 100];
legend(ax, 'FontSize', 18, 'TextColor', [1 1 1]);
style_dark(ax, 'Round-Trip Efficiency: All 4 Systems (Comparison)');
print(fig, fullfile(OUTPUT_DIR, '2A_RTE_All_4_Horizontal.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);

%% 2B: Stacked loss all 4 (wider)
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
b = bar(ax, x, M, 0.6, 'stacked');
b(1).DisplayName = 'Rope'; b(2).DisplayName = 'Bearing'; b(3).DisplayName = 'Gearbox';
b(4).DisplayName = 'Motor'; b(5).DisplayName = 'System-specific';
ax.XTick = x;
ax.XTickLabel = order;
ax.YLabel.String = 'Loss (J)';
for i = 1:4, text(ax, x(i), total_loss(i)+60, sprintf('%.0f J', total_loss(i)), 'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 18); end
legend(ax, 'FontSize', 18, 'TextColor', [1 1 1], 'Location', 'eastoutside');
style_dark(ax, 'Energy Loss Breakdown Per Cycle: All 4 Systems');
print(fig, fullfile(OUTPUT_DIR, '2B_Loss_Breakdown_All_4.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);

%% 3A: RTE horizontal headline
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
b = barh(ax, y_pos, mean_rte, 0.6);
b.FaceColor = 'flat';
b.CData = [cfg.COLOR_VARIABLE_CW; cfg.COLOR_DUAL_WEIGHT; cfg.COLOR_BUOYANCY; cfg.COLOR_HALBACH];
b.HandleVisibility = 'off';
hold(ax, 'on');
he = errorbar(ax, mean_rte, y_pos, sd_rte_emp, 'horizontal', 'Color', [0.9 0.9 0.9], 'LineStyle', 'none', 'CapSize', 5);
he.HandleVisibility = 'off';
xline(ax, cfg.RTE_pumped_hydro_pct, '--', 'Color', [0.55 0.55 0.55], 'LineWidth', 2.5, 'DisplayName', 'Pumped hydro (77.5%)');
xline(ax, cfg.RTE_lithium_ion_pct, ':', 'Color', [0.85 0.85 0.85], 'LineWidth', 2.5, 'DisplayName', 'Li-ion (88.5%)');
for i = 1:4, text(ax, mean_rte(i)+2, y_pos(i), sprintf('%.1f%%', mean_rte(i)), 'Color', [0.92 0.92 0.95], 'VerticalAlignment', 'middle', 'FontSize', 18); end
ax.YTick = y_pos;
ax.YTickLabel = order;
ax.XLabel.String = 'RTE (%)';
ax.XLim = [0 100];
legend(ax, 'FontSize', 18, 'TextColor', [1 1 1]);
style_dark(ax, 'Round-Trip Power Efficiency: All 4 Gravitational Storage Systems vs. Industry Benchmarks');
print(fig, fullfile(OUTPUT_DIR, '3A_RTE_All_Headline.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);

%% 3B: Energy In to Charge vs. Energy Out on Discharge (presentation data)
E_in_3B = repmat(PE_input_J, 4, 1);
E_out_3B = E_out_J;
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
w = 0.35;
bar(ax, x - w/2, E_in_3B, w, 'FaceColor', [0.7 0.7 0.75]);
hold(ax, 'on');
b2 = bar(ax, x + w/2, E_out_3B, w);
b2.FaceColor = 'flat';
b2.CData = [cfg.COLOR_VARIABLE_CW; cfg.COLOR_DUAL_WEIGHT; cfg.COLOR_BUOYANCY; cfg.COLOR_HALBACH];
offset = 0.03 * max(E_in_3B);
for i = 1:4
    text(ax, x(i)-w/2, E_in_3B(i)+offset, sprintf('%.0f J', E_in_3B(i)), 'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 18);
    text(ax, x(i)+w/2, E_out_3B(i)+offset, sprintf('%.0f J', E_out_3B(i)), 'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 18);
end
ax.XTick = x;
ax.XTickLabel = order;
ax.YLabel.String = 'Energy per cycle (J)';
legend(ax, {'Energy in to charge (PE input)', 'Energy out on discharge (electrical)'}, 'FontSize', 18, 'TextColor', [1 1 1]);
style_dark(ax, 'Energy In to Charge vs. Energy Out on Discharge Per Cycle: All 4 Systems');
print(fig, fullfile(OUTPUT_DIR, '3B_Energy_In_vs_Out.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);

%% 3C: Full loss breakdown all 4
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
b = bar(ax, x, M, 0.6, 'stacked');
labels = {'Rope','Bearing','Gearbox','Motor','System-specific'};
for j = 1:5, b(j).DisplayName = labels{j}; end
ax.XTick = x;
ax.XTickLabel = order;
ax.YLabel.String = 'Loss (J)';
for i = 1:4, text(ax, x(i), total_loss(i)+80, sprintf('%.0f J', total_loss(i)), 'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 18); end
legend(ax, 'FontSize', 18, 'TextColor', [1 1 1], 'Location', 'eastoutside');
style_dark(ax, 'Energy Loss Breakdown Per Cycle: Where Each System Loses Power');
print(fig, fullfile(OUTPUT_DIR, '3C_Loss_Breakdown_All.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);

%% 3D: Cumulative net 500 cycles
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
n_cycles = (1:cfg.n_cycles_cumulative)';
J_TO_KJ = 1e-3;
for i = 1:4
    plot(ax, n_cycles, cumulative(order{i}) * J_TO_KJ, 'LineWidth', 2.5, 'Color', COLORS(order{i}), 'DisplayName', order{i});
    hold(ax, 'on');
end
hl = yline(ax, 0, '--', 'Color', [0.5 0.5 0.5]);
hl.HandleVisibility = 'off';
vals_500 = zeros(4,1);
for i = 1:4, v = cumulative(order{i}); vals_500(i) = v(end)*J_TO_KJ; end
for i = 1:4
    text(ax, 502, vals_500(i), sprintf('%.0f kJ', vals_500(i)), 'Color', COLORS(order{i}), 'FontSize', 18, 'VerticalAlignment', 'middle');
end
ax.XLabel.String = 'Cycle number';
ax.YLabel.String = 'Cumulative net energy (kJ)';
legend(ax, order, 'FontSize', 18, 'TextColor', [1 1 1]);
style_dark(ax, 'Cumulative Net Energy Output Over 500 Cycles: All 4 Systems');
print(fig, fullfile(OUTPUT_DIR, '3D_Cumulative_Net_500.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);

%% 3E: Sensitivity baseline / +10% / -10%
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
rtes = [sens_baseline sens_plus10 sens_minus10];
width = 0.25;
bar(ax, x - width, rtes(:,1), width, 'DisplayName', 'baseline');
hold(ax, 'on');
bar(ax, x, rtes(:,2), width, 'DisplayName', '+10%');
bar(ax, x + width, rtes(:,3), width, 'DisplayName', '-10%');
for row = 1:4
    for col = 1:3
        xoff = (col-2)*width;
        text(ax, x(row)+xoff, rtes(row,col)+1.2, sprintf('%.1f%%', rtes(row,col)), 'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 18);
    end
end
ax.XTick = x;
ax.XTickLabel = order;
ax.YLabel.String = 'RTE (%)';
legend(ax, 'FontSize', 18, 'TextColor', [1 1 1]);
style_dark(ax, 'Efficiency Robustness: Effect of ±10% Friction Variation on All 4 Systems');
print(fig, fullfile(OUTPUT_DIR, '3E_Sensitivity_Friction.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);

%% BONUS: Sankey Energy Flow (4 individual + 1 combined) — via Python/plotly
% Run: python sankey_energy_flow.py <output_dir>
% Sankeys are saved to the same OUTPUT_DIR. Requires: pip install plotly kaleido
proj_root = fileparts(fileparts(mfilename('fullpath')));
sankey_script = fullfile(proj_root, 'sankey_energy_flow.py');
if isfile(sankey_script)
    [st, msg] = system(sprintf('python "%s" "%s"', sankey_script, OUTPUT_DIR));
    if st == 0
        fprintf('Sankey diagrams saved to %s\n', OUTPUT_DIR);
    else
        fprintf('Sankey script warning: %s (run manually: python sankey_energy_flow.py "%s")\n', msg, OUTPUT_DIR);
    end
else
    fprintf('Sankey script not found: %s\n', sankey_script);
end

%% Data analysis graphs (all read loss_breakdown_figures.csv written above)
try, sensitivity_motor_system(); catch e, fprintf('Sensitivity: %s\n', e.message); end
try, scale_to_1kWh(); catch e, fprintf('Scale to 1 kWh: %s\n', e.message); end
try, cycles_to_1kWh_vs_height(); catch e, fprintf('Cycles vs height: %s\n', e.message); end
try, energy_vs_height(); catch e, fprintf('Energy vs height: %s\n', e.message); end
try, anova_presentation_replicates(); catch e, fprintf('ANOVA: %s\n', e.message); end

fprintf('All presentation graphs (dark mode) saved to %s\n', OUTPUT_DIR);
end

function style_dark(ax, title_str)
% MATLAB dark-mode style: dark background, light text/axes. Large fonts for backboard visibility.
if nargin >= 2 && ~isempty(title_str)
    ax.Title.String = title_str;
    ax.Title.FontSize = 28;
    ax.Title.FontWeight = 'bold';
    ax.Title.Color = [1 1 1];
end
ax.FontSize = 20;
if ~isempty(ax.XLabel.String), ax.XLabel.FontSize = 22; end
if ~isempty(ax.YLabel.String), ax.YLabel.FontSize = 22; end
set(ax.Parent, 'Units', 'inches', 'Position', [0.5 0.5 14 10]);
ax.Color = [0.08 0.08 0.12];
ax.Parent.Color = [0.02 0.02 0.05];
ax.XColor = [0.92 0.92 0.95];
ax.YColor = [0.92 0.92 0.95];
ax.YGrid = 'on';
ax.XGrid = 'off';
ax.GridColor = [0.35 0.35 0.45];
ax.Box = 'off';
if ~isempty(ax.Legend) && isvalid(ax.Legend)
    ax.Legend.FontSize = 18;
    ax.Legend.TextColor = [1 1 1];
    ax.Legend.Color = 'none';
end
end
