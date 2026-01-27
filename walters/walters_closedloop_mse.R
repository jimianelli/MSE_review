################################################################################
# Closed-Loop Management Strategy Evaluation (MSE) using Kalman Filter Approach
#
# Based on Walters (2004) "Simple representation of the dynamics of biomass
# error propagation for stock assessment models"
#
# This implementation provides:
# 1. Operating Model (true dynamics)
# 2. Observation Model (survey with error)
# 3. Assessment Model (Kalman filter estimator)
# 4. Management Procedure (harvest control rule)
# 5. Closed-loop simulation framework
#
# Author: Claude Code
# Date: January 23, 2026
################################################################################

# ============================================================================
# PART 1: OPERATING MODEL (True Population Dynamics)
# ============================================================================

#' Operating Model: Age-Structured Population with Recruitment Variability
#'
#' Simulates true population dynamics using delay-difference model as
#' per Walters (2004) Equation 5
#'
#' @param B_init Initial exploitable biomass
#' @param n_years Number of years to simulate
#' @param M Natural mortality (annual)
#' @param g Growth-survival constant (see Walters eq. 6)
#' @param w_k Mean weight at recruitment age k
#' @param recruitment_sd Standard deviation of recruitment (log-scale)
#' @param harvest_rate Annual harvest rates (fraction of exploitable biomass)
#' @param use_sr Logical: use stock-recruitment relationship? (default: FALSE)
#' @param sr_params Stock-recruitment parameters (Ricker: c(a, b))

operating_model <- function(
    B_init = 1000,
    n_years = 50,
    M = 0.15,           # Natural mortality
    g = 0.95,           # Growth-survival constant
    w_k = 5,            # Mean weight at recruitment
    recruitment_sd = 0.5,  # Log-scale SD (lognormal)
    harvest_rate = rep(0.2, n_years),
    use_sr = FALSE,
    sr_params = c(a = 1.5, b = 0.001)) {

  # Initialize arrays
  B_true <- numeric(n_years + 1)
  R_true <- numeric(n_years + 1)  # Recruitment (age k)
  C_true <- numeric(n_years)      # Catch
  H_true <- numeric(n_years)      # Harvest in biomass

  B_true[1] <- B_init

  # Generate recruitment deviations
  rec_dev <- rlnorm(n_years + 1, meanlog = 0, sdlog = recruitment_sd)

  # Reference recruitment (unfished equilibrium or long-term mean)
  if (use_sr) {
    R_ref <- sr_params["a"] / sr_params["b"]
  } else {
    R_ref <- B_init / 20  # Simple default
  }

  # Simulate forward
  for (t in 1:n_years) {

    # Recruitment (age k) for year t
    if (use_sr) {
      # Ricker stock-recruitment
      R_true[t] <- sr_params["a"] * B_true[t] *
                   exp(-sr_params["b"] * B_true[t]) * rec_dev[t]
    } else {
      # Random recruitment around mean
      R_true[t] <- R_ref * rec_dev[t]
    }

    # Harvest (from harvest control rule)
    H_true[t] <- B_true[t] * harvest_rate[t]
    C_true[t] <- H_true[t]

    # Delay-difference population dynamics (Walters eq. 5)
    # B(t+1) = g*(B(t) - H(t)) + w_k * R(t)
    B_true[t + 1] <- g * (B_true[t] - H_true[t]) + w_k * R_true[t]

    # Ensure biomass doesn't go negative
    B_true[t + 1] <- max(B_true[t + 1], w_k * R_true[t] * 0.1)
  }

  return(list(
    B_true = B_true[-length(B_true)],  # Remove last year
    R_true = R_true[-length(R_true)],
    C_true = C_true,
    H_true = H_true
  ))
}

# ============================================================================
# PART 2: OBSERVATION MODEL (Survey Data with Error)
# ============================================================================

