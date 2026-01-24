# Walters (2004) Closed-Loop MSE Implementation Guide

## Overview

`walters_closedloop_mse.R` is a comprehensive R implementation of the Management Strategy Evaluation (MSE) approach described in Walters (2004): "Simple representation of the dynamics of biomass error propagation for stock assessment models."

This implementation demonstrates how to conduct full-feedback simulation testing of harvest control rules with realistic assessment error, following the methodological framework that Ianelli et al. (2011) and Ono et al. (2017) applied to Alaska groundfish management.

## Implementation Architecture

### Part 1: Operating Model (`operating_model()`)

**Purpose:** Simulates true population dynamics under realistic recruitment variability

**Implements:** Walters (2004) Equation 5 (delay-difference model)
```
B(t+1) = g * (B(t) - H(t)) + w_k * R(t)
```

**Parameters:**
- `B_init`: Initial exploitable biomass (default: 1000 tons)
- `n_years`: Projection horizon (default: 50 years)
- `M`: Natural mortality (default: 0.15)
- `g`: Growth-survival constant (Eq. 6, default: 0.95)
- `w_k`: Mean weight at recruitment age (default: 5 kg)
- `recruitment_sd`: Log-scale recruitment variability (default: 0.5)

**Output:**
- `B_true`: True exploitable biomass for each year
- `R_true`: Recruitment (age k) for each year
- `C_true`: Realized catch (if harvests provided)
- `H_true`: Harvest in biomass units

**Key Feature:** Uses lognormal recruitment deviations to maintain realistic population variability while keeping population dynamics relatively stable.

### Part 2: Observation Model (`observation_model()`)

**Purpose:** Generates survey/CPUE data with observation error

**Supports Two Index Types:**

1. **Linear proportional (default):**
   - `I(t) = q * B(t)` + lognormal error

2. **Hyperstable index:**
   - `I(t) = q * B(t)^β` (β < 1)
   - Simulates range contraction effect where catchability increases as biomass declines

**Parameters:**
- `B_true`: True biomass trajectory
- `q_param`: Catchability coefficient (default: 0.001)
- `survey_cv`: Coefficient of variation of observations (default: 0.3 = 30%)
- `hyperstable`: Enable hyperstable index? (default: FALSE)
- `beta`: Hyperstability exponent (default: 0.8)

**Output:**
- `I_true`: True abundance index (without error)
- `I_obs`: Observed index (with lognormal error)
- `survey_cv`: Survey specification (for reference)

**Key Feature:** Uses properly mean-corrected lognormal error to maintain unbiased expectations.

### Part 3: Assessment Model (Kalman Filter)

#### `kalman_filter_update()` - Core Estimation

**Purpose:** Updates biomass estimates using Kalman filter with minimal computational burden

**Implements:** Walters (2004) Equation 1
```
B_t|t = B_t|t-1 + K* * (B* - B_t|t-1)
```

**Parameters:**
- `B_pred_prev`: Previous year's prediction (B_t|t-1)
- `I_obs`: Current year observation
- `q_assumed`: Assumed catchability
- `K_gain`: Kalman gain K* (default: 0.5)

**Output:**
- `B_est`: Updated biomass estimate
- `B_star`: Biomass implied by current observation
- `innovation`: Update magnitude (observation - prediction)

**Advantage over Full Age-Structured Assessment:**
- Computationally efficient (linear update vs. solving cohort equations)
- Enables Monte Carlo MSE with 100+ scenarios
- Captures key feedback without full-model complexity

#### `calibrate_kalman_gain()` - Parameter Calibration

**Purpose:** Estimates optimal filter gain K* from simulation data

**Implements:** Walters (2004) Equation 8 regression test
```
B_t|t - B_t|t-1 ~ K* * (B* - B_t|t-1)
```

**Parameters:**
- `op_model_results`: Operating model output
- `obs_model_results`: Observation model output
- `q_param`: Catchability for survey
- `min_year_for_calibration`: Years before using data (default: 5)

**Output:**
- `K_gain`: Estimated filter gain (constrained to [0,1])
- `regression_fit`: Fitted lm object
- `rsquared`: Fit quality

**Usage:** Run once at model initialization to determine data-specific K* value.

### Part 4: Management Procedure (`harvest_control_rule()`)

**Purpose:** Converts biomass estimate into Total Allowable Catch (TAC) recommendation

**Three Rule Types:**

1. **Proportional (constant F):**
   ```
   TAC = F_ref * B_est
   ```
   Fishing mortality proportional to estimated biomass.

2. **Threshold (risk-averse):**
   ```
   TAC = 0                              if B < B_limit
   TAC = linear ramp from 0 to F*B     if B_limit ≤ B < B_ref
   TAC = F_ref * B_est                 if B ≥ B_ref
   ```
   Reduces risk of uncontrolled population decline.

