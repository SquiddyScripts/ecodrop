% RUN_EXAMPLE Run simulation and generate results (graphs + summary table).

clear; close all; clc;

fprintf('=== Electromechanical System Simulation ===\n\n');

% Setup MATLAB path
setup_path;

%% Generate results and plots
fprintf('Generating graphs and summary table...\n');
plot_demo_results();

fprintf('\n=== Complete ===\n\n');

%% ----- Optional: run simulation and plot (uncomment to use) -----
% fprintf('Running single simulation...\n');
% params = system_parameters();
% results = main_simulation(params);
% fprintf('\n=== Simulation Results ===\n');
% fprintf('Drop time: %.2f s\n', results.final.drop_time);
% fprintf('Electrical energy: %.2f J\n', results.final.E_electrical);
% fprintf('Efficiency: %.2f%%\n', 100 * results.final.efficiency);
% fprintf('==========================\n\n');
% fprintf('Generating plots (simulation data)...\n');
% plot_results(results);

%% ----- Optional: run gearbox optimization (uncomment to use) -----
% fprintf('\nRunning gearbox optimization...\n');
% opt_results = optimize_gearbox(params);
% plot_results([], opt_results);