#' Generate Survey Observations
#'
#' Creates relative abundance index with lognormal observation error
#' Simulates CPUE or survey data
#'
#' @param B_true True exploitable biomass
#' @param q_param Catchability coefficient
#' @param survey_cv Coefficient of variation of survey
#' @param hyperstable Optional: make index hyperstable (q proportional to B^beta)

observation_model <- function(
    B_true,
    q_param = 0.001,
    survey_cv = 0.3,
    hyperstable = FALSE,
    beta = 0.8) {

  n_years <- length(B_true)

  if (hyperstable) {
    # Hyperstable function: y_t = q * B_t^beta
    # Simulates range contraction effects
    I_true <- q_param * B_true ^ beta
  } else {
    # Linear proportional: y_t = q * B_t
    I_true <- q_param * B_true
  }

  # Add lognormal observation error
  # E[log(y_obs)] = log(y_true) - 0.5*log(1 + cv^2)
  # So observations are unbiased in expectation
  tau_log <- sqrt(log(1 + survey_cv^2))

  I_obs <- I_true * exp(rnorm(n_years, mean = -tau_log^2/2, sd = tau_log))

  return(list(
    I_true = I_true,
    I_obs = I_obs,
    survey_cv = survey_cv
  ))
}

# ============================================================================
# PART 3: ASSESSMENT MODEL (Kalman Filter Estimator)
# ============================================================================

#' Kalman Filter Assessment Model
#'
#' Updates biomass estimates using Kalman filter equation (Walters eq. 1)
#' Implements simple closed-loop assessment without full age-structure
#'
#' @param B_pred_prev Previous biomass prediction (given data to t-1)
#' @param I_obs Current year observation
#' @param q_assumed Assumed catchability
#' @param K_gain Kalman filter gain (or K* in Walters 2004)
#' @param B_surv Previous year catch used for population dynamics

kalman_filter_update <- function(
    B_pred_prev,      # B_t|t-1 in Walters notation
    I_obs,            # y_t observation
    q_assumed,        # Assumed q
    K_gain = 0.5,     # Kalman gain K*
    catch_prev = 0) {

  # Current estimate based on survey data (Walters eq. 1, alternative form)
  B_star <- I_obs / q_assumed

  # Update using Kalman filter
  # B_t|t = B_t|t-1 + K* * (B* - B_t|t-1)
  B_update <- B_pred_prev + K_gain * (B_star - B_pred_prev)

  # Ensure non-negative
  B_update <- max(B_update, 1)

  return(list(
    B_est = B_update,
    B_star = B_star,
    innovation = B_star - B_pred_prev
  ))
}

#' Calibrate Kalman Filter Gain
#'
#' Determines optimal K* by running simulations across increasing data years
#' Tests Walters (2004) Equation 8 prediction
#'
#' @param op_model_results Output from operating_model()
#' @param obs_model_results Output from observation_model()
#' @param q_param Catchability to use
#' @param min_year_for_calibration Start calibration after this year

calibrate_kalman_gain <- function(
    op_model_results,
    obs_model_results,
    q_param = 0.001,
    min_year_for_calibration = 5) {

  B_true <- op_model_results$B_true
  I_obs <- obs_model_results$I_obs
  n_years <- length(B_true)

  # Initialize estimates
  B_est_prev <- B_true[1]  # Start with true value
  innovations <- numeric(n_years)
  diffs <- numeric(n_years)

  for (t in 1:n_years) {
    # Current estimate from survey
    B_star <- I_obs[t] / q_param

    # For calibration, we use a simple proportional relationship
    # and estimate what K* should be
    innovation <- B_star - B_est_prev
    diff_true <- B_true[t] - B_est_prev

    innovations[t] <- innovation
    diffs[t] <- diff_true

    # Update estimate for next year
    # For calibration, we use the true biomass as if it were known
    B_est_prev <- B_true[t]
  }

  # Perform regression B_t|t - B_t|t-1 = K* * (B* - B_t|t-1)
  # This tests Walters equation 8
  keep_idx <- min_year_for_calibration:n_years

  # Use least squares to estimate K*
  fit <- lm(diffs[keep_idx] ~ innovations[keep_idx] - 1)  # Regression through origin
  K_gain_est <- as.numeric(coef(fit))
  K_gain_est <- max(min(K_gain_est, 1), 0)  # Constrain to [0, 1]

  return(list(
    K_gain = K_gain_est,
    regression_fit = fit,
    rsquared = summary(fit)$r.squared
  ))
}

