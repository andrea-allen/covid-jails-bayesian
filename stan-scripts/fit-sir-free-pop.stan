#include /epi-models.stan

data {
    int max_t; // duration of simulation
    real ts[max_t]; // time points to evaluate SIR
    int y[max_t]; // cases for each day
    real N[max_t]; // population size for each day
    
    real alpha;
}

transformed data {
  real inf_init; // initial conditions for I compartment
  real pop_init;
  inf_init = fmax(1.0, y[1]);
  pop_init = N[1];
}

parameters {
    real<lower=0> beta;
    real<lower=0, upper=pop_init> rec_init;
    real arr_rate;
}

transformed parameters {
    vector[3] epi_curve[max_t]; // output from ODE system
    {
    vector[3] init;
    init[1] = inf_init;
    init[2] = rec_init;
    init[3] = pop_init;
    epi_curve = ode_rk45(sir_free_pop, init, 0.9, ts, beta, alpha, arr_rate);
  }
}

model {
    /* priors */
    beta ~ lognormal(log(0.3), 0.3);
    rec_init ~ normal(0, 100) T[0, pop_init];
    arr_rate ~ normal(0, 1);
    
    /* likelihood */
    N ~ normal(epi_curve[:, 3], 30);
    y ~ poisson(epi_curve[:, 1]);
}

generated quantities {
    int yhat[max_t];
    yhat = poisson_rng(epi_curve[:, 1]);
}
