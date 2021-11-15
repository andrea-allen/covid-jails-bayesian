#include /epi-models.stan

data {
    int max_t; // duration of simulation
    real ts[max_t]; // time points to evaluate SIR
    real alpha;
    real inf_init;
    int pop_init;
}

generated quantities {
  int yhat[max_t]; // cases for each day
  real N[max_t]; // population size for each day
  real<lower=0> beta;
  real<lower=0, upper=pop_init> rec_init;
  real arr_rate;
  vector[3] epi_curve[max_t];

  /* sample priors */
  beta = lognormal_rng(log(0.3), 0.3);
  rec_init = 200;
  arr_rate = normal_rng(0, 1);
  
  /* sample infection curve */
  {
    vector[3] init;
    init[1] = inf_init;
    init[2] = rec_init;
    init[3] = pop_init;
    epi_curve = ode_rk45(sir_free_pop, init, 0.9, ts, beta, alpha, arr_rate);
  }
    
  N = normal_rng(epi_curve[:, 3], 30);
  yhat = poisson_rng(epi_curve[:, 1]);
}
