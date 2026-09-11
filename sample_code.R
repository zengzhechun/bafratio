# From GitHub (development version)
# install.packages("remotes")
remotes::install_github("zengzhechun/bafratio")


library(bafratio)

fit <- baf_analyze(
  logRr    = sim_est$logRr,   # primary estimate: log RR = -0.184 (RR = 0.83)
  seLogRr  = sim_est$seLogRr,
  ncLogRr  = sim_nc$logRr,    # 12 negative control outcomes
  ncSeLogRr = sim_nc$seLogRr,
  ncNames  = sim_nc$outcome,
  nBoot    = 2000, seed = 42,
  loo      = TRUE
)
fit
#> bafratio: full BAF / BER analysis
#> ========================================================
#> Empirical null:  mu_B = -0.208, sigma_B = 0.027  (K = 12 negative controls)
#> Uncalibrated:    RR = 0.832 [0.762, 0.909],  p < 0.001
#> Calibrated:      RR = 1.024,  calibrated p 0.649
#> BAF  = 0.879,  95% CI [0.751, 0.994]  (bootstrap median)
#> BER = 7.27,  95% CI [3.01, 164.95]  (log bootstrap, n = 2000)
#> Classification (CI-based):  bias-dominated
#> Diagnostics: Shapiro-Wilk p = 0.637; max |std. resid| = 1.35 (Benign prostatic hyperplasia)
#> Leave-one-out: 12/12 exclusions remain bias-dominated
#> 

plot_baf_gauge(fit)   # primary gauge on the bounded 0-1 scale
plot_gauge(fit)      # auxiliary gauge on the ratio scale
plot_null(fit)
plot_calibration(fit)
plot_loo(fit)
plot_boot(fit)
data(sccs, package = "EmpiricalCalibration")
nc <- sccs[sccs$groundTruth == 0, ]
pc <- sccs[sccs$groundTruth == 1, ]

est <- baf_estimate(pc$logRr, pc$seLogRr, nc$logRr, nc$seLogRr,
                    ncNames = nc$drugName)
est$ber
#> [1] 13.30586
ber_classify(est$ber)
#> [1] "bias-dominated"
#> 

citation("bafratio")
