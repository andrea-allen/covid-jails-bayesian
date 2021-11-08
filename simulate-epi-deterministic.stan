#include /epi-models.stan

data {
  int max_t; // duration of simulation
  real ts[max_t]; // time points to evaluate SIR

  real<lower=0> beta; // infection rate
  real<lower=0> alpha; // recovery rate
  real<lower=1> c; // clustering bonus
  real<lower=0, upper=1> psi; // prop. of workers in facility at any given time
  
  vector[6] init_cond; // initial conditions
}

model {  
}

generated quantities {
   // infection curves for each group
  real inf_community[max_t];
  real inf_workers[max_t];
  real inf_residents[max_t];
  { // brackets for outside of global scope
    vector[6] epi_vec[max_t];
    epi_vec = ode_rk45(
      sir_cwr_no_arrest, init_cond, 0, ts, 
      beta, alpha, c, psi
    );
    inf_community = epi_vec[:,1];
    inf_workers = epi_vec[:,3];
    inf_residents = epi_vec[:,5];
  }
}
