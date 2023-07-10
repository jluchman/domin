*! domin_se version 0.0.0  xx/xx/202x Joseph N. Luchman
// version information at end of file

program define domin_se, eclass 

version 17

**# Program definition and argument checks
syntax varlist(min = 1 ts) [in] [if] [aw pw iw fw] , ///
	[Reg(string) Fitstat(string) Sets(string) All(varlist fv ts) ///
	noGENeral noCONditional noCOMplete EPSilon CONSmodel REVerse noESAMPleok] // remove direct mi support - make it into a wrapper
	
if strlen("`epsilon'") {
	local esampleok "esampleok"
	local conditional "conditional"
	local complete "complete"
}

**# Wrapper process for -domin- processing in Mata
mata: domin_se_2mata("`reg'", "`fitstat'", "`sets'", "`all'", ///
	"`conditional'", "`complete'", "`epsilon'", "`consmodel'", "`reverse'", ///
	"`esampleok'", "`weight'`exp'", "`in' `if'", "`varlist'")
		
**# Ereturn processing
tempname domwgts cdldom cptdom stdzd ranks

if !strlen("`epsilon'") & strlen("`e(title)'") local title "`e(title)'"

else if strlen("`epsilon'") & strlen("`e(title)'") local title "Epsilon-based `reg'"

else local title "Custom user analysis"

matrix `domwgts' = r(domwgts)
ereturn post `domwgts' [`weight'`exp'], depname(`dv') obs(`=`r(N)'') esample(`touse')

**# Ereturn scalars
ereturn scalar N = `=r(N)'

matrix `domwgts' = r(domwgts)*J(colsof(r(domwgts)), 1, 1)
ereturn scalar fitstat_o = `=`domwgts'[1,1] + r(allfs) + r(consfs)'

if `:list sizeof all' ereturn scalar fitstat_a = `=r(allfs)'
if strlen("`consmodel'") ereturn scalar fitstat_c = `=r(consfs)'

if strlen("`setcnt'") {

	ereturn hidden scalar setcnt = `setcnt'

	forvalues x = 1/`setcnt' {
	
		fvunab set`x': `set`x''

		ereturn local set`x' "`set`x''"
		
	}
	
}

else ereturn hidden scalar setcnt = 0

**# Ereturn macros
ereturn hidden local dtitle "`title'"

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
	ereturn matrix cptdom = `cptdom'
}

if !strlen("`conditional'") {
	matrix `cdldom' = r(cdldom)
	ereturn matrix cdldom = `cdldom'
}

matrix `ranks' =  r(ranks)
ereturn matrix ranking = `ranks'

matrix `stdzd' =  r(stdzd)
ereturn matrix std = `stdzd'

end

**# Mata function adapting Stata input for Mata and initiating the Mata environment
version 17

mata:

mata set matastrict on

