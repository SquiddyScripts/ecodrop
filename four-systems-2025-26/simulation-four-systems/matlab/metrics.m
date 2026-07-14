function varargout = metrics(fcn, data)
% metrics  EcoDrop Gravity Battery — Aggregate metrics: RTE, loss breakdown, net energy, ANOVA.
%   summary_df = metrics('build_summary_table', data);
%   anova = metrics('anova_rte_and_net', data);

switch fcn
    case 'build_summary_table'
        varargout{1} = build_summary_table(data);
    case 'anova_rte_and_net'
        varargout{1} = anova_rte_and_net(data);
    otherwise
        error('metrics:unknown', 'Unknown function %s', fcn);
end
end

function summary_df = build_summary_table(data)
all_runs = data.all_runs;
n_sys = length(all_runs);
System = cell(n_sys, 1);
Category = cell(n_sys, 1);
Mean_RTE = zeros(n_sys, 1);
SD_RTE = zeros(n_sys, 1);
Net_Energy = zeros(n_sys, 1);
SD_Net = zeros(n_sys, 1);
Total_Loss = zeros(n_sys, 1);
Rope_Loss = zeros(n_sys, 1);
Bearing_Loss = zeros(n_sys, 1);
Gearbox_Loss = zeros(n_sys, 1);
Motor_Loss = zeros(n_sys, 1);
System_Specific_Loss = zeros(n_sys, 1);

for i = 1:n_sys
    item = all_runs{i};
    runs = item.runs;
    System{i} = item.name;
    Category{i} = item.category;
    rte_list = cellfun(@(r) r.RTE_pct, runs);
    net_list = cellfun(@(r) r.net_energy, runs);
    Mean_RTE(i) = mean(rte_list);
    SD_RTE(i) = std(rte_list);
    Net_Energy(i) = mean(net_list);
    SD_Net(i) = std(net_list);
    total_loss_list = cellfun(@(r) r.PE_input - r.E_out, runs);
    Total_Loss(i) = mean(total_loss_list);
    Rope_Loss(i) = mean(cellfun(@(r) r.loss_dict.rope_J, runs));
    Bearing_Loss(i) = mean(cellfun(@(r) r.loss_dict.bearing_J, runs));
    Gearbox_Loss(i) = mean(cellfun(@(r) r.loss_dict.gearbox_J, runs));
    Motor_Loss(i) = mean(cellfun(@(r) r.loss_dict.motor_J, runs));
    System_Specific_Loss(i) = mean(cellfun(@(r) r.loss_dict.system_specific_J, runs));
end

summary_df = table(System, Category, Mean_RTE, SD_RTE, Net_Energy, SD_Net, Total_Loss, ...
    Rope_Loss, Bearing_Loss, Gearbox_Loss, Motor_Loss, System_Specific_Loss, ...
    'VariableNames', {'System', 'Category', 'Mean RTE (%)', 'SD RTE', 'Net Energy/Cycle (J)', 'SD Net', ...
    'Total Loss/Cycle (J)', 'Rope Loss (J)', 'Bearing Loss (J)', 'Gearbox Loss (J)', 'Motor Loss (J)', 'System-Specific Loss (J)'});
end

function anova_out = anova_rte_and_net(data)
all_runs = data.all_runs;
groups_rte = cell(length(all_runs), 1);
groups_net = cell(length(all_runs), 1);
for i = 1:length(all_runs)
    runs = all_runs{i}.runs;
    groups_rte{i} = cellfun(@(r) r.RTE_pct, runs);
    groups_net{i} = cellfun(@(r) r.net_energy, runs);
end

% One-way ANOVA (manual: no Statistics Toolbox required)
[F_rte, p_rte] = oneway_anova(groups_rte);
[F_net, p_net] = oneway_anova(groups_net);

eta_sq_rte = eta_squared(groups_rte);
eta_sq_net = eta_squared(groups_net);

anova_out = struct('RTE', struct('F', F_rte, 'p', p_rte, 'eta_sq', eta_sq_rte), ...
    'Net_energy', struct('F', F_net, 'p', p_net, 'eta_sq', eta_sq_net));
end

function [F, p] = oneway_anova(groups)
% One-way ANOVA: F = MS_between / MS_within, p from F distribution.
y = vertcat(groups{:});
g = repelem((1:length(groups))', cellfun(@length, groups));
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
% F-distribution p-value using betainc (no Statistics Toolbox required)
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
