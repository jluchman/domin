*! mixdom version 2.0 2/15/2021 Joseph N. Luchman

version 12

program define mixdom, eclass

syntax varlist(min = 2 fv ts) [pw fw] if, id(varlist max = 1 min = 1) [REopt(string) XTMopt(string) ///
Mopt(string) noConstant]

if strlen("`xtmopt'") & strlen("`mopt'") {
    display as err "{cmd:xtmopt} both {cmd:mopt} cannot be used together"
	exit 198
}

if c(stata_version) >= 13 local reg "mixed"
else local reg "xtmixed"

if strlen("`xtmopt'") local mopt "`xtmopt'"

tempname estmat r2w r2b base_e base_u mean_h

gettoken dv ivs: varlist

foreach temp in base_e base_u mean_h {

	capture assert e(`temp')

	if !_rc scalar ``temp'' = e(`temp')

}

`reg' `dv' `ivs' [`weight'`exp'] `if' , `constant' || `id':, `reopt' `mopt' nostderr

matrix `estmat' = e(b)

scalar `r2w' = (exp(`estmat'[1, `=colsof(`estmat') - 1']))^2 + (exp(`estmat'[1, `=colsof(`estmat')']))^2

di `r2w'

if missing(`mean_h') {

	preserve

	quietly collapse (count) `dv' `if', by(`id') fast

	quietly ameans `dv'

	scalar `mean_h' = r(mean_h)
	
	di `mean_h'

	restore

}

scalar `r2b' = (exp(`estmat'[1, `=colsof(`estmat') - 1']))^2 + ((exp(`estmat'[1, `=colsof(`estmat')']))^2)/`mean_h'

di `r2b'

if missing(`base_e') | missing(`base_u') {

	`reg' `dv' [`weight'`exp'] `if' , `constant' || `id':, `reopt' `mopt' nostderr

	matrix `estmat' = e(b)

	scalar `base_e' = `estmat'[1, `=colsof(`estmat')']

	scalar `base_u' = `estmat'[1, `=colsof(`estmat') - 1']
	
}

scalar `r2w' = 1 - ((exp(`base_u'))^2 + (exp(`base_e'))^2)^-1*`r2w'

scalar `r2b' = 1 - ((exp(`base_u'))^2 + ((exp(`base_e'))^2)/`mean_h')^-1*`r2b'

ereturn scalar r2_w = `r2w'

di `r2w'

ereturn scalar r2_b = `r2b'

di `r2b'

ereturn scalar base_e = `base_e'

ereturn scalar base_u = `base_u'

ereturn scalar mean_h = `mean_h'

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
- mixdom version 2.0.1 - date - Feb 15, 2021
- -xtmopt()- depreciated in favor of -mopt()-
-- v12...
