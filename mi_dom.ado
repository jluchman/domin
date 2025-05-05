*! mi_dom version 0.0.4 1/1/2025 Joseph N. Luchman
**# Program definition
program define mi_dom, eclass
version 16
syntax varlist(min = 1 fv ts) [if] [aw fw iw pw], Reg_mi(string) Fitstat_mi(string) [MIOpt(string)] 
**# Set Stata Environment
tempfile mifile	//produce a tempfile to store imputed fitstats for retreival
tempvar touse 
tempname fitstat
**# Parse varlist and estimate 
gettoken reg_mi regopts_mi: reg_mi, parse(",") // separate out reg() options
local regopts_mi = regexr("`regopts_mi'", "^,", "") // remove leading comma for options when present
quietly generate byte `touse' = 1 `if'
**# Implement multiple imputaiton estimation command
quietly mi estimate, saving(`mifile') `miopt': `reg_mi' `varlist' [`weight'`exp'] `if', `regopts_mi'	//run mi analysis while saving results
**# 
scalar `fitstat' = 0 //placeholder scalar to hold the sum
local num_imputes = `:word count `e(m_est_mi)''
foreach imputation of numlist `=e(m_est_mi)' {
	estimates use `mifile', number(`imputation') //find the focal estimates
	scalar `fitstat' = `fitstat' + `=`fitstat_mi''*`num_imputes'^(-1) //add in the weighted fitstat value
}
**# Return values
local title = e(title)
ereturn clear
ereturn post, esample(`touse') // note, assumption is all obs used that are not 'if'-ed out
ereturn local title = "Multiply imputed: `title'"
ereturn scalar fitstat = `fitstat'
end
/* programming notes and history
- mi_dom version 0.0.0 - August 14, 2023
// 0.0.1 - January 12, 2024
 - fixed 'which' reference - erroneously noted 'fitdom' as program - thanks to Eric Melse for bug report
// 0.0.2 - August 13, 2024
 - allows factor- and time-series variables - thanks to katherine // kathy chan for bug report
 - fix to documentation of -reg_mi()- option
// 0.0.3 - December 20, 2024
-  version to 16 consistent with base -domin-
// 0.0.4 - January 1, 2025
- fix for options; not parsing on comma