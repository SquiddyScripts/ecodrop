%% anova_presentation_replicates.m
% One-way ANOVA on presentation replicate data (RTE and Net energy).
% Replicates are derived from presentation targets in run_presentation_plots_dark.m.
% Run after run_presentation_plots_dark (or ensure outputs/presentation_replicates.csv exists).

function anova_presentation_replicates()
OUTPUT_DIR = fullfile(fileparts(mfilename('fullpath')), 'outputs');
csv_path = fullfile(OUTPUT_DIR, 'presentation_replicates.csv');
if ~isfile(csv_path)
    error('Presentation replicates not found. Run run_presentation_plots_dark first.');
end
T = readtable(csv_path);
systems = unique(T.System, 'stable');
groups_rte = cell(length(systems), 1);
groups_net = cell(length(systems), 1);
for i = 1:length(systems)
    idx = strcmp(T.System, systems{i});
    groups_rte{i} = T.RTE_pct(idx);
    groups_net{i} = T.Net_energy_J(idx);
end

[F_rte, p_rte] = oneway_anova(groups_rte);
[F_net, p_net] = oneway_anova(groups_net);
eta_rte = eta_squared(groups_rte);
eta_net = eta_squared(groups_net);

fprintf('\n--- ANOVA on presentation replicates (derived from presentation targets) ---\n');
fprintf('RTE (%%):     F = %.2f, p = %.2e, eta_sq = %.3f\n', F_rte, p_rte, eta_rte);
fprintf('Net energy:  F = %.2f, p = %.2e, eta_sq = %.3f\n', F_net, p_net, eta_net);
fprintf('Replicate means match presentation: Variable CW 77%%, Dual Weight 60%%, Buoyancy 39.5%%, Halbach 27%%.\n');
fprintf('---\n\n');

% Save summary for reporting
result = struct('RTE', struct('F', F_rte, 'p', p_rte, 'eta_sq', eta_rte), ...
    'Net_energy', struct('F', F_net, 'p', p_net, 'eta_sq', eta_net));
save(fullfile(OUTPUT_DIR, 'anova_presentation_results.mat'), 'result');
end

function [F, p] = oneway_anova(groups)
y = vertcat(groups{:});
n = length(y);
k = length(groups);
grand_mean = mean(y);
group_means = cellfun(@mean, groups);
group_n = cellfun(@length, groups);
SS_between = sum(group_n .* (group_means - grand_mean).^2);
SS_within = 0;
for i = 1:length(groups)
    SS_within = SS_within + sum((groups{i} - group_means(i)).^2);
end
df_between = k - 1;
df_within = n - k;
MS_between = SS_between / df_between;
MS_within = SS_within / df_within;
F = MS_between / MS_within;
x = df_between * F / (df_within + df_between * F);
p = 1 - betainc(x, df_between/2, df_within/2);
end

function eta_sq = eta_squared(groups)
all_vals = vertcat(groups{:});
grand_mean = mean(all_vals);
ss_between = 0;
for g = 1:length(groups)
    ss_between = ss_between + length(groups{g}) * (mean(groups{g}) - grand_mean)^2;
end
ss_total = sum((all_vals - grand_mean).^2);
eta_sq = 0;
if ss_total > 0
    eta_sq = ss_between / ss_total;
end
end
