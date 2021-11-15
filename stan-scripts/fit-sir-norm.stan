#include /epi-models.stan

data {
    int max_t; // duration of simulation
    real ts[max_t]; // time points to evaluate SIR
    real<lower=0, upper=1> y[max_t]; // cases for each day
    real<lower=0> alpha;
}

transformed data {
  real inf_init; // initial conditions for I compartment
  inf_init = fmax(0.0001, y[1]);
}

parameters {
    real<lower=0> beta;
    real<lower=0, upper=1> rec_init;
}

transformed parameters {
    real<lower=0, upper=1> inf_curve[max_t];
    {
        vector[2] init;
        init[1] = inf_init;
        init[2] = rec_init;
        inf_curve = ode_rk45(sir, init, 0.5, ts, beta, alpha)[:,1];
    }
}

model {
    beta ~ gamma(2, 1.5);
    rec_init ~ beta(1.5, 4);
    
    for (t in 1:max_t)
      y[t] ~ normal(inf_curve[t], 0.01) T[0, 1];
}
