#include /epi-models.stan

data {
    int max_t; // duration of simulation
    real ts[max_t]; // time points to evaluate SIR
    int yr[max_t]; // resident cases for each day
    int yw[max_t]; // worker cases for each day
    int yc[max_t]; // community cases
    real res_pop; // population size for each day
    real worker_pop; // constant worker pop
    real state_pop; //constant state pop
    real alpha;
}

transformed data {
  real inf_init_res; // initial conditions for I compartment
  real inf_init_worker; // coniditions for I worker compartment
  real inf_init_state;
  real pop_init_res;
  inf_init_res = fmax(1.0, yr[1]);
  inf_init_worker = fmax(1.0, yw[1]);
  inf_init_state = fmax(1.0, yc[1]);
  pop_init_res = res_pop;
}

parameters {
    real<lower=0> beta;
    real<lower=0, upper=pop_init_res> rec_init_res;
    real<lower=0, upper=worker_pop> rec_init_worker;
    real<lower=0, upper=state_pop> rec_init_state;
    real<lower=0> c;
}

transformed parameters {
    vector[6] epi_curve[max_t]; // output from ODE system
    {
    vector[6] init;
    init[1] = inf_init_res;
    init[2] = rec_init_res;
    init[3] = inf_init_worker;
    init[4] = rec_init_worker;
    init[5] = inf_init_state;
    init[6] = rec_init_state;
    epi_curve = ode_rk45(sir_cwr_state2, init, 0.9, ts, beta, alpha, pop_init_res, worker_pop, state_pop, c);
  }
}

model {
    /* priors */
    beta ~ lognormal(log(0.3), 0.3);
    rec_init_res ~ normal(res_pop * .9, 500) T[0, res_pop];
    rec_init_worker ~ normal(worker_pop * .9, 500) T[0, worker_pop];
    rec_init_state ~ normal(state_pop, 1000) T[0, state_pop];
    c ~ beta(2, 4);
    
    /* likelihood */
    yr ~ poisson(epi_curve[:, 1]);
    yw ~ poisson(epi_curve[:, 3]);
    yc ~ poisson(epi_curve[:, 5]);
}

generated quantities {
    int yhat[max_t];
    int ywhat[max_t];
    int ychat[max_t];
    yhat = poisson_rng(epi_curve[:, 1]);
    ywhat = poisson_rng(epi_curve[:,3]);
    ychat = poisson_rng(epi_curve[:,5]);
}
