*! domme version 1.2.0 1/12/2024 Joseph N. Luchman
// version information at end of file

**# Pre-program definition
quietly include dominance.mata, adopath

program define domme, eclass 

	version 15

	if replay() & !strlen("`0'") {

		if ("`e(cmd)'" != "domme") error 301

		if _by() error 190

		Display `0'

		exit 0

	}
	
**# Program definition and argument checks
syntax [anything(id="equation names" equalok)] [in] [if] [aw pw iw fw], ///
	Reg(string) Fitstat(string) ///
	[Sets(string) All(string) ///
	noCOMplete noCONditional REVerse ///
	ROPts(string)]

**# Wrapper process for -domme- processing in Mata
mata: domme_2mata("`reg'", "`fitstat'", "`sets'", "`all'", ///
	"`conditional'", "`complete'", "`ropts'", "`reverse'", ///
	"`weight'`exp'", "`in' `if'", "`anything'")

**# Ereturn processing
tempname domwgts cdldom cptdom stdzd ranks 

if !strlen("`conditional'") matrix `cdldom' = r(cdldom)
if !strlen("`complete'") matrix `cptdom' = r(cptdom)

if strlen("`e(title)'") local title "`e(title)'"
else if !strlen("`e(title)'") & strlen("`e(cmd)'") local title "`e(cmd)'"
else local title "Custom user analysis"	

matrix `domwgts' = r(domwgts)
ereturn post `domwgts' [`weight'`exp'] , obs(`=r(N)') esample(`touse')

**# Ereturn scalars
ereturn scalar fitstat_o = `=r(fullfs) + r(allfs) + r(consfs)'

if `=r(allfs)' != 0 ereturn scalar fitstat_a = r(allfs)
if `=r(consfs)' != 0 ereturn scalar fitstat_c = r(consfs)

if strlen("`setcount'") {

	ereturn hidden scalar setcount = `setcount'	
	
	forvalues set = 1/`setcount' {	
		
		ereturn local set`set' = trim("`set`set''")	

	}

}

else ereturn hidden scalar setcount = 0	

**# Ereturn macros
ereturn hidden local disp_title "`title'"

ereturn hidden local reverse "`reverse'"

if strlen("allset") ereturn local all = "`allset'"

if strlen("`ropts'") ereturn local ropts `"`ropts'"'

ereturn local reg "`reg'"

ereturn local fitstat "`fitstat'"

ereturn local cmd "domme"

ereturn local title `"Dominance analysis for multiple equations"'

ereturn local cmdline `"domme `0'"'

**# Ereturn matrices
if !strlen("`conditional'") ereturn matrix cdldom `cdldom'

if !strlen("`complete'") ereturn matrix cptdom `cptdom'

matrix `ranks' = r(ranks)
ereturn matrix ranking `ranks'

matrix `stdzd' = r(stdzd)
ereturn matrix std `stdzd'

Display

end


/*Display program*/
program define Display

version 15

/*set up*/
tempname gendom stzd_gendom ranks

matrix `gendom' = e(b)
matrix `stzd_gendom' = e(std)
matrix `ranks' = e(ranking)

local diivs: colnames e(b)
local eqivs: coleq e(b)

mata: st_local("cdltest", strofreal(cols(st_matrix("e(cdldom)"))))
mata: st_local("cpttest", strofreal(cols(st_matrix("e(cptdom)")))) 

tokenize `diivs'

display _newline "{txt}General dominance statistics: `e(disp_title)'" ///
	_newline "{txt}Number of obs{col 27}={res}{col 40}" %12.0f e(N) 			

display "{txt}Overall Fit Statistic{col 27}={res}{col 36}" ///
	%16.4f e(fitstat_o)

if !missing( e(fitstat_a) ) display "{txt}All Sub-models Fit Stat." ///
	"{col 27}={res}{col 36}" %16.4f e(fitstat_a)

if !missing( e(fitstat_c) ) display "{txt}Constant-only Fit Stat." ///
	"{col 27}={res}{col 36}" %16.4f e(fitstat_c)

