*! domin version 3.4.1  1/27/2023 Joseph N. Luchman

program define domin, eclass //history and version information at end of file

version 12.1

if replay() { //replay results - error if "by"

	if ("`e(cmd)'" != "domin") error 301
	
	if _by() error 190
	
	Display `0'
	
	exit 0
	
}

syntax varlist(min = 1 ts) [in] [if] [aw pw iw fw] , [Reg(string) Fitstat(string) Sets(string) /// define syntax
All(varlist fv ts) noCOMplete noCONditional EPSilon mi miopt(string) CONSmodel REVerse]

/*defaults and warnings*/
if !strlen("`reg'") { //if no "reg" option specified - notify and use default "regress"

	local reg "regress"	
	
	display "{err}Regression type not entered in {opt reg()}. " _newline ///
	"{opt reg(regress)} assumed." _newline
	
}

if !strlen("`fitstat'") & !strlen("`epsilon'") { //if no "fitstat" and "epsilon" options specified - notify and make default "e(r2)"

	local fitstat "e(r2)"
	
	display "{err}Fitstat type not entered in {opt fitstat()}. " _newline ///
	"{opt fitstat(e(r2))} assumed." _newline
	
}

if strlen("`epsilon'") & strlen("`fitstat'") {	//warning if any "reg" or "fitstat" option specified with "epsilon"

	display "{err}Option {opt epsilon} cannot be used with {opt fitstat(e(r2))}." _newline ///
	"Entries in {opt fitstat()} ignored." _newline

}

if !strlen("`mi'") & strlen("`miopt'") {	//warning if "miopt" is used without "mi"

	local mi "mi"
	
	display "{err}You have added {cmd:mi estimate} options without adding the {opt mi} option.  {opt mi} assumed." _newline

}

/*exit conditions*/
if strlen("`epsilon'") & strlen("`sets'") {	//"epsilon" and "sets" cannot go together 

	display "{err}Options {opt epsilon} and {opt sets()} not allowed together."
	
	exit 198

}

if strlen("`epsilon'") & strlen("`all'") {	//"epsilon" and "all" cannot go together

	display "{err}Options {opt epsilon} and {opt all()} not allowed together."
	
	exit 198

}

if strlen("`epsilon'") & strlen("`consmodel'") {	//"epsilon" and "consmodel" cannot go together

	display "{err}Options {opt epsilon} and {opt consmodel} not allowed together."
	
	exit 198

}

if strlen("`epsilon'") & strlen("`reverse'") 	///"epsilon" and "reverse" cannot go together
display "{err}Options {opt epsilon} and {opt reverse} not allowed together." _newline ///
"{opt reverse} ignored."
	

if strlen("`epsilon'") & strlen("`weight'") {	//"epsilon" disallows weights

	display "{err}Option {opt epsilon} does not allow {opt weight}s."
	
	exit 198

}

if strlen("`epsilon'") & strlen("`mi'") {	//"epsilon" and multiple imputation options cannot go together

	display "{err}Options {opt epsilon} and {opt mi} not allowed together."
	
	exit 198

}

