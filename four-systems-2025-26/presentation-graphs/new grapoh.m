% EcoDrop Gravity Battery — Graph Generation Script
% Run this script to generate all 5 publication-ready figures.
% Simulation conducted in MATLAB. Export as PNG at 300 DPI.

close all; clear;

%% ── FORCE WHITE THEME REGARDLESS OF MATLAB SETTINGS ─────────
set(groot, 'defaultFigureColor',       'white')
set(groot, 'defaultAxesColor',         'white')
set(groot, 'defaultTextColor',         'black')
set(groot, 'defaultAxesXColor',        'black')
set(groot, 'defaultAxesYColor',        'black')
set(groot, 'defaultAxesZColor',        'black')
set(groot, 'defaultAxesGridColor',     [0.93 0.93 0.93])
set(groot, 'defaultAxesFontName',      'Helvetica')
set(groot, 'defaultTextFontName',      'Helvetica')
set(groot, 'defaultAxesFontSize',      13)
set(groot, 'defaultAxesLineWidth',     0.8)
set(groot, 'defaultAxesTickDir',       'out')
set(groot, 'defaultAxesBox',           'off')
set(groot, 'defaultAxesXGrid',         'off')
set(groot, 'defaultAxesYGrid',         'on')

%% ── SHARED DATA ──────────────────────────────────────────────
systems   = {'Variable CW','Dual Weight','Buoyancy','Halbach Array'};
rtes      = [77.0, 60.0, 39.5, 27.0];
e_out     = [1133, 883, 581, 397];
e_in      = 1471.5;
totals    = [338, 589, 890, 1074];

% Consistent colors across all figures
c_vcw  = [0.498 0.467 0.867];   % purple
c_dw   = [0.290 0.565 0.851];   % blue
c_buoy = [0.878 0.482 0.227];   % orange
c_hal  = [0.353 0.620 0.227];   % green
sys_colors = [c_vcw; c_dw; c_buoy; c_hal];

font_size_ax    = 20;
font_size_label = 22;
font_size_title = 22;
font_size_annot = 11;
fig_w = 1600;
fig_h = 900;


%% ── FIG 1: Round-Trip Efficiency ────────────────────────────
f1 = figure('Color','white','Position',[100 100 fig_w fig_h]);
ax1 = axes('Parent',f1);

% Plot horizontal bars in reverse order so Variable CW is on top
systems_rev   = fliplr(systems);
rtes_rev      = fliplr(rtes);
colors_rev    = flipud(sys_colors);

bh = barh(ax1, 1:4, rtes_rev, 0.72);
bh.FaceColor = 'flat';
for i = 1:4
    bh.CData(i,:) = colors_rev(i,:);
end

hold(ax1,'on');

% Value labels
for i = 1:4
    text(rtes_rev(i)+1, i, sprintf('%.1f%%', rtes_rev(i)), ...
        'VerticalAlignment','middle', 'FontSize',20, ...
        'FontWeight','bold', 'Color',[0.1 0.1 0.1], 'Parent',ax1);
end

ax1.YTick = 1:4;
ax1.YTickLabel = systems_rev;
ax1.XLim = [0 100];
ax1.FontSize = font_size_ax;
ax1.XGrid = 'on';
ax1.YGrid = 'off';
ax1.Box = 'off';
ax1.TickDir = 'out';
xlabel(ax1, 'Discharge efficiency (%)', 'FontSize',font_size_label);
title(ax1, 'Fig 5 — Discharge efficiency: all 4 gravitational storage systems', ...
    'FontSize',font_size_title, 'FontWeight','bold', 'HorizontalAlignment','left', 'Units','normalized', 'Position',[0 1.04 0]);

annotation(f1,'textbox',[0.08 0.01 0.88 0.05], ...
    'String','Discharge efficiency defined as electrical energy recovered on discharge divided by gravitational PE stored (mgh = 1471.5 J, 50 kg, 3 m drop). Baseline physical prototype: 30-35%.', ...
    'EdgeColor','none','FontSize',15,'Color',[0.2 0.2 0.2],'FitBoxToText','off');

