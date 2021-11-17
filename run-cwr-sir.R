### Load required packages------------------------------------------------------
library(cmdstanr)
library(tidyverse)
library(posterior)

dat_org <- read_csv('epi-timeseries-fac112.csv')

dat_org |> 
  pivot_longer(c(Residents.Active, Staff.Active, Community.Active)) |> 
  ggplot(aes(Date, value)) +
  geom_point() +
  facet_wrap(~name, scales = 'free_y')

stan_dat <- list(
  max_t = nrow(dat_org),
  ts = 1:nrow(dat_org),
  y_res = dat_org$Residents.Active,
  N_res = dat_org$Residents.Population,
  y_staff = dat_org$Staff.Active
  # etc
)