if strlen("`mi'") {	//are data actually mi set?

	capture mi describe

	if _rc {	//if data are not mi set

		display "{err}Data are not {cmd:mi set}."
	
		exit `=_rc'
		
	}
	
	if !r(M) {	//exit if no imputations
	
		display "{err}No imputations for {cmd:mi estimate}." _newline
		
		exit 2001
	
	}

}

capture which lmoremata.mlib	//is moremata present?

if _rc {	//if moremata cannot be found, tell user to install it.

	display "{err}Module {cmd:moremata} not found.  Install {cmd:moremata} here {stata ssc install moremata}."
	
	exit 198

}

/*disallow complete and conditional with epsilon option*/
if strlen("`epsilon'") {

	local conditional "conditional"
	
	local complete "complete"
	
}

/*general set up*/
if strlen("`mi'") tempfile mifile	//produce a tempfile to store imputed fitstats for retreival

tempname ranks domwgts sdomwgts	cdldom cptdom //temporary matrices for results

gettoken dv ivs: varlist	//parse varlist line to separate out dependent from independent variables

gettoken reg regopts: reg, parse(",")	//parse reg() option to pull out estimation command options

if strlen("`regopts'") gettoken erase regopts: regopts, parse(",")	//parse out comma if one is present

local diivs "`ivs'"	//create separate macro to use for display purposes

local mkivs "`ivs'"	//create separate macro to use for sample marking purposes

if `:list sizeof sets' {	//parse and process the sets if included

	/*pull out set #1 from independent variables list*/
	gettoken one two: sets, bind	//pull out the first set
	
	local setcnt = 1	//give the first set a number that can be updated as a macro
	
	local one = regexr("`one'", "[/(]", "")	//remove left paren
			
	local one = regexr("`one'", "[/)]", "")	//remove right paren
	
	local set1 `one'	//name and number set
	
	local ivs "`ivs' <`set1'>"	//include set1 into list of independent variables, include characters for binding in Mata
	
	local mkivs `mkivs' `set1'	//include variables in set1 in the mark sample independent variable list
	
	local diivs "`diivs' set1"	//include the name "set1" into list of variables
	
	
	while strlen("`two'") {	//continue parsing beyond set1 so long at sets remain to be parsed (i.e., there's something in the macro "two")

		gettoken one two: two, bind	//again pull out a set
			
		local one = regexr("`one'", "[/(]", "")	//remove left paren
		
		local one = regexr("`one'", "[/)]", "")	//remove right paren
	
		local set`++setcnt' `one'	//name and number set - advance set count by 1
		
		local ivs "`ivs' <`set`setcnt''>"	//include further sets - separated by binding characters - into independent variables list
		
		local mkivs `mkivs' `set`setcnt''	//include sets into mark sample independent variables list
		
		local diivs "`diivs' set`setcnt'"	//include set number into display list
				
	}
			
}


if `:list sizeof ivs' < 2 {	//exit if too few predictors/sets (otherwise prodices cryptic Mata error)

	display "{err}{cmd:domin} requires at least 2 independent variables or independent variable sets."
	
	exit 198

}

/*finalize setup*/
tempvar touse keep	//declare sample marking variables

tempname obs allfs consfs	//declare temporary scalars

mark `touse'	//declare marking variable

quietly generate byte `keep' = 1 `if' `in' //generate tempvar that adjusts for "if" and "in" statements

markout `touse' `dv' `mkivs' `all' `keep'	//do the sample marking

local nobindivs = subinstr("`ivs'", "<", "", .)	//take out left binding character(s) for use in adjusting e(sample) when obs are dropped by an anslysis

local nobindivs = subinstr("`nobindivs'", ">", "", .)	//take out right binding character(s) for use in adjusting e(sample) when obs are dropped by an anslysis

