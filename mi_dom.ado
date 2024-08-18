*! mi_dom version 0.0.2  8/13/2024 Joseph N. Luchman

program define mi_dom, eclass //history and version information at end of file

version 15

syntax varlist(min = 1 fv ts) if [aw fw iw pw], Reg_mi(string) Fitstat_mi(string) [MIOpt(string)] 

tempfile mifile	//produce a tempfile to store imputed fitstats for retreival

tempvar touse 

tempname fitstat

gettoken reg_mi regopts_mi: reg_mi // separate out reg() options

quietly generate byte `touse' = 1 `if'

quietly mi estimate, saving(`mifile') `miopt': `reg_mi' `varlist' [`weight'`exp'] `if', `regopts_mi'	//run mi analysis saving results

scalar `fitstat' = 0 //placeholder scalar to hold the sum

local num_imputes = `:word count `e(m_est_mi)''

foreach x of numlist `=e(m_est_mi)' {

	estimates use `mifile', number(`x') //find the focal estimates
	
	scalar `fitstat' = `fitstat' + `=`fitstat_mi''*`num_imputes'^-1 //add in the weighted fitstat value

}

local title = e(title)

ereturn clear

ereturn post, esample(`touse')

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
