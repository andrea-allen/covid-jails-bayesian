#include /epi-models.stan

data {
    int max_t; // duration of simulation
    real ts[max_t]; // time points to evaluate SIR
    real alpha;
    int inf_init_res;
    int pop_init;
    int inf_init_worker;
    int inf_init_state;
    real worker_pop;
    real state_pop;
}

generated quantities {
  int yhat[max_t]; // cases for each day
  int ywhat[max_t];
  int ychat[max_t];
  real N[max_t]; // population size for each day
  real<lower=0> beta;
  real<lower=0, upper=pop_init> rec_init_res;
  real<lower=0, upper=worker_pop> rec_init_worker;
  real<lower=0, upper=state_pop> rec_init_state;
  real arr_rate;
  vector[7] epi_curve[max_t];

  /* sample priors */
  beta = lognormal_rng(log(0.3), 0.3);
  rec_init_res = uniform_rng(10, .5*pop_init);
  rec_init_state = uniform_rng(10, .5*state_pop);
  rec_init_worker = uniform_rng(10, .5*worker_pop);
  arr_rate = normal_rng(0, 1);
  
  /* sample infection curve */
  {
    vector[7] init;
    init[1] = inf_init_res;
    init[2] = rec_init_res;
    init[3] = pop_init;
    init[4] = inf_init_worker;
    init[5] = rec_init_worker;
    init[6] = inf_init_state;
    init[7] = rec_init_state;
    epi_curve = ode_rk45(sir_cwr_state, init, 0.9, ts, beta, alpha, arr_rate, worker_pop, state_pop);
  }
    
  N = normal_rng(epi_curve[:, 3], 30);
  yhat = poisson_rng(epi_curve[:, 1]);
  ywhat = poisson_rng(epi_curve[:, 4]);
  ychat = poisson_rng(epi_curve[:,6]);
}
