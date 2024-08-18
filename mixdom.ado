*! mixdom version 2.1.0 8/14/2023 Joseph N. Luchman

version 15

program define mixdom, eclass

syntax varlist(min = 2 fv ts) [pw fw] [if], id(varlist max = 1 min = 1) [REopt(string) XTMopt(string) ///
Mopt(string)]

if strlen("`xtmopt'")  {
    display as err "{cmd:xtmopt()} is defunct. Use {cmd:mopt()}."
	exit 198
}

tempname estmat r2w r2b base_e base_u mean_h

tempvar touse

gettoken dv ivs: varlist

foreach temp in base_e base_u mean_h {

	capture assert e(`temp')

	if !_rc scalar ``temp'' = e(`temp')

}

mixed `dv' `ivs' [`weight'`exp'] `if' , `constant' || `id':, `reopt' `mopt' nostderr

matrix `estmat' = e(b)

scalar `r2w' = (exp(`estmat'[1, `=colsof(`estmat') - 1']))^2 + (exp(`estmat'[1, `=colsof(`estmat')']))^2

if missing(`mean_h') {

	preserve

	quietly collapse (count) `dv' `if', by(`id') fast

	quietly ameans `dv'

	scalar `mean_h' = r(mean_h)
	
	di `mean_h'

	restore

}

scalar `r2b' = (exp(`estmat'[1, `=colsof(`estmat') - 1']))^2 + ((exp(`estmat'[1, `=colsof(`estmat')']))^2)/`mean_h'

if missing(`base_e') | missing(`base_u') {

	mixed `dv' [`weight'`exp'] `if' , `constant' || `id':, `reopt' `mopt' nostderr

	matrix `estmat' = e(b)

	scalar `base_e' = `estmat'[1, `=colsof(`estmat')']

	scalar `base_u' = `estmat'[1, `=colsof(`estmat') - 1']
	
}

scalar `r2w' = 1 - ((exp(`base_u'))^2 + (exp(`base_e'))^2)^-1*`r2w'

scalar `r2b' = 1 - ((exp(`base_u'))^2 + ((exp(`base_e'))^2)/`mean_h')^-1*`r2b'

generate `touse' =  e(sample)

ereturn clear

ereturn post, esample(`touse')

ereturn scalar r2_w = `r2w'

ereturn scalar r2_b = `r2b'

ereturn local title = "Mixed-effects ML regression"

ereturn hidden scalar base_e = `base_e' // note to self - make these hidden not official returned values

ereturn hidden scalar base_u = `base_u'

ereturn hidden scalar mean_h = `mean_h'

// note to self - return esample and title

end

/* programming notes and history

- mixdom version 1.0 - date - Jan 15, 2014
Basic version
-----
- mixdom version 1.1 - date - Mar 11, 2015
- added version statement (12.1)
- time series operators allowed
- removed scalars persisting after estimation
-----
- mixdom version 2.0 - date - Feb 15, 2021
- -xtmopt()- depreciated in favor of -mopt()-
 ---
 mixdom version 2.1.0 - mth day, year
 - minimum version 15 consistent with base -domin-
 - xtmopt defunct - gives warning
 - noconstant option removed
 - returns e(smaple) to satisfy -domin- 3.5 requirements
 
 ** mi-able?