set(ax1, 'Units','normalized');
set(ax1, 'Position', [0.10 0.20 0.85 0.68]);
exportgraphics(f1,'Fig5_RTE.png','Resolution',300,'BackgroundColor','white');


%% ── FIG 2: Loss Breakdown Stacked Bar ───────────────────────
f2 = figure('Color','white','Position',[100 100 fig_w fig_h]);
ax2 = axes('Parent',f2);

rope    = [20,  71,  27,  32];
bearing = [3,   6,   9,   11];
gearbox = [47,  129, 45,  54];
motor   = [61,  153, 62,  86];
syssp   = [207, 230, 748, 892];

loss_data = [rope; bearing; gearbox; motor; syssp]';
b2 = bar(ax2, loss_data, 'stacked', 'BarWidth', 0.72);

loss_colors = [...
    0.298 0.686 0.510;   % rope    — teal green
    0.910 0.659 0.220;   % bearing — amber
    0.878 0.420 0.420;   % gearbox — coral
    0.608 0.557 0.769;   % motor   — lavender
    0.227 0.490 0.173];  % syssp   — dark green

for i = 1:5
    b2(i).FaceColor = loss_colors(i,:);
end

hold(ax2,'on');
for i = 1:4
    text(i, totals(i)+28, sprintf('%d J', totals(i)), ...
        'HorizontalAlignment','center','FontSize',20, ...
        'FontWeight','bold','Color',[0.1 0.1 0.1],'Parent',ax2);
end

ax2.XTickLabel = systems;
ax2.FontSize   = font_size_ax;
ax2.YLim       = [0 1150];
ax2.YGrid      = 'on';
ax2.Box        = 'off';
ax2.TickDir    = 'out';
ylabel(ax2,'Energy loss per cycle (J)','FontSize',font_size_label);
legend(ax2, {'Rope','Bearing','Gearbox','Motor','System-specific'}, ...
    'Location','northwest','FontSize',18,'Box','off');
title(ax2,'Fig 1 — Energy loss breakdown per cycle: mechanical vs. system-specific losses', ...
    'FontSize',font_size_title,'FontWeight','bold','HorizontalAlignment','left','Units','normalized','Position',[0 1.04 0]);

annotation(f2,'textbox',[0.08 0.01 0.88 0.05], ...
    'String','Baseline: 50 kg mass, 3 m drop, 1471.5 J gravitational PE input. Mechanical losses (rope, bearing, gearbox, motor) are nearly identical across all four systems. System-specific losses account for the entire performance difference between systems.', ...
    'EdgeColor','none','FontSize',15,'Color',[0.2 0.2 0.2],'FitBoxToText','off');

set(ax2, 'Units','normalized');
set(ax2, 'Position', [0.10 0.20 0.85 0.68]);
exportgraphics(f2,'Fig1_LossBreakdown.png','Resolution',300,'BackgroundColor','white');


%% ── FIG 3: Energy In vs Out ──────────────────────────────────
f3 = figure('Color','white','Position',[100 100 fig_w fig_h]);
ax3 = axes('Parent',f3);

x     = 1:4;
w     = 0.42;
e_in_arr = repmat(e_in, 1, 4);

b_in  = bar(ax3, x-w/2, e_in_arr, w, 'FaceColor',[0.80 0.80 0.80], ...
    'EdgeColor',[0.6 0.6 0.6], 'BarWidth',1);
hold(ax3,'on');

b_out = bar(ax3, x+w/2, e_out, w, 'BarWidth',1);
b_out.FaceColor = 'flat';
for i = 1:4
    b_out.CData(i,:) = sys_colors(i,:);
end

% Labels
for i = 1:4
    text(i-w/2, e_in+18, '1471.5 J', 'HorizontalAlignment','center', ...
        'FontSize',16,'Color',[0.4 0.4 0.4],'Parent',ax3);
    text(i+w/2, e_out(i)+32, sprintf('%d J', e_out(i)), ...
        'HorizontalAlignment','center','FontSize',20, ...
        'FontWeight','bold','Color',[0.1 0.1 0.1],'Parent',ax3);
