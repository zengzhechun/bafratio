# Provenance / generation script for the bundled reference calibration table
# used by baf_screen() / bf_screen() (Layer 2 of the two-layer screening).
#
# The numbers below are the bias-dominated probability P(bias-dominated) by
# bias-fraction (BAF) bin, estimated from the 960-condition BAF estimator
# simulation study (manuscript v38: a five-factor full factorial design —
# true effect psi, bias center mu_B, bias heterogeneity sigma_PS, number of
# negative controls K, and exchangeability violation — crossed to yield
# 960 conditions x 1000 reps = 960,000 simulated target estimates). They are
# the reference calibration reported as Table 2 (twelve-bucket lookup) in the
# bias-fraction manuscript and reused by the interactive explainer; identical
# in spirit to output/tables/v38_part2_reliability_lookup.csv.
#
# Two columns are reported because the BAF 95% CI width is itself informative:
#   * p_bias_dom_narrow  -- P(bias-dominated) conditional on a NARROW bootstrap CI
#                          (half-width <= median half-width across the simulation)
#   * p_bias_dom_wide    -- P(bias-dominated) conditional on a WIDE bootstrap CI
# The screening takes the conservative max(narrow, wide) as the reported
# P(bias-dominated), so the clinician never needs to know which column applies.
#
# med_ci_width (0.1299) is the median bootstrap-CI half-width across the 960
# conditions; it is the cut point that splits "narrow" from "wide".

# Resolve the package root from the script location so the script is portable.
args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
if (length(file_arg)) {
  pkg_root <- normalizePath(file.path(dirname(sub("^--file=", "", file_arg)), ".."))
} else {
  pkg_root <- getwd()
}

# Twelve-bin BAF estimator simulation calibration (manuscript v38, 960 x 1000).
# baf_center, p_bd_narrow, p_bd_wide taken from v38_part2_reliability_lookup.csv.
baf_center <- c(0.0927213667338725, 0.1833447469638830, 0.2654203256284330,
                0.3336647840111200, 0.3906129064194290, 0.4403526433339310,
                0.4881238755070010, 0.5393525702996570, 0.5992885368231120,
                0.6730183696294000, 0.7674044214492160, 0.8862049808498200)

p_bias_dom_narrow <- c(0.00623089354907802, 0.01098315205800810, 0.04286515030828690,
                       0.11140047027888000, 0.24494053828499900, 0.43776731325873800,
                       0.62973723007544900, 0.81213078719604300, 0.92832331837428100,
                       0.97610073667980100, 0.99356847182785400, 0.99687344238524600)

p_bias_dom_wide <- c(0.03568062004678280, 0.07264874869856940, 0.13864607509272700,
                     0.23901703379564400, 0.36133792691859000, 0.50192844004034900,
                     0.64824654622741800, 0.76798986951494800, 0.85601222909835000,
                     0.90221886255502700, 0.93023301621068000, 0.97180859963192200)

baf_reliability <- data.frame(
  baf_center = baf_center,
  p_bias_dom_narrow = p_bias_dom_narrow,
  p_bias_dom_wide = p_bias_dom_wide
)
attr(baf_reliability, "med_ci_width") <- 0.1298899
attr(baf_reliability, "source") <-
  "960-condition BAF estimator simulation (manuscript v38): five-factor full factorial (true effect psi, bias center mu_B, bias heterogeneity sigma_PS, number of negative controls K, exchangeability violation), 960 conditions x 1000 reps = 960,000 simulated target estimates; twelve-bucket lookup (Table 2), narrow/wide columns."

out_file <- file.path(pkg_root, "data", "baf_reliability.rda")
save(baf_reliability, file = out_file, compress = "gzip")
cat("Wrote", out_file, "\n")
print(baf_reliability)
