require(cmdstanr)
require(tidyverse)
require(posterior)
require(bayesplot)

# make some fake data
# y <- pmax(my_logistic(1:20, 100, 10, .5) * rnorm(20, 1), 0)
# y <- c(y, 145, 65, 100, 45, 25)

y <- read_csv('sample_facility_cases.csv')$Residents.Active

plot(seq_along(y), y)

### Model option 1--------------------------------------------------------------

# info for stan 'data' block
stan_dat <- list(
  max_t = length(y),
  ts = seq_along(y),
  y = as.integer(y),
  inf_init = 0.01
)

# compile and fit the model
exec <- cmdstan_model('stan-scripts/fit-sir.stan', include_path = paste0(getwd(), '/stan-scripts'))
fit <- exec$sample(data = stan_dat, adapt_delta = 0.9)

draws <- fit$draws() |> 
  as_draws_matrix()

pairs(draws[,2:5])

### Model option 2--------------------------------------------------------------

# info for stan 'data' block
stan_dat2 <- list(
  max_t = length(y),
  ts = seq_along(y),
  y = as.integer(y),
  inf_init = 1, 
  alpha = 0.1
)

# compile and fit the model
exec2 <- cmdstan_model('stan-scripts/fit-sir-free.stan', include_path = paste0(getwd(), '/stan-scripts'))
fit2 <- exec2$sample(data = stan_dat2, adapt_delta = 0.99)

# save draws for later
write_csv(as_draws_df(fit2$draws()), paste0('stan-fits/fit-sir-free', Sys.Date(), '.csv'))

# diagnostics
mcmc_trace(fit2$draws(), pars = c('beta', 'sus_init'), n_warmup = 300)
pairs(select(fit2$draws, beta:sus_init))

# time series data
inf_ts <- fit2$draws() |>
  thin_draws(thin = 100) |> 
  as_draws_df() |> 
  pivot_longer(contains('inf_curve'), names_to = 'time', values_to = 'inf') |> 
  mutate(time = as.double(str_extract(time, '\\d+')))

inf_ts |> 
  ggplot(aes(time, inf)) +
  geom_line(aes(col = as.factor(.chain), group = .draw), alpha = 0.2) +
  geom_point(data = tibble(time = seq_along(y), inf = y)) +
  guides(col = guide_legend(override.aes = list(alpha = 1)))
