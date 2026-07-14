function energy_vs_height()
% energy_vs_height
%   Plot: "Energy Delivered Per Cycle vs. Drop Height: How Each System Scales"
%   X-axis: drop height (m), 3–100 m
%   Y-axis: energy delivered per cycle (kWh), using presentation RTE values.
%
%   E_out(h) = RTE * m * g * h
%   RTE comes from loss_breakdown_figures.csv (presentation mode),
%   m = 50 kg, g from config().

cfg = config();
outDir = fullfile(fileparts(mfilename('fullpath')), 'outputs');
csvPath = fullfile(outDir, 'loss_breakdown_figures.csv');
if ~isfile(csvPath)
    error('energy_vs_height:missingCSV', ...
        'File not found: %s. Run run_presentation_plots_dark first.', csvPath);
end

T = readtable(csvPath);
names = T.System;
eta = T.RTE_pct / 100.0;  % RTE as fraction

% Common assumptions
m = cfg.m_primary;   % 50 kg
g = cfg.g;           % 9.81 m/s^2
heights = linspace(3, 100, 100);   % metres
J_to_kWh = 1 / 3.6e6;

E_kWh = zeros(length(names), numel(heights));
for i = 1:length(names)
    E_kWh(i,:) = eta(i) * m * g * heights * J_to_kWh;
end

% Plot
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
hold(ax, 'on');

COLORS = containers.Map(...
    {'Dual Weight', 'Variable CW', 'Buoyancy', 'Halbach Array'}, ...
    {cfg.COLOR_DUAL_WEIGHT, cfg.COLOR_VARIABLE_CW, cfg.COLOR_BUOYANCY, cfg.COLOR_HALBACH});

% Engineering wall height for storage systems (m)
wall_h = 15.0;

for i = 1:length(names)
    name = names{i};
    c = COLORS(name);

    if strcmp(name, 'Buoyancy') || strcmp(name, 'Halbach Array')
        % Solid up to wall_h, dashed beyond ("engineering wall")
        h_solid = heights(heights <= wall_h);
        h_dash  = heights(heights > wall_h);
        E_solid = E_kWh(i, heights <= wall_h);
        E_dash  = E_kWh(i, heights > wall_h);

        plot(ax, h_solid, E_solid, '-', 'Color', c, 'LineWidth', 2.5, ...
            'DisplayName', name);
        plot(ax, h_dash,  E_dash,  '--', 'Color', c, 'LineWidth', 2.5, ...
            'HandleVisibility', 'off');
    else
        % Regenerative systems: full solid line
        plot(ax, heights, E_kWh(i,:), '-', 'Color', c, 'LineWidth', 2.5, ...
            'DisplayName', name);
    end
end

% Axis labels and title
xlabel(ax, 'Drop height (m)');
ylabel(ax, 'Energy delivered per cycle (kWh)');
title(ax, 'Energy Delivered Per Cycle vs. Drop Height: How Each System Scales');
legend(ax, 'Location', 'northwest');

% Add annotation for engineering wall
yl = ylim(ax);
plot(ax, [wall_h wall_h], yl, ':', 'Color', [0.7 0.7 0.7], 'LineWidth', 1.5, ...
    'HandleVisibility', 'off');
text(ax, wall_h + 1, yl(2)*0.75, ...
    'Engineering wall: redesign required beyond this height', ...
    'Color', [0.92 0.92 0.95], 'FontSize', 11);

% Dark styling consistent with other MATLAB figures
set(ax, 'FontSize', 14, ...
    'XColor', [0.92 0.92 0.95], 'YColor', [0.92 0.92 0.95], ...
    'YGrid', 'on', 'XGrid', 'off', 'GridColor', [0.35 0.35 0.45], ...
    'Box', 'off');
ax.Parent.Color = [0.02 0.02 0.05];

outPath = fullfile(outDir, 'Energy_vs_Height_Eout_per_Cycle.png');
print(fig, outPath, '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
fprintf('Saved energy-vs-height plot to %s\n', outPath);
end

