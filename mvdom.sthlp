{smcl}
{* *! version 1.3.0 December 28, 2024 J. N. Luchman}{...}
{cmd:help mvdom}
{hline}{...}

{title:Title}

{pstd}
Multivariate regression wrapper program for {cmd:domin}{p_end}

{title:Syntax}

{phang}
{cmd:mvdom} {it:{help varname:depvar1}} {it:{help varlist:indepvars}} [{it:{help if}}] {weight}} {cmd:,} 
{opt dvs(depvar2 [... depvar_r])} [{opt pxy} {opt epsilon}]

{phang}{cmd:aweight}s and {cmd:fweight}s are allowed (see help {help weights:weights}).  {help fvvarlist: Factor} and {help tsvarlist:time series variables} are not allowed.

{title:Description}

{pstd}
{cmd:mvdom} is a specialized {help mvreg:multivariate regression} command that is designed with a syntax structure that can be used in {help domin:dominance analysis}.
{cmd:mvdom} also returns one of two model fit metrics recommended for use by Azen and Budescu (2006).
These two fit metrics are the the {it:Rxy} and {it:Pxy} discussed by Van den Berg and Lewis (1988).
For an example, see {cmd:domin}'s {help domin##examp:Example #6}.

{pstd}
{cmd:mvdom} uses the standard {it:depvar indepvars} syntax common to many estimation commands in Stata but extends on it by allowing additional {it:depvars} to be submitted in the {opt dvs()} option.
{cmd:mvdom} requires at least two dependent variables, one submitted in the primary variable list (i.e., {it:depvar1}) and one or more submitted in the {opt dvs()} option (i.e., {it:depvar2 ... depvar_r}).
Note that {cmd:domin} will only show the first dependent variable submitted in the output although all are used in model estimation.

{pstd}
{cmd:mixdom} is intended for use only as a wrapper program with {cmd:domin} and is not recommended for use as an estimation command outside of {cmd:domin}. 
As of version 1.3.0, {cmd:mvdom} is compatible with {cmd:domin}'s {help mi_dom} wrapper command. 
To do so, {cmd:mvdom} returns uninformative {cmd:b} and {cmd:V} matrices that are both values of 1.
This is because {cmd:mvdom} is intended to be used only for its fit statistics and these two matrices are irrelevant for dominance analysis.

{pstd}
{cmd:mvdom} uses {help canon:canonical correlation} as its underlying estimation engine.

{marker options}{...}
{title:Options}

{phang}{opt dvs(depvar2 [... depvar_r])} is a required option that specifies the second through {it:r}th dependent variables to be used in the multivariate regression. 
Note the first dependent variable, {it:depvar1}, is submitted in the overall variable list. 
{opt dvs()} must have at least one variable.

{phang}{opt pxy} changes the fit statistic from the default "symmetric" {it:Rxy} to the "nonsymmetric" {it:Pxy} model fit statistic.

{phang}{opt epsilon} changes the decomposition estimation method to relative weights estimation method described by LeBreton and Tonidandel (2008). 
The {opt epsilon} method produces a decomposition of the {it:Pxy} statistic.

{title:Saved results}

{phang}{cmd:mvdom} saves the following results to {cmd: e()}:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:e(r2)}}{it:Rxy} metric (default) or {it:Pxy} metric (with option {opt pxy}){p_end}
{p2col 5 15 19 2: macros}{p_end}
{synopt:{cmd:e(title)}}"Multivariate regression"{p_end}
{synopt:{cmd:e(cmd)}}{cmd:mvdom}{p_end}
{p2col 5 15 19 2: matrices}{p_end}
{synopt:{cmd:e(b)}}1; required for {cmd:mi_dom}{p_end}
{synopt:{cmd:e(V)}}1; required for {cmd:mi_dom}{p_end}
{p2col 5 15 19 2: functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{title:References}

{p 4 8 2}Azen, R., & Budescu, D. V. (2006). Comparing predictors in multivariate regression models: An extension of dominance analysis. {it:Journal of Educational and Behavioral Statistics, 31(2)}, 157-180.{p_end}
{p 4 8 2}LeBreton, J. M., & Tonidandel, S. (2008). Multivariate relative importance: Extending relative weight analysis to multivariate criterion spaces. {it:Journal of Applied Psychology, 93(2)}, 329-345.{p_end}
{p 4 8 2}Van den Burg, W., & Lewis, C. (1988). Some properties of two measures of multivariate association. {it:Psychometrika, 53}, 109-122.{p_end}

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