if !strlen("`epsilon'") {	//don't invoke program checks if epsilon option is invoked

	if !strlen("`mi'") capture `reg' `dv' `nobindivs' `all' [`weight'`exp'] if `touse', `regopts'	//run overall analysis - probe to check for e(sample) and whether everything works as it should

	else {

		capture mi estimate, saving(`mifile') `miopt': `reg' `dv' `nobindivs' `all' [`weight'`exp'] if `keep', `regopts'	//run overall analysis with mi prefix - probe to check for e(sample) and whether everything works as it should

		if _rc {	//if something's amiss with mi...
		
			display "{err}Error in {cmd:mi estimate: `reg'}. See return code."
		
			exit `=_rc'
			
		}
		
		else estimates use `mifile', number(`:word 1 of `e(m_est_mi)'')	//if touse doesn't equal e(sample) - use e(sample) from first imputation and proceed
	
	}
	
	quietly count if `touse'	//tally up observations from count based on "touse"

	if r(N) > e(N) & !strlen("`mi'") quietly replace `touse' = e(sample)	//if touse doesn't equal e(sample) - use e(sample) and proceed; not possible with multiple imputation though

	if _rc {	//exit if regression is not estimable or program results in error - return the returned code

		display "{err}{cmd:`reg'} resulted in an error."
	
		exit `=_rc'

	}
	
	capture assert `fitstat' != .	//is the "fitstat" the user supplied actually returned by the command?
	
	if _rc {	//exit if fitstat can't be found

		display "{err}{cmd:`fitstat'} not returned by {cmd:`reg'} or {cmd:`fitstat'} is not scalar valued. See {help return list}."
	
		exit 198

	}

	capture assert sign(`fitstat') != -1	//what is the sign of the fitstat?  domin works best with positive ones - warn and proceed

	if _rc {

		display "{err}{cmd:`fitstat'} returned by {cmd:`reg'}." _newline ///
		"is negative.  {cmd:domin} is programmed to work best" _newline ///
		"with positive {opt fitstat()} summary statistics." _newline

	}
	
}

if !inlist("`weight'", "iweight", "fweight") & !strlen("`mi'") {	//if weights don't affect obs
	
	quietly count if `touse'	//tally up "touse" if not "mi"
	
	scalar `obs' = r(N)	//pull out the number of observations included
	
}

else if inlist("`weight'", "iweight", "fweight") & !strlen("`mi'") {	//if the weights do affect obs

	quietly summarize `=regexr("`exp'", "=", "")' if `touse'	//tally up "touse" by summing weights
	
	scalar `obs' = r(sum)	//pull out the number of observations included
	
}

else {

	quietly mi estimate, `miopt': regress `dv' `nobindivs' `all' [`weight'`exp'] if `keep'	//obtain estimate of obs when multiply imputed
	
	scalar `obs' = e(N)	//pull out the number of observations included

}
 
