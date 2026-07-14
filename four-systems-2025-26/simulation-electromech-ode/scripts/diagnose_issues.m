% DIAGNOSE_ISSUES Diagnostic script to identify problems with simulation
%
% Run this to see what's actually happening with power losses and efficiency

clear; close all; clc;
setup_path;

params = system_parameters();
results = main_simulation(params);

fprintf('\n=== DIAGNOSTIC ANALYSIS ===\n\n');

% Check a few time points
check_indices = [1, round(length(results.time)/4), round(length(results.time)/2), ...
                 round(3*length(results.time)/4), length(results.time)];

fprintf('Checking power and efficiency at key time points:\n');
fprintf('%-8s %-12s %-12s %-12s %-12s %-12s\n', ...
        'Time', 'P_mech', 'P_elec', 'P_loss_mech', 'P_loss_elec', 'Efficiency');
fprintf('%s\n', repmat('-', 1, 80));

for i = check_indices
    if i <= length(results.time) && ~isempty(results.energy_history{i})
        t = results.time(i);
        P_mech = results.P_mechanical(i);
        P_elec = results.P_electrical(i);
        P_loss_mech = results.energy_history{i}.P_loss_mechanical;
        P_loss_elec = results.energy_history{i}.P_loss_electrical;
        eta = results.eta_system(i);
        
        fprintf('%-8.3f %-12.2f %-12.2f %-12.2f %-12.2f %-12.2f%%\n', ...
                t, P_mech, P_elec, P_loss_mech, P_loss_elec, 100*eta);
    end
end

fprintf('\n=== Stage Power Losses (Last Active State) ===\n');
% Find last non-zero state (before mass hits bottom)
last_valid_idx = length(results.energy_history);
for i = length(results.energy_history):-1:1
    if ~isempty(results.energy_history{i}) && results.energy_history{i}.P_mechanical > 1e-3
        last_valid_idx = i;
        break;
    end
end

if last_valid_idx > 0 && ~isempty(results.energy_history{last_valid_idx})
    fprintf('Using state at t=%.3f s (before mass hits bottom)\n', results.time(last_valid_idx));
    stages = results.energy_history{last_valid_idx}.stages;
    stage_names = fieldnames(stages);
    for i = 1:length(stage_names)
        stage = stages.(stage_names{i});
        if isfield(stage, 'P_in') && isfield(stage, 'P_out') && isfield(stage, 'P_loss')
            fprintf('%s: P_in=%.2f W, P_out=%.2f W, P_loss=%.2f W\n', ...
                    stage_names{i}, stage.P_in, stage.P_out, stage.P_loss);
        end
    end
else
    fprintf('No valid state found!\n');
end

fprintf('\n=== Stage Efficiencies (Last Active State) ===\n');
if last_valid_idx > 0 && ~isempty(results.energy_history{last_valid_idx})
    fprintf('Using state at t=%.3f s\n', results.time(last_valid_idx));
    fprintf('Sprocket: %.2f%%\n', 100 * results.energy_history{last_valid_idx}.eta_sprocket);
    fprintf('Gearbox: %.2f%%\n', 100 * results.energy_history{last_valid_idx}.eta_gearbox);
    fprintf('Bevel: %.2f%%\n', 100 * results.energy_history{last_valid_idx}.eta_bevel);
    fprintf('Motor: %.2f%%\n', 100 * results.energy_history{last_valid_idx}.eta_motor);
    fprintf('System: %.2f%%\n', 100 * results.energy_history{last_valid_idx}.eta_system);
end

fprintf('\n=== Checking for Invalid Values ===\n');
invalid_eta = sum(isnan(results.eta_system) | isinf(results.eta_system) | ...
                  results.eta_system > 1 | results.eta_system < 0);
fprintf('Invalid efficiency values: %d out of %d\n', invalid_eta, length(results.eta_system));

invalid_P_mech = sum(isnan(results.P_mechanical) | isinf(results.P_mechanical) | ...
                     results.P_mechanical < 0);
fprintf('Invalid mechanical power values: %d out of %d\n', invalid_P_mech, length(results.P_mechanical));

invalid_P_elec = sum(isnan(results.P_electrical) | isinf(results.P_electrical) | ...
                     results.P_electrical < 0);
fprintf('Invalid electrical power values: %d out of %d\n', invalid_P_elec, length(results.P_electrical));

fprintf('\n=== Power Loss Breakdown (Last Active State) ===\n');
% Find last non-zero component state
last_comp_idx = length(results.component_history);
for i = length(results.component_history):-1:1
    if ~isempty(results.component_history{i}) && results.component_history{i}.P_electrical > 1e-3
        last_comp_idx = i;
        break;
    end
end

if last_comp_idx > 0 && ~isempty(results.component_history{last_comp_idx})
    fprintf('Using state at t=%.3f s\n', results.time(last_comp_idx));
    comp = results.component_history{last_comp_idx};
    fprintf('Sprocket loss: %.2f W\n', comp.P_loss_sprocket);
    fprintf('Gearbox loss: %.2f W\n', comp.P_loss_gearbox);
    fprintf('Bevel loss: %.2f W\n', comp.P_loss_bevel);
    fprintf('Motor loss: %.2f W\n', comp.P_losses_motor);
    fprintf('Total mechanical loss: %.2f W\n', ...
            comp.P_loss_sprocket + comp.P_loss_gearbox + comp.P_loss_bevel);
end

fprintf('\n=== Diagnostic Complete ===\n');
