# Walters (2004) Equations - R Implementation Reference

This document maps the mathematical equations from Walters (2004) to the corresponding R code sections.

## Population Dynamics

### Equation 5: Delay-Difference Model

**Walters 2004:**
```
B(t+1) = g * (B(t) - H(t)) + w_k * R(t)
```

**Where:**
- B(t) = Exploitable biomass at start of year t
- H(t) = Harvest in biomass units during year t
- g = Survival-growth constant accounting for natural mortality and growth
- w_k = Mean weight at recruitment age k
- R(t) = Recruitment (numbers at age k)

**R Implementation:**
```r
# In operating_model() function, line 85
B_true[t + 1] <- g * (B_true[t] - H_true[t]) + w_k * R_true[t]
```

### Equation 6: Growth-Survival Constant

**Walters 2004:**
```
g = (1 - M) * (1 + growth rate)
```

Or simplified:
```
g ≈ 1 - M  (if growth is small relative to other terms)
```

**Parameter Specification in R:**
```r
# Typical value for temperate groundfish
g = 0.95  # Implies M ≈ 0.05 or moderate growth-survival

# In operating_model() parameters
closed_loop_mse(g = 0.95, ...)
```

### Recruitment Generation

**R Implementation (operating_model, lines 56-77):**
```r
# Log-normal recruitment deviations
rec_dev <- rlnorm(n_years + 1, meanlog = 0, sdlog = recruitment_sd)

# Random recruitment (no stock-recruitment relationship)
R_true[t] <- R_ref * rec_dev[t]

# Or Ricker stock-recruitment relationship
R_true[t] <- sr_params["a"] * B_true[t] *
             exp(-sr_params["b"] * B_true[t]) * rec_dev[t]
```

## Observation Model

### Index Formula: Linear Proportional (Default)

**Walters 2004 (standard):**
```
I(t) = q * B(t)  [true index without error]
log(I_obs(t)) = log(I_true(t)) + ε(t)   [with lognormal error]
```

**R Implementation (observation_model, lines 127-136):**
```r
# True proportional index
I_true <- q_param * B_true

# Lognormal error with correct mean correction
tau_log <- sqrt(log(1 + survey_cv^2))
I_obs <- I_true * exp(rnorm(n_years, mean = -tau_log^2/2, sd = tau_log))
```

### Index Formula: Hyperstable (Range Contraction)

**Walters 2004 (implicit in discussion of index behavior):**
```
I(t) = q * B(t)^β    [β < 1 creates hyperstability]
```

**R Implementation (observation_model, lines 122-125):**
```r
if (hyperstable) {
  I_true <- q_param * B_true ^ beta  # default beta = 0.8
} else {
  I_true <- q_param * B_true        # linear proportional
}
```

**Effect:** Hyperstable indices compress high-biomass signals, making them less informative about true biomass changes at low stock levels.

## Assessment Model: Kalman Filter

### Equation 1: Kalman Filter Update

**Walters 2004:**
```
B_t|t = B_t|t-1 + K* * (B* - B_t|t-1)
```

**Where:**
- B_t|t = Current year estimate given data to year t
- B_t|t-1 = Prediction from previous assessment
- B* = "New" estimate from current observation: B* = I_obs(t) / q_assumed
- K* = Kalman gain (between 0 and 1)

**R Implementation (kalman_filter_update, lines 167-172):**
```r
# Current estimate based on current observation
B_star <- I_obs / q_assumed

# Kalman filter update
B_update <- B_pred_prev + K_gain * (B_star - B_pred_prev)
```

**Interpretation:**
- K* = 0: Trust prediction, ignore observation (no learning from data)
- K* = 1: Trust observation, discard prediction (treat each year independently)
- K* = 0.5: Weight prediction and observation equally

### Equation 8: Kalman Gain Calibration (Regression Test)

**Walters 2004:**
```
Regression: [B_t|t - B_t|t-1] ~ β₀ + β₁ * [B* - B_t|t-1]
Hypothesis: β₀ ≈ 0 and β₁ ≈ K*
```

This tests whether the Kalman filter approximation is valid.

**R Implementation (calibrate_kalman_gain, lines 226-239):**
```r
# Prepare data for regression
keep_idx <- min_year_for_calibration:n_years

# Regression through origin (no intercept)
fit <- lm(diffs[keep_idx] ~ innovations[keep_idx] - 1)
K_gain_est <- as.numeric(coef(fit))

# Constrain to valid range [0, 1]
K_gain_est <- max(min(K_gain_est, 1), 0)
```

### Equation 9: Error Propagation

**Walters 2004 (equation describing error dynamics):**
```
σ²(B_t|t) = K* * τ² / q²

Where τ² is the observation variance
```

**Implication in R:**
- `survey_cv`: Controls observation error magnitude
- `K_gain`: Lower values reduce estimate variance (more stable estimates)
- **Trade-off:** Lower K* = more stable but slower learning from new data

## Management Procedure: Harvest Control Rule

### Proportional (Constant Fishing Mortality) Rule

**General form:**
```
TAC(t) = F_ref * B_est(t)
```

**Where:**
- TAC = Total Allowable Catch recommendation
- F_ref = Target fishing mortality (e.g., 0.2 means remove 20% of exploitable biomass)
- B_est = Current biomass estimate from assessment

**R Implementation (harvest_control_rule, lines 264-266):**
```r
if (rule == "proportional") {
  TAC <- F_ref * B_est
}
```

### Threshold (Risk-Averse) Rule

**Piecewise form:**
```
TAC(t) = 0                              if B_est < B_limit
       = [F_ref * B_ref] * (B_est - B_limit) / (B_ref - B_limit)  if B_limit ≤ B_est < B_ref
       = F_ref * B_est                 if B_est ≥ B_ref
```

