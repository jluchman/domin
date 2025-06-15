*! mixdom version 2.2.0  12/26/2024 Joseph N. Luchman
**# Program definition and initialization
version 16
program define mixdom, eclass properties(mi)
syntax varlist(min = 2 fv ts) [pw fw] [if], id(varlist max = 1 min = 1) ///
	[REopt(string) XTMopt(string) Mopt(string)]
**# Error conditions
if strlen("`xtmopt'")  {
    display as err "{cmd:xtmopt()} is defunct. Use {cmd:mopt()}."
	exit 198
}
**# Environment set-up
tempname estmat r2w r2b base_e base_u mean_h b V
tempvar touse
	* ~~ check for pre-existing re-usable baseline estimates ~~ 
foreach temp in base_e base_u mean_h {
	capture assert e(`temp')
	if !_rc scalar ``temp'' = e(`temp')
}
**# Parse varlist and estimate 
gettoken dv ivs: varlist
mixed `dv' `ivs' [`weight'`exp'] `if', || `id':, `reopt' `mopt' nostderr
**# Process estimates
matrix `estmat' = e(b)
scalar `r2w' = ///
	(exp(`estmat'[1, `=colsof(`estmat') - 1']))^2 + ///
	(exp(`estmat'[1, `=colsof(`estmat')']))^2
if missing(`mean_h') {
	preserve
	quietly collapse (count) `dv' `if', by(`id') fast
	quietly ameans `dv'
	scalar `mean_h' = r(mean_h)
	restore
}
scalar `r2b' = ///
	(exp(`estmat'[1, `=colsof(`estmat') - 1']))^2 + ///
	((exp(`estmat'[1, `=colsof(`estmat')']))^2)/`mean_h'
**# Estimate baseline results if not available from previous run
if missing(`base_e') | missing(`base_u') {
	mixed `dv' [`weight'`exp'] `if', || `id':, `reopt' `mopt' nostderr
	matrix `estmat' = e(b)
	scalar `base_e' = `estmat'[1, `=colsof(`estmat')']
	scalar `base_u' = `estmat'[1, `=colsof(`estmat') - 1']
}
**# Construct R2 metrics
scalar `r2w' = 1 - ((exp(`base_u'))^2 + (exp(`base_e'))^2)^-1*`r2w'
scalar `r2b' = 1 - ((exp(`base_u'))^2 + ((exp(`base_e'))^2)/`mean_h')^(-1)*`r2b'
**# Return values
generate `touse' =  e(sample)
ereturn clear
	* ~~ 'dummy' values for -mi_dom- ~~ 
matrix `b' = 1
matrix colnames `b' = "empty"
matrix `V' = 1
matrix colnames `V' =  "empty"
matrix rownames `V' =  "empty"
ereturn post `b' `V', esample(`touse')
	* ~~ return R2s ~~
ereturn scalar r2_w = `r2w'
ereturn scalar r2_b = `r2b'
ereturn local cmd "mixdom"
ereturn local title "Mixed-effects ML regression"
	* ~~ re-usable baseline errors and harmonic sample size estimates ~~ 
ereturn hidden scalar base_e = `base_e'
ereturn hidden scalar base_u = `base_u'
ereturn hidden scalar mean_h = `mean_h'
end
/* programming notes and history
- mixdom version 1.0 - date - January 15, 2014
Basic version
-----
- mixdom version 1.1 - date - March 11, 2015
- added version statement (12.1)
- time series operators allowed
- removed scalars persisting after estimation
-----
- mixdom version 2.0 - date - February 15, 2021
- -xtmopt()- depreciated in favor of -mopt()-
 ---
 mixdom version 2.1.0 - August 14, 2023
 - minimum version 15 consistent with base -domin-
 - xtmopt defunct - gives warning
 - noconstant option removed
 - returns e(smaple) to satisfy -domin- 3.5 requirements
 // 2.1.1 - December 20, 2024
 -  version to 16 consistent with base -domin-
 -----
- mixdom version 2.2.0 - date - December 26, 2024
 - -mi estimate-able and usable with -mi_dom-
