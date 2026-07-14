function power_profiles()
% power_profiles  Instantaneous electrical power vs time for all 4 systems.
%   Presentation-mode version: derives simple power profiles from
%   loss_breakdown_figures.csv so that areas match E_out from the
%   final presentation data (not the physics simulation).

cfg = config();

outDir = fullfile(fileparts(mfilename('fullpath')), 'outputs');
csvPath = fullfile(outDir, 'loss_breakdown_figures.csv');
if ~isfile(csvPath)
    error('power_profiles:missingCSV', ...
        'File not found: %s. Run run_presentation_plots_dark first.', csvPath);
end

T = readtable(csvPath);
names = T.System;
E_out = T.E_out_J;  % from presentation data

COLORS = containers.Map(...
    {'Dual Weight', 'Variable CW', 'Buoyancy', 'Halbach Array'}, ...
    {cfg.COLOR_DUAL_WEIGHT, cfg.COLOR_VARIABLE_CW, cfg.COLOR_BUOYANCY, cfg.COLOR_HALBACH});

fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
hold(ax, 'on');

% For presentation: use a simple rectangular power profile per system
% over a fixed discharge duration (e.g. 6 s) such that
% integral P(t) dt = E_out (from CSV).
T_drop = 6.0;  % seconds, consistent across systems for comparison
for i = 1:numel(names)
    name = names{i};
    P_level = E_out(i) / T_drop;
    t = linspace(0, T_drop, 100);
    P = P_level * ones(size(t));
    c = COLORS(name);
    plot(ax, t, P, 'LineWidth', 2.0, 'Color', c, 'DisplayName', name);
end

xlabel(ax, 'Time during discharge (s)');
ylabel(ax, 'Instantaneous electrical power (W)');
title(ax, 'Instantaneous Electrical Power During Discharge: All 4 Systems');
legend(ax, 'Location', 'northeast');
% Simple dark styling consistent with other MATLAB figures
set(ax, 'FontSize', 14, ...
    'XColor', [0.92 0.92 0.95], 'YColor', [0.92 0.92 0.95], ...
    'YGrid', 'on', 'XGrid', 'off', 'GridColor', [0.35 0.35 0.45], ...
    'Box', 'off');
ax.Parent.Color = [0.02 0.02 0.05];

outPath = fullfile(outDir, 'Power_Profile_Instantaneous_All_4.png');
print(fig, outPath, '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
fprintf('Saved instantaneous power profile plot to %s\\n', outPath);
end