# ============================================================================
# PART 4: MANAGEMENT PROCEDURE (Harvest Control Rule)
# ============================================================================

#' Harvest Control Rule (Management Procedure)
#'
#' Converts biomass estimate to catch recommendation
#' Common implementations: fixed-escapement, proportional control, etc.
#'
#' @param B_est Estimated exploitable biomass
#' @param B_ref Reference biomass (e.g., MSY level)
#' @param F_ref Reference fishing mortality
#' @param B_limit Lower biomass limit
#' @param rule Type of control rule

harvest_control_rule <- function(
    B_est,
    B_ref,
    F_ref = 0.2,
    B_limit = 0.2 * B_ref,
    rule = "proportional") {

  if (rule == "proportional") {
    # TAC = F_ref * B_est (constant F strategy)
    TAC <- F_ref * B_est
  }
  else if (rule == "threshold") {
    # Adjusted control rule with threshold
    if (B_est < B_limit) {
      TAC <- 0  # No fishing below limit
    } else if (B_est < B_ref) {
      # Linear increase from 0 to F_ref*B_ref as B goes from B_limit to B_ref
      slope <- (F_ref * B_ref - 0) / (B_ref - B_limit)
      TAC <- slope * (B_est - B_limit)
    } else {
      TAC <- F_ref * B_est
    }
  }
  else if (rule == "fixed_catch") {
    # Fixed total allowable catch
    TAC <- 200
  }

  return(max(TAC, 0))  # Ensure non-negative
}

# ============================================================================
# PART 5: CLOSED-LOOP MSE SIMULATION
# ============================================================================

#' Closed-Loop Management Strategy Evaluation
#'
#' Full MSE with feedback: operating model -> observations -> assessment ->
#' management -> decisions -> back to operating model
#'
#' @param n_years Number of years to simulate
#' @param n_scenarios Number of Monte Carlo replicates
#' @param B_init Initial biomass
#' @param M Natural mortality
#' @param g Growth-survival constant
#' @param q_true True catchability
#' @param q_assumed Assumed catchability (assessment)
#' @param survey_cv Survey observation error
#' @param hcr_rule Harvest control rule to test
#' @param verbose Print progress?

