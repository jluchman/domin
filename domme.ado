*! domme version 1.1.2 8/14/2023 Joseph N. Luchman

capture include dominance0.mata, adopath																// include Mata-based dominance code

program define domme, eclass 																			// ~ history and version information at end of file ~

	version 15.1

	if replay() & !strlen("`0'") { 																		//replay results - error if "by"; domme allows nothing in "anything" - allow it to replay only when there is nothing in options

		if ("`e(cmd)'" != "domme") error 301

		if _by() error 190

		Display `0'

		exit 0

	}

	/*define syntax*/
	syntax [anything(id="equation names" equalok)] [in] [if] ///
		[aw pw iw fw], Reg(string) Fitstat(string) [Sets(string) ///
		noCOMplete noCONditional ///
		REVerse all(string) EXTraconstr(numlist) ///
		ROPts(string) ADDConstr(numlist)] 																//addconstr() and extraconstr() undocumented - for use in possible extensions

	/*exit conditions*/
	capture which lmoremata.mlib																		//is -moremata- present?


	if _rc { 																							//if -domin- cannot be found, tell user to install it.

		display "{err}Module {cmd:moremata} not found.  Install " ///
			"{cmd:moremata} here {stata ssc install moremata}."

		exit 198

	}

	/*general set up*/
	mata: model_specs = domme_specs() 																	//initiate instance of domme_specs() structure
	
	tempname ranks gendom stzd_gendom cdldom cptdom 													//temporary matrices for results

	local two "`anything'" 																				//rename the input equation-to-independent variable mapping in "anything": done to generalize and simplify loop below

	local drop_exit = 0 																				//local macro indicating that -domme- should drop constraints made so they do not persist due to error/when something goes wrong before the end of command's successful execution

	//**process "anything" and obtain individual constraints**//
	while strlen("`two'") {																				//process the equation-to-independent variable mapping in "anything" if something is present...

		gettoken one two: two, bind																		//parse the equation-to-independent variable mapping to bind all parenthetical statements together and pull out first parenthetical statement/equation

		if !regexm("`one'", "=") { 																		//exit if there is no equal sign to make an equation

			display "{err}Equation {cmd:`one'} is missing a {cmd:=} to " ///
				"distinguish equation and independent variable names."

			local drop_exit = 1																			//indicate that constraints will be dropped

			continue, break																				//stop the -while- loop...

		}

		local one = regexr("`one'", "[/(]", "")															//remove left paren from equation statement

		local one = regexr("`one'", "[/)]", "")															//remove right paren from equation statement

		gettoken dv ivlist: one, parse("=")																//further parse the focal equation to separate out dependent from independent variables

		if ( `: list sizeof dv' != 1 ) | regexm("`dv'", "=")  {											//multiple dependent variables/equations or no dependent variable where one should be... exit

			display "{err}Invalid equation name specified for {cmd:(`dv'`ivlist')}."

			local drop_exit = 1																			//indicate that constraints will be dropped

			continue, break																				//stop the -while- loop...

		}

		local ivlist = regexr("`ivlist'", "=", "")														//remove the equal sign from the independent variable list

		if ( `: list sizeof ivlist' == 0 )  { 															//empty independent variable list... exit as an empty list is an error

			display "{err}Empty set of independent variables specified for " ///
				"equation {cmd:`dv'}."

			local drop_exit = 1	 																		//indicate that constraints will be dropped

			continue, break																				//stop the -while- loop...

		}

		local dv = trim("`dv'")																			//remove white spaces in dependent variable which can affect putting the string into equations

		foreach iv of local ivlist {																	//loop over the independent variables in the first equation...

			if substr("`dv'", 1, 1) == "~" {															//method for parsing (G)SEM parameters with Stata defaults

				local dv "/"																			//(g)sem's DV is a forward slash

				local iv = subinstr("`iv'", "+", " ", .)												//remove all plus signs required for covariance 

				if `: list sizeof iv' == 3 ///															//formatting if this is a covariance statement (situation where there would be 3 items in the parsed "independent variable")
					local iv "`: word 1 of `iv''(`: word 2 of `iv'',`: word 3 of `iv'')"

				else local iv  "`: word 1 of `iv''(`: word 2 of `iv'')"									//formatting if this is a standard parameter

			}

			capture constraint free																		//find an unused constraint number - capture to ensure they're not all used

			if !_rc {																					//if an unused constraint can be found...

				local constr `r(free)'																	//use the free constraint by putting into local macro

				constraint `constr' _b[`dv':`iv'] = 0													//establish this constraint as one that domme will use

				local add "`dv':`iv'"																	//set up the equation, independent variable/parameter estimate combination for display

				local ivs = "`ivs' `add'"																//record the parameter estimate for display

				local constrs "`constrs' `constr'"														//add the constraint associated with the parameter estimate to the list of constraints
				
				mata: model_specs.param_list.put(st_local("add"), st_local("constr")) // add the parameters associated with the name to the parameter mapping

			}

			else {																						//if no unused constraints remain...

				display "{err}{cmd:domme} cannot make any more constraints as the " ///
					"{help constraint dir} is full (see {help constraint drop})."

				local drop_exit = 1																		//indicate that constraints will be dropped

				continue, break																			//stop the -while- loop...

			}

			if `drop_exit' continue, break																//stop the within equation -forvalues- loop... 
		}

		if `drop_exit' continue, break																	//stop the overall -while- loop...

	}

	//**process and obtain sets**//
	local two "`sets'"																					//rename the set-based equation-to-independent variable mapping: done to generalize and simplify loop below

	local setcount = 0																					//used if there are sets to start a count and number them

	while strlen("`two'") & !`drop_exit' {																//if nothing's wrong so far and there are sets...

		gettoken one two: two, bind																		//parse the sets of equation-to-independent variable mappings in parentheses

		local 2 = trim("`one'")																			//rename the set to generalize and simplify loop below

		if ( substr("`2'", 1, 1) != "[" ) | ///
			( substr("`2'", strlen("`2'"), strlen("`2'")) != "]" ) {										//if a left paren does not begin and a right paren does not end the first set...

			display "{err}Set {cmd:`2'} not bound by brackets, {cmd:[ ]}."

			local drop_exit = 1																			//indicate that constraints will be dropped

			continue, break																				//stop the -while- loop...

		}

		local setcount = `setcount' + 1																	//increment setcount in the case that the first (and subsequent) set is valid

		while strlen("`2'") & !`drop_exit' {															//mirrors the processing of the equation-to-independent variable  mapping for "anything" if they exist within a set...

			local 2 = subinstr("`2'", "[", "", 1)														//remove left bracket

			local 2 = trim(subinstr("`2'", "]", "", 1))													//remove right bracket

			gettoken 1 2: 2, bind																		//parse the equation-to-independent variable mapping to bind all brackets together and pull out first equation

			if ( substr("`1'", 1, 1) != "(" ) | ///
				( substr("`1'", strlen("`1'"), strlen("`1'")) != ")" ) {								//if a left bracket does not begin and a right bracket does not end the first equation...

				display "{err}Equation {cmd:`1'} in set {cmd:`one'} not bound by " ///
					"parentheses; {cmd:( )}."

				local drop_exit = 1																		//indicate that constraints will be dropped

				continue, break																			//stop the -while- loop...

			}

			if !regexm("`1'", "=") {																	//exit if there is no equal sign to make an equation

				display "{err}Equation {cmd:`1'} in set {cmd:`one'} is missing a " ///
					"{cmd:=} to distinguish equation and independent variable names."

				local drop_exit = 1																		//indicate that constraints will be dropped

				continue, break																			//stop the -while- loop...

			}

			local 1 = subinstr("`1'", "(", "", 1)														//remove left paren

			local 1 = trim(subinstr("`1'", ")", "", 1))													//remove right paren

			gettoken dv ivlist: 1, parse("=")															//further parse the focal equation to separate out dependent from independent variables

			if ( `: list sizeof dv' != 1 ) | regexm("`dv'", "=")  { 									//multiple dependent variables or no dependent variable where one should be... exit

				display "{err}Invalid equation name specified for " ///
					"{cmd:(`dv'`ivlist')} in set {cmd:`one'}."

				local drop_exit = 1																		//indicate that constraints will be dropped

				continue, break																			//stop the -while- loop...

			}

			local ivlist = regexr("`ivlist'", "=", "")													//remove the equal sign from the independent variable list

			if ( `: list sizeof ivlist' == 0 )  { 														//empty independent vatiable list... exit as it breaks process

				display "{err}Empty set of independent variables specified for " ///
					"equation {cmd:`dv'} in set {cmd:`one'}."

				local drop_exit = 1																		//indicate that constraints will be dropped

				continue, break																			//stop the -while- loop...

			}

			local dv = trim("`dv'")																		//remove white spaces in dependent variable which can affect putting the string into equations

			foreach iv of local ivlist {																//loop over the independent variables in the first equation...

				if substr("`dv'", 1, 1) == "~" {														//method for parsing (G)SEM parameters with Stata defaults

					local dv "/"																		//(g)sem's DV is a forward slash

					local iv = subinstr("`iv'", "+", " ", .)											//remove all plus signs required for covariance 

					if `: list sizeof iv' == 3 ///														//formatting if this is a covariance statement (situation where there would be 3 items in the parsed "independent variable")
						local iv "`: word 1 of `iv''(`: word 2 of `iv'',`: word 3 of `iv'')"

					else local iv  "`: word 1 of `iv''(`: word 2 of `iv'')"								//formatting if this is a standard parameter

				}

				capture constraint free																	//find an unused constraint number

				if !_rc {																				//if an unused constraint can be found...

					local constr `r(free)'																//use the free constraint

					constraint `constr' _b[`dv':`iv'] = 0												//establish this constraint as one that -domme- will use

					local add "`dv':`iv'"																//set up the parameter estimate label

					local set`setcount' "`set`setcount'' `add'"											//add parameter estimate label to set

					local cset`setcount' "`cset`setcount'' `constr'"									//add constraint to set

				}

				else {																					//if no unused constraints remain...

					display "{err}{cmd:domme} cannot make any more constraints as the " ///
						"{help constraint dir} is full (see {help constraint drop})."

					local drop_exit = 1																	//indicate that constraints will be dropped

					continue, break																		//stop the -while- loop...

				}

				if `drop_exit' continue, break															//stop the within equation, -forvalues- loop ...	

			}

			if `drop_exit' continue, break																//stop the -while- loop looking for equations in a set...

		}	

		if `drop_exit' continue, break																	//stop the -while- overall sets loop...

		else {																							//nothing went wrong, so entire set was processed, thus...

			local ivs "`ivs' _set:set`setcount'"														//add parameter estimate set to all all subsets - the chevrons bind sets together; Mata separates them	

			local constrs "`constrs' <`cset`setcount''>"												//add constraint set to all other constraints - the chevrons bind sets together; Mata separates them
			
			mata: model_specs.param_list.put("_set:set" + st_local("setcount"), ///
				st_local("cset" + st_local("setcount"))) // add the parameters associated with the name to the parameter mapping*/

		}

	}

	if ( `:list sizeof ivs' < 2 ) & !`drop_exit' {														//exit if too few parameter estimates/sets (otherwise prodices cryptic Mata error)

		display "{err}{cmd:domme} requires at least 2 parameter estimates " ///
			"or parameter estimate sets."

		local drop_exit = 1																				//indicate that constraints will be dropped

	}

	if strlen("`addconstr'") {																			//if there are custom constraints added to the analysis by number...

		foreach constrnum of numlist `addconstr' {														//foreach constraint...

			local ivs "`ivs' _cns:cns`constrnum'"														// format the constraint as a domme-able parameter

			local constrs "`constrs' `constrnum'"														// add the constraint to the domme-able constraint list

		}

	}

	local nobrkt_constrs = ///
		subinstr(subinstr("`constrs'", ">", "", .), "<", "", .)											//local macro where chevrons in constraint list is removed to estimate the constant model	

	/*finalize setup*/
	//**markouts and sample**//
	tempvar touse keep																					//declare sample marking variables

	tempname obs allfs consfs																			//declare temporary scalars

	mark `touse'																						//declare marking variable using Stata norm "touse"

	quietly generate byte `keep' = 1 `if' `in' 															//generate tempvar that adjusts for "if" and "in" statements

	markout `touse' `keep'																				//mark sample for only really works with the if & in; all other missing-based adjustments must derive from running full model

	//**inital run to ensure the syntax works and restrict sample based on full model**//
	if !`drop_exit' capture `reg' [`weight'`exp'] if `touse', `ropts' constraints(`extraconstr')		//run of overall analysis assuming all is well so far; intended to check e(sample) and whether everything works as it should

	if _rc & !`drop_exit' {																				//exit if model is not estimable or program results in error - return the returned code

		display "{err}{cmd:`reg'} resulted in an error."

		local exit_code = `=_rc'

		local drop_exit = 1																				//indicate that constraints will be dropped

	}

	//**fitstat processing**//
	if regexm("`fitstat'", "^e\(\)") & !`drop_exit' {													//if internal fitstat indication is in "fitstat" option; must have "e()"

		gettoken omit fit_opts: fitstat, parse(",")														//parse the fitstat to see if "mcf", "est", "aic", or "bic" present

		compute_fitstat `fit_opts'																		//return fitstat using internal computation program; this is just to determine if the options given work

		if `r(many_few)' {																				//something's wrong - probably too many or too few fitstat options provided

			local drop_exit = 1																			//indicate that constraints will be dropped

			display "{err}Options offered to e() fitstat computation " ///
				"resulted in error."

		}

		else {																							//...otherwise nothing's wrong - indicate to program to use built in approach

			local fitstat = "r(fitstat)"																//placeholder "returned" statistic - changed prior to program completion

			mata: st_numscalar("r(fitstat)", 0)															//placeholder "returned" statistic's value

			local built_in = 1																			//indicate that the program is to produce it's own fitstat

			local built_in_style "`r(style)'"															//indicate the style of built in statistic to ask for

		}

	}

	else local built_in = 0																				//if not built in, then indicate the estimation model produces it's own fitstat
	
	capture assert `fitstat' != .																		//is the "fitstat" the user supplied actually returned by the command?

	if _rc & !`drop_exit' {																				//exit if fitstat can't be found

		display "{err}{cmd:`fitstat'} not returned by {cmd:`reg'} or " ///
			"{cmd:`fitstat'} is not scalar valued. See {help return list}." ///
			_newline "Alternatively, {err}{cmd:`fitstat'} may have problems " ///
			"being computed internally with the information supplied."


		local drop_exit = 1																				//indicate that constraints will be dropped

	}

	capture assert sign(`fitstat') != -1																//what is the sign of the fitstat?  -domme- works best with positive ones - warn and proceed

	if _rc & !`drop_exit' {																				//merely note that -domme- works best with positive ones (that's what's expected)

		display "{err}{cmd:`fitstat'} returned by {cmd:`reg'}" _newline ///
			"is negative.  {cmd:domme} is programmed to work best" _newline ///
			"with positive {opt fitstat()} summary statistics." _newline

	}

	//**count observations**//
	if !`drop_exit' {																					//if nothing's wrong so far...

		quietly replace `touse' = e(sample) 															//replace sample marking variable with e(sample) from the model run

		if !inlist("`e(wtype)'", "iweight", "fweight") {												//if weights don't affect obs (for probability and analytic weights)

			quietly count if `touse'																	//tally up "touse"	

			scalar `obs' = r(N)																			//pull out the number of observations included

		}

		else if inlist("`e(wtype)'", "iweight", "fweight") {											//if the weights do affect obs (for frequency and importance weights)

			quietly summarize `=regexr("`e(wexp)'", "=", "")' if `touse'								//tally up "touse" by summing weights

			scalar `obs' = r(sum)																		//pull out the number of observations included

		}

		//**obtain parameters considered to be "part of model" and not adjusted out of fitstat**//
		scalar `allfs' = 0																				//defining fitstat of "all subsets" parameters as 0 - needed for dominance() function

		if `:list sizeof all' {																			//if there is something in the "all" option
			
			local 2 "`all'"																				//rename the content of "all" to generalize and simplify loop below

			while strlen("`2'") & !`drop_exit' {														//process the equation-to-independent variable mapping for "all"...

				gettoken 1 2: 2, bind																	//parse the equation-to-independent variable mapping to bind all parentheses together and pull out first equation

				if ( substr("`1'", 1, 1) != "(" ) ///
					| ( substr("`1'", strlen("`1'"), strlen("`1'")) != ")" ) {							//if a left paren does not begin and a right paren does not end the first all equation...

					display "{err}Equation {cmd:`1'} in {cmd:all()} not bound by " ///
						"parentheses."

					local drop_exit = 1																	//indicate that constraints will be dropped

					continue, break																		//stop the -while- loop...

				}

				if !regexm("`1'", "=") {																//exit if there is no equal sign to make an equation

					display "{err}Equation {cmd:`1'} in {cmd:all()} is missing a " ///
						"{cmd:=} to distinguish equation and independent variable names."

					local drop_exit = 1																	//indicate that constraints will be dropped

					continue, break																		//stop the -while- loop...

				}

				local 1 = subinstr("`1'", "(", "", 1)													//remove left paren

				local 1 = subinstr("`1'", ")", "", 1)													//remove right paren

				gettoken dv ivlist: 1, parse("=")														//further parse the focal equation to separate out dependent from independent variables

				if ( `: list sizeof dv' != 1 ) | regexm("`dv'", "=")  { 								//multiple dependent variables or no dependent variable where one should be... exit

					display "{err}Invalid equation name specified for " ///
						"{cmd:(`dv'`ivlist')} in {cmd:all()}."

					local drop_exit = 1																	//indicate that constraints will be dropped

					continue, break																		//stop the -while- loop...

				}

				local ivlist = regexr("`ivlist'", "=", "")												//remove the equal sign from the independent variable list

				if ( `: list sizeof ivlist' == 0 )  { 													//empty independent vatiable list... exit as it breaks process

					display "{err}Empty set of independent variables specified for " ///
						"equation {cmd:`dv'} in {cmd:all()}."

					local drop_exit = 1																	//indicate that constraints will be dropped

					continue, break																		//stop the -while- loop...

				}

				local dv = trim("`dv'")																	//remove white spaces in dependent variable which can affect putting the string into equations

				foreach iv of local ivlist {															//loop over the independent variables in the all equations...

					if substr("`dv'", 1, 1) == "~" {													//method for parsing (G)SEM parameters with Stata defaults

						local dv "/"																	//(g)sem's DV is a forward slash

						local iv = subinstr("`iv'", "+", " ", .)										//remove all plus signs required for covariance 

						if `: list sizeof iv' == 3 ///													//formatting if this is a covariance statement (situation where there would be 3 items in the parsed "independent variable")
							local iv "`: word 1 of `iv''(`: word 2 of `iv'',`: word 3 of `iv'')"

						else local iv  "`: word 1 of `iv''(`: word 2 of `iv'')"							//formatting if this is a standard parameter

					}

					capture constraint free																//find an unused constraint number

					if !_rc {																			//if an unused constraint can be found...

						local constr `r(free)'															//use the free constraint

						constraint `constr' _b[`dv':`iv'] = 0											//establish this constraint as one that -domme- will use

						local add "`dv':`iv'"															//set up the parameter estimate label

						local allset "`allset' `add'"													//add the parameter estimate label to set

						local allcset "`allcset' `constr'"												//add constraint to set

					}

					else {																				//if no unused constraints remain...

						display "{err}{cmd:domme} cannot make any more constraints as the " ///
							"{help constraint dir} is full (see {help constraint drop})."

						local drop_exit = 1																//indicate that constraints will be dropped

						continue, break																	//stop the -while- loop...

					}

					if `drop_exit' continue, break														//stop the -forvalues- loop...	

				}

			}

		}

		//**obtain "constant" model which will adjusted out of fitstat**//
		scalar `consfs' = 0																				//define constant-only model fitstat as 0 - needed for dominance() function

		quietly `reg' [`weight'`exp'] if `touse', `ropts' ///
			constraints(`nobrkt_constrs' `allcset' `extraconstr')										//all constraints used - this estimates the "constant" model

		if `built_in' {
			
			compute_fitstat `fit_opts' iscons 															//if a built-in fistat desired, estimate it; note constant model
			
			scalar `consfs' = `fitstat'
			
		}

		if !`built_in' & !missing(`fitstat') ///
			scalar `consfs' = `fitstat'																	//return constant model's fitstat if user supplied and not missing
		
		if !`built_in' & missing(`fitstat') scalar `consfs' = 0 										//otherwise assume the constant-only model is 0	

		if strlen("`all'") {																			//distinguishes "all subsets" from "constant" fitstats/models

			quietly `reg' [`weight'`exp'] if `touse', `ropts' ///
				constraints(`nobrkt_constrs' `extraconstr')												//all "subsets" and extra constraints used - this estimates the "all" model

			if `built_in' compute_fitstat `fit_opts' consmodel(`=`consfs'')								//if a built-in fistat desired, estimate it; supply constant model's value

			scalar `allfs' = `fitstat'																	//return all subset model's fitstat as distinct from any constant model


		}

		if `built_in' local cons_no_add = ///
			!inlist("`built_in_style'", "mcf", "est")													//local macro indicating that the constant model fitstat should be included in the total fitstat - will be 0 for built in "mcf" and "est" and the actual value of "consfs" for non-built in where "consmodel" is not chosen will be 0

		else local cons_no_add = 1																		//...all other cases can be allowed to be 0

		if strlen("`all'") scalar `allfs' = `allfs' - `consfs'*`cons_no_add'							//adjust all subsets fitstat for the constant fitstat in situations where it's not 0

		/*dominance statistic determination*/
		mata: model_specs.built_in = strtoreal(st_local("built_in"))
		mata: model_specs.constraint_list = tokens(st_local("nobrkt_constrs"))
		mata: model_specs.built_in_cons = st_numscalar(st_local("consfs"))

		mata: dominance0(model_specs, &domme_call(), ///
		st_local("conditional'"), st_local("complete"), ///
		st_local("ivs"), ///
		st_numscalar(st_local("allfs")), ///
		st_numscalar(st_local("consfs"))*strtoreal(st_local("cons_no_add")))							//invoke "dominance()" function in Mata 

		/*translate r-class results from me_dominance() into temp results*/
		matrix `gendom' = r(domwgts)																	//general dominance statistics

		matrix `stzd_gendom' = r(sdomwgts)																//standardized general dominance statistics

		matrix `ranks' = r(ranks)																		//ranks based on general dominance statistics

		if !strlen("`conditional'") matrix `cdldom' = r(cdldom)											//conditional dominance statistic matrix

		if !strlen("`complete'") matrix `cptdom' = r(cptdom)											//complete dominance designation matrix

		/*processing display results*/
		//**name matrices**//
		matrix colnames `gendom' = `ivs'																//name the columns of general dominance statistic vector

		if strlen("`reverse'") {																		//reverse the direction and interpretation of ranked and standardized general dominance statistics

			mata: st_matrix("`stzd_gendom'", ///
				( st_matrix("`gendom'"):*-1 ):/sum( st_matrix("`gendom'"):*-1 ) )						//reverse the signs of the standardized general dominance statistics

			mata: st_matrix("`ranks'", ///
				( ( st_matrix("`ranks'"):-1 ):*-1 ):+cols( st_matrix("`ranks'") ) )						//reverse the sign of the ranked general dominance statistics

		}

		matrix colnames `stzd_gendom' = `ivs'															//name the columns of stanadrdized general dominance statistic vector

		matrix colnames `ranks' = `ivs'																	//name the columns of ranked general dominance statistic vector

		if !strlen("`complete'") { 																		//if the complete dominance matrix was not suppressed...

			local cptivs = subinstr("`ivs'", ":", "_", .)												//must remove colons between equation and independent variable; only 1 colon allowed - "dominates?" and "dominated?" are equations for complete dominance matrix

			local cptivs = subinstr("`ivs'", ".", "_", .)												//must also remove "."s - causes error in naming

			if strlen("`reverse'") mata: ///
				st_matrix("`cptdom'", st_matrix("`cptdom'"):*-1 )										//reverse the sign of the complete dominance designations

			matrix colnames `cptdom' = `cptivs'															//name the columns of the complete dominance designations
										
			mata: st_matrixcolstripe("`cptdom'", ///
				("<?":+st_matrixcolstripe("`cptdom'")[,1], st_matrixcolstripe("`cptdom'")[,2]))			//add name the equation for the columns "<?" - replacement for "dominated?"
			
			matrix rownames `cptdom' = `cptivs'															//name the rows of the complete dominance designations

			mata: st_matrixrowstripe("`cptdom'", ///
				(">?":+st_matrixrowstripe("`cptdom'")[,1], st_matrixrowstripe("`cptdom'")[,2]))			//add name the equation for the rows ">?"  replacement for "dominates?"

		}

		if !strlen("`conditional'") { 																	//if the conditional dominance matrix was not suppressed...

			matrix rownames `cdldom' = `ivs'															//name the rows of the conditional dominance matrix

			local colcdl `:colnames `cdldom''															//the columns of the conditional dominance matrix are at defaults "c1 c2 ... cN"

			local colcdl = subinstr("`colcdl'", "c", "", .)												//remove the "c"s from all the rownames; keep the values

			matrix colnames `cdldom' = `colcdl'															//replace the column names of the conditional dominance matrix with the number of "orders" which matches their counting sequennce

			matrix coleq `cdldom' = #param_ests															//equation names for all columns are "#param_ests"

		}	

		if strlen("`e(title)'") local title "`e(title)'"												//if the estimation command has an "e(title)" returned, save it

		else if !strlen("`e(title)'") & strlen("e(cmd)") local title "`e(cmd)'"							//...otherwise save the "e(cmd)" as that's informative too

		else local title "Custom user analysis"															//...finally, if none of the options are returned, call it "custom user analysis"

		/*return values*/
		ereturn post `gendom' [`weight'`exp'], obs(`=`obs'') esample(`touse')							//primary estimation command returned value command; clears ereturn and returns "gendom" as e(b)

		if strlen("`setcount'") {																		//if there are sets...

			ereturn hidden scalar setcount = `setcount'													//hidden scalar for use in "display"

			forvalues set = 1/`setcount' {																//for each set...

				ereturn local set`set' = trim("`set`set''")												//make a separate local macro with it's parameter estimate label contents

			}

		}

		else ereturn hidden scalar setcount = 0															//...otherwise hidden set count is 0

		ereturn hidden local disp_title "`title'"														//hidden title for display (hence, "disp_title")

		ereturn hidden local reverse "`reverse'"														//hidden indicator for reverse - for display

		if `:list sizeof all' ereturn local all = strtrim("`allset'")									//parameter estimate labels in all subsets

		if strlen("`ropts'") ereturn local ropts `"`ropts'"'											//if there were regression command options return them as macro

		ereturn local reg "`reg'"																		//return command used in -domme- in macro

		if `built_in' local fitstat "e(`built_in_style')"												//if a built-in is used, change "r(fitstat)" to the "e()" form with fitstat name

		ereturn local fitstat "`fitstat'"																//return the name of the fitstat used

		ereturn local cmd "domme"																		//this command is -domme-; return that

		ereturn local title `"Dominance analysis for multiple equations"'								//The title/description of -domme-

		ereturn local cmdline `"domme `0'"'																//full command as read into -domme- the 0 macro is everything after the command's name

		ereturn scalar fitstat_o = r(fs)																//overall fitstat value

		if `:list sizeof all' ereturn scalar fitstat_a = `allfs' + ///
			`consfs'*`cons_no_add'																		//all subsets fitstat value

		if sign( `consfs'*`cons_no_add' ) ereturn scalar fitstat_c = ///								//constant model fitstat value
			`consfs'*`cons_no_add'

		if !strlen("`conditional'") ereturn matrix cdldom `cdldom'										//return conditional dominance matrix

		if !strlen("`complete'") ereturn matrix cptdom `cptdom'											//return complete dominance designations

		ereturn matrix ranking `ranks'																	//return ranked general dominance vector

		ereturn matrix std `stzd_gendom'																//return standardized general dominance vector

		/*begin display*/
		Display

	}

	/*drop constraints -domme- made; not ones user supplied*/
	if missing(`exit_code') local exit_code = 198														//make the default exit code 198 

	if `drop_exit' {																					//if there was a problem during the program's execution

		if `: list sizeof constrs' {																	//if there are constraints used...

			foreach constr of numlist `constrs' {														//go through each constraint that was made...

				constraint drop `constr'																//drop the constraint

			}

		}

		exit `exit_code'																				//exit using applicable exit code

	}

	foreach constr of numlist `nobrkt_constrs' {														//go through each constraint that was made...

		constraint drop `constr'																		//drop the constraint

	}

