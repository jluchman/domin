*! domin version 3.5.2  8/13/2024 Joseph N. Luchman
// version information at end of file
**# Pre-program definition
quietly include dominance.mata, adopath
program define domin, eclass 
if `c(version)' < 15 {
	display "{err}As of {cmd:domin} version 3.5.0, the minimum version of Stata is 15." _newline "If you have an older version of Stata, most functionality of {cmd:domin} is available from" _newline `"{stata net install st0645:this} Stata journal article back to version 12."'
	exit 198
}
version 15
if replay() {
	if ("`e(cmd)'" != "domin") error 301
	if _by() error 190
	Display `0'
	exit 0
}
**# Program definition and argument checks
syntax varlist(min = 1 ts) [in] [if] [aw pw iw fw] , ///
	[Reg(string) Fitstat(string) Sets(string) All(varlist fv ts) ///
	noCONditional noCOMplete EPSilon CONSmodel REVerse noESAMPleok mi miopt(string)] 
if strlen("`epsilon'") {
	local esampleok "esampleok"
	local conditional "conditional"
	local complete "complete"
}
if strlen("`mi'") | strlen("`mi'") {
	display "{err}{cmd:mi} and {opt miopt()} are depreciated. Please use {help mi_dom}."
	exit 198
}
**# Wrapper process for -domin- processing in Mata
mata: domin_2mata("`reg'", "`fitstat'", "`sets'", "`all'", "`conditional'", "`complete'", "`epsilon'", "`consmodel'", "`reverse'", "`esampleok'", "`weight'`exp'", "`in' `if'", "`varlist'")
**# Ereturn processing
tempname domwgts cdldom cptdom stdzd ranks

if !strlen("`epsilon'") & strlen("`e(title)'") local title "`e(title)'"

else if strlen("`epsilon'") & strlen("`e(title)'") local title "Epsilon-based `reg'"

else local title "Custom user analysis"

matrix `domwgts' = r(domwgts)
ereturn post `domwgts' [`weight'`exp'], depname(`dv') obs(`=r(N)') esample(`touse')

**# Ereturn scalars
matrix `domwgts' = r(domwgts)*J(colsof(r(domwgts)), 1, 1)
if strlen("`epsilon'") ereturn scalar fitstat_o = `=`domwgts'[1,1]'
else ereturn scalar fitstat_o = `=r(fullfs) + r(allfs) + r(consfs)'

if `:list sizeof all' ereturn scalar fitstat_a = `=r(allfs)'
if strlen("`consmodel'") ereturn scalar fitstat_c = `=r(consfs)'

if strlen("`setcount'") {

	ereturn hidden scalar setcount = `setcount'

	forvalues x = 1/`setcount' {
	
		fvunab set`x': `set`x''

		ereturn local set`x' "`set`x''"
		
	}
	
}

else ereturn hidden scalar setcount = 0

**# Ereturn macros
ereturn hidden local disp_title "`title'"

ereturn hidden local reverse "`reverse'"

if `:list sizeof all' {

	fvunab all: `all'

	ereturn local all "`all'"
	
}

if strlen("`epsilon'") ereturn local estimate "epsilon" 

else ereturn local estimate "dominance"

if strlen("`regopts'") ereturn local regopts `"`regopts'"'

ereturn local reg `"`reg'"'

ereturn local fitstat "`fitstat'"

ereturn local cmd `"domin"'

ereturn local title `"Dominance analysis"'

ereturn local cmdline `"domin `0'"'