**Where:**
- B_limit = Biomass below which no fishing allowed (default: 0.2 * B_ref)
- B_ref = Reference biomass level (e.g., unfished or MSY biomass)

**R Implementation (harvest_control_rule, lines 268-278):**
```r
else if (rule == "threshold") {
  if (B_est < B_limit) {
    TAC <- 0
  } else if (B_est < B_ref) {
    slope <- (F_ref * B_ref - 0) / (B_ref - B_limit)
    TAC <- slope * (B_est - B_limit)
  } else {
    TAC <- F_ref * B_est
  }
}
```

**Purpose:** Reduces harvest when biomass is low, preventing overexploitation during assessment errors.

## Closed-Loop Feedback System

### Annual Sequence (Loop in closed_loop_mse, lines 355-411)

**Year t cycle:**

**Step 1: Observation (lines 365-373)**
```
I_true(t) = q_true * B_true(t)  [+ error for hyperstable if enabled]
I_obs(t) ~ LogNormal(log(I_true(t)), σ²_obs)
```

**Step 2: Assessment Update (lines 376-383)**
```
B_est(t) = B_pred(t) + K_gain * (I_obs(t)/q_assumed - B_pred(t))
```

**Step 3: Management Decision (lines 388-394)**
```
TAC(t) = HCR(B_est(t), B_ref, F_ref, rule_type)
```

**Step 4: Population Dynamics (lines 405-406)**
```
B_true(t+1) = g * (B_true(t) - TAC(t)) + w_k * R(t)
```

**Step 5: Prediction for Next Assessment (lines 409-410)**
```
B_pred(t+1) = g * (B_est(t) - TAC(t)) + w_k * R_ref
```

The prediction uses the **estimated** biomass and **mean recruitment**, since the true values are unknown to the manager.

## Performance Metrics

### Mean Absolute Error (MAE)

**Definition:**
```
MAE = (1/T) * Σ|B_est(t) - B_true(t)|
```

**R Implementation (mse_performance, line 494):**
```r
mae <- mean(abs(est_error))
```

### Root Mean Squared Error (RMSE)

**Definition:**
```
RMSE = sqrt[(1/T) * Σ(B_est(t) - B_true(t))²]
```

**R Implementation (mse_performance, line 495):**
```r
rmse <- sqrt(mean(est_error^2))
```

### Bias

**Definition:**
```
Bias = (1/T) * Σ(B_est(t) - B_true(t))
```

**R Implementation (mse_performance, line 496):**
```r
bias <- mean(est_error)
```

**Interpretation:**
- Bias > 0: Estimates systematically overestimate true biomass (optimistic)
- Bias < 0: Estimates systematically underestimate true biomass (conservative)

### Collapse Probability

**Definition:**
```
P_collapse = (# scenarios where min(B) < B_limit) / n_scenarios
```

**R Implementation (mse_performance, line 489):**
```r
prob_collapse <- mean(rowMins(B_true) < B_limit)
```

**Where:**
```
B_limit = 0.2 * B_ref  (or user-specified)
```

## Implementation Quality Checks

### 1. Operating Model Validation

Check that:
```r
# After operating_model():
mean(om$B_true) > 0   # Positive biomass maintained
var(om$B_true) > 0    # Recruitment variability present
mean(om$C_true) > 0   # Harvests achieved
```

### 2. Assessment Accuracy

Check that calibration regression fits well:
```r
# After calibrate_kalman_gain():
summary(calib$regression_fit)$r.squared > 0.5  # R² should be reasonable
calib$K_gain >= 0 & calib$K_gain <= 1         # Gain in valid range
```

### 3. MSE Stability

Check that results are numerically stable:
```r
# After closed_loop_mse():
all(!is.na(mse$B_true))    # No NaN/Inf values
nrow(mse$B_true) == n_scenarios  # All scenarios completed
all(mse$B_true > 0)        # Positive biomass throughout
```

## Troubleshooting Common Issues

### Problem: Estimate diverges from truth

**Possible causes:**
1. K_gain too high (> 0.8) - reduces stability
2. q_assumed wrong - creates systematic bias
3. survey_cv too high - noisy observations confuse estimator

**Solution:**
```r
# Test K_gain sensitivity
for (k in c(0.3, 0.5, 0.7)) {
  mse <- closed_loop_mse(..., K_gain = k)
  perf <- mse_performance(mse)
  cat("K =", k, "RMSE =", round(perf$rmse, 0), "\n")
}
```

### Problem: Collapse probability too high

**Possible causes:**
1. F_ref too aggressive
2. B_limit set too low
3. Assessment misspecification (q_assumed wrong)

**Solution:**
```r
# Test HCR types
mse_prop <- closed_loop_mse(..., hcr_rule = "proportional")
mse_thresh <- closed_loop_mse(..., hcr_rule = "threshold")

# Compare collapse probabilities
perf_prop <- mse_performance(mse_prop)
perf_thresh <- mse_performance(mse_thresh)
```

### Problem: Assessment uncertainty too high (RMSE large)

**Possible causes:**
1. survey_cv too high
2. K_gain too low (slow learning)
3. q_assumed wrong

**Solution:**
```r
# Improve survey precision or increase K_gain
mse_better <- closed_loop_mse(
  ...,
  survey_cv = 0.15,  # Reduce from 0.3
  K_gain = 0.6       # Increase from 0.5
)
```

---

**Document Date:** January 24, 2026
**Reference:** Walters, C.J. (2004). Canadian Journal of Fisheries and Aquatic Sciences, 61(2), 154-165.