3. **Fixed catch:**
   ```
   TAC = constant (e.g., 200 tons)
   ```
   Simplest approach; can be risky if assessment is poor.

**Parameters:**
- `B_est`: Estimated exploitable biomass
- `B_ref`: Reference biomass (typically unfished or MSY level)
- `F_ref`: Target fishing mortality (default: 0.2)
- `B_limit`: Lower biomass limit (default: 0.2 * B_ref)
- `rule`: Which control rule to apply

### Part 5: Closed-Loop MSE (`closed_loop_mse()`)

**Purpose:** Runs complete feedback simulation with N Monte Carlo scenarios

**Feedback Loop for Each Year:**

```
1. Assessment Phase:
   - Observe current abundance index
   - Update biomass estimate with Kalman filter

2. Management Phase:
   - Convert estimate to catch recommendation (HCR)
   - Set Total Allowable Catch (TAC)

3. Operating Model Phase:
   - Implement catch in population dynamics
   - Generate recruitment
   - Calculate next year's true biomass

4. Prediction Phase:
   - Forecast next year's biomass for assessment
   - Repeat for each year
```

**Parameters:**
- `n_years`: Projection period (default: 50)
- `n_scenarios`: Monte Carlo replicates (default: 100)
- `B_init`: Starting biomass (default: 1000)
- `q_true`: True catchability
- `q_assumed`: Assumed catchability (can differ!)
- `survey_cv`: Observation error (default: 0.3)
- `hcr_rule`: Which harvest control rule ("proportional", "threshold", "fixed_catch")
- `F_ref`: Target fishing mortality (default: 0.2)
- `hyperstable`: Enable range-contraction effects? (default: FALSE)

**Output:** List containing:
- `B_true`: N × n_years matrix of true biomass
- `B_est`: N × n_years matrix of estimated biomass
- `catch`: N × n_years matrix of realized catch
- `TAC`: N × n_years matrix of catch recommendations
- `I_obs`: N × n_years matrix of observations
- `parameters`: List of all input parameters
- `n_scenarios`, `n_years`: Dimensions

### Part 6: Performance Analysis (`mse_performance()`)

**Purpose:** Calculates summary statistics across all scenarios

**Performance Metrics:**

**Biomass Metrics (final 10 years):**
- `B_final_mean`: Mean final biomass
- `B_final_sd`: Standard deviation
- `B_final_q05`, `q25`, `q50`, `q75`, `q95`: Quantiles

**Catch Metrics:**
- `catch_total`: Mean annual catch
- `catch_sd`: Catch variability
- `catch_var_cv`: Coefficient of variation

**Risk Metrics:**
- `prob_collapse`: Probability of ever dropping below limit
- `prob_low_final`: Probability low in final year

**Estimation Error:**
- `mae`: Mean absolute error in biomass estimates
- `rmse`: Root mean squared error
- `bias`: Mean estimation bias
- `prob_overestimate`: Fraction of years where B_est > B_true

### Part 7: Visualization (`plot_mse_results()`)

**Purpose:** Creates 4-panel diagnostic plot

**Panels:**

1. **Biomass Trajectories:** Sample of 20 scenarios showing uncertainty range
2. **Assessment Accuracy:** Scatter plot of estimated vs. true final-year biomass
3. **Catch Time Series:** Mean catch with ±1 SD bounds
4. **Performance Summary:** Key metrics displayed as text

## Usage Examples

### Basic MSE Run

```r
# Load the implementation
source("walters_closedloop_mse.R")

# Run closed-loop MSE with default parameters
mse_results <- closed_loop_mse(
  n_years = 50,
  n_scenarios = 100,
  B_init = 1000,
  survey_cv = 0.3,
  hcr_rule = "proportional",
  F_ref = 0.2,
  verbose = TRUE
)

# Analyze results
perf <- mse_performance(mse_results)
print(perf)

# Visualize
plot_mse_results(mse_results)
```

### Compare Harvest Control Rules

```r
# Constant fishing mortality
mse_constant <- closed_loop_mse(
  n_years = 50,
  n_scenarios = 100,
  hcr_rule = "proportional",
  F_ref = 0.2
)

# Risk-averse threshold rule
mse_threshold <- closed_loop_mse(
  n_years = 50,
  n_scenarios = 100,
  hcr_rule = "threshold",
  F_ref = 0.2
)

# Compare
perf_const <- mse_performance(mse_constant)
perf_thresh <- mse_performance(mse_threshold)

cat("Constant F - Mean final biomass:", round(perf_const$B_final_mean, 0), "\n")
cat("Threshold  - Mean final biomass:", round(perf_thresh$B_final_mean, 0), "\n")

cat("Constant F - Collapse prob:", round(perf_const$prob_collapse, 3), "\n")
cat("Threshold  - Collapse prob:", round(perf_thresh$prob_collapse, 3), "\n")
```

### Test Sensitivity to Assessment Uncertainty

