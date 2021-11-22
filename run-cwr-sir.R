### Load required packages------------------------------------------------------
library(cmdstanr)
library(tidyverse)
library(posterior)

FNAME = 'epi-timeseries-fed-agg-CA-partial'
SAVE_CSV = TRUE
PLOT_TS = TRUE
SIMULATE = TRUE

dat_org <- read_csv('joined_datasets_california2/epi-timeseries-fed-agg-CA-partial.csv')


if (!SIMULATE) {
  stan_dat <- list(
    max_t = nrow(dat_org),
    ts = 1:nrow(dat_org),
    yw = dat_org$Staff.Active,
    yr = dat_org$Residents.Active,
    yc = dat_org$Community.Active,
    N = dat_org$Residents.Population,
    worker_pop = dat_org$Staff.Population[1],
    state_pop = 39000000,
    alpha = 1/14
  )

  print( 'got to here' )
  print(stan_dat)

  exec <- cmdstan_model(
    'stan-scripts/fit-sir-cwr.stan',
    include_path = paste0(getwd(), '/stan-scripts')
  )

  fit <- exec$sample(data = stan_dat, adapt_delta = 0.8)

  post <- as_draws_df(fit$draws())

  if (SAVE_CSV) {
    write_csv(post, paste0('stan-fits/fit-sir-cwr-', FNAME, '-', Sys.Date(), '.csv'))
  }
} else { 
  # SIMULATE
  stan_dat <- list(
    max_t = nrow(dat_org),
    ts = 1:nrow(dat_org),
    inf_init_res = dat_org$Residents.Active[1],
    pop_init = dat_org$Residents.Population[1],
    inf_init_worker = dat_org$Staff.Active[1],
    inf_init_state = dat_org$Community.Active[1],
    worker_pop = dat_org$Staff.Population[1],
    state_pop = 39000000,
    alpha = 1/14
  )

  # compile and fit the model
  exec <- cmdstan_model(
    'stan-scripts/simulate-sir-cwr.stan',
    include_path = paste0(getwd(), '/stan-scripts')
  )

  fit <- exec$sample(
    data = stan_dat,
    chains = 1,
    iter_sampling = 1000,
    fixed_param = TRUE
  )
  
  post <- as_draws_df(fit$draws())

  if (SAVE_CSV) {
    date <- str_replace(Sys.time(), ':', '-')
    write_csv(post, paste0('stan-fits/simulate-sir-cwr-', date, '.csv'))
  }
}

if (PLOT_TS) {
  draws_ts <- fit$draws() |>
    as_draws_df() |>
    slice_sample(n = 200) |>
    pivot_longer(matches('y\\w*hat'), values_to = 'inf') |> 
    select(name, inf, contains('.')) |> 
    extract(name, c('Group', 'Time'), '(\\w+)\\[(\\d+)', remove = TRUE) |> 
    mutate(
      Group = as.character(fct_recode(
        Group, Community.Active = 'ychat', 
        Residents.Active = 'yhat', Staff.Active = 'ywhat'
      ))
    )
  
  obs_ts <- dat_org |>
    mutate(Time = seq_along(Date)) |> 
    pivot_longer(contains('Active'), names_to = 'Group', values_to = 'inf')

  ggplot(draws_ts, aes(as.double(Time), inf)) +
    geom_point(aes(col = as.factor(.chain)), alpha = 0.4, shape = 1) +
    geom_smooth(method = 'gam', se = FALSE, col = 'gray70', linetype = 'dashed') +
    geom_point(data = obs_ts) +
    facet_wrap(~Group, nrow = 1, scales = 'free')
    guides(col = guide_legend(override.aes = list(alpha = 1)))
}
