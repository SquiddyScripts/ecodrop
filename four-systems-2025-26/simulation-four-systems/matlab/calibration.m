function varargout = calibration(fcn, varargin)
% calibration  EcoDrop Gravity Battery — Validation and physical-build calibration.
%   [ok, imbalance] = calibration('energy_balance_check_one', result, tol_frac);
%   ok = calibration('rte_bounds_check', result);
%   val = calibration('run_validation', data, tol_frac);
%   [ok, order] = calibration('check_ranking', all_runs);
%   validation = calibration('run_all_validation', data);
%   cal = calibration('calibration_physical_build', multimeter_E_out_J);

switch fcn
    case 'energy_balance_check_one'
        [result, tol_frac] = parse_energy_balance(varargin);
        [ok, imbalance] = energy_balance_check_one(result, tol_frac);
        varargout = {ok, imbalance};
    case 'rte_bounds_check'
        result = varargin{1};
        varargout{1} = rte_bounds_check(result);
    case 'run_validation'
        [data, tol_frac] = parse_run_validation(varargin);
        varargout{1} = run_validation(data, tol_frac);
    case 'check_ranking'
        all_runs = varargin{1};
        [ok, order] = check_ranking(all_runs);
        varargout = {ok, order};
    case 'run_all_validation'
        data = varargin{1};
        if isempty(data), cfg = config(); data = run_simulation('run_all', cfg); end
        varargout{1} = run_all_validation(data);
    case 'calibration_physical_build'
        if length(varargin) >= 1 && ~isempty(varargin{1})
            varargout{1} = struct('note', 'Run with m=25, h=2.7 and compare; adjust eta_motor and friction if error > 15%');
        else
            varargout{1} = [];
        end
    otherwise
        error('calibration:unknown', 'Unknown function %s', fcn);
end
end

function [result, tol_frac] = parse_energy_balance(v)
result = v{1};
tol_frac = 0.01;
if length(v) >= 2 && ~isempty(v{2}), tol_frac = v{2}; end
end

function [data, tol_frac] = parse_run_validation(v)
data = v{1};
tol_frac = 0.05;
if length(v) >= 2 && ~isempty(v{2}), tol_frac = v{2}; end
end

function [ok, imbalance] = energy_balance_check_one(result, tol_frac)
PE = result.PE_input;
E_out = result.E_electrical_out;
loss = result.loss_dict;
discharge_loss = loss.rope_J + loss.bearing_J + loss.gearbox_J + loss.motor_J;
sum_side = E_out + discharge_loss;
imbalance = 0;
ok = true;
if PE <= 0
    return
end
imbalance = abs(PE - sum_side) / PE;
ok = imbalance <= tol_frac;
end

function ok = rte_bounds_check(result)
PE = result.PE_input;
E_out = result.E_electrical_out;
ok = true;
if PE <= 0, return; end
rte = 100.0 * E_out / PE;
ok = rte >= 0 && rte <= 100;
end

function out = run_validation(data, tol_frac)
all_runs = data.all_runs;
out = struct('energy_balance', struct(), 'rte_bounds', struct());
for i = 1:length(all_runs)
    item = all_runs{i};
    name = item.name;
    runs = item.runs;
    fn = matlab.lang.makeValidName(name);
    balances_ok = false(length(runs), 1);
    for k = 1:length(runs)
        [balances_ok(k), ~] = energy_balance_check_one(runs{k}, tol_frac);
    end
    out.energy_balance.(fn) = balances_ok;
    rte_oks = false(length(runs), 1);
    for k = 1:length(runs)
        rte_oks(k) = rte_bounds_check(runs{k});
    end
    out.rte_bounds.(fn) = rte_oks;
end
end

function [ok, order] = check_ranking(all_runs)
means = containers.Map();
for i = 1:length(all_runs)
    item = all_runs{i};
    rtes = cellfun(@(r) r.RTE_pct, item.runs);
    means(item.name) = mean(rtes);
end
names = means.keys;
[~, idx] = sort(cellfun(@(n) means(n), names), 'descend');
order = names(idx);
ok = strcmp(order{1}, 'Variable CW') && strcmp(order{end}, 'Halbach Array');
end

function validation = run_all_validation(data)
val = run_validation(data, 0.05);
energy_ok = true;
names_eb = fieldnames(val.energy_balance);
for i = 1:length(names_eb)
    if ~all(val.energy_balance.(names_eb{i}))
        energy_ok = false;
        break
    end
end
rte_ok = true;
names_rte = fieldnames(val.rte_bounds);
for i = 1:length(names_rte)
    if ~all(val.rte_bounds.(names_rte{i}))
        rte_ok = false;
        break
    end
end
[rank_ok, ~] = check_ranking(data.all_runs);
cal = calibration('calibration_physical_build', []);
if isempty(cal)
    cal = struct('sim_E_out_J', [], 'PE_input_J', [], 'note', 'No multimeter data attached');
end
validation = struct('energy_conservation', energy_ok, 'rte_bounds', rte_ok, ...
    'ranking', rank_ok, 'calibration', cal);
end