closed_loop_mse <- function(
    n_years = 50,
    n_scenarios = 100,
    B_init = 1000,
    M = 0.15,
    g = 0.95,
    w_k = 5,
    q_true = 0.001,
    q_assumed = 0.001,
    survey_cv = 0.3,
    recruitment_sd = 0.5,
    hcr_rule = "proportional",
    F_ref = 0.2,
    hyperstable = FALSE,
    verbose = TRUE) {

  # Storage for results
  B_list <- vector("list", n_scenarios)
  C_list <- vector("list", n_scenarios)
  B_est_list <- vector("list", n_scenarios)
  TAC_list <- vector("list", n_scenarios)
  I_obs_list <- vector("list", n_scenarios)

  if (verbose) cat("Starting closed-loop MSE simulation...\n")

  for (scenario in 1:n_scenarios) {

    if (verbose && scenario %% 20 == 0) {
      cat("  Scenario", scenario, "of", n_scenarios, "\n")
    }

    # Initialize arrays for this scenario
    B_true <- numeric(n_years + 1)
    B_est <- numeric(n_years + 1)
    B_pred <- numeric(n_years + 1)
    C_realized <- numeric(n_years)
    TAC <- numeric(n_years)
    I_obs <- numeric(n_years)

    B_true[1] <- B_init
    B_est[1] <- B_init
    B_pred[1] <- B_init

    # Generate random recruitment and survey deviations
    rec_dev <- rlnorm(n_years + 1, meanlog = 0, sdlog = recruitment_sd)
    R_ref <- B_init / 20

    for (t in 1:n_years) {

      # Step 1: Assessment (Kalman filter update)
      if (t == 1) {
        K_gain <- 0.5  # Default for first year
      } else {
        # In practice, would calibrate once; here we use fixed value
        K_gain <- 0.5
      }

      # Generate observation
      if (hyperstable) {
        I_true_t <- q_true * B_true[t] ^ 0.8
      } else {
        I_true_t <- q_true * B_true[t]
      }

      tau_log <- sqrt(log(1 + survey_cv^2))
      I_obs[t] <- I_true_t * exp(rnorm(1, mean = -tau_log^2/2, sd = tau_log))

      # Kalman filter update
      update_result <- kalman_filter_update(
        B_pred_prev = B_pred[t],
        I_obs = I_obs[t],
        q_assumed = q_assumed,
        K_gain = K_gain
      )

      B_est[t] <- update_result$B_est

      # Step 2: Management procedure (harvest control rule)
      B_ref <- B_init  # Reference biomass

      TAC[t] <- harvest_control_rule(
        B_est = B_est[t],
        B_ref = B_ref,
        F_ref = F_ref,
        B_limit = 0.2 * B_ref,
        rule = hcr_rule
      )

      # Realized catch (stochastic with observation error on catch composition)
      # In simplified form, assume TAC is achieved
      C_realized[t] <- TAC[t]

      # Step 3: Operating model (population dynamics)
      # Recruitment
      R_t <- R_ref * rec_dev[t]

      # Delay-difference model
      B_true[t + 1] <- g * (B_true[t] - C_realized[t]) + w_k * R_t
      B_true[t + 1] <- max(B_true[t + 1], 1)

      # Step 4: Predict next year's biomass (for assessment)
      B_pred[t + 1] <- g * (B_est[t] - C_realized[t]) + w_k * R_ref
      B_pred[t + 1] <- max(B_pred[t + 1], 1)
    }

    # Store results
    B_list[[scenario]] <- B_true[1:n_years]
    B_est_list[[scenario]] <- B_est[1:n_years]
    C_list[[scenario]] <- C_realized
    TAC_list[[scenario]] <- TAC
    I_obs_list[[scenario]] <- I_obs
  }

  # Convert to matrices for easier analysis
  B_matrix <- do.call(rbind, B_list)
  B_est_matrix <- do.call(rbind, B_est_list)
  C_matrix <- do.call(rbind, C_list)
  TAC_matrix <- do.call(rbind, TAC_list)

  if (verbose) cat("MSE simulation complete.\n")

  return(list(
    B_true = B_matrix,
    B_est = B_est_matrix,
    catch = C_matrix,
    TAC = TAC_matrix,
    I_obs = do.call(rbind, I_obs_list),
    n_scenarios = n_scenarios,
    n_years = n_years,
    parameters = list(
      B_init = B_init,
      M = M,
      g = g,
      q_true = q_true,
      q_assumed = q_assumed,
      survey_cv = survey_cv,
      F_ref = F_ref,
      hcr_rule = hcr_rule
    )
  ))
}

# ============================================================================
# PART 6: PERFORMANCE ANALYSIS
# ============================================================================

#' Summarize MSE Performance
#'
#' Calculates performance metrics for management strategy

