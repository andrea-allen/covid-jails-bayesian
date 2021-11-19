### Load required packages------------------------------------------------------
library(cmdstanr)
library(tidyverse)
library(posterior)

FNAME = 'epi-timeseries-fed-agg-CA-partial'
SAVE_CSV = TRUE
PLOT_TS = TRUE
SIMULATE = FALSE

dat_org <- read_csv('joined_datasets_california2/epi-timeseries-fed-agg-CA-partial.csv')

#dat_org |>
#  pivot_longer(c(Residents.Active, Staff.Active, Community.Active, Staff.Population)) |>
#  ggplot(aes(Date, value)) +
#  geom_point() +
#  facet_wrap(~name, scales = 'free_y')


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
  print('finished fit')
    post <- as_draws_df(fit$draws())

  if (SAVE_CSV) {
    date <- str_replace(Sys.time(), ':', '-')
    write_csv(post, paste0('stan-fits/simulate-sir-cwr-', date, '.csv'))
  }
}

if (PLOT_TS) {
  inf_ts <- fit$draws() |>
    thin_draws(thin = 100) |>
    as_draws_df() |>
    pivot_longer(matches('yhat'), names_to = 'time', values_to = 'inf') |>
    mutate(time = as.double(str_extract(time, '\\d+')))

  gg <- ggplot(inf_ts, aes(time, inf)) +
    geom_point(aes(col = as.factor(.chain)), alpha = 0.4, shape = 1) +
    geom_smooth(method = 'gam', se = FALSE) +
    guides(col = guide_legend(override.aes = list(alpha = 1)))

  gg
  # + geom_point(data = tibble(time = stan_dat$ts, inf = stan_dat$yr))

  ggsave("prior-p-sir-cwr-ca-fed-agg-res.png")
}

if (PLOT_TS) {
  inf_ts <- fit$draws() |>
    thin_draws(thin = 100) |>
    as_draws_df() |>
    pivot_longer(matches('ywhat'), names_to = 'time', values_to = 'inf') |>
    mutate(time = as.double(str_extract(time, '\\d+')))

  gg <- ggplot(inf_ts, aes(time, inf)) +
    geom_point(aes(col = as.factor(.chain)), alpha = 0.4, shape = 1) +
    geom_smooth(method = 'gam', se = FALSE) +
    guides(col = guide_legend(override.aes = list(alpha = 1)))

  if (!SIMULATE)
    gg + geom_point(data = tibble(time = stan_dat$ts, inf = stan_dat$yw))
  else
    gg
  ggsave("prior-p-sir-cwr-ca-fed-agg-worker.png")
}

if (PLOT_TS) {
  inf_ts <- fit$draws() |>
    thin_draws(thin = 100) |>
    as_draws_df() |>
    pivot_longer(matches('ychat'), names_to = 'time', values_to = 'inf') |>
    mutate(time = as.double(str_extract(time, '\\d+')))

  gg <- ggplot(inf_ts, aes(time, inf)) +
    geom_point(aes(col = as.factor(.chain)), alpha = 0.4, shape = 1) +
    geom_smooth(method = 'gam', se = FALSE) +
    guides(col = guide_legend(override.aes = list(alpha = 1)))

  if (!SIMULATE)
    gg + geom_point(data = tibble(time = stan_dat$ts, inf = stan_dat$yc))
  else
    gg
  ggsave("prior-p-sir-cwr-ca-fed-agg-state.png")
}




## aggregate federal by state
## pick one state
## make a CWR model
## fit single state model >> staff pop,