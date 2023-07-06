*! domin version 4.0.0  xx/xx/202x Joseph N. Luchman
// version information at end of file

**# Pre-program definition
*quietly include dominance.mata, adopath

program define domin, nclass 

if `c(version)' < 17 {
	
	display "{err}As of {cmd:domin} version 4.0.0, the minimum version of Stata is 17." _newline ///
	"If you have an older version of Stata, most functionality of {cmd:domin} is available from" _newline ///
	`"{stata net install st0645:this} Stata journal article back to version 12.1."'
	
	exit 198
	
}

version 17

/* replays with new domin?*/

if replay() {

	if ("`e(cmd)'" != "domin") error 301
	
	if _by() error 190
	
	Display `0'
	
	exit 0
	
}

**# Check for -moremata-
capture which lmoremata.mlib	

if _rc {

	display "{err}Module {cmd:moremata} not found.  Install {cmd:moremata} here {stata ssc install moremata}."
	
	exit 198

}

gettoken subcommand 0: 0

if "`subcommand'" == "me"  display "ho" //domin_me `0'

if "`subcommand'" == "se" domin_se `0'

else domin_se `subcommand'`0'

Display

end

/*Display program*/
program define Display

version 17

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

if  1 { //e(estimate) == "dominance" & `=`cpttest'*`cdltest'' {

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
 // 3.4.2 - March 7, 2023
 - call 'dominance.mata' as opposed to using 'lb_dominance.mlib' to allow backward compatability
 ---
 domin version 4.0.0 - mth day, year
 ** planned ** change to front-end, minimum version now 17, most of command migrated to Mata
	- argument check changes - 
    - remove support for -mi- make it a wrapper like fitdom()
 ** planned ** -domme- depreciated in favor of -domin [se]- and -domin me-
 ** planned ** - built-in regress function
 ** planned ** - by-able?
 ** planned ** - updates to dominance.mata ??
 */
