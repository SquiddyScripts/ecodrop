function plot_3b_energy_in_out_presentation()
% plot_3b_energy_in_out_presentation
%   Presentation-mode 3B graph:
%   "Energy In to Charge vs. Energy Out on Discharge (Per Cycle)"
%
%   Uses loss_breakdown_figures.csv produced by run_presentation_plots_dark,
%   so values match your final RTE / net-energy / loss story exactly.
%   Energy in = PE_input_J (1471.5 J) for all systems.
%   Energy out = E_out_J from CSV.

cfg = config();
outDir = fullfile(fileparts(mfilename('fullpath')), 'outputs');
csvPath = fullfile(outDir, 'loss_breakdown_figures.csv');
if ~isfile(csvPath)
    error('plot_3b_energy_in_out_presentation:missingCSV', ...
        'File not found: %s. Run run_presentation_plots_dark first.', csvPath);
end

T = readtable(csvPath);
names = T.System;
E_in  = T.PE_input_J;   % 1471.5 J for all systems
E_out = T.E_out_J;      % presentation-mode electrical output

fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
x = (0:length(names)-1)';
w = 0.35;

% Colors consistent with other plots
COLORS = containers.Map(...
    {'Dual Weight', 'Variable CW', 'Buoyancy', 'Halbach Array'}, ...
    {cfg.COLOR_DUAL_WEIGHT, cfg.COLOR_VARIABLE_CW, cfg.COLOR_BUOYANCY, cfg.COLOR_HALBACH});

bar(ax, x - w/2, E_in, w, 'FaceColor', [0.8 0.8 0.8]);
hold(ax, 'on');
clrs = arrayfun(@(i) COLORS(names{i}), (1:length(names))', 'UniformOutput', false);
b2 = bar(ax, x + w/2, E_out, w);
b2.FaceColor = 'flat';
b2.CData = vertcat(clrs{:});

% Value labels
offset = 0.03 * max(E_in);
for i = 1:length(names)
    text(ax, x(i) - w/2, E_in(i) + offset, sprintf('%.0f J', E_in(i)), ...
        'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 11);
    text(ax, x(i) + w/2, E_out(i) + offset, sprintf('%.0f J', E_out(i)), ...
        'Color', [0.92 0.92 0.95], 'HorizontalAlignment', 'center', 'FontSize', 11);
end

ax.XTick = x;
ax.XTickLabel = names;
ax.YLabel.String = 'Energy per cycle (J)';
legend(ax, {'Energy in to charge (PE input)', 'Energy out on discharge (electrical)'}, ...
    'FontSize', 12, 'TextColor', [1 1 1]);
title(ax, 'Energy In to Charge vs. Energy Out on Discharge Per Cycle: All 4 Systems');

% Dark styling consistent with other MATLAB figures
set(ax, 'FontSize', 14, ...
    'XColor', [0.92 0.92 0.95], 'YColor', [0.92 0.92 0.95], ...
    'YGrid', 'on', 'XGrid', 'off', 'GridColor', [0.35 0.35 0.45], ...
    'Box', 'off');
ax.Parent.Color = [0.02 0.02 0.05];

outPath = fullfile(outDir, '3B_Energy_In_vs_Out_Presentation.png');
print(fig, outPath, '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
fprintf('Saved presentation 3B Energy In vs Out plot to %s\n', outPath);
end