display _newline "{txt}{col 13}{c |}{col 20}Dominance" ///
	"{col 35}Standardized{col 53}Ranking"

display "{txt}{col 13}{c |}{col 20}Stat.{col 35}Domin. Stat." 

display "{txt}{hline 12}{c +}{hline 72}"

local current_eq ""

forvalues iv = 1/`:list sizeof diivs' {

	if "`current_eq'" != abbrev("`: word `iv' of `eqivs''", 11) ///
		display `"{txt}`=abbrev("`: word `iv' of `eqivs''", 11)'{txt}{col 13}{c |}"'

	local current_eq = abbrev("`: word `iv' of `eqivs''", 11)

	local `iv' = abbrev("``iv''", 10)

	display "{txt}{col 2}{lalign 11:``iv''}{c |}{col 14}{res}" ///
		%15.4f `gendom'[1,`iv'] "{col 29}" %12.4f ///
		`stzd_gendom'[1,`iv'] "{col 53}" %-2.0f `ranks'[1,`iv']

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

if `=`cpttest'*`cdltest'' {		

	display _newline "{txt}Strongest dominance designations" 

	tempname bestdom cdl gen decision
	if strlen("`e(reverse)'") mata: st_matrix("`bestdom'", ///	
		st_matrix("e(cptdom)"):*-1)

	else matrix `bestdom' = e(cptdom)		

	forvalues dominator = 1/`=colsof(e(cdldom))-1' {

		forvalues dominatee = `=`dominator'+1'/`=colsof(e(cdldom))' {

			scalar `cdl' = 0			

			scalar `gen' = 0

			mata: st_numscalar("`cdl'", ///
				( sum( st_matrix("e(cdldom)")[`dominator', .] ///
				:>st_matrix("e(cdldom)")[`dominatee', .] ) ) ///
				:==rows( st_matrix("e(cdldom)") ) ) 											

			if !`cdl' mata: ///
				st_numscalar("`cdl'", -1*((sum(st_matrix("e(cdldom)")[`dominator', .] ///
				:<st_matrix("e(cdldom)")[`dominatee', .])):==rows(st_matrix("e(cdldom)"))))	

			mata: st_numscalar("`gen'", ///
				st_matrix("e(b)")[1, `dominator']>st_matrix("e(b)")[1, `dominatee'])	

			if !`gen' mata: st_numscalar("`gen'", ///
				(st_matrix("e(b)")[1, `dominator']<st_matrix("e(b)")[1, `dominatee'])*-1)	

			local reverse_adj = cond(strlen("`e(reverse)'"), -1, 1)	

			scalar `decision' = ///
				cond(abs(`bestdom'[`dominator', `dominatee']) == 1, ///
				`bestdom'[`dominator', `dominatee'], cond(abs(`cdl') == 1, ///
				`cdl'*2, cond(abs(`gen') == 1, `gen'*3, 0)))	
			
			matrix `bestdom'[`dominator', `dominatee'] = ///
				`decision'*`reverse_adj'				

			matrix `bestdom'[`dominatee', `dominator'] = ///
				-`decision'*`reverse_adj'				

		}

	}

	local names `:colfullnames e(b)'

	mata: display(("{txt}", select(vec(tokens(st_local("names"))' ///
		:+((st_matrix("`bestdom'"):==1):*" completely dominates ") ///
		:+tokens(st_local("names")))', ///
		regexm(vec(tokens(st_local("names"))' ///
		:+((st_matrix("`bestdom'"):==1):*" completely dominates ") ///
		:+tokens(st_local("names")))', ///
		"completely dominates")) , ///
		select(vec(tokens(st_local("names"))':+((st_matrix("`bestdom'"):==2) ///
		:*" conditionally dominates "):+tokens(st_local("names")))', ///
		regexm(vec(tokens(st_local("names"))':+((st_matrix("`bestdom'"):==2) ///
		:*" conditionally dominates "):+tokens(st_local("names")))', ///
		"conditionally dominates")), ///
		select(vec(tokens(st_local("names"))':+((st_matrix("`bestdom'"):==3) ///
		:*" generally dominates "):+tokens(st_local("names")))', ///
		regexm(vec(tokens(st_local("names"))':+((st_matrix("`bestdom'"):==3) ///
		:*" {txt}generally dominates{res} "):+tokens(st_local("names")))', ///
		"generally dominates")))')						

	display ""

}

