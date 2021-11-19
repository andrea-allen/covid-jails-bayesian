### ----------------------------------------------------------------------------
### Run a Stan pipeline for fitting/simulating the sir-free-pop model-----------
### ----------------------------------------------------------------------------
### FNAME: the csv containing data to be fit------------------------------------
### SAVE_CSV: save the posterior and predictive draws?--------------------------
### PLOT_TS: display a plot of the predictive distribution?---------------------
### SIMULATE: simulate fake data (prior predictive check)?----------------------

FNAME = 'kern_171.0'
SAVE_CSV = FALSE
PLOT_TS = TRUE
SIMULATE = FALSE

### Load required packages------------------------------------------------------
library(cmdstanr)
library(tidyverse)
library(posterior)

pivot_ts_var <- function(draws, var_regex) {
  draws |> 
    pivot_longer(matches(var_regex), names_to = 'time', values_to = var_regex) |>
    mutate(time = as.double(str_extract(time, '\\d+(?=])')))
}

### Fit the posterior-----------------------------------------------------------
if (!SIMULATE) {
  dat_org <- read_csv(
    paste0('joined_datasets_california2/', FNAME, '.csv'), 
    col_select = -1
  )
  
  stan_dat <- list(
    max_t = nrow(dat_org),
    t2 = 37,
    y = dat_org$Residents.Active,
    N = mean(dat_org$Residents.Population),
    alpha = 1/14
  )
  
  exec <- cmdstan_model(
    'stan-scripts/fit-mix-sir.stan', 
    include_path = paste0(getwd(), '/stan-scripts')
  )
  
  fit <- exec$sample(data = stan_dat, adapt_delta = 0.8)
  post <- as_draws_df(fit$draws())
  
  if (SAVE_CSV) {
    write_csv(post, paste0('stan-fits/fit-sir-free-pop-', FNAME, '-', Sys.Date(), '.csv'))
  }
} else {
  stan_dat <- list(
    max_t = nrow(dat_org),
    ts = 1:nrow(dat_org),
    inf_init = dat_org$Residents.Active[1],
    pop_init = dat_org$Residents.Population[1],
    alpha = 1/14
  )
  
  # compile and fit the model
  exec <- cmdstan_model(
    'stan-scripts/simulate-sir-free-pop.stan', 
    include_path = paste0(getwd(), '/stan-scripts')
  )
  
  fit <- exec$sample(
    data = stan_dat,
    chains = 1,
    iter_sampling = 1000,
    fixed_param = TRUE
  )
  
  if (SAVE_CSV) {
    date <- str_replace(Sys.time(), ':', '-')
    write_csv(post, paste0('stan-fits/simulate-sir-free-pop-', date, '.csv'))
  }
}

if (PLOT_TS) {
  thin <- fit$draws() |>
    thin_draws(thin = 100) |>
    as_draws_df()

  gg <- ggplot(pivot_ts_var(thin, 'yhat'), aes(time, yhat)) +
    geom_point(
      aes(col = as.factor(.chain)), 
      alpha = 0.4, shape = 1
    ) +
    geom_line(
      aes(y = curve1 * lam1, group = as.factor(.draw)), 
      pivot_ts_var(thin, 'curve1'), 
      alpha = 0.1, col = 'lightblue'
    ) +
    geom_line(
      aes(y = curve2 * lam2, group = as.factor(.draw)), 
      pivot_ts_var(thin, 'curve2'), 
      alpha = 0.3, col = 'lightgreen'
    ) +
    guides(col = guide_legend(override.aes = list(alpha = 1)))
  
    gg + geom_point(data = tibble(time = seq_along(stan_dat$y), yhat = stan_dat$y))
}