end

ax3.XTick      = 1:4;
ax3.XTickLabel = systems;
ax3.FontSize   = font_size_ax;
ax3.YGrid      = 'on';
ax3.Box        = 'off';
ax3.TickDir    = 'out';
ax3.YLim       = [0 1650];
ylabel(ax3,'Energy per cycle (J)','FontSize',font_size_label);
% Custom legend for Fig 3
gray_patch  = patch(ax3, NaN, NaN, [0.80 0.80 0.80], 'EdgeColor',[0.6 0.6 0.6]);
vcw_patch   = patch(ax3, NaN, NaN, sys_colors(1,:));
dw_patch    = patch(ax3, NaN, NaN, sys_colors(2,:));
buoy_patch  = patch(ax3, NaN, NaN, sys_colors(3,:));
hal_patch   = patch(ax3, NaN, NaN, sys_colors(4,:));
legend(ax3, [gray_patch, vcw_patch, dw_patch, buoy_patch, hal_patch], ...
    {'Energy in to charge', ...
     'Variable CW', ...
     'Dual Weight', ...
     'Buoyancy', ...
     'Halbach Array'}, ...
    'Location','northeast','FontSize',14,'Box','off', ...
    'Position',[0.72 0.55 0.20 0.25]);
title(ax3,'Fig 2 — Energy input to charge vs. electrical energy recovered on discharge per cycle', ...
    'FontSize',font_size_title,'FontWeight','bold','HorizontalAlignment','left','Units','normalized','Position',[0 1.04 0]);

annotation(f3,'textbox',[0.08 0.01 0.88 0.05], ...
    'String','All systems receive identical gravitational PE input (1471.5 J). Gap between gray and colored bar = total cycle losses. Ratio of output to input = discharge efficiency.', ...
    'EdgeColor','none','FontSize',15,'Color',[0.2 0.2 0.2],'FitBoxToText','off');

set(ax3, 'Units','normalized');
set(ax3, 'Position', [0.10 0.20 0.85 0.68]);
exportgraphics(f3,'Fig2_EnergyInOut.png','Resolution',300,'BackgroundColor','white');


%% FIG 4: Tornado Sensitivity
f4 = figure('Color','white','Position',[100 100 fig_w fig_h]);
ax4 = axes('Parent',f4);
hold(ax4,'on');

base_rte = [77.0, 60.0, 39.5, 27.0];
rte_low  = [74.0, 57.5, 37.5, 25.5];
rte_high = [78.5, 61.5, 40.5, 27.8];
bar_h    = 0.45;

for i = 1:4
    lo = rte_low(i);
    hi = rte_high(i);
    patch(ax4, [lo hi hi lo], [i-bar_h/2 i-bar_h/2 i+bar_h/2 i+bar_h/2], ...
        sys_colors(i,:), 'FaceAlpha',0.5, 'EdgeColor',sys_colors(i,:), 'LineWidth',1.2);
    plot(ax4, [base_rte(i) base_rte(i)], [i-bar_h/2 i+bar_h/2], ...
        'Color',sys_colors(i,:), 'LineWidth',3);
    text(hi+0.8, i+0.18, sprintf('%.1f%% - %.1f%%', lo, hi), ...
        'VerticalAlignment','middle','FontSize',18,'Color',[0.15 0.15 0.15]);
    text(hi+0.8, i-0.18, sprintf('(baseline %.1f%%)', base_rte(i)), ...
        'VerticalAlignment','middle','FontSize',15,'Color',[0.4 0.4 0.4]);
end

ax4.YTick      = 1:4;
ax4.YTickLabel = systems;
ax4.XLim       = [20 90];
ax4.YLim       = [0.3 4.7];
ax4.FontSize   = font_size_ax;
ax4.XGrid      = 'on';
ax4.YGrid      = 'off';
ax4.Box        = 'off';
ax4.TickDir    = 'out';
xlabel(ax4,'Discharge efficiency (%)','FontSize',font_size_label);
title(ax4,'Fig 3 - Discharge efficiency robustness: sensitivity to +-20% friction variation, all 4 systems', ...
    'FontSize',font_size_title,'FontWeight','bold','HorizontalAlignment','left','Units','normalized','Position',[0 1.04 0]);

