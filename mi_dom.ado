*! fitdom version 0.0.0  xx/xx/202x Joseph N. Luchman

program define mi_dom, eclass //history and version information at end of file

version 15

syntax varlist if [aw fw iw pw], mi_reg(string) [miopt(string) mi_regops(string)] mi_fitstat(string) //epsilon is a hidden option

tempfile mifile	//produce a tempfile to store imputed fitstats for retreival

tempvar touse 

tempname fitstat

quietly generate byte `touse' = 1 `if'

quietly mi estimate, saving(`mifile') `miopt': `mi_reg' `varlist' [`weight'`exp'] `if', `mi_regopts'	//run mi analysis saving results

scalar `fitstat' = 0 //placeholder scalar to hold the sum

local num_imputes = `:word count `e(m_est_mi)''

foreach x of numlist `=e(m_est_mi)' {

	estimates use `mifile', number(`x') //find the focal estimates
	
	scalar `fitstat' = `fitstat' + `=`mi_fitstat''*`num_imputes'^-1 //add in the weighted fitstat value

}

local title = e(title)

ereturn clear

ereturn post, esample(`touse')

ereturn local title = "Multiply imputed: `title'"

ereturn scalar fitstat = `fitstat'
	
end

/*program to average fitstat across all multiple imputations for use in domin*/
program define mi_avg, rclass

version 15

syntax, name(string) fitstat(string) list(numlist)

tempname passstat



return scalar passstat = `passstat' //average fitstat = the MI'd fitstat

end


/* programming notes and history
- mi_dom version 0.0.0 - mth day, year

