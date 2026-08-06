# Generates the simulated demonstration datasets shipped in data/
# 完全合成数据：复刻 healthy-adherer 偏倚情景的统计性质，不含任何真实患者数据。
# 种子固定（20260806），任何人运行本脚本都可逐位复现 data/*.rda。
#
# 用法：在包根目录运行  Rscript data-raw/make-sim-data.R

set.seed(20260806)

K <- 12
ncNames <- c(
  "Urinary tract infection", "Cellulitis", "Viral gastroenteritis",
  "Cataract", "Osteoarthritis", "Hemorrhoids",
  "Benign prostatic hyperplasia", "Gout", "Tendinitis",
  "Allergic rhinitis", "Dental caries", "Tinea pedis"
)

# 生成机制：阴性对照的"真实"对数 RR 来自 N(-0.19, 0.068)，
# 即整个研究环境存在系统性的保护方向偏倚（healthy-adherer 型）；
# 再叠加每个对照各自的抽样噪声 N(0, se_k)，se_k ~ U(0.06, 0.18) 模拟精度差异。
seNc <- round(runif(K, 0.06, 0.18), 3)
trueNc <- rnorm(K, mean = -0.19, sd = 0.068)
logRrNc <- round(trueNc + rnorm(K, 0, seNc), 4)

sim_nc <- data.frame(
  outcome = ncNames,
  logRr = logRrNc,
  seLogRr = seNc,
  stringsAsFactors = FALSE
)

# 主估计：观察到一个看似保护性的关联（RR = 0.83, p < 0.001），
# 但其大小与阴性对照揭示的系统偏倚几乎相同——这正是 BER 要暴露的情形。
sim_est <- data.frame(
  label = "Hypothetical drug-outcome pair (simulated)",
  logRr = -0.184,
  seLogRr = 0.045,
  stringsAsFactors = FALSE
)

save(sim_nc, file = "data/sim_nc.rda", compress = "xz")
save(sim_est, file = "data/sim_est.rda", compress = "xz")

# 自检：重新加载并打印关键数值，供与测试锚点核对
load("data/sim_nc.rda")
load("data/sim_est.rda")
cat("sim_nc rows:", nrow(sim_nc), "\n")
cat("sim_est:", sim_est$logRr, sim_est$seLogRr, "\n")