if `=e(setcount)' {	

	forvalues set = 1/`=e(setcount)' {

		display "{txt}Parameters in set`set': `e(set`set')'"

	}

}

if strlen("`e(all)'") ///
	display "{txt}Parameter estimates included in all sub-models: `e(all)'"
		
end

**# Mata function adapting Stata input for Mata and initiating the Mata environment
version 15

mata:

mata set matastrict on

void domme_2mata(
	string scalar reg, 
	string scalar fitstat, 
	string scalar sets, 
	string scalar all,
	string scalar conditional, 
	string scalar complete,
	string scalar ropts, 
	string scalar reverse,
	string scalar weight,
	string scalar inif, 
	string scalar anything
	) {
	
/* ~ declarations and initial structure */
	class AssociativeArray scalar model_specs
	
	real scalar param, index_count, set, set_param,
		full_fitstat, all_fitstat, cons_fitstat, 
		obs, rc
	
	string scalar dv, marks, bi_type
	
	string rowvector params, dv_iv_pairs, dv_iv_parsed, ivs, 
		all_pairs, sets2, set_list, set_params, 
		dv_iv_cns, set_cns, set_prm_cns, all_cns, 
		parm_display, eq_display
	
	transmorphic parser	

/* ~ argument checks ~ */
	if ( strmatch(fitstat, "e()*") ) {
		if ( !((fitstat == "e(), mcf") | (fitstat == "e()")) )  {
			display(("{err}{opt fitstat()} incorrectly specified." \
					"Must be set up as 'e()' or 'e(), mcf'." \ 
					"Note that types 'est', 'aic', and 'bic' are disallowed " \ 
					"from {cmd:domme} version 1.2."))
			exit(198)
		}
		else bi_type = "mcf"
	}
	else bi_type = ""
	
/* ~ process parm ests and sets ~ */
	/*parse individual parm ests; if empty, return empty vector*/
	if ( strlen(anything) ) {
		parser = tokeninit(" ", "", "()")
		tokenset(parser, anything)
			
		/*get all parms; remove parentehses*/
		params = tokengetall(parser)
		params = substr(params, 2, strlen(params):-2)
		
		/*create dummy dv-iv pair vector; create index*/
		dv_iv_pairs = 
			J(1, sum(ustrwordcount(params)) - 2*length(params), "")
		if ( !length(dv_iv_pairs) ) dv_iv_pairs = J(0, 0, "")
		index_count = 0
		
		/*fill in dv-iv pair vector*/
		for (param=1; param<=length(params); param++) {
			
			/*parse dv vs ivs on '='*/
			dv_iv_parsed = tokens( params[param], "=")
			
			/*exit conditions*/
			if ( length(dv_iv_parsed) == 1 ) {
				display(("{err}Parameter specification in position " + 
					strofreal(param) + " missing '='." \ 
					"DV-IV pairs cannot be parsed."))
				exit(111)
			}
			if ( (selectindex(dv_iv_parsed:=="=") != 2) | (ustrwordcount(dv_iv_parsed[1]) != 1) ) {
				display(("{err}Parameter specification in position " + strofreal(param) + 
					" has un-parsable DV." \ 
						"DV-IV pairs cannot be parsed."))
				exit(111)
			}
			
			/*flag ivs and dvs*/
			ivs = tokens(dv_iv_parsed[3..length(dv_iv_parsed)])
			dv = strtrim(dv_iv_parsed[1])
			
			/*construct pairs; update index*/
			dv_iv_pairs[index_count+1..index_count+length(ivs)] = 
				(dv + ":"):+ivs
			index_count = index_count + length(ivs)
		}
	}
	
	/*setup all parsing; largely repeats dv-iv processing*/
	if ( strlen(all) ) {
		parser = tokeninit(" ", "", "()")
		tokenset(parser, all)
			
		params = tokengetall(parser)
		params = substr(params, 2, strlen(params):-2)
		
		all_pairs = 
			J(1, sum(ustrwordcount(params)) - 2*length(params), "")
		index_count = 0
		for (param=1; param<=length(params); param++) {
			dv_iv_parsed = tokens( params[param], "=")
			if ( length(dv_iv_parsed) == 1 ) {
				display(("{err}All parameter specification in position " + 
					strofreal(param) + " missing '='." \ 
					"DV-IV pairs cannot be parsed."))
				exit(111)
			}
			if ( (selectindex(dv_iv_parsed:=="=") != 2) | (ustrwordcount(dv_iv_parsed[1]) != 1) ) {
				display(("{err}All parameter specification in position " + strofreal(param) + 
					" has un-parsable DV." \ 
						"DV-IV pairs cannot be parsed."))
				exit(111)
			}
			ivs = tokens(dv_iv_parsed[3..length(dv_iv_parsed)])
			dv = strtrim(dv_iv_parsed[1])
			all_pairs[index_count+1..index_count+length(ivs)] = 
				(dv + ":"):+ ivs
			index_count = index_count + length(ivs)
		}
	}
	else all_pairs = J(0, 0, "")
	
	/*record parms implied by -all()- in Stata*/
	st_local("allset", (length(all_pairs) ? invtokens(all_pairs) : "" ))
	
	/*setup sets parsing; repeats dv-iv processing with extra parsing layer*/
	if ( strlen(sets) ) {
		
		/*initial parsing layer; binds sets first on brackets*/
		parser = tokeninit(" ", "", "[]")
		tokenset(parser, sets)
		
		/*parse out all sets*/
		sets2 = tokengetall(parser)
		sets2 = substr(sets2, 2, strlen(sets2):-2)
		
		/*list of sets to update with lists of parm ests*/
		set_list = 
			J(1, length(sets2), "")
		
		for (set=1; set<=length(set_list); set++) {
			
			/*second parsing layer; binds parm ests on parentheses*/
			parser = tokeninit(" ", "", "()")
			tokenset(parser, sets2[set])
			
			set_params = tokengetall(parser)
			set_params = substr(set_params, 2, strlen(set_params):-2)
			
			set_pairs = 
				J(1, sum(ustrwordcount(set_params)) - 2*length(set_params), "")
			index_count = 0
			
			/*combined sets of parm ests within a set; note they are combined*/
			for (set_param=1; set_param<=length(set_params); set_param++) {
				dv_iv_parsed = tokens( set_params[set_param], "=")
				if ( length(dv_iv_parsed) == 1 ) {
					display(("{err}Set position " + strofreal(set) + 
					" parameter specification in position " + strofreal(set_param) + " missing '='." \ 
						"DV-IV pairs cannot be parsed."))
					exit(111)
				}
				if ( (selectindex(dv_iv_parsed:=="=") != 2) | (ustrwordcount(dv_iv_parsed[1]) != 1) ) {
					display(("{err}All parameter specification in position " + strofreal(param) + 
						" has un-parsable DV." \ 
							"DV-IV pairs cannot be parsed."))
					exit(111)
				}
				ivs = tokens(dv_iv_parsed[3..length(dv_iv_parsed)])
				dv = strtrim(dv_iv_parsed[1])
				set_pairs[index_count+1..index_count+length(ivs)] = 
					(dv + ":"):+ ivs
				index_count = index_count + length(ivs)
			}
			set_list[set] = invtokens(set_pairs)
			st_local("set" + strofreal(set), invtokens(set_pairs))
			
		}
		
	}
	else set_list = J(0, 0, "")
	
	/*record set count in Stata environment*/
	st_local("setcount", strofreal(length(set_list)))
	
/* ~ check primary analysis and set estimation sample ~ */
	st_eclear()
		
	if (inif == " ") inif = "if _n > 0"
	
	rc = _stata(reg + " [" + weight + "] " + inif + ", " + ropts, 1)
	
	if ( rc ) {
		
		display("{err}{cmd:" + reg + "} resulted in an error.")
		exit(rc)
		
	}
		
	if ( (!strlen(bi_type)) )	{
		
		if ( !length( st_numscalar( strtrim(fitstat) ) ) ) {
			
			display("{err}{cmd:" + fitstat + 
				"} not returned by {cmd:" + reg + "} or {cmd:" + fitstat + 
				"} is not scalar valued. See {help return list}.")
			exit(198)
			
		}
	}
	
	if ((bi_type == "mcf") & 
		(!length(st_numscalar("e(ll)")))) {
			
		display("{err}{cmd:e(ll} not returned by {cmd:" + reg + "}.")
		exit(198)
		
	}
	
	full_fitstat = built_in_fitstat(fitstat, bi_type, ., 1) 
	
	marks = st_tempname()
		
	stata("generate byte " + marks[1] + " = e(sample)", 1)
	
	if (strmatch(weight, "fweight*") | strmatch(weight, "iweight*")) {
		
		stata("summarize " + marks[1] + " if " + marks[1] + 
			" [" + weight + "]", 1)
		
	}
	else stata("count if " + marks[1], 1)
		
	obs = st_numscalar("r(N)")
	
/* ~ generate constraints ~ */
	if ((length(dv_iv_pairs) + length(set_list)) < 2) {
		display("{err}{cmd:domme} requires at least 2 parameter estimates or parameter estimate sets.")
		exit(198)
	}
	
	rc = 0
	
	/*generate constraints for dv-iv pairs*/
	if (length(dv_iv_pairs)) {
		
		/*initalize empty list for constraint numbers*/
		dv_iv_cns = J(1, length(dv_iv_pairs), "")
		
		/*iterate across all dv-iv pairs*/
		for (param=1; param<=length(dv_iv_pairs); param++) {
			/*get a free constraint in memory from Stata; catch if error*/
			rc = _stata("constraint free")
			if (rc) break
			
			/*record the value of the constraint*/
			dv_iv_cns[param] = st_macroexpand("`" + "r(free)" + "'")
			
			/*map the value of the constraint to a dv-iv pair*/
			stata("constraint " + dv_iv_cns[param] + " _b[" + 
				dv_iv_pairs[param] + "] = 0")
		}
		
	}
	
	/*repeats dv-iv pair process but groups constraints by set*/
	if (length(set_list)) {
		
		set_cns = J(1, length(set_list), "")
		
		for (set=1; set<=length(set_list); set++) {
			set_params = tokens(set_list[set])
			set_prm_cns = J(1, length(set_params), "")
			for (param=1; param<=length(set_prm_cns); param++) {
				rc = _stata("constraint free")
				if (rc) break
				set_prm_cns[param] = st_macroexpand("`" + "r(free)" + "'")
				stata("constraint " + set_prm_cns[param] + " _b[" + 
					set_params[param] + "] = 0")
			}
			set_cns[set] = invtokens(set_prm_cns)
		}
		
	}
	
	/*repeats dv-iv pair process but groups -all()- params together*/
	if (length(all_pairs)) {
		
		all_cns = J(1, length(all_pairs), "")
		
		for (param=1; param<=length(all_pairs); param++) {
			rc = _stata("constraint free")
			if (rc) break
			all_cns[param] = st_macroexpand("`" + "r(free)" + "'")
			stata("constraint " + all_cns[param] + " _b[" + 
				all_pairs[param] + "] = 0")
		}
		
	}
	
	if (rc) {
		display("{err}{cmd:domme} cannot make any more constraints as the " + 
					"{help constraint dir} is full (see {help constraint drop}).")
		
		/*drop constraints if generated*/
		exit_constraint((dv_iv_cns, set_cns, all_cns), 198)
	}
	
/* ~ begin collecting effect sizes ~ */
	all_fitstat = 0

	if ( length(all_pairs) ) {
			
		rc = _stata(reg + " [" + weight + "] " + inif + ", constraints(" + 
			invtokens((dv_iv_cns, set_cns)) + ")" + ropts, 1)
			
		if (rc) {
			exit_constraint((dv_iv_cns, set_cns, all_cns), rc)
		}
	
		all_fitstat = built_in_fitstat(fitstat, bi_type, ., 1)

	}
				
	rc = _stata(reg + " [" + weight + "] " + inif + ", constraints(" + 
			invtokens((dv_iv_cns, set_cns, all_cns)) + ")" + ropts, 1)
			
	if (rc) {
			exit_constraint((dv_iv_cns, set_cns, all_cns), rc)
		}
	
	cons_fitstat = built_in_fitstat(fitstat, bi_type, ., 1)
	
	if ( bi_type == "mcf" ) {
		full_fitstat = 1 - full_fitstat/cons_fitstat
		if ( length(all_pairs) )
			all_fitstat = 1 - all_fitstat/cons_fitstat
		
	}
	
	if ( length(all_pairs) & !strlen(bi_type) ) 
		all_fitstat = all_fitstat - cons_fitstat
	
	full_fitstat = 
		full_fitstat - all_fitstat - 
			(strlen(bi_type)? 0 : cons_fitstat)
	
/* ~ invoke dominance ~ */	
	model_specs.put("reg", reg)
	model_specs.put("fitstat", fitstat)
	model_specs.put("weight", weight)
	model_specs.put("inif", inif)
	model_specs.put("ropts", ropts)
	model_specs.put("cns", (dv_iv_cns, set_cns))
	
	model_specs.put("reverse", reverse)
	
	model_specs.put("all_fitstat", all_fitstat)
	model_specs.put("cons_fitstat", cons_fitstat)
	
	model_specs.put("bi_type", bi_type)
	
	dominance( model_specs, &domme_call(), 
		(dv_iv_cns, set_cns)', conditional, complete, full_fitstat )
	
/* ~ return values ~ */		
	if ( length(set_list) ) dv_iv_pairs = (dv_iv_pairs, "_set:set":+strofreal((1..length(set_list))))
	
	parm_display = eq_display = J(1, length(dv_iv_pairs), "")
	
	for (param=1; param<=length(dv_iv_pairs); param++) {
		parm_display[param] = ustrsplit(dv_iv_pairs[param], ":")[2]
		eq_display[param] = ustrsplit(dv_iv_pairs[param], ":")[1]
	}
	
	st_matrixcolstripe("r(domwgts)", (eq_display \ parm_display)')
	
	if ( strlen(reverse) )
		st_matrix("r(cptdom)", 
			 st_matrix("r(cptdom)"):*-1 )
	
	if ( !strlen(conditional) ) {
		st_matrixrowstripe("r(cdldom)", (eq_display \ parm_display)' )
		st_matrixcolstripe("r(cdldom)", 
			(J(1, length(dv_iv_pairs), "#param_ests") \ strofreal(1..length(dv_iv_pairs)))' )
	}
	
	if ( !strlen(complete) ) {
		st_matrixrowstripe("r(cptdom)", (">?":+eq_display \ parm_display)' )
		st_matrixcolstripe("r(cptdom)", ("<?":+eq_display \ parm_display)' )
	}
	
	st_matrix("r(stdzd)", 
		(st_matrix("r(domwgts)")):/(sum(st_matrix("r(domwgts)") ) ) ) 
	st_matrixcolstripe("r(stdzd)", (eq_display \ parm_display)' )
			
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
	st_matrixcolstripe("r(ranks)", (eq_display \ parm_display)' )
		
	st_numscalar("r(N)", obs)
	st_local("reg", reg)
	st_local("touse", marks[1])
	built_in
	st_local("built_in", strofreal(strlen(bi_type)>0))
	st_local("built_in_style", bi_type)
	
	st_numscalar("r(allfs)", all_fitstat)
	st_numscalar("r(consfs)", 
		(strlen(bi_type) ? 0 : cons_fitstat) )
	st_numscalar("r(fullfs)", full_fitstat)

/* mechanism to drop constraints if generated */
	exit_constraint((dv_iv_cns, set_cns, all_cns), 0)
	
}

end

**# Mata function to execute 'domme-flavored' models
version 15

mata:

	mata set matastrict on

	real scalar domme_call(string scalar params_to_remove,
		class AssociativeArray scalar model_specs) { 

		real scalar fitstat, rc
		
		string scalar params_in_model
		
		string rowvector cns
		
		/*enumerate all constraints generated*/
		cns = tokens(invtokens(model_specs.get("cns")))
		
		/*constraints indicate omitted parm est; reverse to get all included*/
		params_in_model = 
			select(cns, 
				!colsum((J(length(tokens(params_to_remove)), 1, 
					strtoreal(cns)):==J(1, length(cns), 
						strtoreal(tokens(params_to_remove))'))))
		
		rc = _stata(model_specs.get("reg") + " [" + model_specs.get("weight") + "] " + 
			model_specs.get("inif") + ", constraints(" + 
			invtokens(params_in_model) + ") " + model_specs.get("ropts"), 1)
		
		/*drop constraints if generated*/
		if (rc) {
			
			exit_constraint(cns, rc)
			
		}
			
		fitstat = 
			built_in_fitstat(model_specs.get("fitstat"), 
				model_specs.get("bi_type"),
				model_specs.get("cons_fitstat"), 0)
		
		fitstat = 
			fitstat - 
			model_specs.get("all_fitstat") - 
			(strlen(model_specs.get("bi_type")) ? 
				0 : model_specs.get("cons_fitstat") )
		
		return(fitstat)

	}
	
end

**# Mata function to drop constraints and exit
version 15

mata:

	mata set matastrict on
	
	void exit_constraint(string rowvector cns_list, numeric scalar exit_num) {
		
		numeric scalar cns
		
		for (cns=1; cns<=length(cns_list); cns++) {
			
			stata("constraint drop " + cns_list[cns])
			
		}
		
		if (exit_num) exit(exit_num)
		
	}
	
end

**# Mata program to obtain fit statistics after model estimation

version 15

mata:

	mata set matastrict on
	
	numeric scalar built_in_fitstat(
		string scalar fitstat, string scalar type, numeric scalar constant, 
		numeric scalar isconstant
	) {
		
		numeric scalar value
		
		/*compute McFadden R2*/
		if (type == "mcf") {
			
			value = (isconstant? 
				st_numscalar("e(ll)") : 
				1 - st_numscalar("e(ll)")/constant)
			
		}
		/*not a built-in, pass the name and assume Stata returns it*/
		else value = st_numscalar( strtrim(fitstat) ) 
		
		return(value)
		
	}

end

/* programming notes and history
   - domme version 1.0 - date - July 2, 2019
   -base version
   // 1.0.1 - April 17, 2021 (initiating new versioning: #major.#minor.#patch)
   -update to documentation for SJ article
   -bug fix on constraint dropping with all() option and use with xi:
---
 domme version 1.1.0 - February 7, 2023
 - leverage dominance() function in -domin-; create own function to function passing; Mata struct to handle input specs
 - -domin- now a dependency.
 - use an AssociativeArray to map parameters/parameter sets to constraints in a way that is conformable with -domin-
 - extensive documentation update
 - fixed complete dominance table display; retains equation name and adds informative prefix
 // 1.1.1 - March 7, 2023
 - call 'dominance.mata' as opposed to using 'lb_dominance.mlib' to allow backward compatability
 // 1.1.2 - August 14, 2023
 - migrated to a sub-method in the -domin- module
 - call temporary 'dominance0.mata' (v 0.0) for time being until re-designed similar to -domin- to use 'dominance.mata' versions > 0.0
 ---
 domme version 1.2.0 - January 12, 2024
 - most of command migrated to Mata
	- now dependent on dominance.mata (not dominance0.mata)
 - fixed references to 'all subsets' - should be 'all sub-models'
 - minimum version sync-ed with -domin- at 15 (not 15.1)
 - fixed issue with -all()- option; not consistent with documentation - required full 'all' typed (not 'a()')
 - estrella, aic and bic disallowed with built-in; mcfadden remains
*/
