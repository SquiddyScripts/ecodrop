function cycles_to_1kWh_vs_height()
% cycles_to_1kWh_vs_height
%   Plot: "Cycles to 1 kWh vs. Drop Height: How Hard Each System Has to Work"
%   X-axis: drop height (m), 3–100 m
%   Y-axis: number of discharge cycles needed to deliver 1 kWh
%
%   Uses presentation-mode RTE values from loss_breakdown_figures.csv and
%   the common mass m = 50 kg. For each system:
%       E_out_per_cycle(h) = RTE * m * g * h
%       cycles(h)          = 1 kWh / E_out_per_cycle(h)

cfg = config();
outDir = fullfile(fileparts(mfilename('fullpath')), 'outputs');
csvPath = fullfile(outDir, 'loss_breakdown_figures.csv');
if ~isfile(csvPath)
    error('cycles_to_1kWh_vs_height:missingCSV', ...
        'File not found: %s. Run run_presentation_plots_dark first.', csvPath);
end

T = readtable(csvPath);
names = T.System;
eta   = T.RTE_pct / 100.0;  % RTE as fraction

% Common assumptions
m = cfg.m_primary;   % 50 kg
g = cfg.g;           % 9.81 m/s^2
heights = linspace(3, 50, 100);   % metres (3 m to 50 m for readability)

E_target = 3.6e6;    % 1 kWh in J

cycles = zeros(length(names), numel(heights));
for i = 1:length(names)
    E_out_per_cycle = eta(i) * m * g * heights;   % J per cycle
    cycles(i,:) = E_target ./ E_out_per_cycle;
end

% Plot
fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
hold(ax, 'on');

COLORS = containers.Map(...
    {'Dual Weight', 'Variable CW', 'Buoyancy', 'Halbach Array'}, ...
    {cfg.COLOR_DUAL_WEIGHT, cfg.COLOR_VARIABLE_CW, cfg.COLOR_BUOYANCY, cfg.COLOR_HALBACH});

% Engineering wall heights for storage systems (m)
wall_buoy = 15.0;      % Buoyancy comfortable up to ~15 m
wall_halb = 10.0;      % Halbach array comfortable up to ~10 m

for i = 1:length(names)
    name = names{i};
    c = COLORS(name);

    if strcmp(name, 'Buoyancy') || strcmp(name, 'Halbach Array')
        % Solid up to system-specific wall, dashed beyond ("engineering wall")
        if strcmp(name, 'Buoyancy')
            wall_h = wall_buoy;
        else
            wall_h = wall_halb;
        end

        h_solid_mask = heights <= wall_h;
        h_dash_mask  = heights > wall_h;
        h_solid = heights(h_solid_mask);
        h_dash  = heights(h_dash_mask);
        c_solid = cycles(i, h_solid_mask);
        c_dash  = cycles(i, h_dash_mask);

        plot(ax, h_solid, c_solid, '-', 'Color', c, 'LineWidth', 2.5, ...
            'DisplayName', name);
        plot(ax, h_dash,  c_dash,  '--', 'Color', c, 'LineWidth', 2.5, ...
            'HandleVisibility', 'off');
    else
        % Regenerative systems: full solid line
        plot(ax, heights, cycles(i,:), '-', 'Color', c, 'LineWidth', 2.5, ...
            'DisplayName', name);
    end
end

% Axis labels and title
xlabel(ax, 'Drop height (m)');
ylabel(ax, 'Cycles needed to deliver 1 kWh');
title(ax, 'Cycles to 1 kWh vs. Drop Height: How Hard Each System Has to Work');
legend(ax, 'Location', 'northeast');

% Dark styling consistent with other MATLAB figures
set(ax, 'FontSize', 14, ...
    'XColor', [0.92 0.92 0.95], 'YColor', [0.92 0.92 0.95], ...
    'YGrid', 'on', 'XGrid', 'off', 'GridColor', [0.35 0.35 0.45], ...
    'Box', 'off');
ax.Parent.Color = [0.02 0.02 0.05];

outPath = fullfile(outDir, 'Cycles_to_1kWh_vs_Height.png');
print(fig, outPath, '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
fprintf('Saved cycles-to-1kWh-vs-height plot to %s\n', outPath);
end