end


/*Display program*/
program define Display

	version 15.1

	/*set up*/
	tempname gendom stzd_gendom ranks																	//declare names for temporary data

	matrix `gendom' = e(b)																				//as in original command "gendom" is general dominance statistics vector; now in e(b)

	matrix `stzd_gendom' = e(std)																		//as in original command "stzd_gendom" is standardized general dominance statistics vector; now in e(std)

	matrix `ranks' = e(ranking)																			//as in original command "ranks" is ranked general dominance statistics vector; now in e(ranking)

	local diivs: colnames e(b)																			//obtain independent variable names

	local eqivs: coleq e(b)																				//obtain dependent variable/equation names

	mata: st_local("cdltest", strofreal(cols(st_matrix("e(cdldom)"))))									//indicator macro for presence of conditional dominance matrix

	mata: st_local("cpttest", strofreal(cols(st_matrix("e(cptdom)"))))									//indicator macro for presence of complete dominance matrix

	tokenize "`diivs'"																					//tokenize list of dependent variables to associate numbers with independent variables

	/*begin displays*/
	display _newline "{txt}General dominance statistics: `e(disp_title)'" ///
		_newline "{txt}Number of obs{col 27}={res}{col 40}" %12.0f e(N) 			

	display "{txt}Overall Fit Statistic{col 27}={res}{col 36}" ///
		%16.4f e(fitstat_o)

	if !missing( e(fitstat_a) ) display "{txt}All Subsets Fit Stat." ///
		"{col 27}={res}{col 36}" %16.4f e(fitstat_a)

	if !missing( e(fitstat_c) ) display "{txt}Constant-only Fit Stat." ///
		"{col 27}={res}{col 36}" %16.4f e(fitstat_c)

	display _newline "{txt}{col 13}{c |}{col 20}Dominance" ///
		"{col 35}Standardized{col 53}Ranking"

	display "{txt}{col 13}{c |}{col 20}Stat.{col 35}Domin. Stat." 

	display "{txt}{hline 12}{c +}{hline 72}"

	local current_eq ""																					//for separating equation from independent variable names in -forvalues- loop below

	forvalues iv = 1/`:list sizeof diivs' {																//for each entry of the e(b) vector...

		if "`current_eq'" != abbrev("`: word `iv' of `eqivs''", 11) ///
			display `"{res}`=abbrev("`: word `iv' of `eqivs''", 11)'{txt}{col 13}{c |}"'				//...display equation name only if it changes

		local current_eq = abbrev("`: word `iv' of `eqivs''", 11)										//note current equation - truncate to 11 chars

		local `iv' = abbrev("``iv''", 10)																//abbreviate independent variable to 10 chars

		display "{txt}{col 2}{lalign 11:``iv''}{c |}{col 14}{res}" ///
			%15.4f `gendom'[1,`iv'] "{col 29}" %12.4f ///
			`stzd_gendom'[1,`iv'] "{col 53}" %-2.0f `ranks'[1,`iv']

	}

	display "{txt}{hline 12}{c BT}{hline 72}"

	if `cdltest' {																						//if conditional dominance matrix exists....

		display "{txt}Conditional dominance statistics" _newline "{hline 85}"

		matrix list e(cdldom), noheader format(%12.4f)

		display "{txt}{hline 85}"

	}

	if `cpttest' {																						//if complete dominance designations exist...

		display "{txt}Complete dominance designation" _newline "{hline 85}"

		matrix list e(cptdom), noheader

		display "{txt}{hline 85}"

	}

	if `=`cpttest'*`cdltest'' {																			//if _both_ complete and conditional dominance designations exist - determine strongest dominance designation between each pair of parameter estimates

		display _newline "{res}Strongest dominance designations" _newline 

		tempname bestdom cdl gen decision																//declare temporary names for strongest designation search

		if strlen("`e(reverse)'") mata: st_matrix("`bestdom'", ///										//start by determining complete dominance as "best" - if reversed, then reflect values over 0
			st_matrix("e(cptdom)"):*-1)

		else matrix `bestdom' = e(cptdom)																//...otherwise take complete dominance values as is

		forvalues dominator = 1/`=colsof(e(cdldom))-1' {												//search through all columns save last...

			forvalues dominatee = `=`dominator'+1'/`=colsof(e(cdldom))' {								//...as well as all columns save first, dependent on dominator

				scalar `cdl' = 0																		//define conditional dominance as 0 or "not"

				scalar `gen' = 0																		//define general dominance as 0 or "not"

				mata: st_numscalar("`cdl'", ///
					( sum( st_matrix("e(cdldom)")[`dominator', .] ///									//...sum the number of times the values across all columns of the conditional dominance matrix for the row corresponding to the "dominator"
					:>st_matrix("e(cdldom)")[`dominatee', .] ) ) ///									//...and compred to the values across the same columns of the conditional dominance matrix for the row corresponding to the "dominatee"
					:==rows( st_matrix("e(cdldom)") ) ) 												//...if that's equal to the number of columns - thus every row for the "dominator" is bigger than every row for the "dominatee" - "dominator" conditionally dominates "dominatee"										

				if !`cdl' mata: ///
					st_numscalar("`cdl'", -1*((sum(st_matrix("e(cdldom)")[`dominator', .] ///
					:<st_matrix("e(cdldom)")[`dominatee', .])):==rows(st_matrix("e(cdldom)"))))			//this replicates the previous command in the opposite direction - does "dominatee" actually dominate "dominator"?

				mata: st_numscalar("`gen'", ///
					st_matrix("e(b)")[1, `dominator']>st_matrix("e(b)")[1, `dominatee'])				//compare dominator's general dominance statistic to dominatee's

				if !`gen' mata: st_numscalar("`gen'", ///
					(st_matrix("e(b)")[1, `dominator']<st_matrix("e(b)")[1, `dominatee'])*-1)			//now the opposite to the previous, compare dominatee's general dominance statistic to dominator's

				local reverse_adj = cond(strlen("`e(reverse)'"), -1, 1)									//if there is a needed "reverse" adjustment - record -1, otherwise 1

				scalar `decision' = ///
					cond(abs(`bestdom'[`dominator', `dominatee']) == 1, ///
					`bestdom'[`dominator', `dominatee'], cond(abs(`cdl') == 1, ///
					`cdl'*2, cond(abs(`gen') == 1, `gen'*3, 0)))										//record decision in cond() statement; "1" is complete, "2" is conditional, "3" is general

				matrix `bestdom'[`dominator', `dominatee'] = `decision'*`reverse_adj'					//record value of decison on lower triangle of matrix

				matrix `bestdom'[`dominatee', `dominator'] = -`decision'*`reverse_adj'					//record value of decison on upper triangle of matrix

			}

		}

		local names `:colfullnames e(b)'																//obtain full names of e(b) vector

		mata: display((select(vec(tokens(st_local("names"))' ///
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
			:*" generally dominates "):+tokens(st_local("names")))', ///
			"generally dominates")))')																	//complex command here - basic idea is that it takes the value in bestdom, displays the correct dominance type based on number, and plugs in the values of the parameter estimate labels

		display ""

	}

	if `=e(setcount)' {																					//if there are sets...

		forvalues set = 1/`=e(setcount)' {																//foreach set...

			display "{txt}Parameters in set`set': `e(set`set')'"										//display the set's parameter estimate labels

		}

	}

	if strlen("`e(all)'") ///
		display "{txt}Parameter estimates included in all subsets: `e(all)'"							//if there is an all subsets set, display those parameter estimate labels