/*begin estimation*/
scalar `allfs' = 0	//begin by defining the fitstat of the "all" variables as 0 - needed for dominance() function

if `:list sizeof all' {	//if there are variables in the "all" list
	
	if !strlen("`mi'") {	//when there is no "mi" option specified
	
		quietly `reg' `dv' `all' [`weight'`exp'] if `touse', `regopts'	//run analysis with "all" independent variables only
	
		scalar `allfs' = `fitstat'	//the resulting "fitstat" is then registered as the value to remove from other fitstats
		
	}
	
	else {	//if "mi" is specified
	
		quietly mi estimate, saving(`mifile', replace) `miopt': `reg' `dv' `all' [`weight'`exp'] if `keep', `regopts'	//run mi analysis with "all" independent variables only
	
		mi_dom, name(`mifile') fitstat(`fitstat') list(`=e(m_est_mi)')	//call mi_dom program to average fitstats
		
		scalar `allfs' = r(passstat)	//the resulting average fitstat is then registered as the value to remove from other fitstats
	
	}

}

scalar `consfs' = 0	//begin by defining the fitstat of the constant-only model as 0 - needed for dominance() function

if strlen("`consmodel'") {	//if the user desires to know what the baseline fitstat is
	
	if !strlen("`mi'") {	//if "mi" is not declared
	
		quietly `reg' `dv' [`weight'`exp'] if `touse', `regopts'	//conduct analysis without independent variables
	
		scalar `consfs' = `fitstat'	//return baseline fitstat
		
	}
	
	else {	//if "mi" is declared
	
		quietly mi estimate, saving(`mifile', replace) `miopt': `reg' `dv' [`weight'`exp'] if `keep', `regopts'	//conduct mi analysis without independent variables
	
		mi_dom, name(`mifile') fitstat(`fitstat') list(`=e(m_est_mi)')	//compute average fitstat
		
		scalar `consfs' = r(passstat)	//return average baseline fitstat
	
	}
	
	if `:list sizeof all' scalar `allfs' = `allfs' - `consfs'
	
}

if strlen("`epsilon'") { //primary analysis when "epsilon" is invoked

	if ("`reg'" == "mvdom") `reg' `dv' `ivs' if `touse', `regopts' `epsilon'	//invoke the epsilon version of mvdom

	else mata: eps_ri("`dv' `ivs'", "`reg'", "`touse'", "`regopts'") //mata function to obtain epsilon-based estimates
	
	matrix `domwgts' = r(domwgts) //translate r-class matrix into temp matrix that domin expects
	
	matrix `sdomwgts' = `domwgts'*(1/r(fs))	//produce standardized relative weights (i.e., out of 100%)
	
	mata: st_matrix("`ranks'", mm_ranks(st_matrix("r(domwgts)")':*-1, 1, 1)')	//rank the relative weights

}

else {
	
	mata: model_specs = domin_specs()
	
	mata: model_specs.mi = st_local("mi")
	mata: model_specs.reg = st_local("reg")
	mata: model_specs.dv = st_local("dv")
	mata: model_specs.all = st_local("all")
	mata: model_specs.weight = st_local("weight")
	mata: model_specs.exp = st_local("exp")
	mata: model_specs.touse = st_local("touse")
	mata: model_specs.regopts = st_local("regopts")

	mata: dominance(model_specs, &domin_call(), ///
		st_local("conditional'"), st_local("complete"), ///
		st_local("ivs"), ///
		st_numscalar(st_local("allfs")), st_numscalar(st_local("consfs"))) //invoke "dominance()" function in Mata 
	
	/*translate r-class results into temp results*/
	matrix `domwgts' = r(domwgts)
	
	matrix `sdomwgts' = r(sdomwgts)
	
	matrix `ranks' = r(ranks)
	
	if !strlen("`conditional'") matrix `cdldom' = r(cdldom)
	
	if !strlen("`complete'") matrix `cptdom' = r(cptdom)
	
}

/*display results - this section will not be extensively explained*/
/*name matrices*/
matrix colnames `domwgts' = `diivs'	

if strlen("`reverse'") {	//if 'reverse', invert the direction and interpretation of rank and standardized weights

	mata: st_matrix("`sdomwgts'", (st_matrix("`domwgts'"):*-1):/sum(st_matrix("`domwgts'"):*-1))
	
	mata: st_matrix("`ranks'", ((st_matrix("`ranks'"):-1):*-1):+cols(st_matrix("`ranks'")))

}

matrix colnames `sdomwgts' = `diivs'	

matrix colnames `ranks' = `diivs'	

if !strlen("`complete'") { 	

	if strlen("`reverse'") mata: st_matrix("`cptdom'", st_matrix("`cptdom'"):*-1) //if 'reverse', invert the direction and interpretation of complete dominance

	matrix colnames `cptdom' = `diivs'	
	
	matrix coleq `cptdom' = dominated?	
	
	matrix rownames `cptdom' = `diivs'	
	
	matrix roweq `cptdom' = dominates?	
	
}

if !strlen("`conditional'") { 
	
	matrix rownames `cdldom' = `diivs'
	
	local colcdl `:colnames `cdldom''
	
	local colcdl = subinstr("`colcdl'", "c", "", .)
	
	matrix colnames `cdldom' = `colcdl'
	
	matrix coleq `cdldom' = #indepvars
	
}	

if !strlen("`epsilon'") & strlen("`e(title)'") local title "`e(title)'"

else if strlen("`epsilon'") & strlen("`e(title)'") local title "Epsilon-based `reg'"

else local title "Custom user analysis"

/*return values*/
ereturn post `domwgts' [`weight'`exp'], depname(`dv') obs(`=`obs'') esample(`touse')

if strlen("`setcnt'") {

	ereturn hidden scalar setcnt = `setcnt'

	forvalues x = 1/`setcnt' {
	
		fvunab set`x': `set`x''

		ereturn local set`x' "`set`x''"
		
	}
	
}

else ereturn hidden scalar setcnt = 0

ereturn hidden local dtitle "`title'"

ereturn hidden local reverse "`reverse'"

if `:list sizeof all' {

	fvunab all: `all'

	ereturn local all "`all'"
	
}

if strlen("`epsilon'") ereturn local estimate "epsilon" 

else ereturn local estimate "dominance"

if strlen("`mi'") {

	if strlen("`miopt'") ereturn local miopt "`miopt'"

	ereturn local mi "mi"

}

if strlen("`regopts'") ereturn local regopts `"`regopts'"'

ereturn local reg `"`reg'"'

ereturn local fitstat "`fitstat'"

ereturn local cmd `"domin"'

ereturn local title `"Dominance analysis"'

ereturn local cmdline `"domin `0'"'

ereturn scalar fitstat_o = r(fs)

if `:list sizeof all' ereturn scalar fitstat_a = `allfs'

if strlen("`consmodel'") ereturn scalar fitstat_c = `consfs'

if !strlen("`conditional'") ereturn matrix cdldom `cdldom'
	
if !strlen("`complete'") ereturn matrix cptdom `cptdom'

ereturn matrix ranking `ranks'

ereturn matrix std `sdomwgts'

/*begin display*/
Display

end

/*Display program*/
program define Display

version 12.1

tempname domwgts sdomwgts ranks

matrix `domwgts' = e(b)

matrix `sdomwgts' = e(std)

matrix `ranks' = e(ranking)

local diivs: colnames e(b)

mata: st_local("cdltest", strofreal(cols(st_matrix("e(cdldom)"))))

mata: st_local("cpttest", strofreal(cols(st_matrix("e(cptdom)"))))

tokenize `diivs'

local dv = abbrev("`e(depvar)'", 10)

display _newline "{txt}General dominance statistics: `e(dtitle)'" _newline ///
"{txt}Number of obs{col 27}={res}{col 40}" %12.0f e(N) 

display "{txt}Overall Fit Statistic{col 27}={res}{col 36}" %16.4f e(fitstat_o)

if !missing(e(fitstat_a)) display "{txt}All Subsets Fit Stat.{col 27}={res}{col 36}" %16.4f e(fitstat_a)

if !missing(e(fitstat_c)) display "{txt}Constant-only Fit Stat.{col 27}={res}{col 36}" %16.4f e(fitstat_c)

display _newline "{txt}{col 13}{c |}{col 20}Dominance{col 35}Standardized{col 53}Ranking"

display "{txt}{lalign 9: `dv'}{col 13}{c |}{col 20}Stat.{col 35}Domin. Stat." 

display "{txt}{hline 12}{c +}{hline 72}"

forvalues x = 1/`:list sizeof diivs' {

	local `x' = abbrev("``x''", 10)
	
	display "{txt}{col 2}{lalign 11:``x''}{c |}{col 14}{res}" %15.4f `domwgts'[1,`x'] ///
	"{col 29}" %12.4f `sdomwgts'[1,`x'] "{col 53}" %-2.0f `ranks'[1,`x']
	
}

display "{txt}{hline 12}{c BT}{hline 72}"

if `cdltest' {

	display "{txt}Conditional dominance statistics" _newline "{hline 85}"
	
	matrix list e(cdldom), noheader format(%12.4f)
	
	display "{txt}{hline 85}"
	
}

if `cpttest' {

	display "{txt}Complete dominance designation" _newline "{hline 85}"
	
	matrix list e(cptdom), noheader
	
	display "{txt}{hline 85}"
	
}

if e(estimate) == "dominance" & `=`cpttest'*`cdltest'' {

	display _newline "{res}Strongest dominance designations" _newline 

	tempname bestdom cdl gen decision
	
	if strlen("`e(reverse)'") mata: st_matrix("`bestdom'", st_matrix("e(cptdom)"):*-1)
	
	else matrix `bestdom' = e(cptdom)
	
	forvalues x = 1/`=colsof(e(cdldom))-1' {
	
		forvalues y = `=`x'+1'/`=colsof(e(cdldom))' {
		
			scalar `cdl' = 0
			
			scalar `gen' = 0
	
			mata: st_numscalar("`cdl'", (sum(st_matrix("e(cdldom)")[`x', .]:>st_matrix("e(cdldom)")[`y', .])):==rows(st_matrix("e(cdldom)"))) 
			
			if !`cdl' mata: st_numscalar("`cdl'", -1*((sum(st_matrix("e(cdldom)")[`x', .]:<st_matrix("e(cdldom)")[`y', .])):==rows(st_matrix("e(cdldom)"))))
			
			mata: st_numscalar("`gen'", st_matrix("e(b)")[1, `x']>st_matrix("e(b)")[1, `y'])
			
			if !`gen' mata: st_numscalar("`gen'", (st_matrix("e(b)")[1, `x']<st_matrix("e(b)")[1, `y'])*-1)
			
			local reverse_adj = cond(strlen("`e(reverse)'"), -1, 1)
			
			scalar `decision' = ///
			cond(abs(`bestdom'[`x', `y']) == 1, `bestdom'[`x', `y'], cond(abs(`cdl') == 1, `cdl'*2, cond(abs(`gen') == 1, `gen'*3, 0)))
			
			matrix `bestdom'[`x', `y'] = `decision'*`reverse_adj'
			
			matrix `bestdom'[`y', `x'] = -`decision'*`reverse_adj'
			
		}
	
	}
	
	local names `:colnames e(b)'
	
	mata: display((select(vec(tokens(st_local("names"))':+((st_matrix("`bestdom'"):==1):*" completely dominates "):+tokens(st_local("names")))', ///
	regexm(vec(tokens(st_local("names"))':+((st_matrix("`bestdom'"):==1):*" completely dominates "):+tokens(st_local("names")))', ///
	"completely dominates")) , ///
	select(vec(tokens(st_local("names"))':+((st_matrix("`bestdom'"):==2):*" conditionally dominates "):+tokens(st_local("names")))', ///
	regexm(vec(tokens(st_local("names"))':+((st_matrix("`bestdom'"):==2):*" conditionally dominates "):+tokens(st_local("names")))', ///
	"conditionally dominates")), ///
	select(vec(tokens(st_local("names"))':+((st_matrix("`bestdom'"):==3):*" generally dominates "):+tokens(st_local("names")))', ///
	regexm(vec(tokens(st_local("names"))':+((st_matrix("`bestdom'"):==3):*" generally dominates "):+tokens(st_local("names")))', ///
	"generally dominates")))')
	
	display ""

}

if `=e(setcnt)' {

	forvalues x = 1/`=e(setcnt)' {

		display "{txt}Variables in set`x': `e(set`x')'"
		
	}
	
}

if strlen("`e(all)'") display "{txt}Variables included in all subsets: `e(all)'"

end

/*program to average fitstat across all multiple imputations for use in domin*/
program define mi_dom, rclass

version 12.1

syntax, name(string) fitstat(string) list(numlist)

tempname passstat

scalar `passstat' = 0 //placeholder scalar to hold the sum

foreach x of numlist `list' {

	estimates use `name', number(`x') //find the focal estimates
	
	scalar `passstat' = `passstat' + `fitstat'*`:list sizeof list'^-1 //add in the weighted fitstat value

}

return scalar passstat = `passstat' //average fitstat = the MI'd fitstat

end

/* programming notes and history
- domin version 1.0 - date - April 4, 2013
-----
- domin version 1.1 - date - April 13, 2013
-fixed incorrect e(cmd) and e(cmdline) entries
-fixed markout variables for sets greater than 1
-----
- domin version 1.2 - date - April 16, 2013
-version 12.1 declared to ensure compatability with factor variables and other advertised features (thanks to Nick Cox for advice on this issue)
-fixed markout problem that kept unwanted characters in markout statement (thanks to Ariel Linden for pointing this out)
-analytic weights disallowed; importance weights allowed in dominance analysis consistent with underlying linear and logit-based regressions
-----
- domin version 2.0 - date - Aug 25, 2013
-tuples, all subset regression, and dominance computations migrated to Mata (thanks to all individuals who pointed out the errors tuples caused when interfacing with domin)
-incorporates complete and conditional dominance criteria
-ranking of predictors returned as a matrix, e(ranking)
-bug related to if and in qualifiers resolved
-dots representing each regression replaced with a progress bar for predictors/sets >6 or >4 (for logits)
-piechart dropped as option
-altered adjusted domin weight computation to result in decomposition of adjusted r2's from full regression
-incorporates "epsilon" or relative weights approach to general dominance (for regress only)
-McFadden's pseudo-R2 used for logit-based models (for consistency with Azen & Traxel, 2009)
-----
- domin version 3.0 - date - Jan 15, 2014
-R2-type metrics no longer default.  Any valid model fit metric can be used.  Consequently, adj R2 was also removed.
-increased flexibility of estimation commands to be used by domin.  Any command that follows standard syntax could potentially be used.
-wrapper program mvdom and mixdom incorporated into domin package to demonstrate command's flexibility.
-due to flexibility in fitstat, constant-only model adjustment incorporated (similar to Stas Kolenikov's -shapley- on SSC) 
-error related to reported number of observations fixed when strongly collinear variables dropped.
-added multiple imputation support
-greatly expanded, clarified, and updated the help file
  -----
- domin version 3.1 - date - Apr 14, 2015
-updated epsilon - works with glm, mvdom, and regress; also migrated to Mata (though not recommended approach - weights nixed for epslilon)
-reverse option to reverse "coding" of fitstat in ranks, standardized metric and complete dominance
-fixed tied ranks (used to randomly assign, - now share highest number)
-added "best dominance" - Com, Cond, Gen - in display (works with "reverse")
-removed unnecessary mata clear in dominance()
-time series operators allowed (for commands that allow them)
-tempfile error fixed for mi
-tempnames used for matrices
-fixed object declarations in dominance() function
-returns unabbreviated each variable in set and all sets lists
-added more ereturned information
-fixed error where all subsets fitstat was not adjusted for the constant-only fitstat
 -----
- domin version 3.2 - date - Apr 8, 2016
 -fixed use of total with mi to obtain N, doesn't work with tsvars and fvars, changed to regress
 -update predictor combination computation - use tuples' approach
 // 3.2.1 - Feb 15, 2021 (initiating new versioning: #major.#minor.#patch)
 -update to documentation for SJ article
 -fixed bug in -if- statements with -mi- (thanks to Annesa Flentje)
 ---
 domin version 3.3.0 - October 17, 2021 
 -bug fix and update to complete dominance computations - inconsistent computation of complete dominance designation
 -update to documentation/helpfile
 -clean up internal functions (naming and redundancy)
 -update to terminology in documentation and reporting
 ---
 domin version 3.4.0 - November 3, 2022
 - reorganization of Mata code; function to function passing; Mata struct to handle input specs
	- lb_dominance.mlib now contains all complied Mata code for -domin- generalized for accommodating -domme- and future commands
 - increased precision of passed 'all' and 'constant' fit stats
 // 3.4.1 - January 27, 2023
 - fixed Mata code (dominance.mata 0.0.1) 
	- increase flexibility to work with -domme-; 3.4.0 makes assumptions -domme- cannot meet
	- does not force arguments but accepts single objects for command-specific needs 
	- records domin options directly (doesn't call them as local macros)
 */
