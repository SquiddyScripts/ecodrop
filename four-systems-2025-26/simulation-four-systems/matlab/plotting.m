function plotting(fcn, varargin)
% plotting  EcoDrop Gravity Battery — All graph sets (1A–3E).
%   plotting('plot_all', data, summary_df);
%   Or call individual: plotting('plot_1a_rte_dual_vs_variable', summary_df);
%   plotting('plot_3d_cumulative_net'); plotting('plot_3e_sensitivity');
%   plotting('plot_3b_p_mech_vs_p_elec', data);

cfg = config();
OUTPUT_DIR = fullfile(fileparts(mfilename('fullpath')), 'outputs');
if ~exist(OUTPUT_DIR, 'dir'), mkdir(OUTPUT_DIR); end

COLORS = containers.Map(...
    {'Dual Weight', 'Variable CW', 'Buoyancy', 'Halbach Array'}, ...
    {cfg.COLOR_DUAL_WEIGHT, cfg.COLOR_VARIABLE_CW, cfg.COLOR_BUOYANCY, cfg.COLOR_HALBACH});

if nargin < 1, fcn = 'plot_all'; end

switch fcn
    case 'plot_all'
        data = varargin{1};
        summary_df = varargin{2};
        plot_1a_rte_dual_vs_variable(summary_df, OUTPUT_DIR, cfg, COLORS);
        plot_1b_stacked_loss_dual_variable(summary_df, OUTPUT_DIR, cfg, COLORS);
        plot_1c_net_energy_dual_variable(summary_df, OUTPUT_DIR, cfg, COLORS);
        plot_2a_rte_buoyancy_vs_halbach(summary_df, OUTPUT_DIR, cfg, COLORS);
        plot_2b_stacked_loss_buoyancy_halbach(summary_df, OUTPUT_DIR, cfg, COLORS);
        plot_3a_rte_all_four(summary_df, OUTPUT_DIR, cfg, COLORS);
        plot_3b_p_mech_vs_p_elec(data, OUTPUT_DIR, cfg, COLORS);
        plot_3c_full_loss_breakdown(summary_df, OUTPUT_DIR, cfg, COLORS);
        plot_3d_cumulative_net(OUTPUT_DIR, cfg, COLORS);
        plot_3e_sensitivity(OUTPUT_DIR, cfg, COLORS);
    case 'plot_1a_rte_dual_vs_variable'
        plot_1a_rte_dual_vs_variable(varargin{1}, OUTPUT_DIR, cfg, COLORS);
    case 'plot_1b_stacked_loss_dual_variable'
        plot_1b_stacked_loss_dual_variable(varargin{1}, OUTPUT_DIR, cfg, COLORS);
    case 'plot_1c_net_energy_dual_variable'
        plot_1c_net_energy_dual_variable(varargin{1}, OUTPUT_DIR, cfg, COLORS);
    case 'plot_2a_rte_buoyancy_vs_halbach'
        plot_2a_rte_buoyancy_vs_halbach(varargin{1}, OUTPUT_DIR, cfg, COLORS);
    case 'plot_2b_stacked_loss_buoyancy_halbach'
        plot_2b_stacked_loss_buoyancy_halbach(varargin{1}, OUTPUT_DIR, cfg, COLORS);
    case 'plot_3a_rte_all_four'
        plot_3a_rte_all_four(varargin{1}, OUTPUT_DIR, cfg, COLORS);
    case 'plot_3b_p_mech_vs_p_elec'
        plot_3b_p_mech_vs_p_elec(varargin{1}, OUTPUT_DIR, cfg, COLORS);
    case 'plot_3c_full_loss_breakdown'
        plot_3c_full_loss_breakdown(varargin{1}, OUTPUT_DIR, cfg, COLORS);
    case 'plot_3d_cumulative_net'
        plot_3d_cumulative_net(OUTPUT_DIR, cfg, COLORS);
    case 'plot_3e_sensitivity'
        plot_3e_sensitivity(OUTPUT_DIR, cfg, COLORS);
    otherwise
        error('plotting:unknown', 'Unknown function %s', fcn);
end
end

function style_axes(ax, title_str, cfg)
% Apply consistent dark-mode styling to axes and figure.
if nargin >= 2 && ~isempty(title_str)
    ax.Title.String = title_str;
    ax.Title.FontSize = 18;
    ax.Title.FontWeight = 'bold';
    ax.Title.Color = [1 1 1];
end

ax.FontSize = 14;

% Dark backgrounds
darkFig = [0.02 0.02 0.05];
darkAx  = [0.08 0.08 0.12];
ax.Color = darkAx;
ax.Parent.Color = darkFig;

% Light foreground for readability
ax.XColor = [0.92 0.92 0.95];
ax.YColor = [0.92 0.92 0.95];

