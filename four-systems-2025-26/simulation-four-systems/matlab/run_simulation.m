function varargout = run_simulation(fcn, varargin)
% run_simulation  EcoDrop Gravity Battery — Simulation orchestrator.
%   run_ten_per_system: 10 runs per system with ±2% motor, ±5% friction.
%   run_sensitivity: baseline, +10%, -10% friction.
%   run_all: all_runs, PE_input_nominal, representative, sensitivity, cumulative.
%
%   data = run_simulation('run_all', cfg);
%   all_runs = run_simulation('run_ten_per_system', cfg, rng_seed);
%   sens = run_simulation('run_sensitivity', cfg, rng_seed);
%   cum = run_simulation('run_cumulative_net', cfg);
%   r = run_simulation('run_one', name, fcn_handle, eta_scale, fric_scale, cfg);

% System list: name, category, function handle (must be on path: systems/)
SYSTEMS = {
    'Dual Weight',     'Regenerative', @run_cycle_dual_weight;
    'Variable CW',     'Regenerative', @run_cycle_variable_cw;
    'Buoyancy',        'Storage',      @run_cycle_buoyancy;
    'Halbach Array',   'Storage',      @run_cycle_halbach;
};

if nargin < 1, fcn = 'run_all'; end

switch fcn
    case 'run_one'
        [name, sys_fcn, eta_scale, fric_scale, cfg] = parse_run_one(varargin);
        varargout{1} = run_one(name, sys_fcn, eta_scale, fric_scale, cfg);
    case 'run_ten_per_system'
        [cfg, rng_seed] = parse_run_ten(varargin);
        varargout{1} = run_ten_per_system(SYSTEMS, cfg, rng_seed);
    case 'run_sensitivity'
        [cfg, rng_seed] = parse_sensitivity(varargin);
        varargout{1} = run_sensitivity(SYSTEMS, cfg, rng_seed);
    case 'get_cumulative_net_per_cycle'
        [all_runs, cfg] = parse_cumulative(varargin);
        varargout{1} = get_cumulative_net_per_cycle(all_runs, cfg);
    case 'run_cumulative_net'
        [cfg, rng_seed] = parse_run_cumulative(varargin);
        varargout{1} = run_cumulative_net(SYSTEMS, cfg, rng_seed);
    case 'run_all'
        [cfg, rng_seed] = parse_run_all(varargin);
        varargout{1} = run_all(SYSTEMS, cfg, rng_seed);
    otherwise
        error('run_simulation:unknown', 'Unknown function %s', fcn);
end
end

function [name, sys_fcn, eta_scale, fric_scale, cfg] = parse_run_one(v)
name = v{1}; sys_fcn = v{2}; eta_scale = v{3}; fric_scale = v{4};
cfg = v{5}; if isempty(cfg), cfg = config(); end
end

function [cfg, rng_seed] = parse_run_ten(v)
cfg = config(); rng_seed = 42;
if length(v) >= 1 && ~isempty(v{1}), cfg = v{1}; end
if length(v) >= 2 && ~isempty(v{2}), rng_seed = v{2}; end
end

function [cfg, rng_seed] = parse_sensitivity(v)
cfg = config(); rng_seed = 43;
if length(v) >= 1 && ~isempty(v{1}), cfg = v{1}; end
if length(v) >= 2 && ~isempty(v{2}), rng_seed = v{2}; end
end

function [all_runs, cfg] = parse_cumulative(v)
all_runs = v{1}; cfg = config();
if length(v) >= 2 && ~isempty(v{2}), cfg = v{2}; end
end

function [cfg, rng_seed] = parse_run_cumulative(v)
cfg = config(); rng_seed = 42;
if length(v) >= 1 && ~isempty(v{1}), cfg = v{1}; end
if length(v) >= 2 && ~isempty(v{2}), rng_seed = v{2}; end
end

function [cfg, rng_seed] = parse_run_all(v)
cfg = config(); rng_seed = 42;
if length(v) >= 1 && ~isempty(v{1}), cfg = v{1}; end
if length(v) >= 2 && ~isempty(v{2}), rng_seed = v{2}; end
end

