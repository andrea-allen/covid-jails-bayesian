functions {
  
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
  vector sir(real t, vector y, real beta, real alpha) {
    vector[2] dydt;
    dydt[1] = beta * y[1] * (1 - y[1] - y[2]) - alpha * y[1]; // infected update
    dydt[2] = alpha * y[1]; // recovered/immune update
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
  
}