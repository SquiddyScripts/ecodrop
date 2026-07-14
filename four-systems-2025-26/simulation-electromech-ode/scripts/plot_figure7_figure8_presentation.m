% PLOT_FIGURE7_FIGURE8_PRESENTATION  Figure 7 and Figure 8 as TWO separate figures (no overlap).
% Figure 7: PE vs energy generated (J). Figure 8: Discharge efficiency (%).
% Readable text: titles/labels slightly emphasized; ticks and bar numbers normal weight.
% Saves: output/figure7_energy_pe_vs_generated.png, output/figure8_discharge_efficiency.png
%
% Run: setup_path, then plot_figure7_figure8_presentation

function plot_figure7_figure8_presentation()

script_dir = fileparts(mfilename('fullpath'));
out_dir = fullfile(script_dir, '..', 'output');
if ~isfolder(out_dir), mkdir(out_dir); end

%% Data
names = {'Variable CW', 'Dual Weight', 'Buoyancy', 'Halbach Array'};
PE_J = 1471.5 * ones(1, 4);
Egen_J = [1133, 883, 581, 397];
eff_pct = [77.0, 60.0, 39.5, 27.0];

C = [0.58 0.40 0.74;
     0.25 0.47 0.85;
     0.85 0.37 0.01;
     0.0  0.55 0.45];

%% Font policy: avoid "everything bold" — bold only on main title
fs_title = 15;
fs_axis  = 13;
fs_tick  = 12;
fs_bar   = 11;
fs_leg   = 11;

%% ========== FIGURE 7 (alone) ==========
fig7 = figure('Color', 'w', 'Position', [120 80 960 640], 'Name', 'Figure 7');
ax = axes(fig7, 'Position', [0.12 0.20 0.80 0.62]);  % room: title, x-label, legend
hold(ax, 'on');
w = 0.32;
x = 1:4;
b0 = bar(ax, x - w/2, PE_J, w, 'FaceColor', [0.55 0.55 0.55], 'EdgeColor', [0.35 0.35 0.35], 'LineWidth', 0.6);
b1 = bar(ax, x + w/2, Egen_J, w, 'FaceColor', 'flat', 'EdgeColor', [0.25 0.25 0.25], 'LineWidth', 0.6);
for k = 1:4, b1.CData(k,:) = C(k,:); end
dy = max(PE_J) * 0.04;
for k = 1:4
    text(ax, x(k)-w/2, PE_J(k)+dy, sprintf('%.1f', PE_J(k)), 'HorizontalAlignment', 'center', ...
        'FontSize', fs_bar, 'FontWeight', 'normal', 'Color', [0.2 0.2 0.2]);
    text(ax, x(k)+w/2, Egen_J(k)+dy, sprintf('%d', Egen_J(k)), 'HorizontalAlignment', 'center', ...
        'FontSize', fs_bar, 'FontWeight', 'normal', 'Color', [0.15 0.15 0.15]);
end
hold(ax, 'off');

ylim(ax, [0 max(PE_J)*1.16]);
grid(ax, 'on'); grid(ax, 'minor');
set(ax, 'XTick', 1:4, 'XTickLabel', names, 'FontSize', fs_tick, 'FontWeight', 'normal', ...
    'LineWidth', 1, 'Box', 'on');
xlabel(ax, 'System', 'FontSize', fs_axis, 'FontWeight', 'normal');
ylabel(ax, 'Energy per cycle (J)', 'FontSize', fs_axis, 'FontWeight', 'normal');
title(ax, 'Figure 7: Gravitational potential energy vs energy generated (each system)', ...
    'FontSize', fs_title, 'FontWeight', 'bold');

lg = legend(ax, [b0 b1], {'Potential energy (J)', 'Energy generated (J)'}, ...
    'Location', 'northeast', 'FontSize', fs_leg, 'FontWeight', 'normal');
set(lg, 'Box', 'on');

% Optional: slight x-label rotation if names ever get longer
set(ax, 'XTickLabelRotation', 0);

out7 = fullfile(out_dir, 'figure7_energy_pe_vs_generated.png');
saveFigPng(fig7, out7);
fprintf('Saved: %s\n', out7);
close(fig7);

%% ========== FIGURE 8 (alone) ==========
% YTick must be strictly increasing (1:4). Using y = [4 3 2 1] makes MATLAB reset ticks to
% 1..4 and drop / mis-pair YTickLabel — you only see numbers 1-4 on the axis.
% Bottom (y=1) = Halbach, top (y=4) = Variable CW — same visual order as before.
fig8 = figure('Color', 'w', 'Position', [140 80 900 620], 'Name', 'Figure 8 - Discharge efficiency');
names_y = {'Halbach Array'; 'Buoyancy'; 'Dual Weight'; 'Variable CW'};  % column cell for YTickLabel
eff_plot = flipud(eff_pct(:));   % [27; 39.5; 60; 77] aligns with names_y
Crows = flipud(C);
% Row 1:4 only — MATLAB rejects non-increasing YTick (e.g. 4:-1:1).
y_bar = 1:4;

ax = axes(fig8, 'Position', [0.22 0.14 0.70 0.68]);
bh = barh(ax, y_bar, eff_plot, 'FaceColor', 'flat', 'EdgeColor', [0.25 0.25 0.25], 'LineWidth', 0.6);
for k = 1:4, bh.CData(k,:) = Crows(k,:); end
hold(ax, 'on');
for k = 1:4
    v = eff_plot(k);
    text(ax, min(v + 2.5, 96), y_bar(k), sprintf('%.1f%%', v), 'VerticalAlignment', 'middle', ...
        'FontSize', fs_bar+1, 'FontWeight', 'normal', 'Color', [0.1 0.1 0.1]);
end
hold(ax, 'off');

set(ax, 'YTick', y_bar, 'YTickLabel', names_y, 'TickLabelInterpreter', 'none', ...
    'FontSize', fs_tick, 'FontWeight', 'normal', 'LineWidth', 1, 'Box', 'on', 'Layer', 'top');
xlabel(ax, 'Discharge efficiency (%)', 'FontSize', fs_axis, 'FontWeight', 'normal');
title(ax, 'Figure 8: Discharge efficiency (each system)', 'FontSize', fs_title, 'FontWeight', 'bold');
xlim(ax, [0 100]);
set(ax, 'XTick', 0:10:100);
grid(ax, 'on'); grid(ax, 'minor');

out8 = fullfile(out_dir, 'figure8_discharge_efficiency.png');
saveFigPng(fig8, out8);
fprintf('Saved: %s\n', out8);
close(fig8);

end

function saveFigPng(fig, pathPng)
if exist('exportgraphics', 'file') == 2
    exportgraphics(fig, pathPng, 'Resolution', 300);
else
    print(fig, pathPng, '-dpng', '-r300');
end
end
