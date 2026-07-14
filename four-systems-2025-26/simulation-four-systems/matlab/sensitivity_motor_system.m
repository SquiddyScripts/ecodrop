function sensitivity_motor_system()
% sensitivity_motor_system  Robustness of Variable CW vs Dual Weight ranking.
%   Varies motor loss and system-specific loss scaling and compares RTE.
%
%   Reads loss_breakdown_figures.csv from matlab/outputs (presentation losses).

cfg = config();
outDir = fullfile(fileparts(mfilename('fullpath')), 'outputs');
csvPath = fullfile(outDir, 'loss_breakdown_figures.csv');
if ~isfile(csvPath)
    error('sensitivity_motor_system:missingCSV', ...
        'File not found: %s. Run run_presentation_plots_dark first.', csvPath);
end

T = readtable(csvPath);
% Extract Variable CW and Dual Weight rows
vcw = T(strcmp(T.System, 'Variable CW'), :);
dw  = T(strcmp(T.System, 'Dual Weight'), :);
PE  = cfg.PE_input_nominal;

loss_vcw = struct('rope', vcw.Rope_J, 'bearing', vcw.Bearing_J, ...
    'gearbox', vcw.Gearbox_J, 'motor', vcw.Motor_J, 'sys', vcw.System_specific_J);
loss_dw  = struct('rope', dw.Rope_J, 'bearing', dw.Bearing_J, ...
    'gearbox', dw.Gearbox_J, 'motor', dw.Motor_J, 'sys', dw.System_specific_J);

motor_scales = 0.8:0.1:1.2;
sys_scales   = [0.5 0.75 1.0 1.25 1.5];
dm = numel(motor_scales);
ds = numel(sys_scales);
diff_RTE = zeros(ds, dm);  % rows: sys_scale, cols: motor_scale

for im = 1:dm
    km = motor_scales(im);
    for is = 1:ds
        ks = sys_scales(is);
        R_vcw = local_rte(loss_vcw, km, ks, PE);
        R_dw  = local_rte(loss_dw,  km, ks, PE);
        diff_RTE(is, im) = R_vcw - R_dw;
    end
end

fig = figure('Visible', 'off', 'Color', [0.02 0.02 0.05]);
ax = axes(fig);
imagesc(ax, motor_scales, sys_scales, diff_RTE);
set(ax, 'YDir', 'normal');
colorbar(ax);
colormap(ax, parula);
xlabel(ax, 'Motor loss scale (k_m)');
ylabel(ax, 'System-specific loss scale (k_s)');
title(ax, 'RTE Advantage of Variable CW over Dual Weight (R_{VCW} - R_{DW})');

% Add contour where diff = 0 (should not appear if VCW always better)
hold(ax, 'on');
[C, h] = contour(ax, motor_scales, sys_scales, diff_RTE, [0 0], 'k', 'LineWidth', 1.5);
clabel(C, h, 'Color', 'k', 'FontSize', 10);

minDiff = min(diff_RTE(:));
maxDiff = max(diff_RTE(:));
fprintf('Minimum RTE advantage of Variable CW over Dual Weight across grid: %.2f percentage points\\n', minDiff);
fprintf('Maximum RTE advantage across grid: %.2f percentage points\\n', maxDiff);

outPath = fullfile(outDir, 'Sensitivity_VariableCW_vs_DualWeight.png');
print(fig, outPath, '-dpng', ['-r' num2str(cfg.DPI)]);
close(fig);
fprintf('Saved sensitivity heatmap to %s\\n', outPath);
end

function R = local_rte(L, km, ks, PE)
total = L.rope + L.bearing + L.gearbox + km*L.motor + ks*L.sys;
R = 100 * (1 - total / PE);
end

