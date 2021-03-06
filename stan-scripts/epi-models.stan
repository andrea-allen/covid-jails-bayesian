functions {
    real normal_lub_rng(real mu, real sigma, real lb, real ub) {
      real p_lb = normal_cdf(lb, mu, sigma);
      real p_ub = normal_cdf(ub, mu, sigma);
      real u = uniform_rng(p_lb, p_ub);
      real y = mu + sigma * inv_Phi(u);
      return y;
    }

  /**
  * @function sir ODEs for the classic SIR model with normalized compartments
  *
  * @param t Rndependent variable time
  * @param y Vector for I and R states
  * @param beta Infection rate
  * @param alpha Recovery rate
  *
  * @return Vector of system derivatives
  */
  vector sir_norm(real t, vector y, real beta, real alpha) {
    vector[2] dydt;
    dydt[1] = beta * y[1] * (1 - y[1] - y[2]) - alpha * y[1]; // infected update
    dydt[2] = alpha * y[1]; // recovered/immune update
    return dydt;
  }
  
  /**
  * @function sir_free_pop ODEs for the classic SIR model with changing population size
  *
  * @param t Rndependent variable time
  * @param y Vector for I and R states, and population size
  * @param beta Infection rate
  * @param alpha Recovery rate
  * @param arrest_rate Rate of change in prison population
  *
  * @return Vector of system derivatives
  */
  vector sir_free_pop(real t, vector y, real beta, real alpha, real arrest_rate) {
    vector[3] dydt;
    dydt[1] = (beta / y[3]) * y[1] * (y[3] - y[1] - y[2]) - alpha * y[1]; // infected update
    dydt[2] = alpha * y[1]; // recovered update
    dydt[3] = arrest_rate; // population update
    return dydt;
  }
  
  /**
  * @function sir_free_pop ODEs for the classic SIR model with changing population size
  *
  * @param t Rndependent variable time
  * @param y Vector for I and R states, and population size
  * @param beta Infection rate
  * @param alpha Recovery rate
  * @param arrest_rate Rate of change in prison population
  *
  * @return Vector of system derivatives
  */
  vector sir_fix_pop(real t, vector y, real beta, real alpha, real pop_size) {
    vector[2] dydt;
    dydt[1] = (beta / pop_size) * y[1] * (pop_size - y[1] - y[2]); // infected update
    dydt[2] = alpha * y[1]; // recovered update
    return dydt;
  }
  
  /**
  * @function sir_free ODEs for the classic SIR model with unknown population size
  *
  * @param t Rndependent variable time
  * @param y Vector for S and I states
  * @param beta Infection rate
  * @param alpha Recovery rate
  *
  * @return Vector of system derivatives
  */
  vector sir_free(real t, vector y, real beta, real alpha) {
    vector[2] dydt;
    dydt[1] = -beta * y[1] * y[2]; //susceptible update
    dydt[2] = beta * y[1] * y[2] - alpha * y[2]; //infectious update
    return dydt;
  }
  
  /**
  * @function seir ODEs for the classic SEIR model with normalized compartments
  *
  * @param t Rndependent variable time
  * @param y Vector for E, I and R states
  * @param beta Infection rate
  * @param sigma Coefficient for changing asymptomatic infection rate (E->R)
  * @param i2r Recovery rate
  * @param e2r Recovery rate from exposed
  * @param e2i Recovery rate from exposed
  *
  * @return Vector of system derivatives
  */
  vector seir(real t, vector y, real beta, real sigma, real i2r, real e2r, real e2i) {
    vector[3] dydt;
    real s = 1 - y[1] - y[2] - y[3];
    dydt[1] = sigma * beta * y[1] * s + beta * y[2] * s - (e2r + e2i) * y[1];
    dydt[2] = e2i * y[1] - i2r * y[2];
    dydt[3] = e2r * y[1] + i2r * y[2];
    return dydt;
  }
  
  /**
  * @function sir_cwr_no_arrest ODEs for community, workers, residents using SIR
  * compartments, transfer through workers, and no transfer through new arrests/release
  *
  * @param t Rndependent variable time
  * @param y Vector for I and R states of commuity, workers, residents
  * @param beta Infection rate
  * @param alpha Recovery rate
  * @param c A coefficient for change in infection rate within facility
  * @param psi Avg. proportion of workers in facility at any given time
  *
  * @return Vector of system derivatives
  */
  vector sir_cwr_no_arrest(real t, vector y, real beta, real alpha, real c, real psi) {
    vector[6] dydt;
    real s_c = 1 - y[1] - y[2];
    real s_w = 1 - y[3] - y[4];
    real s_r = 1 - y[5] - y[6];
    
    dydt[1] = beta * y[1] * s_c + beta * (1-psi) * y[3] * s_c - alpha * y[1];
    dydt[2] = alpha * y[1];
    
    dydt[3] = beta * (1-psi) * (y[1]+y[3]) * s_w + c * beta * psi * y[5] * s_w - alpha * y[3];
    dydt[4] = alpha * y[3];
    
    dydt[5] = c * beta * y[5] * s_r + c * beta * psi * y[3] * s_r - alpha * y[5];
    dydt[6] = alpha * y[5];
    
    return dydt;
  }

    /**
  * @function sir_cwr_state ODEs for the classic SIR model with changing population size for residents, constant for workers
  * and community, and mechanism for community to prison transmission TBD, aggregated over a whole state
  * FUNCTION IS A WORK IN PROGRESS
  *
  * @param t Independent variable time
  * @param y Vector for I and R states, and population size
  * @param beta Infection rate
  * @param alpha Recovery rate
  * @param arrest_rate Rate of change in prison population
  * @param state_pop
  * @param worker_pop
  *
  * @return Vector of system derivatives
  */
  vector sir_cwr_state2(real t, vector y, real beta, real alpha, real resident_pop, real worker_pop, real state_pop, real c) {
    vector[6] dydt;
    real s_res = resident_pop - y[1] - y[2];
    real s_work = worker_pop - y[3] - y[4];
    real s_state = state_pop - y[5] - y[6];
    real fac_pool = resident_pop + worker_pop;
    real comm_pool = worker_pop + state_pop;


    dydt[1] = beta * s_res * (y[1]+y[3]) / fac_pool - alpha * y[1];
    dydt[2] = alpha * y[1]; // recovered update

    dydt[3] = beta * s_work * (y[1]+y[3]) / fac_pool
      + c * beta * s_work * (y[3]+y[5]) / comm_pool
      - alpha*y[3];
    dydt[4] = alpha * y[3]; // recovered worker update

    dydt[5] = beta * s_state * (y[3]+y[5]) / comm_pool  - alpha * y[5];
    dydt[6] = alpha * y[5];
    return dydt;
  }
  
}