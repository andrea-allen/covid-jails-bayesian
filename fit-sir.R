require(cmdstanr)
require(tidyverse)
require(posterior)

# make some fake data
y <- pmax(my_logistic(1:20, 100, 10, .5) * rnorm(20, 1), 0)
y <- c(y, 145, 65, 100, 45, 25)

# info for stan 'data' block
stan_dat <- list(
  max_t = length(y),
  ts = seq_along(y),
  y = as.integer(y),
  inf_init = 0.01
)

# compile and fit the model
exec <- cmdstan_model('stan-scripts/fit-sir.stan', include_path = paste0(getwd(), '/stan-scipts')
fit <- exec$sample(data = stan_dat, adapt_delta = 0.9)

draws <- fit$draws() |> 
  as_draws_matrix()

pairs(draws[,2:5])
