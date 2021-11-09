require(cmdstanr)
require(tidyverse)
require(posterior)

# make some fake data
y <- pmax(my_logistic(1:20, 100, 10, .5) * rnorm(20, 1), 0)
y <- c(y, 145, 65, 100, 45, 25)

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
fit2 <- exec2$sample(data = stan_dat2, adapt_delta = 0.9)

draws <- fit2$draws() |> 
  as_draws_df()

pairs(select(draws, beta:sus_init))
