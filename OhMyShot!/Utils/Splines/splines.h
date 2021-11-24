//
//  This file defines the target's public headers exposed in Swift.
//

void cubgcv(double *x, double *f, double *df, int *n, double *y, double *c, int *ic, double *var, int *job, double *se,
            double *wk, int *ier);

void cubgcv_with_manual_rho(double *x, double *f, double *df, int *n, double *y, double *c, int *ic, double *var, int *job, double *se, double *wk, int *ier, double rho);