void domin_se_2mata(
	string scalar reg, 
	string scalar fitstat, 
	string scalar sets, 
	string scalar all,
	string scalar conditional, 
	string scalar complete,
	string scalar epsilon, 
	string scalar consmodel, 
	string scalar reverse,
	string scalar esampleok,
	string scalar weight,
	string scalar inif, 
	string scalar varlist
	) {
	
	
/* ~ declarations and initial structure */
	class AssociativeArray scalar model_specs
	
	real scalar set, rc, full_fitstat, obs, all_fitstat, cons_fitstat
	
	string scalar regopts, dv, marks
	
	string rowvector ivs, iv_sets
	
	transmorphic parser	
	
/* ~ argument checks ~ */
	/*-domin- defaults*/
	if ( !strlen(reg) & !strlen(fitstat) ) {
		
		reg = "regress"
		
		fitstat = "e(r2)" 
		
	}
	
	/*'epsilon' specifics*/
	if ( strlen(epsilon) ) {
		
		/*exit conditions: user must restructure*/
		if ( strlen(all + sets + weight) ) { 									// <- note to self: consider adding weights for 'epsilon'
			
			display("{err}{opt epsilon} not allowed with" + 
					" {opt all()}, {opt sets()}, or {opt weight}s.")
			exit(198) 															// <- note to self: document change to epsilon's error behavior ~~ 
				
		}
		
	}	
	
/* ~ process iv and sets ~ */
	/*parse varlist - store as 'ivs'*/
	ivs = tokens(varlist)
	
	/*'dv ivs' structure means first entry is 'dv'*/
	dv = ivs[1]
	
	/*remaining entries, if any, are 'ivs'*/
	if ( length(ivs) ) ivs = ivs[2..length(ivs)]							
	else ivs = ""
	
	/*set processing*/
	if ( strlen(sets) ) {
		/*setup parsing sets -  bind on parentheses*/
		t = tokeninit(" ", "", "()")
		tokenset(t, sets)
		
		/*get all sets and remove parentehses*/
		iv_sets = tokengetall(t)
		iv_sets = substr(iv_sets, 2, strlen(iv_sets):-2)
		st_local("setcnt", strofreal( length(iv_sets) ) )
		for (set=1; set<=length(iv_sets); set++) {
			
			st_local("set"+strofreal(set), iv_sets[set] )
			
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
	
	if ( length(ivs) < 2 ) {	

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
		
		stata("count if " + marks[1], 1)
		
		obs = st_numscalar("r(N)")
	
	}
	else obs = 0

	if (obs == 0 & strlen(esampleok) ) 	{
	
		marks = st_tempname(2)

		stata("mark " + marks[1]) 
		
		stata("generate byte " + marks[2] + " = 1 " + inif, 1)
			
		stata("markout " + marks[1] + " " + marks[2] + 
			" " + invtokens(ivs) + " " + all, 1)
			
		stata("count if " + marks[1], 1)
			
		obs = st_numscalar("r(N)")
	
	}
	
	if (obs == 0 & !strlen(esampleok)) {
		
		display("{err}{cmd:esample()} not set. Use {opt noesampleok} to avoid checking {cmd:esample()}.")
		exit(198)
	}

/* ~ begin collecting effect sizes ~ */
	all_fitstat = 0	
	
	if ( strlen(all) ) {
			
		stata(reg + " " + dv + " " + all + " [" + weight + "] if " + marks[1] + 
			", " + regopts, 1)
	
		all_fitstat = st_numscalar( strtrim(fitstat) )

	}
	
	cons_fitstat = 0	
	
	if ( strlen(consmodel) ) {
			
		stata(reg + " " + dv + " [" + weight + "] if " + marks[1] + 
			", " + regopts, 1)
				
		cons_fitstat = st_numscalar( strtrim(fitstat) )
			
		
	}
	
	if ( strlen(all) ) all_fitstat = all_fitstat - cons_fitstat
	
	full_fitstat = full_fitstat - all_fitstat - cons_fitstat
	
	
/* ~ invoke dominance ~ */	
	if ( strlen(epsilon) ) {

		if (reg == "mvdom") 
			stata("mvdom " + dv + " " + invtokens(ivs) + " if " + 
				marks[1] + ", " + regopts + " epsilon", 1)
		else eps_ri(dv + " " + invtokens(ivs), reg, marks[1], regopts) 
		
	}
	else {
		
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
		
		dominance(
			model_specs, &domin_call(), 
			ivs', conditional, complete, full_fitstat )
			
	}
	
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
		(mm_ranks( (st_matrix("r(domwgts)")'):*-1, 1, 1)') )
	if ( strlen(reverse) ) 
		st_matrix("r(ranks)", 
			( mm_ranks( (st_matrix("r(ranks)")'):*-1, 1, 1) )' )
	st_matrixcolstripe("r(ranks)", (J(length(ivs), 1, ""), ivs') )
		
	st_numscalar("r(N)", obs)
		
	st_local("reg", reg)
	st_local("regopts", regopts)
	st_local("touse", marks[1])
	st_local("dv", dv)
	
	st_numscalar("r(allfs)", model_specs.get("all_fitstat"))
	st_numscalar("r(consfs)", model_specs.get("cons_fitstat"))
	
}

end

**# Mata function to execute 'domin-flavored' models
version 17

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

/* programming notes and history
- domin_se version 0.0.0 - date - mth day, year