**# Ereturn matrices
if !strlen("`complete'") {
	matrix `cptdom' =  r(cptdom)
	mata: st_matrixcolstripe("`cptdom'", ///
		(J(cols(st_matrix("`cptdom'")), 1, "dominated?"), ///
		st_matrixcolstripe("e(b)")[,2]))
	mata: st_matrixrowstripe("`cptdom'", ///
		(J(cols(st_matrix("`cptdom'")), 1, "dominates?"), ///
		st_matrixcolstripe("e(b)")[,2]))
	ereturn matrix cptdom = `cptdom'
}

if !strlen("`conditional'") {
	matrix `cdldom' = r(cdldom)
	mata: st_matrixcolstripe("`cdldom'", ///
		(J(cols(st_matrix("`cdldom'")), 1, "#indepvars"), ///
		strofreal(1::cols(st_matrix("`cdldom'")))))
	ereturn matrix cdldom = `cdldom'
}

matrix `ranks' = r(ranks)
ereturn matrix ranking = `ranks'

matrix `stdzd' = r(stdzd)
ereturn matrix std = `stdzd'

Display

end

/*Display program*/
program define Display

version 15

tempname domwgts sdomwgts ranks

matrix `domwgts' = e(b)

matrix `sdomwgts' = e(std)

matrix `ranks' = e(ranking)

local diivs: colnames e(b)

mata: st_local("cdltest", strofreal(cols(st_matrix("e(cdldom)"))))

mata: st_local("cpttest", strofreal(cols(st_matrix("e(cptdom)"))))

tokenize `diivs'

local dv = abbrev("`e(depvar)'", 10)

display _newline "{txt}General dominance statistics: `e(disp_title)'" _newline ///
"{txt}Number of obs{col 27}={res}{col 40}" %12.0f e(N) 

display "{txt}Overall Fit Statistic{col 27}={res}{col 36}" %16.4f e(fitstat_o)

