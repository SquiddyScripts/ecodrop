% PLOT_FIGURE4_CYCLES_VS_HEIGHT  Cycles to deliver 1 kWh vs drop height (3-50 m, 50 kg).
% Fig 4 style: Variable CW, Dual Weight, Buoyancy (dashed >~15 m), Halbach (dashed >~10 m).
% Includes a clear visual start at 3 m (vertical line + tick + note).
% Run: setup_path then plot_figure4_cycles_vs_height

function plot_figure4_cycles_vs_height()

script_dir = fileparts(mfilename('fullpath'));
out_dir = fullfile(script_dir, '..', 'output');
if ~isfolder(out_dir), mkdir(out_dir); end

m = 50;
g = 9.81;
kWh_J = 3.6e6;
H = linspace(3, 50, 400);

% Discharge efficiency (same as your Results slide) scales electrical out vs m*g*H
eff = [0.77, 0.60, 0.395, 0.27];
names = {'Variable CW', 'Dual Weight', 'Buoyancy', 'Halbach Array'};
C = [0.58 0.40 0.74; 0.25 0.47 0.85; 0.85 0.37 0.01; 0.0 0.55 0.45];

% Cycles to deliver 1 kWh: N = (1 kWh in J) / (electrical energy per cycle)
Egen = @(H, e) e * m * g * H;
Ncyc = @(H, e) kWh_J ./ Egen(H, e);

% Engineering limits (dashed beyond)
H_lim_buoy = 15;
H_lim_halb = 10;

%% Figure
fs_title = 18;
fs_label = 16;
fs_tick  = 14;
fs_note  = 12;
fs_start = 11;

fig = figure('Color', 'w', 'Position', [80 60 900 560], 'Name', 'Fig 4 Cycles vs height');

hold on;
for i = 1:4
    y = Ncyc(H, eff(i));
    switch i
        case 3 % Buoyancy
            idx_s = H <= H_lim_buoy;
            plot(H(idx_s), y(idx_s), '-', 'Color', C(i,:), 'LineWidth', 2.2);
            idx_d = H >= H_lim_buoy;
            plot(H(idx_d), y(idx_d), '--', 'Color', C(i,:), 'LineWidth', 2.2);
        case 4 % Halbach
            idx_s = H <= H_lim_halb;
            plot(H(idx_s), y(idx_s), '-', 'Color', C(i,:), 'LineWidth', 2.2);
            idx_d = H >= H_lim_halb;
            plot(H(idx_d), y(idx_d), '--', 'Color', C(i,:), 'LineWidth', 2.2);
        otherwise
            plot(H, y, '-', 'Color', C(i,:), 'LineWidth', 2.2);
    end
end
hold off;

ax = gca;
grid(ax, 'on');
set(ax, 'FontSize', fs_tick, 'LineWidth', 1.2, 'Box', 'on');
xlabel('Drop height (m)', 'FontSize', fs_label, 'FontWeight', 'bold');
ylabel('Cycles required to deliver 1 kWh', 'FontSize', fs_label, 'FontWeight', 'bold');
title({'Fig 4 — Cycles required to deliver 1 kWh vs. drop height'; ...
       'all 4 systems at 50 kg mass, 3–50 m'}, 'FontSize', fs_title, 'FontWeight', 'bold');

% --- Start at 3 m: tick + vertical line + shaded 0–3 m (not modeled) + label ---
xlim([0 50]);
ylim auto;
yl = ylim;
hp = patch([0 3 3 0], [yl(1) yl(1) yl(2) yl(2)], [0.88 0.90 0.95], ...
    'EdgeColor', 'none', 'FaceAlpha', 0.45);
uistack(hp, 'bottom');
% Vertical line at first modeled height (3 m)
line([3 3], yl, 'Color', [0.1 0.1 0.1], 'LineWidth', 2.2, 'Clipping', 'off');
% Ticks include 3 so the axis explicitly shows where data begin
xt_vals = [0 3 5:5:50];
xt_lbl = arrayfun(@num2str, xt_vals, 'UniformOutput', false);
set(ax, 'XTick', xt_vals, 'XTickLabel', xt_lbl);

text(1.5, yl(1) + 0.02*(yl(2)-yl(1)), 'Below 3 m: not modeled', ...
    'FontSize', fs_start-1, 'FontWeight', 'bold', 'Color', [0.35 0.35 0.45], ...
    'HorizontalAlignment', 'center');
text(3.4, yl(2)*0.93, {'Data start'; '3 m'}, ...
    'FontSize', fs_start, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05], ...
    'VerticalAlignment', 'top');

% Annotation block (similar to your slide)
note = sprintf(['Buoyancy shown dashed beyond ~%d m and Halbach Array beyond ~%d m — ', ...
    'fundamental machine redesign required at greater heights. ', ...
    'Variable CW and Dual Weight scale naturally with shaft height and are shown solid through 50 m. ', ...
    '50 kg system mass.'], H_lim_buoy, H_lim_halb);
text(0.02, 0.98, note, 'Units', 'normalized', 'FontSize', fs_note, ...
    'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', ...
    'BackgroundColor', [1 1 1 0.85], 'EdgeColor', [0.7 0.7 0.7], 'Margin', 4);

% Legend (include dashed meaning)
lg = legend(names, 'Location', 'eastoutside', 'FontSize', fs_tick);
% Add second line for dashed convention via title or separate text
annotation(fig, 'textbox', [0.72 0.12 0.26 0.08], 'String', ...
    {'Dashed = beyond engineering limit'}, 'EdgeColor', 'k', ...
    'FontSize', fs_note-1, 'FitBoxToText', 'on', 'BackgroundColor', [1 1 1]);

print(fig, fullfile(out_dir, 'figure4_cycles_to_1kWh_vs_height.png'), '-dpng', '-r300');
fprintf('Saved: %s\n', fullfile(out_dir, 'figure4_cycles_to_1kWh_vs_height.png'));

end
