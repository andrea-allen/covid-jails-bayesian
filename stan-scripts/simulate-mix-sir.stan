#include /epi-models.stan

data {
    int max_t; // duration of simulation
    int t2;
    int y[max_t]; // cases for each day
    real N; // population size for each day
    
    real alpha;
}

transformed data {
  real inf_init1; // initial conditions for I compartment
  real inf_init2;
  // real pop_init;
  real ts[max_t]; // time points to evaluate SIR
  real ts2[max_t-t2+1];
  inf_init1 = fmax(1.0, y[1]);
  inf_init2 = 1.0;
  // pop_init = N[1];
  for (i in 1:max_t) ts[i] = i;
  for (i in 1:(max_t-t2+1)) ts2[i] = t2 + i - 1;
}

generated quantities {
  /* parameters and data */
  real<lower=0> beta;
  real<lower=0, upper=N> rec_init1;
  real<lower=0, upper=N> rec_init2;
  real<lower=0, upper=1> lam1;
  real<lower=0, upper=1> lam2;
  int yhat[max_t];
  
  /* draw from priors */
  beta = lognormal_rng(log(0.3), 0.3);
  rec_init1 = 200;
  rec_init2 = normal_rng(log(500), 30);
  lam1 = 0.75;
  lam2 = 0.75;
  
  /* make the infectious curves */
  real inf_curve1[max_t];
  real inf_curve2[max_t];
  real inf_mix[max_t];
  {
    vector[2] epi_curve1[max_t]; // output from ODE system
    vector[2] init1;
    vector[2] init2;
    init1[1] = inf_init1;
    init1[2] = rec_init1;
    // init1[3] = N;
    init2[1] = inf_init2;
    init2[2] = rec_init2;
    // init2[3] = N;
    epi_curve1 = ode_rk45(sir_fix_pop, init1, 0.9, ts, beta, alpha, N);
    inf_curve1 = epi_curve1[:,1];
    inf_curve2[1:(t2-1)] = rep_array(0.0, t2-1);
    inf_curve2[t2:max_t] = ode_rk45(sir_fix_pop, init2, t2-0.1, ts2, beta, alpha, N)[:,1];
    for (i in 1:max_t)
      inf_mix[i] = lam1 * inf_curve1[i] + lam2 * inf_curve2[i];
  }
  
  yhat = poisson_rng(inf_mix);
}