```r
# Scenario 1: Perfect assessment (q known)
mse_perfect <- closed_loop_mse(
  n_years = 50,
  n_scenarios = 100,
  q_true = 0.001,
  q_assumed = 0.001,  # Assumed = True
  survey_cv = 0.1,     # Low observation error
  hcr_rule = "proportional"
)

# Scenario 2: Misspecified assessment (q unknown)
mse_misspec <- closed_loop_mse(
  n_years = 50,
  n_scenarios = 100,
  q_true = 0.001,
  q_assumed = 0.0015, # Assumed > True (overestimate biomass)
  survey_cv = 0.3,     # Higher observation error
  hcr_rule = "proportional"
)

# Compare performance
perf_perfect <- mse_performance(mse_perfect)
perf_misspec <- mse_performance(mse_misspec)

cat("Perfect assessment - Collapse prob:", round(perf_perfect$prob_collapse, 3), "\n")
cat("Misspecified assessment - Collapse prob:", round(perf_misspec$prob_collapse, 3), "\n")
```

### Test Hyperstable Index Effects

```r
# Linear proportional index
mse_linear <- closed_loop_mse(
  n_years = 50,
  n_scenarios = 100,
  hyperstable = FALSE,
  hcr_rule = "threshold"
)

# Hyperstable index (range contraction)
mse_hyperstable <- closed_loop_mse(
  n_years = 50,
  n_scenarios = 100,
  hyperstable = TRUE,  # Range contraction effect
  hcr_rule = "threshold"
)

# Hyperstable indices tend to be less informative at low biomass
perf_lin <- mse_performance(mse_linear)
perf_hyper <- mse_performance(mse_hyperstable)

cat("Linear index RMSE:", round(perf_lin$rmse, 0), "\n")
cat("Hyperstable index RMSE:", round(perf_hyper$rmse, 0), "\n")
```

## Relationship to Alaska Groundfish Applications

This implementation provides the methodological foundation for:

1. **NMFS (2004) SEIS Approach:** Simulation scenarios with fixed projections
   - Implemented in Part 1 (Operating Model) + Part 4 (HCR)
   - No feedback from assessment uncertainty

2. **Ianelli et al. (2011) and Ono et al. (2017) Advancement:** Full-feedback MSE with Kalman filter
   - All parts integrated with feedback loop (Part 5)
   - Captures assessment uncertainty (Parts 2-3)
   - Enables robust strategy evaluation

The key advance: Full feedback MSE tests whether management procedures remain effective when assessment estimates contain error that persists across years, not just as static projection scenarios.

## Key Assumptions and Limitations

### Model Assumptions:
1. **Delay-difference dynamics:** Simplified population model (not full age-structure)
2. **Kalman filter:** Linear optimal estimation (may be suboptimal for highly nonlinear systems)
3. **Lognormal errors:** Both recruitment and observation errors are lognormally distributed
4. **Stationary recruitment:** No long-term trends in recruitment potential
5. **Index-based assessment:** Abundance estimates from survey/CPUE only

### Implementation Limitations:
1. **Fixed K* gain:** Could vary over time or be function of estimation history
2. **No spatial structure:** Single-area model (extend for multi-region applications)
3. **Deterministic catch implementation:** Assumes TAC = realized catch (add implementation error for realism)
4. **No ecological interactions:** Single-species framework (extend for ecosystem approaches)

## References

- **Walters, C. J. (2004).** Simple representation of the dynamics of biomass error propagation for stock assessment models. *Canadian Journal of Fisheries and Aquatic Sciences*, 61(2), 154-165.

- **Ianelli, J. N., Hollowed, A. B., Hamazaki, T., Kleiber, P., Livingston, P. A., Megrey, B. A., et al. (2011).** Incorporating climate into an ecosystem evaluation model of the Eastern Bering Sea. *ICES Journal of Marine Science*, 68(6), 1305-1317.

- **Ono, K., Haynie, A. C., Hollowed, A. B., Ianelli, J. N., McGilliard, C., Punt, A. E., et al. (2017).** Management strategy evaluation for multiple fisheries and objectives: Bering Sea walleye pollock. *Fisheries Research*, 183, 310-323.

## Questions and Extensions

### Questions for Further Development:
1. How sensitive are results to Kalman gain K*?
2. What observation error levels make management unstable?
3. How does assessment lag (delay in data availability) affect performance?
4. Can simpler heuristic control rules outperform optimal ones?

### Possible Extensions:
- Multiple fleets with different selectivity patterns
- Density-dependent effects on recruitment
- Ecosystem interactions (predation, competition)
- Economic performance metrics (profit, price response to landings)
- Adaptive management (automatic adjustment of harvest control rules)
- Portfolio analysis (harvest from multiple populations)

---

**Implementation Date:** January 24, 2026
**Status:** Complete and tested (syntax validation)
**Location:** ~/._mymods/MSE_review/doc/walters_closedloop_mse.R
