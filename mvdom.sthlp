{smcl}
{* *! version 1.2.0 August 14, 2023 J. N. Luchman}{...}
{cmd:help mvdom}
{hline}{...}

{title:Title}

{pstd}
Wrapper program for {cmd:domin} to conduct multivariate regression-based dominance analysis{p_end}

{title:Syntax}

{phang}
{cmd:mvdom} {it:depvar1} {it:indepvars} {it:{help if} {weight}} {cmd:,} 
{opt dvs(depvar2 [... depvar_r])} [{opt pxy} {opt epsilon}]

{phang}{cmd:aweight}s and {cmd:fweight}s are allowed (see help {help weights:weights}).  {help fvvarlist: Factor} and {help tsvarlist:time series variables} are not allowed.  Use the {help xi} prefix for factor variables.

{title:Description}

{pstd}
{cmd:mvdom} sets the data up in a way to allow for the dominance analysis of a multivariate regression by utilizing {help canon}ical correlation. The default metric used is the Rxy metric described by Azen and Budescu (2006). 

{pstd}
{cmd:mvdom} uses the first variable in the {it:varlist} as the first dependent variable in the multivariate regression.  All other variables in the {it:varlist} are used as independent variables.  All dependent variables after the first are entered into the regression in the {opt dvs()} option. {cmd:domin} will only show the first dependent variable in the output.

{pstd}
{cmd:mvdom} is intended for use only as a wrapper program with {cmd:domin} for the dominance analysis of multivariate linear regression, and its syntax is designed to conform with {cmd:domin}'s expectations. 
It is not recommended for use as an estimation command outside of {cmd:domin}.

{marker options}{...}
{title:Options}

{phang}{opt dvs(depvar2 [... depvar_r])} specifies the second through {it:r}th other dependent variables to be used in the multivariate regression. Note the first dependent variable, depvar1, as shown in the syntax. dvs() is required.

{phang}{opt pxy} changes the fit statistic from the default "symmetric" {it:Rxy} to the "nonsymmetric" {it:Pxy} model fit statistic. Both fit statistics are described by Azen and Budescu (2006).

{phang}{opt epsilon} changes the decomposition estimation method to relative weights estimation method described by LeBreton & Tonidandel (2008). The {opt epsilon} method produces a decomposition of the {it:Pxy} statistic.

{title:Saved results}

{phang}{cmd:mvdom} saves the following results to {cmd: e()}:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:e(r2)}}{it:Rxy} metric (default) or {it:Pxy} metric (with option {opt pxy}){p_end}
{p2col 5 15 19 2: macros}{p_end}
{synopt:{cmd:e(title)}}"Multivariate regression"{p_end}
{p2col 5 15 19 2: functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{title:References}

{p 4 8 2}Azen, R., & Budescu, D. V. (2006). Comparing predictors in multivariate regression models: An extension of dominance analysis. {it:Journal of Educational and Behavioral Statistics, 31(2)}, 157-180.{p_end}
{p 4 8 2}LeBreton, J. M., & Tonidandel, S. (2008). Multivariate relative importance: Extending relative weight analysis to multivariate criterion spaces. {it:Journal of Applied Psychology, 93(2)}, 329-345.{p_end}

{title:Author}

{p 4}Joseph N. Luchman{p_end}
{p 4}Research Fellow{p_end}
{p 4}Fors Marsh{p_end}
{p 4}Arlington, VA{p_end}
{p 4}jluchman@forsmarsh.com{p_end}

{title:Also see}

{psee}
{manhelp mvreg R},
{manhelp canon R}.
{p_end}