function result = run_one(name, sys_fcn, eta_motor_scale, friction_scale, cfg)
result = sys_fcn(eta_motor_scale, friction_scale, 1, cfg);
if ~isfield(result, 'net_energy')
    result.net_energy = result.E_electrical_out - result.E_consumed;
end
pe = result.PE_input;
rte = 0;
if pe > 0
    rte = 100.0 * result.E_electrical_out / pe;
end
result.RTE_pct = min(100.0, rte);
result.E_out = result.E_electrical_out;
end

function all_runs = run_ten_per_system(SYSTEMS, cfg, rng_seed)
if isnumeric(rng_seed), rng(double(rng_seed), 'twister'); end
all_runs = cell(size(SYSTEMS,1), 1);
for i = 1:size(SYSTEMS, 1)
    name = SYSTEMS{i,1};
    category = SYSTEMS{i,2};
    sys_fcn = SYSTEMS{i,3};
    runs = cell(cfg.n_runs, 1);
    for k = 1:cfg.n_runs
        eta_scale = 1.0 + (2*rand() - 1) * cfg.motor_perturb_pct;
        fric_scale = 1.0 + (2*rand() - 1) * cfg.friction_perturb_pct;
        r = run_simulation('run_one', name, sys_fcn, eta_scale, fric_scale, cfg);
        runs{k} = r;
    end
    all_runs{i} = struct('name', name, 'category', category, 'runs', {runs});
end
end

function results = run_sensitivity(SYSTEMS, cfg, rng_seed)
if isnumeric(rng_seed), rng(double(rng_seed), 'twister'); end
results = [];
for i = 1:size(SYSTEMS, 1)
    name = SYSTEMS{i,1};
    category = SYSTEMS{i,2};
    sys_fcn = SYSTEMS{i,3};
    for j = 1:3
        if j == 1, fric = 1.0; label = 'baseline';
        elseif j == 2, fric = 1.1; label = '+10%';
        else, fric = 0.9; label = '-10%';
        end
        r = run_simulation('run_one', name, sys_fcn, 1.0, fric, cfg);
        results = [results; struct('system', name, 'category', category, 'friction', label, ...
            'RTE_pct', r.RTE_pct, 'net_energy', r.net_energy)];
    end
end
end

function cumulative = get_cumulative_net_per_cycle(all_runs, cfg)
n_cycles = (1:cfg.n_cycles_cumulative)';
cumulative = containers.Map();
for i = 1:length(all_runs)
    item = all_runs{i};
    runs = item.runs;
    nets = cellfun(@(r) r.net_energy, runs);
    mean_net = mean(nets);
    cumulative(item.name) = n_cycles * mean_net;
end
end

function out = run_cumulative_net(SYSTEMS, cfg, rng_seed)
all_runs = run_simulation('run_ten_per_system', cfg, rng_seed);
cumulative = run_simulation('get_cumulative_net_per_cycle', all_runs, cfg);
out = struct('n_cycles', (1:cfg.n_cycles_cumulative)', 'cumulative', cumulative);
end

function data = run_all(SYSTEMS, cfg, rng_seed)
all_runs = run_ten_per_system(SYSTEMS, cfg, rng_seed);
representative = struct();
for i = 1:length(all_runs)
    representative.(matlab.lang.makeValidName(all_runs{i}.name)) = all_runs{i}.runs{1};
end
sens_list = run_sensitivity(SYSTEMS, cfg, rng_seed);
sensitivity_rtes = struct();
for idx = 1:size(sens_list, 1)
    item = sens_list(idx);
    name = item.system;
    label = item.friction;
    % Use valid field name for struct
    fn = matlab.lang.makeValidName(name);
    if ~isfield(sensitivity_rtes, fn), sensitivity_rtes.(fn) = struct(); end
    if strcmp(label, 'baseline'), sensitivity_rtes.(fn).baseline = item.RTE_pct;
    elseif strcmp(label, '+10%'), sensitivity_rtes.(fn).plus_10 = item.RTE_pct;
    else, sensitivity_rtes.(fn).minus_10 = item.RTE_pct;
    end
end
cumulative = get_cumulative_net_per_cycle(all_runs, cfg);

data = struct('all_runs', {all_runs}, 'PE_input_nominal', cfg.PE_input_nominal, ...
    'representative', representative, 'sensitivity', sensitivity_rtes, 'cumulative', cumulative);
end
