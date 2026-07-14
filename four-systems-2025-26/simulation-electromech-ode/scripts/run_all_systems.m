% RUN_ALL_SYSTEMS  Run all four gravity storage system simulations and the comparison.
%
% Generates plots for: Dual-weight, Buoyancy, Halbach, Variable counterweight,
% then runs the comparative data analysis (ANOVA, conclusion).
% All systems use 50 kg effective mass and 3 m height (set in each script).
%
% Run:  run_all_systems

clear; close all; clc;

fprintf('=== Gravity Storage — Running All Systems ===\n\n');

%% 1) Dual-weight elevator
fprintf('(1/5) Dual-weight elevator...\n');
plot_dual_weight_results();

%% 2) Buoyancy gravity battery
fprintf('(2/5) Buoyancy gravity battery...\n');
plot_buoyancy_gravity_results();

%% 3) Halbach linear motor
fprintf('(3/5) Halbach linear motor...\n');
plot_halbach_gravity_results();

%% 4) Variable counterweight
fprintf('(4/5) Variable counterweight...\n');
plot_variable_counterweight_results();

%% 5) Comparative analysis (ANOVA, bar charts, conclusion)
fprintf('(5/5) Comparative data analysis...\n');
analysis_compare_systems();

fprintf('\n=== All systems complete ===\n');
fprintf('Figures: Dual-weight, Buoyancy, Halbach, Variable CW, and System Comparison.\n');
fprintf('Conclusion saved to: analysis_conclusion.txt\n\n');