if !missing(e(fitstat_a)) display "{txt}All Sub-models Fit Stat.{col 27}={res}{col 36}" %16.4f e(fitstat_a)

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

	display _newline "{txt}Strongest dominance designations" _newline 

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
	
	mata: display(("{txt}", select(vec(tokens(st_local("names"))':+((st_matrix("`bestdom'"):==1):*" completely dominates "):+tokens(st_local("names")))', ///
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

if `=e(setcount)' {

	forvalues x = 1/`=e(setcount)' {

		display "{txt}Variables in set`x': `e(set`x')'"
		
	}
	
}

if strlen("`e(all)'") display "{txt}Variables included in all sub-models: `e(all)'"

end

**# Mata function adapting Stata input for Mata and initiating the Mata environment
version 15
mata:
mata set matastrict on
void domin_2mata(string scalar reg, string scalar fitstat, string scalar sets, string scalar all, string scalar conditional, string scalar complete, string scalar epsilon, string scalar consmodel, string scalar reverse, string scalar esampleok, string scalar weight, string scalar inif, string scalar varlist) {
/* ~ declarations and initial structure */
	class AssociativeArray scalar model_specs
	real scalar builtin, iv, set, rc, obs, full_fitstat, all_fitstat, cons_fitstat, index_count
	string scalar regopts, dv, marks
	string rowvector ivs, iv_sets, bltin_varlist, bltin_index, bltin_all_varlist, bltin_all_index
	real rowvector bltin_dvcor
	real matrix bltin_corrmat
	transmorphic parser
/* ~ argument checks ~ */
	/*-domin- defaults*/
	if ((!strlen(reg) & !strlen(fitstat)) & !strlen(epsilon)) {
		reg = "regress"
		fitstat = "e(r2)" 
		weight = subinword( subinword( weight, "pweight", "aweight"), "iweight", "aweight")
		builtin = 1
		if (strlen(consmodel)) {
			display("{err}{opt consmodel} is not valid with built-in method.")
			exit(198)
		}
	} else if ( (strlen(reg) & strlen(fitstat)) | strlen(epsilon) ) {
		builtin = 0
	} else {
		display("{err}Both {opt reg()} and {opt fitstat()} must be chosen or neither as of {cmd:domin} version 3.5.")
		exit(198)
	}
	/*'epsilon' specifics*/
	if ( strlen(epsilon) ) {
		
		/*exit conditions: user must restructure*/
		if ( strlen(all + sets) ) { 									
			
			display("{err}{opt epsilon} not allowed with" + 
					" {opt all()} or {opt sets()}.")
			exit(198) 															
				
		}
		
	}	
	
/* ~ process iv and sets ~ */
	/*parse varlist - store as 'ivs'*/
	ivs = tokens(varlist)
	
	/*'dv ivs' structure means first entry is 'dv'*/
	dv = ivs[1]
	
	/*remaining entries, if any, are 'ivs'*/
	if ( length(ivs) > 1 ) ivs = ivs[2..length(ivs)]							
	else ivs = ""
	
	/*set processing*/
	if ( strlen(sets) ) {
		/*setup parsing sets - bind on parentheses*/
		parser = tokeninit(" ", "", "()")
		tokenset(parser, sets)
		
		/*get all sets and remove parentehses*/
		iv_sets = tokengetall(parser)
		iv_sets = substr(iv_sets, 2, strlen(iv_sets):-2)
		st_local("setcount", strofreal( length(iv_sets) ))
		for (set=1; set<=length(iv_sets); set++) {
			
			st_local("set"+strofreal(set), iv_sets[set])
			
			rc = _stata("fvunab waste: " + iv_sets[set], 1)
			if ( rc ) {
				display("{err}Problem with variables in set position " + strofreal(set) + ": " + iv_sets[set])
				exit(111)
			}
			
		}
		
		/*combine to single iv vector*/
		if ( length(ivs) > 1 ) ivs = (ivs, iv_sets)
		else ivs = iv_sets
	
	}
	
	if ( length(ivs) < 2 | ivs == "") {	

		stata("display " + char(34) + 
			"{err}{cmd:domin} requires at least 2 independent variables or independent variable sets." + 
			char(34))
		exit(198)
		
	}

/* ~ parse regression options ~ */
	parser = tokeninit(" ", ",")
	
	tokenset(parser, strtrim(reg))
	
	reg = tokenget(parser)
	
	if ( length(tokenrest(parser)) ) regopts = substr(tokenrest(parser), 2)
	else regopts = ""
	
/* ~ check primary analysis and set estimation sample ~ */
	if ( !strlen(epsilon) ) {
		
		st_eclear()
		
		if (inif == " ") inif = "if _n > 0"
		
		rc = _stata(reg + " " + dv + " " + invtokens(ivs) + " " + all +  
			" [" + weight + "] " + inif + ", " + regopts, 1)
		
		if ( rc ) {
			
			display("{err}{cmd:" + reg + "} resulted in an error.")
			exit(rc)

		}
		
		if ( !length( st_numscalar( strtrim(fitstat) ) ) )	{
		
			display("{err}{cmd:" + fitstat + 
				"} not returned by {cmd:" + reg + "} or {cmd:" + fitstat + 
				"} is not scalar valued. See {help return list}.")
			exit(198)

		}
		else full_fitstat = st_numscalar( strtrim(fitstat) ) 
		
		marks = st_tempname()
		
		stata("generate byte " + marks[1] + " = e(sample)", 1)
		
		if (strmatch(weight, "fweight*") | strmatch(weight, "iweight*")) {
		
		stata("summarize " + marks[1] + " if " + marks[1] + 
			" [" + weight + "]", 1)
		
		}
		else stata("count if " + marks[1], 1)
		
		obs = st_numscalar("r(N)")
	
	}
	else obs = 0

	if (obs == 0 & strlen(esampleok) ) 	{
	
		marks = st_tempname(2)

		stata("mark " + marks[1]) 
		
		stata("generate byte " + marks[2] + " = 1 " + inif, 1)
			
		stata("markout " + marks[1] + " " + marks[2] + 
			" " + invtokens(ivs) + " " + all, 1)
			
		if (strmatch(weight, "fweight*") | strmatch(weight, "iweight*")) {
		
		stata("summarize " + marks[1] + " if " + marks[1] + 
			" [" + weight + "]", 1)
		
		}
		else stata("count if " + marks[1], 1)
			
		obs = st_numscalar("r(N)")
	
	}
	
	if (obs == 0 & !strlen(esampleok)) {
		
		display("{err}{cmd:esample()} not set. Use {opt noesampleok} to avoid checking {cmd:esample()}.")
		exit(198)
		
	}
/* ~ built-in linear regression-based model ~ */
	if (builtin) { 
		bltin_varlist = bltin_index = J(1, length(ivs), "") // dummy vector for names in Stata data names and locations in corr matrix
		index_count = 1 // begin index at 1 as DV is always first
		for (iv = 1; iv <= length(ivs); iv++) { // for all IVs ...
			stata("fvexpand " + ivs[iv], 1) // test factor variable expansion
			if (strlen( st_macroexpand("`" + "r(fvops)" + "'")) | strlen(st_macroexpand("`" + "r(tsops)" + "'"))) { // if there are factor- or time-series variables...
				bltin_index[iv] = st_macroexpand("`" + "r(varlist)" + "'") // begin by recording the names of factor- or time-series these variables (this will eventualy be indexes for corr mat)
				stata("fvrevar " + ivs[iv], 1) // implement the generation of (temporary) factor- and time-series variables
				bltin_varlist[iv] = st_macroexpand("`" + "r(varlist)" + "'") // record the tempnames of the impemented variables
				if (any(strmatch(tokens(bltin_index[iv]), "*b.*"))) { // when there is a 'base' variable included ...
					bltin_varlist[iv] = invtokens(select(tokens(bltin_varlist[iv]), !strmatch(tokens(bltin_index[iv]), "*b.*"))) // omit the base variable from the tempname list
				}
				bltin_index[iv] = invtokens(strofreal((index_count..index_count+length(tokens(bltin_varlist[iv]))-1))) // overwrite with record locations of new variables as they will be in correlation matrix
				index_count = index_count + length(tokens(bltin_varlist[iv])) // update the index count where we will start next time
			} else { // ... if no factor- or time-series variables...
				bltin_varlist[iv] = ivs[iv] // record name of variable in varlist
				bltin_index[iv] = strofreal(index_count) // record the index of the variable in the corr mat
				index_count++ // increment index count
			}
		}
		if (strlen(all)) { // ... if there is an entry in the -all()- option ...
			stata("fvexpand " + all, 1) // test factor variable expansion 
			if (strlen(st_macroexpand("`" + "r(fvops)" + "'")) | strlen(st_macroexpand("`" + "r(tsops)" + "'"))) { // if there are factor- or time-series variables...
				bltin_all_index = st_macroexpand("`" + "r(varlist)" + "'")
				stata("fvrevar " + all, 1)
				bltin_all_varlist = st_macroexpand("`" + "r(varlist)" + "'")
				if (any(strmatch(tokens(bltin_all_index), "*b.*"))) {
					bltin_all_varlist = invtokens(select(tokens(bltin_all_varlist), !strmatch(tokens(bltin_all_index), "*b.*")))
				}
				bltin_all_index = strofreal((index_count..index_count+length(tokens(bltin_all_varlist))-1))
				index_count = index_count + length(tokens(bltin_all_varlist))
			} else {
				bltin_all_varlist = strofreal((index_count..index_count+length(tokens(all))-1))
				bltin_all_index = strofreal((index_count..index_count+length(tokens(bltin_all_varlist))-1))
				index_count = index_count + length(tokens(all))
			}
		} else {
			bltin_all_varlist = bltin_all_index = ""
		}
		if (regexm(weight, "^[pi]weight=")) {
			weight = regexr(weight, "^[pi]weight=", "aweight=")
		}
		stata("correlate " + invtokens(bltin_varlist) + " " + invtokens(bltin_all_varlist) + " [" + weight + "] if " + marks[1], 1)
		bltin_corrmat = st_matrix("r(C)")
		stata("correlate " + dv + " " + invtokens(bltin_varlist) + " " + invtokens(bltin_all_varlist) + " [" + weight + "] if " + marks[1], 1)
		bltin_dvcor = st_matrix("r(C)")[1, 2..index_count]
	}
/* ~ begin collecting effect sizes ~ */
	all_fitstat = 0
	if (strlen(all) & !builtin) {
		stata(reg + " " + dv + " " + all + " [" + weight + "] if " + marks[1] + ", " + regopts, 1)
		all_fitstat = st_numscalar(strtrim(fitstat))
	} else if (strlen(all) & builtin) {
		all_fitstat = bltin_dvcor[strtoreal(bltin_all_index)]*qrsolve(bltin_corrmat[strtoreal(bltin_all_index), strtoreal(bltin_all_index)], bltin_dvcor[strtoreal(bltin_all_index)]') // compute -all()- option's fitstat with built-in
	}
	cons_fitstat = 0
	if (strlen(consmodel)) {	
		stata(reg + " " + dv + " [" + weight + "] if " + marks[1] + ", " + regopts, 1)	
		cons_fitstat = st_numscalar(strtrim(fitstat))
	}
	if (strlen(all)) {
		all_fitstat = all_fitstat - cons_fitstat
	}
	full_fitstat = full_fitstat - all_fitstat - cons_fitstat
/* ~ invoke dominance ~ */	
	if (strlen(epsilon)) {
		if (reg == "mvdom") {
			stata("mvdom " + dv + " " + invtokens(ivs) + " if " + marks[1] + ", " + regopts + " epsilon", 1)
		} else {
			eps_ri(dv + " " + invtokens(ivs), reg, marks[1], regopts, ( length(tokens(weight, "=")) == 3 ) ? tokens(weight, "=")[3] : "")
		}
	} else if (builtin) {
		model_specs.put("corrmat", bltin_corrmat)
		model_specs.put("dvcor", bltin_dvcor)
		model_specs.put("all", bltin_all_index)
		model_specs.put("all_fitstat", all_fitstat)
		model_specs.put("cons_fitstat", 0)
		dominance(model_specs, &domin_regress(), bltin_index', conditional, complete, full_fitstat)	
	} else {
		model_specs.put("reg", reg)
		model_specs.put("fitstat", fitstat)
		model_specs.put("weight", weight)
		model_specs.put("touse", marks[1])
		model_specs.put("regopts", regopts)
		model_specs.put("all", all)
		model_specs.put("dv", dv)
		model_specs.put("consmodel", consmodel)
		model_specs.put("reverse", reverse)
		model_specs.put("all_fitstat", all_fitstat)
		model_specs.put("cons_fitstat", cons_fitstat)
		dominance(model_specs, &domin_call(), ivs', conditional, complete, full_fitstat)	
	}
/* ~ return values ~ */	
	if ( length(iv_sets) )
		ivs[(( length(ivs)-length(iv_sets)+1 )..length(ivs))] = 
			"set":+( strofreal( (1..length(iv_sets)) ) )
	
	st_matrixcolstripe("r(domwgts)", (J(length(ivs), 1, ""), ivs') )
	
	if ( strlen(reverse) )
		st_matrix("r(cptdom)", 
			 st_matrix("r(cptdom)"):*-1 )
	
	if ( !strlen(conditional) ) st_matrixrowstripe("r(cdldom)", (J(length(ivs), 1, ""), ivs') )
	
	if ( !strlen(complete) ) {
		st_matrixrowstripe("r(cptdom)", (J(length(ivs), 1, ""), ivs') )
		st_matrixcolstripe("r(cptdom)", (J(length(ivs), 1, ""), ivs') )
	}
			
	st_matrix("r(stdzd)", 
		(st_matrix("r(domwgts)")):/(sum(st_matrix("r(domwgts)") ) ) ) 
	st_matrixcolstripe("r(stdzd)", (J(length(ivs), 1, ""), ivs') )
			
	st_matrix("r(ranks)", 
		colsum( 
			J(cols(st_matrix("r(domwgts)")), 
				1, st_matrix("r(domwgts)") ):<=(st_matrix("r(domwgts)")') 
			) )
	if ( strlen(reverse) ) 
		st_matrix("r(ranks)", 
			colsum( 
				J(cols(st_matrix("r(domwgts)")), 
					1, st_matrix("r(domwgts)") ):>=(st_matrix("r(domwgts)")') 
				) )
	st_matrixcolstripe("r(ranks)", (J(length(ivs), 1, ""), ivs') )
		
	st_numscalar("r(N)", obs)
		
	st_local("reg", reg)
	st_local("regopts", regopts)
	st_local("touse", marks[1])
	st_local("dv", dv)
	
	st_numscalar("r(allfs)", all_fitstat)
	st_numscalar("r(consfs)", cons_fitstat)
	st_numscalar("r(fullfs)", full_fitstat)
	
}

end

**# Mata function to execute 'domin-flavored' models
version 15

mata:

	mata set matastrict on

	real scalar domin_call(string scalar IVs_in_model,
		class AssociativeArray scalar model_specs) { 

		real scalar fitstat

		stata(model_specs.get("reg") + " " + model_specs.get("dv") + " " + 
			model_specs.get("all") + " " + IVs_in_model + " [" + 
			model_specs.get("weight") + "] if " + 
			model_specs.get("touse") + ", " + model_specs.get("regopts"), 1)

		fitstat = st_numscalar(model_specs.get("fitstat")) - 
			model_specs.get("all_fitstat") - 
			model_specs.get("cons_fitstat")

		return(fitstat)

	}
	
end
**# Mata function to execute built-in linear regression
version 15
mata:
mata set matastrict on
real scalar domin_regress(string scalar IVs_in_model, class AssociativeArray scalar model_specs) { 
	real scalar fitstat
	real rowvector index
	real colvector coeffs
	real matrix analysis_mat
	index = strtoreal(tokens(invtokens((IVs_in_model, model_specs.get("all")))))
	coeffs = qrsolve(model_specs.get("corrmat")[index, index], model_specs.get("dvcor")[index]')
	fitstat = model_specs.get("dvcor")[index]*coeffs - model_specs.get("all_fitstat")
	return(fitstat)
}
end
**# Mata function to execute epsilon-based relative importance
version 12

mata: 

mata set matastrict on

void eps_ri(string scalar varlist, string scalar reg, 
	string scalar touse, string scalar regopts, string scalar weight) 
{
	/*object declarations*/
	real scalar rc
	
	real matrix X, L, R, Lm, L2, R2, orth

	real rowvector V, Bt, V2, glmwgts, varloc
	
	string rowvector orthnames
	
	real scalar sd_yhat, cor_yhat
	
	string scalar predmu, wgt_stmnt
	
	transmorphic view, wgt_view, mu_view
	
	/*begin processing*/
	st_view(view, ., tokens(varlist), st_varindex(touse))
	
	if ( strlen(weight) ) st_view(wgt_view, ., weight, st_varindex(touse))
	else wgt_view = 1
	
	X = correlation(view, wgt_view) //obtain correlations
	
	L = R = X[2..rows(X), 2..cols(X)] //set-up for svd()
	
	V = J(1, cols(X)-1, .) //placeholder for eigenvalues
	
	svd(X[2..rows(X), 2..cols(X)], L, V, R) //conduct singular value decomposition
	
	Lm = (L*diag( sqrt(V) )*R) //process orthogonalized predictors
	
	if (reg == "regress") Bt = invsym(Lm)*X[2..rows(X), 1] //obtain adjusted regression weights
	
	else if (reg == "glm") { //if glm-based...
	
		svd(
			( view[., 2..cols(view)]:-mean( 
				view[., 2..cols(view)] ) ):/( sqrt( diagonal( variance( 
					view[., 2..cols(view)] ) ) )' ),
		L2, V2, R2)
		
		orth = L2*R2 //produce the re-constructed orthogonal predictors for use in regression
		
		orth = (orth:-mean(orth)):/sqrt( diagonal( variance(orth) ) )' //standardize the orthogonal predictors
		
		orthnames = st_tempname( cols(orth) )
		
		varloc = st_addvar("double", orthnames) //generate some tempvars for Stata
		
		st_store(., orthnames, st_varindex(touse), orth) //put the orthogonalized variables in Stata
		
		if ( strlen(weight) ) wgt_stmnt = " [iweight="
		else wgt_stmnt = " ["
		
		rc = _stata("glm " + tokens(varlist)[1] + " " + 
			invtokens(orthnames) + wgt_stmnt + weight + "] if " + 
			touse + ", " + regopts, 1) //conduct the analysis

		if ( rc ) {
		
			display("{err}{cmd:" + reg + "} failed when executing {cmd:epsilon}.")
		
			exit( rc )
			
		}
		
		glmwgts = st_matrix("e(b)") //record the regression weights to standardize
		
		predmu = st_tempname() //generate some more tempvars for Stata
		
		sd_yhat = sqrt( variance(orth*glmwgts[1, 1..cols(glmwgts)-1]') ) //SD of linear predictor
		
		stata("predict double " + predmu + " if " + touse + ", mu", 1) //translated with link function
		
		st_view(mu_view, ., st_varindex(predmu), st_varindex(touse))
		
		cor_yhat = correlation((view[., 1], mu_view), wgt_view)
		
		Bt = (glmwgts[1, 1..cols(glmwgts)-1]:*((cor_yhat[2, 1])/(sd_yhat)))'

	}
	
	else { //asked for invalid reg
	
		display("{err}{opt reg(" + reg + ")} invalid with {opt epsilon}.")
	
		exit(198)
		
	}
	
	Bt = Bt:^2 //square values of regression weights
	
	Lm = Lm:^2 //square values of orthogonalized predictors

	st_matrix("r(domwgts)", (Lm*Bt)')	//produce proportion of variance explained and put into Stata
	
}

end

/* programming notes and history
- domin_se version 0.0.0 - date - mth day, year


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
 domin version 3.5.0 - August 14, 2023
 - most of command migrated to Mata - minimum supported version is 15
	- argument check changes - new requirement that underlying command has e(sample)
    - remove support for -mi- make it a wrapper like fitdom()
	- remove dependency on -moremata-
 - built-in linear regression/-regress- function for speedier DA
 - updates to dominance.mata (to 0.1.0)
	- updated 'epsilon' method to use st_view() instead of st_data()
	- 'epsilon' method accepts weights
 // 3.5.1 - January 12, 2024
 - fixed references to 'all subsets' - should be 'all sub-models'
 - fixed error in docuementation of -rforest- Example 11; needed -noesampleok-
 - removed redundant e(N) setting
 - fixed N computation with -fweight- and -iweight-
 // 3.5.2 -- August 13, 2024
 - fixed error using -all- with factor or time-series variables with the built-in method (thanks to Felix Bittman)
 - -consmodel- not allowed with built-in regress method
 - -mi_dom- and factor- and time-series variable error fixes (thanks to katherine // kathy chan)
 ---
 
 future domin
 ** planned ** - commonality coefficients?
 ** planned ** - bootstrap?
 ** planned ** - built in -glm-?
 ** planned ** - depreciated by -domin2-'s bmaregress interface; eventually will be defunct and enveloped by its interface
 ** planned ** - owen decomp
 ** planned ** - mi with mixdom // mvdom (tor neilands)
 */
