#include /epi-models.stan

data {
    int max_t; // duration of simulation
    real ts[max_t]; // time points to evaluate SIR
    int y[max_t]; // cases for each day
    
    real inf_init; // initial conditions for I compartment
}

parameters {
    real<lower=0> alpha;
    real<lower=0> beta;
    real<lower=0, upper=1> rec_init;
    real<lower=0> samp_effort;
}

transformed parameters {
    real inf_curve[max_t];
    {
        vector[2] init;
        init[1] = inf_init;
        init[2] = rec_init;
        inf_curve = ode_rk45(sir, init, 0, ts, beta, alpha)[:,1];
    }
}

model {
    alpha ~ gamma(2, 2);
    beta ~ gamma(2, 1.5);
    rec_init ~ beta(1.5, 4);
    samp_effort ~ normal(100, 200) T[1,];
    
    for (t in 1:max_t)
        y[t] ~ poisson(inf_curve[t] * samp_effort);
}
