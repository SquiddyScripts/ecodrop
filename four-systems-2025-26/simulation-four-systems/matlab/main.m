% main  EcoDrop Gravity Battery Simulation — Main entry.
%   Runs simulation (10 runs per system), summary table, ANOVA, validation, and all plots.
%   Run from MATLAB with current folder set to matlab/, or addpath the matlab folder and run main.

%% Ensure path includes this directory and systems subfolder
thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);
addpath(fullfile(thisDir, 'systems'));

disp(repmat('=', 1, 60));
disp('EcoDrop Gravity Battery — Simulation Results');
disp(repmat('=', 1, 60));

cfg = config();
data = run_simulation('run_all', cfg);
summary_df = metrics('build_summary_table', data);

% Master Summary Table (console)
disp(' ');
disp('--- Master Summary Table ---');
disp(summary_df);

% Export CSV to matlab/outputs/
outDir = fullfile(thisDir, 'outputs');
if ~exist(outDir, 'dir'), mkdir(outDir); end
csvPath = fullfile(outDir, 'summary_table.csv');
writetable(summary_df, csvPath);
fprintf('\nSummary table exported to %s\n', csvPath);

% ANOVA
anova = metrics('anova_rte_and_net', data);
disp(' ');
disp('--- Statistical Results (ANOVA) ---');
fprintf('RTE:       F = %.4f, p = %.4f, eta_squared = %.4f\n', ...
    anova.RTE.F, anova.RTE.p, anova.RTE.eta_sq);
fprintf('Net energy: F = %.4f, p = %.4f, eta_squared = %.4f\n', ...
    anova.Net_energy.F, anova.Net_energy.p, anova.Net_energy.eta_sq);
if anova.RTE.p < 0.05
    disp('System type significantly affects efficiency (p < 0.05). Differences are not due to chance.');
else
    disp('System type effect on efficiency not statistically significant at p < 0.05.');
end

% Validation
validation = calibration('run_all_validation', data);
disp(' ');
disp('--- Validation (Sanity Checks) ---');
fprintf('Energy conservation (E_out + discharge losses = PE within 5%%): %s\n', ...
    iif(validation.energy_conservation, 'PASS', 'FAIL'));
fprintf('RTE in [0, 100]%%:                                             %s\n', ...
    iif(validation.rte_bounds, 'PASS', 'FAIL'));
fprintf('Ranking (Variable CW highest, Halbach lowest):           %s\n', ...
    iif(validation.ranking, 'PASS', 'FAIL'));
disp('Calibration build (25 kg, 2.7 m):');
disp(validation.calibration);

% Generate all graphs
disp(' ');
disp('--- Generating graphs ---');
plotting('plot_all', data, summary_df);
fprintf('All PNGs saved to %s\n', outDir);

disp(' ');
disp('Done.');

function out = iif(cond, a, b)
if cond, out = a; else, out = b; end
end
