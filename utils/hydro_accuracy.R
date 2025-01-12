library(here)

source(here::here('utils/time_tools.R')) # For find_avail_data_df

### NSE
compute_nse <- function(obs, sim, tol = 0.05) {
  if (length(obs) != length(sim)) {
    stop('the length of OBS and SIM differ')
  }

  # Time steps for which obs and sim are available
  avail_data <- find_avail_data_df(cbind(obs, sim), tol)

  1 - sum((sim[avail_data] - obs[avail_data])^2) /
    sum((obs[avail_data] - mean(obs[avail_data]))^2)
}

### RMSE
compute_rmse <- function(obs, sim, tol = 0.05) {
  # Time steps for which obs and sim are available
  avail_data <- find_avail_data_df(cbind(obs, sim), tol)

  sqrt(sum((sim[avail_data] - obs[avail_data])^2) /
         length(obs[avail_data]))
}

### Error in water balance
compute_dv <- function(obs, sim, tol = 0.05) {

  # Time steps for which obs and sim are available
  avail_data <- find_avail_data_df(cbind(obs, sim), tol)

  (sum(sim[avail_data]) - sum(obs[avail_data])) / sum(obs[avail_data])

}

### Kling Gupta efficiency
compute_kge <- function(obs, sim, tol = 0.05, return_decomp = FALSE) {

  # Time steps for which obs and sim are available
  avail_data <- find_avail_data_df(cbind(obs, sim), tol)

  r <- cor(obs[avail_data], sim[avail_data], use = "everything")
  alpha <- sd(sim[avail_data]) / sd(obs[avail_data])
  beta <- mean(sim[avail_data]) / mean(obs[avail_data])

  kge <- 1 - sqrt((r - 1)^2 + (alpha - 1)^2 + (beta - 1)^2)

  if (return_decomp) {
    return(data.frame(kge = kge, r = r, alpha = alpha, beta = beta))
  } else {
    kge
  }
}
