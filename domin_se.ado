*! domin_se version 0.0.0  xx/xx/202x Joseph N. Luchman
// version information at end of file

program define domin_se, eclass 

version 17

if replay() {

	if ("`e(cmd)'" != "domin") error 301
	
	if _by() error 190
	
	Display `0'
	
	exit 0
	
}

**# Program definition and argument checks
syntax varlist(min = 1 ts) [in] [if] [aw pw iw fw] , [Reg(string) Fitstat(string) Sets(string) ///
	All(varlist fv ts) noGENeral noCONditional noCOMplete EPSilon CONSmodel REVerse] // remove direct mi support - make it into a wrapper

**# Wrapper process for -domin- processing in Mata
mata: domin_se_2mata("`reg'", "`fitstat'", /*, "`sets'", "`all'", ///
	"`general'", "`conditional'", "`complete'", "`epsilon'", ///
	"`consmodel'", "`reverse'", ///
	"`weight'`exp'", "`in' `if'",*/ "`varlist'")
		
/*return values*/
tempname domwgts cdldom cptdom stdzd ranks

matrix `domwgts' = r(domwgts)
ereturn post `domwgts' //[`weight'`exp'], depname(`dv') obs(`=`obs'') esample(`touse')

matrix `domwgts' = r(domwgts)*J(colsof(r(domwgts)), 1, 1)
ereturn scalar fitstat_o = `=`domwgts'[1,1]'

matrix `cdldom' = r(cdldom)
ereturn matrix cdldom = `cdldom'

matrix `cptdom' =  r(cptdom)
ereturn matrix cptdom = `cptdom'

matrix `stdzd' =  r(stdzd)
ereturn matrix std = `stdzd'

matrix `ranks' =  r(ranks)
ereturn matrix ranking = `ranks'

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
	string scalar all, 
	string scalar general,
	string scalar conditional, 
	string scalar complete, 
	string scalar epsilon, 
	string scalar consmodel, 
	string scalar reverse,
	string scalar weight,
	string scalar inif, */
	string scalar varlist
	) {
	
	
/* ~ declarations and initial structure */
	//struct domin_se_specs scalar model_specs
	class AssociativeArray scalar model_specs
	
	real scalar rc, full_fitstat, obs, all_fitstat, cons_fitstat
	
	string scalar regopts, dv
	
	string rowvector ivs, iv_sets, marks
	
	transmorphic parser
	
/* ~ check for moremata ~ */

	/*  TBI  */
	
	
/* ~ argument checks ~ */
	/*reg() defaults to 'regress'*/
/*	if ( !strlen(reg) ) reg = "regress"
	
	/*fitstat() defaults to 'e(r2)'*/
	if ( !strlen(fitstat) ) fitstat = "e(r2)" 
	
	/*must allow for at least one type of dominance*/
	if ( strlen(general) & strlen(conditional) & strlen(complete) ) {
		
		stata("display " + char(34) + "{err}{opt nogeneral}, {opt noconditional}, " + 
			"and {opt nocomplete}, cannot all be used simultaneously." + 
			char(34) )
				
			exit(198) 
	}

	/*'epsilon' specifics*/
	if ( strlen(epsilon) ) {
		
		/*exit conditions: user must restructure*/
		if ( strlen(all + sets + mi + weight) ) { 								// <- note to self: consider adding weights for 'epsilon'
			
			stata("display " + char(34) + "{err}{opt epsilon} not allowed with" + 
					" {opt all()}, {opt sets()}, {opt mi}, or {opt weight}s." + 
					char(34) )
				
			exit(198) 															// <- note to self: document change to epsilon's error behavior ~~ 
				
		}
		
	}	
	*/
/* ~ process iv and sets ~ */
	/*parse varlist - store as 'ivs'*/
	ivs = tokens(varlist)
	
	/*'dv ivs' structure means first entry is 'dv'*/
	dv = ivs[1]
	
	/*remaining entries, if any, are 'ivs'*/
	if ( length(ivs) ) ivs = ivs[2..length(ivs)]								
	else ivs = ""
	(dv, ivs) // ~~
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
	(reg, regopts) // ~~
	/*
/* ~ sample markouts ~ */
	marks = st_tempname(2)

	stata("mark " + marks[1])
	
	if ( strlen(inif) ) stata("generate byte " + marks[2] + " = 1 " + inif, 1)
	
	stata("markout " + marks[1] + " " + dv + " " + invtokens(ivs) + " " + all + " " + marks[2])
	
/* ~ check primary analysis ~ */
	if ( !strlen(epsilon) ) {

		if ( !strlen(mi) ) 
			rc = _stata(reg + " " + dv + " " + invtokens(ivs) + " " + all +  
				" [" + weight + "] if " + marks[1] + 
				", " + regopts, 1)
		else {

			rc = _stata("mi estimate, saving(" + mifile + ") " + 
				miopt + ":" + reg + " " + dv + " " + invtokens(ivs) + " " + all +  
				" [" + weight + "] if " + marks[1] + 
				", " + regopts, 1) 
			
			if ( !rc ) stata("estimates use " + mifile + ", number(`:word 1 of `e(m_est_mi)''")	
		
		}
		
		if ( rc ) {
			
			stata( "display " + char(34) + "{err}{cmd:" + reg + "} resulted in an error." + 
				char(34) )
			exit(rc)

		}
		
		if ( !length( st_numscalar( strtrim(fitstat) ) ) )	{
		
			stata( "display " + char(34) + "{err}{cmd:" + fitstat + 
				"} not returned by {cmd:" + reg + "} or {cmd:" + fitstat + 
				"} is not scalar valued. See {help return list}." + 
				char(34) )
			exit(198)

		}
		else full_fitstat = st_numscalar( strtrim(fitstat) ) 
	
	}
	
	obs = st_numscalar("e(N)")													// <- note to self; determine if vsn <4 code that counts obs is necessary here
	
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
	
/* ~ invoke dominance ~ */	
	if ( strlen(epsilon) ) {

		if (reg == "mvdom") 
			stata("mvdom " + dv + invtokens(ivs) + " if " + 
				marks[1] + ", " + regopts + " epsilon", 1)
		else eps_ri(dv + " " + ivs, reg, marks[1], regopts) 
		
	}
	else {
		
		/*model_specs.reg = reg
		model_specs.fitstat = fitstat
		model_specs.weight = weight
		model_specs.touse = marks[1]
		model_specs.regopts = regopts
		
		model_specs.all = all
		model_specs.dv = dv
		
		model_specs.epsilon = epsilon
		model_specs.consmodel = consmodel
		model_specs.reverse = reverse
		
		model_specs.mi = mi
		model_specs.miopts = miopts
		model_specs.mifile = mifile
		
		model_specs.all_fitstat = all_fitstat
		model_specs.cons_fitstat = cons_fitstat
		
		model_specs.ivs = ivs
		*/
		*/
		model_specs.put("reg", reg)
		model_specs.put("fitstat", fitstat)
		/*model_specs.put("weight", weight)
		model_specs.put("touse", marks[1])*/
		model_specs.put("regopts", regopts)
		
		/*model_specs.put("all", all)*/
		model_specs.put("dv", dv)
		
		/*model_specs.put("epsilon", epsilon)
		model_specs.put("consmodel", consmodel)
		model_specs.put("reverse", reverse)
		
		model_specs.put("all_fitstat" all_fitstat)
		model_specs.put("cons_fitstat", cons_fitstat)
		*/
		model_specs.put("ivs", ivs) // <-- need?
		
		model_specs.keys() // ~~
		
		dominance(
			model_specs, &domin_call(), 
			ivs', "", "", "") /*,
			general, conditional, complete ) */
			
			
		st_matrix("r(domwgts)") // ~~
		
		st_matrixcolstripe("r(domwgts)", (J(length(ivs), 1, ""), ivs') )
		
	/*}*/
	
	//if ( ( strlen(general) & !strlen(epsilon) ) | strlen(epsilon) ) {
			
		st_matrix("r(stdzd)", 
			(st_matrix("r(domwgts)")):/(sum(st_matrix("r(domwgts)") ) ) ) 
			
		st_matrix("r(ranks)", 
			(mm_ranks( (st_matrix("r(domwgts)")'):*-1, 1, 1)') )
	
	//}
	
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
			/*model_specs.all + " " +*/ IVs_in_model + /*" [" + 
			model_specs.weight + "] if " + 
			model_specs.touse + */ ", " + model_specs.get("regopts"), 1) //conduct regression

		fitstat = st_numscalar(model_specs.get("fitstat")) /*- model_specs.all_fitstat - model_specs.cons_fitstat*/ //record fitstat omitting constant and all subsets values; note that the fitstat to be pulled from Stata is stored as the Stata local "fitstat"

		return(fitstat)

	}
	
end
/*
**# Mata function to execute 'domin-flavored' models
version 17

mata:

	mata set matastrict on

	real scalar domin_call(string scalar IVs_in_model,
		struct domin_se_specs scalar model_specs)  
	{ 

		real scalar fitstat

		if (strlen(model_specs.mi) == 0) { //if not multiple imputation, then regular regression

			stata(model_specs.reg + " " + model_specs.dv + " " + ///
				model_specs.all + " " + IVs_in_model + " [" + ///
				model_specs.weight + "] if " + 
				model_specs.touse + ", " + model_specs.regopts, 1) //conduct regression

			fitstat = st_numscalar(model_specs.fitstat) - model_specs.all_fitstat - model_specs.cons_fitstat //record fitstat omitting constant and all subsets values; note that the fitstat to be pulled from Stata is stored as the Stata local "fitstat"

		}

		else { //otherwise, regression with "mi estimate:"

			stata("mi estimate, saving(" + 
				model_specs.mifile + ", replace) " + model_specs.miopts + ": " + 
				model_specs.reg + " " + model_specs.dv + " " + ///
				model_specs.all + " " + IVs_in_model + " [" + ///
				model_specs.weight + "] if " + 
				model_specs.touse + ", " + model_specs.regopts, 1) //conduct regression with "mi estimate:"

			stata("mi_dom, name(" + model_specs.mifile + 
				") fitstat(" model_specs.fitstat + ") list(\`=e(m_est_mi)')", 1) //use built-in program to obtain average fitstat across imputations

			fitstat = st_numscalar("r(passstat)") - model_specs.all_fitstat - model_specs.cons_fitstat //record fitstat omitting constant and "all" subsets values with "mi estimate:"

		}

		return(fitstat)

	}
	
end

/* programming notes and history
- domin_se version 0.0.0 - date - mth day, year
