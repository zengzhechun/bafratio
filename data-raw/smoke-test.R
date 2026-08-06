# 冒烟测试：加载包，跑通核心流程与全部绘图函数，输出数值与 PNG 供目检
suppressPackageStartupMessages(devtools::load_all("."))
ggsave <- ggplot2::ggsave

data(sim_nc); data(sim_est)

cat("==== 1. ber_estimate ====\n")
est <- ber_estimate(sim_est$logRr, sim_est$seLogRr,
                    sim_nc$logRr, sim_nc$seLogRr, ncNames = sim_nc$outcome)
print(est)

cat("\n==== 2. ber_bootstrap ====\n")
boot <- ber_bootstrap(sim_est$logRr, sim_est$seLogRr,
                      sim_nc$logRr, sim_nc$seLogRr, nBoot = 2000, seed = 42)
print(boot)

cat("\n==== 3. ber_analyze (含 LOO) ====\n")
fit <- ber_analyze(sim_est$logRr, sim_est$seLogRr,
                   sim_nc$logRr, sim_nc$seLogRr, ncNames = sim_nc$outcome,
                   nBoot = 2000, seed = 42, loo = TRUE, looBoot = 300)
print(fit)

cat("\n==== 4. LOO 表 ====\n")
print(as.data.frame(fit$loo))

dir.create("smoke_plots", showWarnings = FALSE)
ggsave("smoke_plots/01_gauge.png", plot_gauge(fit), width = 8, height = 3.2, dpi = 150)
ggsave("smoke_plots/02_null.png", plot_null(fit), width = 8, height = 5.5, dpi = 150)
ggsave("smoke_plots/03_calibration.png", plot_calibration(fit), width = 8, height = 4, dpi = 150)
ggsave("smoke_plots/04_qq.png", plot_qq(fit), width = 6.5, height = 5, dpi = 150)
ggsave("smoke_plots/05_loo.png", plot_loo(fit), width = 8, height = 5.5, dpi = 150)
ggsave("smoke_plots/06_boot.png", plot_boot(fit), width = 8, height = 4.5, dpi = 150)

cat("\n==== 5. sccs 真实数据（偏倚主导案例）====\n")
data(sccs, package = "EmpiricalCalibration")
nc <- sccs[sccs$groundTruth == 0, ]
pc <- sccs[sccs$groundTruth == 1, ]
fitSccs <- ber_analyze(pc$logRr, pc$seLogRr, nc$logRr, nc$seLogRr,
                       ncNames = nc$drugName, nBoot = 2000, seed = 42)
print(fitSccs)
ggsave("smoke_plots/07_sccs_gauge.png", plot_gauge(fitSccs), width = 8, height = 3.2, dpi = 150)
ggsave("smoke_plots/08_sccs_null.png", plot_null(fitSccs), width = 8, height = 5.5, dpi = 150)

cat("\n==== 6. cohortMethod 真实数据（效应主导案例）====\n")
data(cohortMethod, package = "EmpiricalCalibration")
nc2 <- cohortMethod[cohortMethod$groundTruth == 0, ]
pc2 <- cohortMethod[cohortMethod$groundTruth == 1, ]
fitCm <- ber_analyze(pc2$logRr, pc2$seLogRr, nc2$logRr, nc2$seLogRr,
                     ncNames = nc2$drugName, nBoot = 2000, seed = 42)
print(fitCm)
ggsave("smoke_plots/09_cm_gauge.png", plot_gauge(fitCm), width = 8, height = 3.2, dpi = 150)

cat("\n==== 7. bsr 别名一致性 ====\n")
stopifnot(identical(bsr_estimate, ber_estimate), identical(bsr_loo, ber_loo))
cat("aliases OK\n")
