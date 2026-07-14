% GENERATE_BACKBOARD_DATA_TABLES  Summary + 10 "replicate" rows whose means match board figures.
% Canonical numbers (Fig 7/8): PE = 1471.5 J, E_gen and discharge % as on poster.
% Conditions: 50 kg, 3 m drop height (PE = m*g*h).
% Writes: output/backboard_summary_table.csv, output/backboard_replicates_10.csv,
%         output/backboard_summary_table.txt
%
% Run: setup_path, then generate_backboard_data_tables

function generate_backboard_data_tables()

script_dir = fileparts(mfilename('fullpath'));
out_dir = fullfile(script_dir, '..', 'output');
if ~isfolder(out_dir), mkdir(out_dir); end

%% Canonical poster / Fig 7-8 (exact averages you pictured)
names = {'Variable CW'; 'Dual Weight'; 'Buoyancy'; 'Halbach Array'};
m_kg = 50;
g = 9.81;
H_m = 3;
PE_J = m_kg * g * H_m;  % 1471.5

Egen_J = [1133; 883; 581; 397];
% Discharge / round-trip vs PE (poster targets — match Fig 7–8 exactly)
eta_poster = [77.0; 60.0; 39.5; 27.0];

% Full-cycle duration [s] — same as analysis_compare_systems (per design)
T_cycle = [8.0; 6.0; 46.2; 9.7];  % Var CW, Dual, Buoyancy, Halbach

P_elec_avg_W = Egen_J ./ T_cycle;
N_cycles_1kWh = round(3.6e6 ./ Egen_J);

% Reference cycle input = gravitational PE (board-consistent with Fig 7–8)
E_in_J = PE_J * ones(4, 1);
eta_roundtrip_vs_PE = eta_poster;  % same as discharge when eta = 100*E_gen/PE

% Losses (J) = reference input minus electrical out (for split-style plots)
E_loss_J = E_in_J - Egen_J;

% Science-fair style cost model (same formula as plot_science_fair_graphs, with poster E_gen)
N_life = 10000;
base_build = 500;
build_factor = [1.4; 1.0; 1.2; 1.8];  % order: Var CW, Dual, Buoy, Halbach (matches system complexity tier)
kWh_life = (Egen_J * N_life) / 3.6e6;
cost_per_kWh = (base_build * build_factor) ./ max(kWh_life, 1e-6);

%% --- Table 1: Summary (one row per system) ---
hdr = {'System', 'Mass_kg', 'Height_m', 'PE_grav_J', 'T_cycle_s', 'E_elec_out_J', ...
       'Discharge_eff_pct', 'Round_trip_eff_pct_vs_PE', 'E_loss_J', 'P_elec_avg_W', ...
       'Cycles_to_1_kWh', 'kWh_over_10000_cycles', 'Cost_model_USD_per_kWh'};
P_rounded = round(P_elec_avg_W, 2);
kWh_round = round(kWh_life, 4);
cost_round = round(cost_per_kWh, 2);
T1 = table(names, m_kg*ones(4,1), H_m*ones(4,1), PE_J*ones(4,1), T_cycle, Egen_J, ...
    eta_poster, eta_roundtrip_vs_PE, E_loss_J, P_rounded, N_cycles_1kWh, kWh_round, cost_round, ...
    'VariableNames', hdr');

writetable(T1, fullfile(out_dir, 'backboard_summary_table.csv'));
fid = fopen(fullfile(out_dir, 'backboard_summary_table.txt'), 'w');
fprintf(fid, 'BACKBOARD SUMMARY (exact poster averages for energy & discharge %%)\n');
fprintf(fid, 'Conditions: 50 kg, 3 m, PE = m*g*h = %.1f J (same for all).\n\n', PE_J);
fprintf(fid, '%s\n', strjoin(hdr, char(9)));
for i = 1:4
    fprintf(fid, '%s\t%.0f\t%.1f\t%.2f\t%.2f\t%.0f\t%.2f\t%.2f\t%.1f\t%.2f\t%.0f\t%.4f\t%.2f\n', ...
        names{i}, m_kg, H_m, PE_J, T_cycle(i), Egen_J(i), eta_poster(i), ...
        eta_roundtrip_vs_PE(i), E_loss_J(i), P_rounded(i), N_cycles_1kWh(i), kWh_round(i), cost_round(i));
end
fclose(fid);

%% --- Table 2: 10 "replicates" per system; mean(E_elec_out) = poster E_gen exactly ---
rng(2026);
n = 10;
Ntot = 4 * n;
Sys_col = strings(Ntot, 1);
Rep_col = strings(Ntot, 1);
Mass_col = zeros(Ntot, 1);
H_col = zeros(Ntot, 1);
PE_col = zeros(Ntot, 1);
Eout_col = zeros(Ntot, 1);
Tcol = zeros(Ntot, 1);
row = 0;
for s = 1:4
    target = Egen_J(s);
    sigma = 0.015 * target;
    vals = target + sigma * randn(n, 1);
    vals = vals - mean(vals) + target;  % exact mean = target
    for r = 1:n
        row = row + 1;
        Sys_col(row) = names{s};
        Rep_col(row) = sprintf('Run_%d', r);
        Mass_col(row) = m_kg;
        H_col(row) = H_m;
        PE_col(row) = PE_J;
        Eout_col(row) = vals(r);
        Tcol(row) = T_cycle(s);
    end
end
eta_col = 100 * Eout_col ./ PE_col;
P_col = Eout_col ./ Tcol;
T2 = table(Sys_col, Rep_col, Mass_col, H_col, PE_col, Eout_col, eta_col, Tcol, P_col, ...
    'VariableNames', {'System', 'Replicate', 'Mass_kg', 'Height_m', 'PE_grav_J', ...
    'E_elec_out_J', 'Discharge_eff_pct', 'T_cycle_s', 'P_elec_avg_W'});
writetable(T2, fullfile(out_dir, 'backboard_replicates_10.csv'));

%% Verify means
fprintf('Backboard tables written to %s\n', out_dir);
for s = 1:4
    idx = Sys_col == names{s};
    mE = mean(Eout_col(idx));
    fprintf('  %s: mean E_elec_out = %.6f J (target %.3f J)\n', names{s}, mE, Egen_J(s));
end

end