end


**# Program to compute built-in fitstats
program define compute_fitstat, rclass

	version 15.1

	syntax, [ll(string) obs(string) parm(string) consmodel(real 0) aic bic mcf est iscons]

	local many_few = 0

	if !strlen("`aic'`bic'`mcf'`est'") local mcf "mcf"													//no fitstat option entry is McFadden by default

	if strlen("`aic'`bic'`mcf'`est'") > 3 local many_few = 1											//too many fitstat options selected

	if !strlen("`ll'") local ll = "e(ll)"

	if strlen("`mcf'`est'") {

		if !strlen("`obs'") & strlen("`est'") local obs = "e(N)"

		if strlen("`iscons'") local fitstat = `ll'														//baseline

		else if !strlen("`iscons'") & strlen("`est'") local ///
			fitstat = 1 - (`ll'/`consmodel')^(-2*`consmodel'/`obs')										//Estrella R2

		else local fitstat = 1 - `ll'/`consmodel'														//McFadden R2

	}

	else if strlen("`aic'`bic'") {

		if !strlen("`parm'") local parm = "e(rank)"

		if !strlen("`obs'") & strlen("`bic'") local obs = "e(N)"

		if strlen("`aic'") local fitstat = -2*(`ll') + 2*`parm'											//AIC

		else local fitstat = -2*(`ll') + `parm'*ln(`obs')												//BIC

	}

	else local many_few = 1

	return local style "`aic'`bic'`mcf'`est'"

	return scalar many_few = `many_few'

	return scalar fitstat = `fitstat'

end

**# Container object for domme specs
version 15.1

mata:

	mata set matastrict on

	struct domme_specs {

		real scalar built_in, built_in_cons

		string rowvector constraint_list
		
		class AssociativeArray scalar param_list

	}

end

**# Mata function to execute 'domme-flavored' models
version 15.1

mata:

	mata set matastrict on

	real scalar domme_call(string scalar Params_in_Model, ///
	real scalar all_subsets_fitstat, real scalar constant_model_fitstat, ///
		struct domme_specs scalar model_specs) 
	{

		real scalar fitstat, loop_length, x

		string scalar Constraints, remove_list, key
		
		string rowvector Param_List, out_list
		
		real rowvector which_constraints
		
		Param_List = tokens(Params_in_Model)
		
		loop_length = length(Param_List)
		
		remove_list = ""
		
		for (x = 1; x <= loop_length; x++) {
			
			remove_list = remove_list + " " + ///
				model_specs.param_list.get(Param_List[x])
			
		}
		
		out_list = tokens(remove_list)
		
		which_constraints = ///
			!colsum( ///
				J(length(out_list), 1, model_specs.constraint_list):==out_list' ///
			)

		Constraints = invtokens(select(model_specs.constraint_list, which_constraints)) 
		
		stata("\`reg' [\`weight'\`exp'] if \`touse', \`ropts'" + ///
			" constraints(" + Constraints + " \`extraconstr')", 1) //estimate model/regression in Stata
			

		if (model_specs.built_in) {
			
			stata("compute_fitstat \`fit_opts' consmodel(" ///
				+ strofreal(model_specs.built_in_cons) + ")", 1)
				
			fitstat = st_numscalar("r(fitstat)")
				
		}
		
		else fitstat = st_numscalar(st_local("fitstat"))

		fitstat = fitstat - ///
			all_subsets_fitstat - ///
			constant_model_fitstat 

		return(fitstat)

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
*/
