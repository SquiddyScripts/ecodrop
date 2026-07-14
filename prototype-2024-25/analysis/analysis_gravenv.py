# analysis.py

# ------------------------------
# 1. Import Required Libraries
# ------------------------------
import numpy as np
import matplotlib.pyplot as plt
from scipy.optimize import curve_fit
from scipy.stats import f_oneway, ttest_ind
import pandas as pd
import seaborn as sns
from mpl_toolkits.mplot3d import Axes3D  # for 3D plotting

# ------------------------------
# 2. Define Data and Constants
# ------------------------------
# Final measured data (from your table)
mass = np.array([10, 15, 20, 25])             # in kilograms
voltage = np.array([3.13, 4.90, 6.33, 8.23])    # average voltage in volts
power = np.array([6.53, 16.0, 26.7, 45.2])      # power output in Watts
measured_efficiency = np.array([18.70, 25.20, 25.60, 28.70])  # in percent

# Raw trial voltage data for statistical tests (each mass group has 3 trials)
voltages_10 = [3.1, 3.3, 3.0]
voltages_15 = [4.8, 5.0, 4.9]
voltages_20 = [6.3, 6.5, 6.2]
voltages_25 = [8.2, 8.4, 8.1]

# Constants for energy calculations
g = 9.81          # acceleration due to gravity (m/s²)
height = 2.5      # fall height (meters) - constant for all trials
run_time = 3      # run time in seconds for the energy calculation

# ------------------------------
# 3. Energy Calculations
# ------------------------------
# Calculate gravitational potential energy for each mass: E_p = m * g * h
potential_energy = mass * g * height
print("Potential Energy (J):", potential_energy)

# Calculate electrical energy output: E_e = power * run_time
electrical_energy = power * run_time
print("Electrical Energy (J):", electrical_energy)

# Calculate efficiency: Efficiency (%) = (E_e / E_p) * 100
efficiency_calculated = (electrical_energy / potential_energy) * 100
print("Calculated Efficiency (%):", efficiency_calculated)

# ------------------------------
# 4. Regression Analysis
# ------------------------------
# Define two models: a linear model and a power law model

# Linear model: V = a * m + b
def linear_model(x, a, b):
    return a * x + b

# Power law model: V = a * m^b
def power_model(x, a, b):
    return a * np.power(x, b)

# Fit the models using curve_fit
popt_linear, _ = curve_fit(linear_model, mass, voltage)
popt_power, _ = curve_fit(power_model, mass, voltage)

# Generate fitted values for plotting
x_fit = np.linspace(min(mass), max(mass), 100)
voltage_fit_linear = linear_model(x_fit, *popt_linear)
voltage_fit_power = power_model(x_fit, *popt_power)

# Define a function to calculate R²
def r_squared(y_actual, y_fit):
    residuals = y_actual - y_fit
    ss_res = np.sum(residuals ** 2)
    ss_tot = np.sum((y_actual - np.mean(y_actual)) ** 2)
    return 1 - (ss_res / ss_tot)

r2_linear = r_squared(voltage, linear_model(mass, *popt_linear))
r2_power = r_squared(voltage, power_model(mass, *popt_power))

print(f"Linear Model: V = {popt_linear[0]:.2f} * m + {popt_linear[1]:.2f}, R² = {r2_linear:.3f}")
print(f"Power Law Model: V = {popt_power[0]:.2f} * m^{popt_power[1]:.2f}, R² = {r2_power:.3f}")

# ------------------------------
# 5. Statistical Tests: ANOVA and T-Test
# ------------------------------
# ANOVA: check if the different mass groups show significant differences in voltage.
anova_stat, p_value_anova = f_oneway(voltages_10, voltages_15, voltages_20, voltages_25)
print("ANOVA p-value:", p_value_anova)

# T-Test: compare, for example, the 10kg and 25kg groups.
t_stat, p_value_t = ttest_ind(voltages_10, voltages_25)
print("T-Test p-value (10kg vs. 25kg):", p_value_t)

# ------------------------------
# 6. Data Consistency: Standard Deviation and Coefficient of Variation (CV)
# ------------------------------
def calc_cv(data):
    mean_val = np.mean(data)
    std_dev = np.std(data, ddof=1)  # use sample standard deviation (ddof=1)
    cv = (std_dev / mean_val) * 100  # expressed in percentage
    return std_dev, cv

for label, data in zip(["10kg", "15kg", "20kg", "25kg"],
                       [voltages_10, voltages_15, voltages_20, voltages_25]):
    std_dev, cv = calc_cv(data)
    print(f"{label}: Std Dev = {std_dev:.3f}, CV = {cv:.2f}%")

# ------------------------------
# 7. Visualizations
# ------------------------------
# 7.1: Scatter Plot with Regression Lines
plt.figure(figsize=(8,6))
plt.scatter(mass, voltage, label="Measured Voltage", color='blue', s=80)
plt.plot(x_fit, voltage_fit_linear, label=f"Linear Fit (R²={r2_linear:.3f})", linestyle="--", color="red")
plt.plot(x_fit, voltage_fit_power, label=f"Power Law Fit (R²={r2_power:.3f})", linestyle="-", color="green")
plt.xlabel("Mass (kg)")
plt.ylabel("Voltage (V)")
plt.title("Mass vs. Voltage Regression Analysis")
plt.legend()
plt.grid(True)
plt.show()  # Display the scatter plot with regression fits

# 7.2: Box Plot of Raw Trial Voltage Data
plt.figure(figsize=(8,6))
data_groups = [voltages_10, voltages_15, voltages_20, voltages_25]
labels = ['10kg', '15kg', '20kg', '25kg']
plt.boxplot(data_groups, labels=labels)
plt.xlabel("Mass")
plt.ylabel("Voltage (V)")
plt.title("Voltage Distribution for Each Mass Group")
plt.grid(True)
plt.show()  # Display the box plot

# 7.3: Correlation Heatmap of Final Data
data_dict = {
    'Mass': mass,
    'Voltage': voltage,
    'Power': power,
    'Efficiency': measured_efficiency
}
df = pd.DataFrame(data_dict)
plt.figure(figsize=(6,5))
corr_matrix = df.corr()
sns.heatmap(corr_matrix, annot=True, cmap='coolwarm')
plt.title("Correlation Matrix of Variables")
plt.show()  # Display the heatmap

# 7.4: 3D Surface Plot (Synthetic Example)
time_values = np.linspace(0, 7, 50)  # generate 50 time steps from 0 to 7 seconds
X, T = np.meshgrid(mass, time_values)
# Create synthetic power decay: for each time, power decays exponentially (for demonstration)
Z = np.array([power * np.exp(-0.1 * t) for t in time_values])
fig = plt.figure(figsize=(10,7))
ax = fig.add_subplot(111, projection='3d')
ax.plot_surface(X, T, Z, cmap="viridis")
ax.set_xlabel("Mass (kg)")
ax.set_ylabel("Time (s)")
ax.set_zlabel("Power (W)")
ax.set_title("3D Surface: Mass vs. Power vs. Time")
plt.show()  # Display the 3D surface plot
