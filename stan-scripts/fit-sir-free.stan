#include /epi-models.stan

data {
    int max_t; // duration of simulation
    real ts[max_t]; // time points to evaluate SIR
    int y[max_t]; // cases for each day
    
    real inf_init; // initial conditions for I compartment
    real alpha;
}

parameters {
    // real<lower=0> alpha;
    real<lower=0> beta;
    real<lower=0> sus_init; 
}

transformed parameters {
    real<lower=0> inf_curve[max_t];
    {
        vector[2] init;
        init[1] = sus_init;
        init[2] = inf_init;
        inf_curve = ode_rk45(sir_free, init, 0, ts, beta, alpha)[:,2];
    }
}

model {
    // alpha ~ lognormal(log(0.1), 0.1);
    beta ~ gamma(2, 1.5);
    sus_init ~ normal(100, 200) T[1,];
    
    y ~ poisson(inf_curve);
}

generated quantities {
  real<lower=0> inf_hat[max_t];
  int<lower=0> y_hat[max_t];
  {
    vector[2] init;
    init[1] = sus_init;
    init[2] = inf_init;
    inf_hat = ode_rk45(sir_free, init, 0, ts, beta, alpha)[:,2];
  }
  y ~ poisson(inf_curve);
}