mse_performance <- function(mse_results) {

  B_true <- mse_results$B_true
  B_est <- mse_results$B_est
  catch <- mse_results$catch
  n_years <- mse_results$n_years

  # Key performance indicators
  performance <- list()

  # Biomass metrics (summary statistics across final years)
  final_years <- (n_years - 9):n_years
  B_final <- B_true[, final_years]

  performance$B_final_mean <- mean(B_final)
  performance$B_final_sd <- sd(as.vector(B_final))
  performance$B_final_q05 <- quantile(as.vector(B_final), 0.05)
  performance$B_final_q25 <- quantile(as.vector(B_final), 0.25)
  performance$B_final_q50 <- quantile(as.vector(B_final), 0.50)
  performance$B_final_q75 <- quantile(as.vector(B_final), 0.75)
  performance$B_final_q95 <- quantile(as.vector(B_final), 0.95)

  # Catch metrics
  performance$catch_total <- mean(rowSums(catch))
  performance$catch_sd <- sd(rowSums(catch))
  performance$catch_var_cv <- sd(as.vector(catch)) / mean(as.vector(catch))

  # Risk metrics
  B_ref <- mse_results$parameters$B_init
  B_limit <- 0.2 * B_ref

  performance$prob_collapse <- mean(rowMins(B_true) < B_limit)
  performance$prob_low_final <- mean(B_true[, n_years] < B_limit)

  # Estimation error metrics
  est_error <- B_est - B_true
  performance$mae <- mean(abs(est_error))
  performance$rmse <- sqrt(mean(est_error^2))
  performance$bias <- mean(est_error)
  performance$prob_overestimate <- mean(est_error > 0)

  return(performance)
}

#' Helper function to get row minimums
rowMins <- function(x) apply(x, 1, min)

# ============================================================================
# PART 7: VISUALIZATION
# ============================================================================

#' Plot MSE Results
#'
#' Visualize biomass trajectories and performance

plot_mse_results <- function(mse_results, scenario_subset = NULL) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("plot_mse_results requires ggplot2. Install with install.packages('ggplot2').")
  }

  B_true <- mse_results$B_true
  B_est <- mse_results$B_est
  catch <- mse_results$catch
  n_scenarios <- mse_results$n_scenarios
  n_years <- mse_results$n_years

  # Select scenarios to plot
  if (is.null(scenario_subset)) {
    if (n_scenarios <= 20) {
      plot_scenarios <- 1:n_scenarios
    } else {
      plot_scenarios <- sample(1:n_scenarios, 20)
    }
  } else {
    plot_scenarios <- scenario_subset
  }

  years <- 1:n_years

  # Plot 1: Biomass trajectories
  df_biomass <- data.frame(
    year = rep(years, times = length(plot_scenarios)),
    biomass = as.vector(t(B_true[plot_scenarios, , drop = FALSE])),
    scenario = factor(rep(plot_scenarios, each = n_years))
  )

  p1 <- ggplot2::ggplot(df_biomass, ggplot2::aes(x = year, y = biomass, group = scenario)) +
    ggplot2::geom_line(alpha = 0.3, color = "black") +
    ggplot2::labs(
      title = "True Biomass Trajectories (sample scenarios)",
      x = "Year",
      y = "Exploitable Biomass"
    ) +
    ggplot2::theme_minimal()

  # Plot 2: Estimated vs True (last year distribution)
  df_accuracy <- data.frame(
    true = B_true[, n_years],
    est = B_est[, n_years]
  )

  p2 <- ggplot2::ggplot(df_accuracy, ggplot2::aes(x = true, y = est)) +
    ggplot2::geom_point(alpha = 0.5) +
    ggplot2::geom_abline(intercept = 0, slope = 1, linetype = "dashed", color = "red") +
    ggplot2::labs(
      title = "Assessment Accuracy",
      x = "True Biomass (Year 50)",
      y = "Estimated Biomass (Year 50)"
    ) +
    ggplot2::theme_minimal()

  # Plot 3: Catch time series
  catch_means <- colMeans(catch)
  catch_sd <- apply(catch, 2, sd)

  df_catch <- data.frame(
    year = years,
    mean = catch_means,
    sd = catch_sd,
    lo = catch_means - catch_sd,
    hi = catch_means + catch_sd
  )

  p3 <- ggplot2::ggplot(df_catch, ggplot2::aes(x = year, y = mean)) +
    ggplot2::geom_ribbon(ggplot2::aes(ymin = lo, ymax = hi), fill = "steelblue", alpha = 0.2) +
    ggplot2::geom_line(color = "steelblue4") +
    ggplot2::labs(
      title = "Mean Catch with 1 SD bounds",
      x = "Year",
      y = "Catch"
    ) +
    ggplot2::theme_minimal()

  # Plot 4: Performance summary
  perf <- mse_performance(mse_results)
  perf_df <- data.frame(
    label = c("Mean Final B", "Mean Total Catch", "Prob Collapse", "RMSE (B_est)", "Bias (B_est)"),
    value = c(
      round(perf$B_final_mean, 0),
      round(perf$catch_total, 0),
      round(perf$prob_collapse, 2),
      round(perf$rmse, 0),
      round(perf$bias, 0)
    )
  )
  perf_df$text <- paste(perf_df$label, ":", perf_df$value)
  perf_df$y <- rev(seq_len(nrow(perf_df)))

  p4 <- ggplot2::ggplot(perf_df, ggplot2::aes(x = 0, y = y, label = text)) +
    ggplot2::geom_text(hjust = 0, size = 4) +
    ggplot2::labs(title = "Performance Metrics") +
    ggplot2::xlim(0, 1) +
    ggplot2::ylim(0, nrow(perf_df) + 1) +
    ggplot2::theme_void() +
    ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0, face = "bold"))

  # Arrange plots in a 2x2 grid
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(layout = grid::grid.layout(2, 2)))
  print(p1, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 1))
  print(p2, vp = grid::viewport(layout.pos.row = 1, layout.pos.col = 2))
  print(p3, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 1))
  print(p4, vp = grid::viewport(layout.pos.row = 2, layout.pos.col = 2))

  invisible(list(
    biomass = p1,
    accuracy = p2,
    catch = p3,
    performance = p4
  ))
}

