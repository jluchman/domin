*! domin_se version 0.0.0  xx/xx/202x Joseph N. Luchman
// version information at end of file

program define domin_se, eclass 

version 17

**# Program definition and argument checks
syntax varlist(min = 1 ts) [in] [if] [aw pw iw fw] , [Reg(string) Fitstat(string) Sets(string) ///
	All(varlist fv ts) noGENeral noCONditional noCOMplete EPSilon CONSmodel REVerse noESAMPleok] // remove direct mi support - make it into a wrapper
	
if strlen("`epsilon'") {
	local esampleok "esampleok"
	local conditional "conditional"
	local complete "complete"
}

**# Wrapper process for -domin- processing in Mata
mata: domin_se_2mata("`reg'", "`fitstat'", /// "`sets'", "`all'",*/ 
	"`conditional'", "`complete'", "`epsilon'", ///"`consmodel'", "`reverse'", 
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
ereturn scalar fitstat_o = `=`domwgts'[1,1]'

/*
if strlen("`setcnt'") {

	ereturn hidden scalar setcnt = `setcnt'

	forvalues x = 1/`setcnt' {
	
		fvunab set`x': `set`x''

		ereturn local set`x' "`set`x''"
		
	}
	
}*/

/*else*/ ereturn hidden scalar setcnt = 0

**# Ereturn macros
ereturn hidden local dtitle "`title'"
/*
ereturn hidden local reverse "`reverse'"

if `:list sizeof all' {

	fvunab all: `all'

	ereturn local all "`all'"
	
}
*/
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


/*
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
*/

**# mata!

**# Mata function adapting Stata input for Mata and initiating the Mata environment
version 17

mata:

mata set matastrict on

void domin_se_2mata(
	string scalar reg, 
	string scalar fitstat, 
	/*string scalar sets, 
	string scalar all, */
	string scalar conditional, 
	string scalar complete,
	string scalar epsilon, 
	/*string scalar consmodel, 
	string scalar reverse,*/
	string scalar esampleok,
	string scalar weight,
	string scalar inif, 
	string scalar varlist
	) {
	
	
/* ~ declarations and initial structure */
	//struct domin_se_specs scalar model_specs
	class AssociativeArray scalar model_specs
	
	real scalar rc, full_fitstat, obs, all_fitstat, cons_fitstat
	
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
		if ( strlen(/*all + sets +*/ weight) ) { 									// <- note to self: consider adding weights for 'epsilon'
			
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
	/*
	/*set processing*/
	if ( strlen(sets) ) {
		/*setup parsing sets -  bind on parentheses*/
		t = tokeninit(" ", "", "()")
		tokenset(t, sets)
		
		/*get all sets and remove parentehses*/
		iv_sets = tokengetall(t)
		iv_sets = substr(iv_sets, 2, strlen(iv_sets):-2)
		
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
*/
/* ~ parse regression options ~ */
	parser = tokeninit(" ", ",")
	
	tokenset(parser, strtrim(reg))
	
	reg = tokenget(parser)
	
	if ( length(tokenrest(parser)) ) regopts = substr(tokenrest(parser), 2)
	else regopts = ""
	
/* ~ check primary analysis and set estimation sample ~ */
	if ( !strlen(epsilon) ) {
		
		st_eclear()

		rc = _stata(reg + " " + dv + " " + invtokens(ivs) + " " + /*all +  */
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
		else full_fitstat = st_numscalar( strtrim(fitstat) ) // note to self - add this to passed values to dominance()
		
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
			" " + invtokens(ivs) + " " /*+ all*/, 1)
			
		stata("count if " + marks[1], 1)
			
		obs = st_numscalar("r(N)")
	
	}
	
	if (obs == 0 & !strlen(esampleok)) {
		
		display("{err}{cmd:esample()} not set. Use {opt noesampleok} to avoid checking {cmd:esample()}.")
		exit(198)
	}
	

	/*	
/* ~ begin collecting effect sizes ~ */
	all_fitstat = 0	
	
	if ( strlen(all) ) {
			
		stata(reg + " " + dv + " " + all +  
			" [" + weight + "] if " + marks[1] + 
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
	*/
	
/* ~ invoke dominance ~ */	
	if ( strlen(epsilon) ) {

		if (reg == "mvdom") 
			stata("mvdom " + dv + " " + invtokens(ivs) + " if " + 
				marks[1] + ", " + regopts + " epsilon", 0)
		else eps_ri(dv + " " + invtokens(ivs), reg, marks[1], regopts) 
		
	}
	else {
		
		model_specs.put("reg", reg)
		model_specs.put("fitstat", fitstat)
		model_specs.put("weight", weight)
		model_specs.put("touse", marks[1])
		model_specs.put("regopts", regopts)
		
		/*model_specs.put("all", all)*/
		model_specs.put("dv", dv)
		
		/*model_specs.put("consmodel", consmodel)
		model_specs.put("reverse", reverse)
		
		model_specs.put("all_fitstat" all_fitstat)
		model_specs.put("cons_fitstat", cons_fitstat)
		*/
		
		dominance(
			model_specs, &domin_call(), 
			ivs', conditional, complete )
			
	}

	st_matrixcolstripe("r(domwgts)", (J(length(ivs), 1, ""), ivs') )
	
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
	st_matrixcolstripe("r(ranks)", (J(length(ivs), 1, ""), ivs') )
		
	st_numscalar("r(N)", obs)
		
	st_local("reg", reg)
	st_local("regopts", regopts)
	st_local("touse", marks[1])
	st_local("dv", dv)
	
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
			/*model_specs.all + " " +*/ IVs_in_model + " [" + 
			model_specs.get("weight") + "] if " + 
			model_specs.get("touse") + ", " + model_specs.get("regopts"), 1) //conduct regression

		fitstat = st_numscalar(model_specs.get("fitstat")) /*- model_specs.all_fitstat - model_specs.cons_fitstat*/ //record fitstat omitting constant and all subsets values; note that the fitstat to be pulled from Stata is stored as the Stata local "fitstat"

		return(fitstat)

	}
	
end

/* programming notes and history
- domin_se version 0.0.0 - date - mth day, year
