functions {
  
  vector sir(real t, vector y, real beta, real alpha) {
    vector[2] dydt;
    dydt[1] = beta * y[1] * (1 - y[1] - y[2]) - alpha * y[1]; # infected update
    dydt[2] = alpha * y[1]; # recovered/immune update
    return dydt;
  }
  
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