% Subtle grid for reference
ax.YGrid = 'on';
ax.XGrid = 'off';
ax.GridColor = [0.35 0.35 0.45];
ax.MinorGridAlpha = 0.3;
ax.Box = 'off';

% If a legend exists, make it readable on dark background
lg = ax.Legend;
if ~isempty(lg) && isvalid(lg)
    lg.TextColor = [1 1 1];
    lg.Color = 'none';
end
end

function plot_1a_rte_dual_vs_variable(summary_df, outDir, cfg, COLORS)
idx = strcmp(summary_df.Category, 'Regenerative');
df = summary_df(idx,:);
if height(df) == 0, return; end
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
x = (0:height(df)-1)';
m = df.('Mean RTE (%)');
s = df.('SD RTE');
clrs = arrayfun(@(i) COLORS(df.System{i}), (1:height(df))', 'UniformOutput', false);
b = bar(ax, x - 0.2, m, 0.35);
b.FaceColor = 'flat';
b.CData = vertcat(clrs{:});
hold(ax, 'on');
errorbar(ax, x - 0.2, m, s, 'k', 'LineStyle', 'none', 'CapSize', 5);
yline(ax, cfg.RTE_pumped_hydro_pct, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 2.5);
yline(ax, cfg.RTE_lithium_ion_pct, ':', 'Color', 'k', 'LineWidth', 2.5);
ax.XTick = x;
ax.XTickLabel = df.System;
ax.YLabel.String = 'RTE (%)';
legend(ax, {'Pumped hydro (77.5%)', 'Li-ion (88.5%)'}, 'FontSize', 12);
style_axes(ax, 'Round-Trip Efficiency: Regenerative Systems Comparison', cfg);
print(fig, fullfile(outDir, '1A_RTE_Regenerative.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
end

function plot_1b_stacked_loss_dual_variable(summary_df, outDir, cfg, COLORS)
idx = strcmp(summary_df.Category, 'Regenerative');
df = summary_df(idx,:);
if height(df) == 0, return; end
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
x = (0:height(df)-1)';
cols = {'Rope Loss (J)', 'Bearing Loss (J)', 'Gearbox Loss (J)', 'Motor Loss (J)', 'System-Specific Loss (J)'};
labels = {'Rope', 'Bearing', 'Gearbox', 'Motor', 'Return energy cost'};
M = zeros(height(df), length(cols));
for j = 1:length(cols), M(:,j) = df.(cols{j}); end
b = bar(ax, x, M, 0.5, 'stacked');
for j = 1:length(b), b(j).DisplayName = labels{j}; end
ax.XTick = x;
ax.XTickLabel = df.System;
ax.YLabel.String = 'Loss (J)';
legend(ax, 'FontSize', 12);
style_axes(ax, 'Where Energy Is Lost Per Cycle: Dual Weight vs. Variable Counterweight', cfg);
print(fig, fullfile(outDir, '1B_Loss_Breakdown_Regenerative.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
end

function plot_1c_net_energy_dual_variable(summary_df, outDir, cfg, COLORS)
idx = strcmp(summary_df.Category, 'Regenerative');
df = summary_df(idx,:);
if height(df) == 0, return; end
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
x = (0:height(df)-1)';
m = df.('Net Energy/Cycle (J)');
s = df.('SD Net');
clrs = arrayfun(@(i) COLORS(df.System{i}), (1:height(df))', 'UniformOutput', false);
b = bar(ax, x, m, 0.5);
b.FaceColor = 'flat';
b.CData = vertcat(clrs{:});
hold(ax, 'on');
errorbar(ax, x, m, s, 'k', 'LineStyle', 'none', 'CapSize', 5);
yline(ax, 0, 'Color', [0.5 0.5 0.5]);
ax.XTick = x;
ax.XTickLabel = df.System;
ax.YLabel.String = 'Net energy per cycle (J)';
legend(ax, 'Zero loss (theoretical maximum)', 'FontSize', 12);
style_axes(ax, 'Net Energy Recovery Per Cycle: Dual Weight vs. Variable Counterweight', cfg);
print(fig, fullfile(outDir, '1C_Net_Energy_Regenerative.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
end

function plot_2a_rte_buoyancy_vs_halbach(summary_df, outDir, cfg, COLORS)
idx = strcmp(summary_df.Category, 'Storage');
df = summary_df(idx,:);
if height(df) == 0, return; end
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
x = (0:height(df)-1)';
m = df.('Mean RTE (%)');
s = df.('SD RTE');
clrs = arrayfun(@(i) COLORS(df.System{i}), (1:height(df))', 'UniformOutput', false);
b = bar(ax, x - 0.2, m, 0.35);
b.FaceColor = 'flat';
b.CData = vertcat(clrs{:});
hold(ax, 'on');
errorbar(ax, x - 0.2, m, s, 'k', 'LineStyle', 'none', 'CapSize', 5);
yline(ax, cfg.RTE_pumped_hydro_pct, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 2.5);
yline(ax, cfg.RTE_lithium_ion_pct, ':', 'Color', 'k', 'LineWidth', 2.5);
ax.XTick = x;
ax.XTickLabel = df.System;
ax.YLabel.String = 'RTE (%)';
ax.YLim = [0 100];
legend(ax, {'Pumped hydro (77.5%)', 'Li-ion (88.5%)'}, 'FontSize', 12);
style_axes(ax, 'Round-Trip Efficiency: Storage Systems Comparison', cfg);
print(fig, fullfile(outDir, '2A_RTE_Storage.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
end

function plot_2b_stacked_loss_buoyancy_halbach(summary_df, outDir, cfg, COLORS)
idx = strcmp(summary_df.Category, 'Storage');
df = summary_df(idx,:);
if height(df) == 0, return; end
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
x = (0:height(df)-1)';
cols = {'Rope Loss (J)', 'Bearing Loss (J)', 'Gearbox Loss (J)', 'Motor Loss (J)', 'System-Specific Loss (J)'};
labels = {'Rope', 'Bearing', 'Gearbox', 'Motor', 'Pump / Linear motor / Aux'};
M = zeros(height(df), length(cols));
for j = 1:length(cols), M(:,j) = df.(cols{j}); end
b = bar(ax, x, M, 0.5, 'stacked');
for j = 1:length(b), b(j).DisplayName = labels{j}; end
ax.XTick = x;
ax.XTickLabel = df.System;
ax.YLabel.String = 'Loss (J)';
legend(ax, 'FontSize', 12);
style_axes(ax, 'Where Energy Is Lost Per Cycle: Buoyancy vs. Halbach Array', cfg);
print(fig, fullfile(outDir, '2B_Loss_Breakdown_Storage.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
end

function plot_3a_rte_all_four(summary_df, outDir, cfg, COLORS)
order = {'Variable CW'; 'Dual Weight'; 'Buoyancy'; 'Halbach Array'};
idx = zeros(4,1);
for i = 1:4
    for j = 1:height(summary_df)
        if strcmp(summary_df.System{j}, order{i})
            idx(i) = j;
            break
        end
    end
end
idx = idx(idx > 0);
df = summary_df(idx,:);
if height(df) == 0, return; end
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
y_pos = (0:height(df)-1)';
m = df.('Mean RTE (%)');
s = df.('SD RTE');
clrs = arrayfun(@(i) COLORS(df.System{i}), (1:height(df))', 'UniformOutput', false);
b = barh(ax, y_pos, m, 0.6);
b.FaceColor = 'flat';
b.CData = vertcat(clrs{:});
hold(ax, 'on');
errorbar(ax, m, y_pos, s, 'horizontal', 'k', 'LineStyle', 'none', 'CapSize', 5);
xline(ax, cfg.RTE_pumped_hydro_pct, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 2.5);
xline(ax, cfg.RTE_lithium_ion_pct, ':', 'Color', 'k', 'LineWidth', 2.5);
ax.YTick = y_pos;
ax.YTickLabel = df.System;
ax.XLabel.String = 'RTE (%)';
ax.XLim = [0 100];
legend(ax, {'Pumped hydro (77.5%)', 'Li-ion (88.5%)'}, 'FontSize', 12);
style_axes(ax, 'Round-Trip Power Efficiency: All 4 Gravitational Storage Systems vs. Industry Benchmarks', cfg);
print(fig, fullfile(outDir, '3A_RTE_All_Headline.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
end

function plot_3b_p_mech_vs_p_elec(data, outDir, cfg, COLORS)
all_runs = data.all_runs;
names = cellfun(@(c) c.name, all_runs, 'UniformOutput', false);
mean_E_in = zeros(length(all_runs), 1);
mean_E_out = zeros(length(all_runs), 1);
for i = 1:length(all_runs)
    runs = all_runs{i}.runs;
    mean_E_in(i) = mean(cellfun(@(r) r.E_consumed, runs));
    mean_E_out(i) = mean(cellfun(@(r) r.E_out, runs));
end
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
x = (0:length(names)-1)';
w = 0.35;
bar(ax, x - w/2, mean_E_in, w, 'FaceColor', [0.8 0.8 0.8]);
hold(ax, 'on');
clrs = arrayfun(@(i) COLORS(names{i}), (1:length(names))', 'UniformOutput', false);
b2 = bar(ax, x + w/2, mean_E_out, w);
b2.FaceColor = 'flat';
b2.CData = vertcat(clrs{:});
for i = 1:length(names)
    text(ax, x(i) - w/2, mean_E_in(i) + 0.03*max(mean_E_in), sprintf('%.0f J', mean_E_in(i)), ...
        'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 11);
    text(ax, x(i) + w/2, mean_E_out(i) + 0.03*max(mean_E_in), sprintf('%.0f J', mean_E_out(i)), ...
        'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 11);
end
ax.XTick = x;
ax.XTickLabel = names;
ax.YLabel.String = 'Energy per cycle (J)';
legend(ax, {'Energy in to charge (E_{consumed})', 'Energy out on discharge (E_{out})'}, 'FontSize', 12);
style_axes(ax, 'Energy In to Charge vs. Energy Out on Discharge Per Cycle: All 4 Systems', cfg);
print(fig, fullfile(outDir, '3B_Energy_In_vs_Out.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
end

function plot_3c_full_loss_breakdown(summary_df, outDir, cfg, COLORS)
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
x = (0:height(summary_df)-1)';
cols = {'Rope Loss (J)', 'Bearing Loss (J)', 'Gearbox Loss (J)', 'Motor Loss (J)', 'System-Specific Loss (J)'};
labels = {'Rope', 'Bearing', 'Gearbox', 'Motor', 'System-specific'};
M = zeros(height(summary_df), length(cols));
for j = 1:length(cols), M(:,j) = summary_df.(cols{j}); end
b = bar(ax, x, M, 0.6, 'stacked');
for j = 1:length(b), b(j).DisplayName = labels{j}; end
ax.XTick = x;
ax.XTickLabel = summary_df.System;
ax.YLabel.String = 'Loss (J)';
legend(ax, 'FontSize', 12);
style_axes(ax, 'Energy Loss Breakdown Per Cycle: Where Each System Loses Power', cfg);
print(fig, fullfile(outDir, '3C_Loss_Breakdown_All.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
end

function plot_3d_cumulative_net(outDir, cfg, COLORS)
cum = run_simulation('run_cumulative_net');
n_cycles = (1:cfg.n_cycles_cumulative)';
J_TO_KJ = 1e-3;
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
names_ord = {'Variable CW', 'Dual Weight', 'Buoyancy', 'Halbach Array'};
cum_map = cum.cumulative;
vals_500_kJ = [];
for i = 1:length(names_ord)
    name = names_ord{i};
    if isKey(cum_map, name)
        arr = cum_map(name);
        plot(ax, n_cycles, arr * J_TO_KJ, 'LineWidth', 2.5, 'Color', COLORS(name), 'DisplayName', name);
        hold(ax, 'on');
        vals_500_kJ = [vals_500_kJ; arr(end) * J_TO_KJ];
    end
end
yline(ax, 0, '--', 'Color', [0.5 0.5 0.5]);
if ~isempty(vals_500_kJ)
    gap = max(vals_500_kJ) - min(vals_500_kJ);
    text(ax, 500, min(vals_500_kJ), sprintf('Gap at 500 cycles: %.0f kJ', gap), 'FontSize', 12);
end
ax.XLabel.String = 'Cycle number';
ax.YLabel.String = 'Cumulative net energy (kJ)';
legend(ax, 'FontSize', 12);
style_axes(ax, 'Cumulative Net Energy Output Over 500 Cycles: All 4 Systems', cfg);
print(fig, fullfile(outDir, '3D_Cumulative_Net_500.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
end

function plot_3e_sensitivity(outDir, cfg, COLORS)
sens = run_simulation('run_sensitivity');
names = {'Variable CW', 'Dual Weight', 'Buoyancy', 'Halbach Array'};
conditions = {'baseline', '+10%', '-10%'};
% sens is struct array with fields: system, category, friction, RTE_pct, net_energy
rtes = zeros(length(names), 3); % columns: baseline, +10%, -10%
for i = 1:length(names)
    for j = 1:3
        cond = conditions{j};
        for k = 1:length(sens)
            if strcmp(sens(k).system, names{i}) && strcmp(sens(k).friction, cond)
                rtes(i, j) = sens(k).RTE_pct;
                break
            end
        end
    end
end
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
x = (0:length(names)-1)';
width = 0.25;
bar(ax, x - width, rtes(:,1), width, 'DisplayName', 'baseline');
hold(ax, 'on');
bar(ax, x, rtes(:,2), width, 'DisplayName', '+10%');
bar(ax, x + width, rtes(:,3), width, 'DisplayName', '-10%');
ax.XTick = x;
ax.XTickLabel = names;
ax.YLabel.String = 'RTE (%)';
legend(ax, 'FontSize', 12);
style_axes(ax, 'Efficiency Robustness: Effect of ±10% Friction Variation on All 4 Systems', cfg);
print(fig, fullfile(outDir, '3E_Sensitivity_Friction.png'), '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
end
