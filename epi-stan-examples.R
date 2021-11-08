require(cmdstanr)
require(tidyverse)
require(posterior)

rstan_options(auto_write = TRUE)

# info for stan 'data' block
stan_dat <- list(
  max_t = 50,
  ts = 1:50,
  beta = .1,
  alpha = .1,
  c = 5,
  shift_prop = 0.3,
  init_cond = c(.1, .2, .05, .2, .05, 0)
)

# compile the model
exec <- cmdstan_model('simulate-epi-deterministic.stan', include_path = getwd())

# simulate from 'generated quantities' block
fit <- exec$sample(
  data = stan_dat,
  chains = 1,
  iter_sampling = 1,
  fixed_param = TRUE
)

# bad solution for extracting posterior draws
inf_curves <- fit$draws() |> 
  as_tibble() |> 
  pack(
    inf_comm = contains('community'),
    inf_work = contains('workers'),
    inf_res = contains('residents')
  ) |> 
  summarise(across(everything(), ~pivot_longer(.x, everything()))) |> 
  unnest(cols = c(inf_comm, inf_work, inf_res), names_repair = 'unique') |> 
  select(inf_comm = value...2, inf_work = value...4, inf_res = value...6) |> 
  mutate(t = stan_dat$ts)

# plot the results
inf_curves |> 
  pivot_longer(-t) |> 
  ggplot(aes(t, value, col = name)) +
  geom_line()