annotation(f4,'textbox',[0.08 0.01 0.88 0.05], ...
    'String','Each bar shows discharge efficiency range when friction coefficients are varied +-20% from baseline. Vertical line marks baseline discharge efficiency. System rankings preserved under all tested conditions.', ...
    'EdgeColor','none','FontSize',15,'Color',[0.2 0.2 0.2],'FitBoxToText','off');

set(ax4, 'Units','normalized');
set(ax4, 'Position', [0.10 0.20 0.85 0.68]);
exportgraphics(f4,'Fig3_Tornado.png','Resolution',300,'BackgroundColor','white');


%% ── FIG 5: Cycles to 1 kWh ──────────────────────────────────
f5 = figure('Color','white','Position',[100 100 fig_w+200 fig_h+100]);
ax5 = axes('Parent',f5);

target_J = 3600000;
mass_kg  = 50;
g        = 9.81;
rte_vals = [0.77, 0.60, 0.395, 0.27];
wall_h   = [Inf, Inf, 15, 10];  % engineering wall heights (Inf = no wall)

h_solid = linspace(3, 50, 300);

for i = 1:4
    rte   = rte_vals(i);
    color = sys_colors(i,:);
    w     = wall_h(i);

    if isinf(w)
        cyc = target_J ./ (rte * mass_kg * g * h_solid);
        plot(ax5, h_solid, cyc, 'Color',color, 'LineWidth',2.5, ...
            'DisplayName', systems{i});
    else
        hs_s = h_solid(h_solid <= w);
        hs_d = h_solid(h_solid >= w);
        cyc_s = target_J ./ (rte * mass_kg * g * hs_s);
        cyc_d = target_J ./ (rte * mass_kg * g * hs_d);
        plot(ax5, hs_s, cyc_s, 'Color',color,'LineWidth',2.5, ...
            'DisplayName',systems{i});
        hold(ax5,'on');
        plot(ax5, hs_d, cyc_d, '--','Color',color,'LineWidth',1.8, ...
            'HandleVisibility','off');
    end
    hold(ax5,'on');

    % inline labels removed — legend is sufficient
end

% dummy line for legend
plot(ax5, NaN, NaN, '--', 'Color',[0.6 0.6 0.6], 'LineWidth',1.5, ...
    'DisplayName','Beyond engineering limit');

ax5.XLim     = [3 50];
ax5.YLim     = [0 10000];
ax5.FontSize = font_size_ax;
ax5.YGrid    = 'on';
ax5.Box      = 'off';
ax5.TickDir  = 'out';
ax5.YAxis.Exponent = 0;
ytickformat(ax5,'%,d');
xlabel(ax5,'Drop height (m)','FontSize',font_size_label);
ylabel(ax5,'Cycles to deliver 1 kWh','FontSize',font_size_label);
legend(ax5,'Location','northeast','FontSize',20,'Box','off');
title(ax5,'Fig 4 — Cycles required to deliver 1 kWh vs. drop height: all 4 systems at 50 kg mass, 3–50 m', ...
    'FontSize',font_size_title,'FontWeight','bold','HorizontalAlignment','left','Units','normalized','Position',[0 1.04 0]);

annotation(f5,'textbox',[0.08 0.01 0.88 0.05], ...
    'String','Buoyancy shown dashed beyond ~15 m and Halbach Array beyond ~10 m — fundamental machine redesign required at greater heights. Variable CW and Dual Weight scale naturally with shaft height and are shown solid through 50 m. 50 kg system mass.', ...
    'EdgeColor','none','FontSize',15,'Color',[0.2 0.2 0.2],'FitBoxToText','off');

set(ax5, 'Units','normalized');
set(ax5, 'Position', [0.10 0.20 0.85 0.68]);
exportgraphics(f5,'Fig4_CyclesToKwh.png','Resolution',300,'BackgroundColor','white');

disp('All 5 figures saved as 300 DPI PNG files.');