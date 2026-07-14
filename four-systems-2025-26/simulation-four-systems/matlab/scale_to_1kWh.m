function scale_to_1kWh()
% scale_to_1kWh  Mass-height requirement to store 1 kWh for each system.
%   Uses RTE values from loss_breakdown_figures.csv to compute m(h).
%
%   E_out_target = 1 kWh = 3.6e6 J.

cfg = config();
outDir = fullfile(fileparts(mfilename('fullpath')), 'outputs');
csvPath = fullfile(outDir, 'loss_breakdown_figures.csv');
if ~isfile(csvPath)
    error('scale_to_1kWh:missingCSV', ...
        'File not found: %s. Run run_presentation_plots_dark first.', csvPath);
end

T = readtable(csvPath);
names = T.System;
eta = T.RTE_pct / 100.0;

E_target = 3.6e6;  % 1 kWh
g = cfg.g;
heights = [10 25 50 75 100];  % metres

fprintf('Mass required to store 1 kWh (delivered)\\n');
fprintf('System        ');
for h = heights
    fprintf('%8dm', h);
end
fprintf('\\n');

mass = zeros(length(names), length(heights));
for i = 1:length(names)
    for j = 1:length(heights)
        h = heights(j);
        mass(i,j) = E_target / (eta(i) * g * h);
    end
    fprintf('%-13s', names{i});
    fprintf('%8.0f', mass(i,:));
    fprintf('\\n');
end

% Plot mass vs height
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
hold(ax, 'on');
COLORS = containers.Map(...
    {'Dual Weight', 'Variable CW', 'Buoyancy', 'Halbach Array'}, ...
    {cfg.COLOR_DUAL_WEIGHT, cfg.COLOR_VARIABLE_CW, cfg.COLOR_BUOYANCY, cfg.COLOR_HALBACH});
for i = 1:length(names)
    c = COLORS(names{i});
    plot(ax, heights, mass(i,:), '-o', 'Color', c, 'LineWidth', 2, 'MarkerSize', 6, ...
        'DisplayName', names{i});
end
xlabel(ax, 'Drop height (m)');
ylabel(ax, 'Mass required for 1 kWh (kg)');
title(ax, 'Mass-Height Requirement to Store 1 kWh (Delivered) for Each System');
legend(ax, 'Location', 'northeast');
% Apply a simple dark-style axis consistent with other figures
set(ax, 'FontSize', 14, ...
    'XColor', [0.92 0.92 0.95], 'YColor', [0.92 0.92 0.95], ...
    'YGrid', 'on', 'XGrid', 'off', 'GridColor', [0.35 0.35 0.45], ...
    'Box', 'off');
ax.Parent.Color = [0.02 0.02 0.05];
outPath = fullfile(outDir, 'Scale_to_1kWh_Mass_vs_Height.png');
print(fig, outPath, '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
fprintf('Saved mass-vs-height plot to %s\\n', outPath);
end

