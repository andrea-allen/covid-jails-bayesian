#include /epi-models.stan

data {
    int max_t; // duration of simulation
    real ts[max_t]; // time points to evaluate SIR
    int yr[max_t]; // resident cases for each day
    int yw[max_t]; // worker cases for each day
    int yc[max_t]; // community cases
    real N[max_t]; // population size for each day
    real worker_pop; // constant worker pop
    real state_pop; //constant state pop
    real alpha;
}

transformed data {
  real inf_init; // initial conditions for I compartment
  real inf_init_worker; // coniditions for I worker compartment
  real inf_init_state;
  real pop_init;
  real pop_worker_init;
  inf_init = fmax(1.0, yr[1]);
  inf_init_worker = fmax(1.0, yw[1]);
  inf_init_state = fmax(1.0, yc[1]);
  pop_init = N[1];
  pop_worker_init = worker_pop;
}

parameters {
    real<lower=0> beta;
    real<lower=0, upper=pop_init> rec_init;
    real arr_rate;
    real pop_state;
    real pop_worker;
}

transformed parameters {
    vector[7] epi_curve[max_t]; // output from ODE system
    {
    vector[7] init;
    init[1] = inf_init;
    init[2] = rec_init;
    init[3] = pop_init;
    init[4] = inf_init_worker;
    init[5] = 3; // init worker recovered, in future pass this in
    init[6] = inf_init_state;
    init[7] = 100;
    epi_curve = ode_rk45(sir_cwr_state, init, 0.9, ts, beta, alpha, arr_rate, worker_pop, state_pop);
  }
}

model {
    /* priors */
    beta ~ lognormal(log(0.3), 0.3);
    rec_init ~ normal(0, 100) T[0, pop_init];
    arr_rate ~ normal(0, 1);
    
    /* likelihood */
    N ~ normal(epi_curve[:, 3], 30);
    yr ~ poisson(epi_curve[:, 1]);
    yw ~ poisson(epi_curve[:, 4]);
    yc ~ poisson(epi_curve[:,6]);
}

generated quantities {
    int yhat[max_t];
    int ywhat[max_t];
    int ychat[max_t];
    yhat = poisson_rng(epi_curve[:, 1]);
    ywhat = poisson_rng(epi_curve[:,4]);
    ychat = poisson_rng(epi_curve[:,6]);
}