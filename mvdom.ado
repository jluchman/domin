*! mvdom version 1.2.0 8/14/2023 Joseph N. Luchman

version 15

program define mvdom, eclass

syntax varlist(min = 2) [if] [aw fw], dvs(varlist min=1) [epsilon pxy] //epsilon is a hidden option

tempname canonmat 

tempvar touse

gettoken dv ivs: varlist

quietly generate byte `touse' = 1 `if'
	
quietly replace `touse' = 0 if missing(`touse')

if strlen("`epsilon'") {

	mata: eps_ri_mv("`dv' `dvs'", "`ivs'", "`touse'")
	
}
else {
	if strlen("`pxy'") {
	
		quietly correlate `dv' `dvs' `ivs' [`weight'`exp'] if `touse'
		
		local dvnum: word count `dv' `dvs'
		
		matrix `canonmat' = r(C)
		
		matrix `canonmat' = trace( ///
		invsym(`canonmat'[1..`:word count `dv' `dvs'', 1..`:word count `dv' `dvs''])* ///
		`canonmat'[`=`:word count `dv' `dvs''+1'..., 1..`:word count `dv' `dvs'']'* ///
		invsym(`canonmat'[`=`:word count `dv' `dvs''+1'..., `=`:word count `dv' `dvs''+1'...])* ///
		`canonmat'[`=`:word count `dv' `dvs''+1'..., 1..`:word count `dv' `dvs''] ///
		)

	}
	else {

		quietly _canon (`dv' `dvs') (`ivs') [`weight'`exp'] if `touse'

		matrix `canonmat' = e(ccorr)

	}
	
	ereturn post, esample(`touse')
	
	if strlen("`pxy'") ereturn scalar r2 = `canonmat'[1, 1]/`:word count `dv' `dvs''
	else ereturn scalar r2 = `canonmat'[1, 1]^2
	
	ereturn local title "Multivariate regression"
	
}

end

/*Mata function to execute epsilon-based relative importance with mvdom*/
version 15

mata: 

mata set matastrict on

void eps_ri_mv(string scalar dvlist, string scalar ivlist, string scalar touse) 
{
	/*object declarations*/
	real matrix X, Y, L, R, Lm, L2, R2, Lm2, Pxy

	real rowvector V, Bt, V2, Bt2
	
	transmorphic view_dv, view_iv
	
	/*begin processing*/
	st_view(view_dv, ., tokens(dvlist), st_varindex(touse))
	
	st_view(view_iv, ., tokens(ivlist), st_varindex(touse))
	
	Y = correlation(view_dv) //obtain DV correlations
	
	X = correlation(view_iv) //obtain IV correlations
	
	L = R = X //set-up for svd(); IV side
	
	L2 = R2 = Y //set-up for svd(); DV side
	
	V = J(1, cols(X), .) //placeholder for eigenvalues; IV side
	
	V2 = J(1, cols(Y), .) //placeholder for eigenvalues; DV side
	
	svd(X, L, V, R) //conduct singular value decomposition; IV side
	
	svd(Y, L2, V2, R2) //conduct singular value decomposition; DV side
	
	Lm = (L*diag(sqrt(V))*R) //process orthogonalized IVs
	
	Lm2 = (L2*diag(sqrt(V2))*R2) //process orthogonalized DVs
	
	Pxy = correlation((view_iv, view_dv)) //correlation between original IVs and DVs
	
	Pxy = Pxy[rows(X)+1..rows(Pxy), 1..cols(X)] //take only IV-DV correlations
	
	Bt2 = Pxy'*invsym(Lm2)	//obtain adjusted DV interrelations
	
	Bt = invsym(Lm)*Bt2 //obtain adjusted regression weights
	
	Bt = Bt:^2 //square values of regression weights
	
	Lm = Lm:^2 //square values of orthogonalized predictors

	st_matrix("r(domwgts)", mean((Lm*Bt)'))	//produce proportion of variance explained and put into Stata
	
	st_numscalar("r(fs)", sum(mean((Lm*Bt)')))	//sum relative weights to obtain R2
	
}

end

/* programming notes and history

- mvdom version 1.0 - date - Jan 15, 2014

Basic version

-----

- mvdom version 1.1 - date - March 11, 2015

//notable changes\\
- added version statement (12.1)
- added the Pxy metric 
- added the epsilon-based function
- changed canon to _canon; canon had odd behavior when called from mvdom
 ---
 mvdom version 1.2.0 - August 14, 2023
 - minimum versions 15 consistent with base -domin-
 - 'if' statement optional to accommodate domin v. 3.5.0
 - cleaned up returned values - consistent with reported
 - added e(sample) needed for domin v. 3.5.0
 - restructured eps_ri_mv()
 - removed noconstant option - not consistently applied, not sure why one would ever use it
 - unhide epsilon -  note that it produces Pxy as a metric
 - use st_view as opposed to st_data for efficiency
 
 ** mi-able?