# ============================================================================
# EXAMPLE USAGE
# ============================================================================

if (FALSE) {

  # Run a closed-loop MSE
  mse_results <- closed_loop_mse(
    n_years = 50,
    n_scenarios = 100,
    B_init = 1000,
    M = 0.15,
    g = 0.95,
    q_true = 0.001,
    q_assumed = 0.001,
    survey_cv = 0.3,
    recruitment_sd = 0.5,
    hcr_rule = "threshold",
    F_ref = 0.2,
    hyperstable = FALSE,
    verbose = TRUE
  )

  # Analyze results
  perf <- mse_performance(mse_results)
  print(perf)

  # Plot results
  plot_mse_results(mse_results)

  # Compare management strategies
  mse_constant <- closed_loop_mse(n_years = 50, n_scenarios = 100,
                                   hcr_rule = "proportional")
  mse_threshold <- closed_loop_mse(n_years = 50, n_scenarios = 100,
                                    hcr_rule = "threshold")

  perf_constant <- mse_performance(mse_constant)
  perf_threshold <- mse_performance(mse_threshold)

  cat("Constant F strategy:\n")
  cat("  Mean final biomass:", round(perf_constant$B_final_mean, 0), "\n")
  cat("  Mean catch:", round(perf_constant$catch_total, 0), "\n")
  cat("  Collapse probability:", round(perf_constant$prob_collapse, 2), "\n\n")

  cat("Threshold strategy:\n")
  cat("  Mean final biomass:", round(perf_threshold$B_final_mean, 0), "\n")
  cat("  Mean catch:", round(perf_threshold$catch_total, 0), "\n")
  cat("  Collapse probability:", round(perf_threshold$prob_collapse, 2), "\n")
}

################################################################################
# END OF WALTERS CLOSED-LOOP MSE IMPLEMENTATION
################################################################################
