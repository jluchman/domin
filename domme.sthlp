{smcl}
{* *! version 1.2.0 January 12, 2024 J. N. Luchman}{...}
{cmd:help domme}

{title:Title}

{pstd}
{bf:domme} {hline 2} {ul on}Dom{ul off}inance analysis for {ul on}m{ul off}ulitple {ul on}e{ul off}quation models{p_end}


{title:Syntax}

{p 8 16 2}
{cmd:domme} [{cmd:(}{it:eqname1 = parmnamelist1}{cmd:)} 
{cmd:(}{it:eqname2 = parmnamelist2}{cmd:)} ...
{cmd:(}{it:eqnameN = parmnamelistN}{cmd:)}] 
{ifin} {weight}{cmd:,} [{it:options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt r:eg(full_estimation_command)}}preditive model command to call{p_end}
{synopt :{opt rop:ts(command_options)}}options to command in {opt reg()}{p_end}
{synopt :{opt f:itstat(fitstat_opts)}}fit statistic returned by {opt reg()} or computed using built-in method{p_end}
{synopt :{opt s:ets([PEset_1] ... [PEset_x])}}sets of indepdendent variables{p_end}
{synopt :{opt a:ll(PEall)}}indepdendent variables included in all subets{p_end}

{syntab:Reporting}
{synopt :{opt nocon:ditional}}suppresses computation of conditional dominance statistics{p_end}
{synopt :{opt nocom:plete}}suppresses computation of complete dominance designations{p_end}
{synopt :{opt rev:erse}}reverses interpretation for statistics that decrease with better fit{p_end}
{synoptline}
{p 4 6 2}
Command in {opt reg()} must accept {help constraint}s as a command option. {p_end}

{p 4 6 2}
{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are
allowed; see {help weight}.  Weight use is restricted to commands in {opt reg()} 
that accept them.{p_end}

{p 4 6 2}
Note that {cmd:domme} requires at least two parameter estimates or 
sets of parameter estimates (see option {opt sets()} below).  
Because it is possible to submit only sets of parameter estimates, the 
initial parameter estimates specification statement is optional. {p_end}

{title:Table of Contents}

{space 4}{help domme##desc: 1. Description}
{space 4}{help domme##setup: 2. Set-up}
{space 4}{help domme##opts: 3. Options}
{space 4}{help domme##sav: 4. Saved Results}
{space 4}{help domme##examp: 5. Examples}
{space 4}{help domme##remark: 6. Final Remarks}
{space 4}{help domme##refs: 7. References}


{marker desc}{...}
{title:1. Description}

{pstd}
Dominance analysis (DA) is a methodology for determining the relative 
importance of independent variables or parameter estimates in a predictive model. 
The {cmd: domme} approach extends on {cmd: domin} by being able to accommodate more 
predictive models such as those with multiple equations/dependent variables 
(see Luchman, Lei, and Kaplan, 2020 for a discussion). As an extension of single 
equation dominance analysis, it is recommended that the user familiarize 
themselves with single equation dominance analysis (i.e., see {help domin:domin}) 
before attempting to use the multiple equation version of the methodology.

{pstd}
This multiple equation DA implementation differs from the implementation of 
the single equation version of DA in how it includes or excludes parameter 
estimates from the model. Multiple equation DA uses {help constraint}s to exclude 
parameter estimates from the model by constraining their values to be 0. When constrained 
to be 0, the parameter estimate cannot affect prediction and, thus, is effectively 
excluded. This is why {cmd: domme} can only be used with commands that accept 
constraints.


{marker setup}{...}
{title:2. Set-up}

{pstd}
This implementation of multiple equatuion DA must be provided with the components 
of the parameter estimates from which it will create "parameter equals 0" 
constraints. How these constraints are constructed follows from the way in which 
Stata names each parameter estimate. Consider, for example, the following logistic 
regression model (estimated on the {cmd: sysuse auto} data).

{pstd}
{cmd:logit foreign price mpg turn trunk}

{pstd}
Following the estimation of this model, the user can ask for the names of all 
the parameters in the {cmd: e(b)} or coefficient matrix by using:

{pstd}
{cmd: display "`: colfullnames e(b)'"}

{pstd}
which produces

{pstd}
{res:foreign:price foreign:mpg foreign:turn foreign:trunk foreign:_cons}

{pstd}
This series of names are the parameter names for all the coefficients in the 
logit model. In order to use DA on this model, the user needs
to supply {cmd: domme} with the names of all the parameters that will be used.
One way to supply these parameter names is to use the initial 
{res:(eqname = parmnamelist)} statements. For instance:

{pstd}
{cmd: domme (foreign = price mpg turn trunk), ...}

{pstd} 
implies four constraints:

{phang}
{res: _b[foreign:price] = 0}

{phang}
{res: _b[foreign:mpg] = 0} 

{phang}
{res: _b[foreign:turn] = 0} 

{phang}
{res: _b[foreign:trunk] = 0}

{pstd}
{cmd: domme} uses these constraints to "remove" parameters by constraining their 
value to 0. This mimics {cmd: domin}'s method where the parameter's name is 
removed from the {cmd: indepvars} list directly.  

{pstd}
The way parameter constraints are produced with the {opt all()} and {opt sets()} 
options is identical to that of the initial statements to {cmd: domme}.

{marker opts}{...}
{title:3. Options}

{dlgtab:Model}

{phang}{opt reg(full_estimation_command)} refers {cmd:domme} to a command that accepts 
{help constraint}s, uses {help ml} to estimate parameters, and that can produce the 
scalar-valued statistic referenced in the {opt fitstat()} option. {cmd:domme} can be 
applied to any built-in or user-written {help program} that meets these criteria.  

{pmore}{it:full_estimation_command} is the full estimation command, not including 
a comma or options following the comma, as would be submitted to Stata.  The 
{opt reg()} option has no default and the user is required to provide a 
{cmd:domme}-compatible statistical model.

{phang}{opt ropts(command_options)} supplies the command in {opt reg()} with any 
relevant estimation options.  Any options normally following the comma in standard 
Stata syntax can be supplied to the statisical model this way. The only exception 
to is the use of {opt constraints()}; {cmd:domme} cannot, at current, accept 
constraints other than those it creates.  

{phang}{opt f:itstat(fitstat_opts)} the scalar-valued model fit summary statistic 
used in the dominance analysis. There are two ways {cmd:domme} points to fit 
statistics.

{pmore}The first method is identical to {cmd:domin}'s approach. {cmd:domme} 
accepts any {help return:returned}, {help ereturn:ereturned}, or other 
{help scalar:scalar} produced by the estimation command in {opt reg()}. Note 
that some Stata commands change their list of ereturn-ed results when 
constraints are applied (e.g., {cmd:logit}, {cmd:poisson}). Ensure that the 
command used produces the desired scalar with constraints.

{pmore}The second method accommodates Stata commands' tendency to not return 
pseudo-R-square values with constraints and expands which commands can get a 
fit statistic using a built-in fit statistic computation. When {opt fitstat()} 
is asked for an empty ereturned statistic indicator (i.e., {res:e()}). Using
{opt fitstat(e())} produces the McFadden pseudo-R squared metric. 
Prior to {cmd:domme} version 1.2 you had to provide a three character code as 
an option to the {opt fitstat()}. {opt fitstat()} still accepts the the 
McFadden pseudo-R squared (as {opt fitstat(e(), mcf)})
(See Example #1). 

{pmore}Note that {cmd:domme} has no default fit statistic and the user is 
required to provide a fit statistic option. The built-in option 
assumes the command in {opt reg()} ereturns {res: e(ll)}.

{phang}{opt sets([PEset_1] ... [PEset_x])} binds together parameter estimate 
constraints as a set that are always constrained jointly and act as a 
single parameter estimate.

{pmore}Each {it:PEset} is put together in the same way as the initial statements in 
that they are constructed from a series of {res:(eqname = parmnamelist)} statements. 
All {it:PEset}s must be bound by brackets "{res:[]}".  For example, consider again 
the model {cmd:logit foreign price mpg turn trunk}.  To produce two sets of parameters, 
one that includes {it:price} and {it:mpg} as well as a second that includes {it:turn} 
and {it:trunk}, the {opt sets()} type {res:sets( [(foreign = price mpg)]} 
{res:[(foreign = turn trunk)] )}.  

{pmore}Note that a single set can include parameters from multiple equations 
(see Example #6).

{phang}{opt all(PEall)} defines a set of parameter estimate constraints that 
are allowed to explain the fit metric with a higher priority than the parameter 
estimates in the initial statements or the {opt sets()} option (see Example #3). 
In effect, the parameter estimates defined in the {opt all()} option are used 
like covariates. 

{pmore}The {it:PEall} statement is set up in a way similar to the {it:PE_set}s 
in a {res:(eqname = parmnamelist)} format and can accept parameters from multiple 
equations. 

{dlgtab:Reporting}

{phang}{opt noconditional} suppresses the computation and display of of the conditional dominance 
statistics which can save computation time when conditional dominance statistics 
are not desired. Suppressing the computation of conditional dominance statistics 
also suppresses the "strongest dominance designations" list.

{phang}{opt nocomplete} suppresses the computation of the complete dominance designations 
which can save computation time when complete dominance designations are not desired. 
Suppressing the computation of complete dominance designations also suppresses 
the "strongest dominance designations" list.

{phang}{opt reverse} reverses the interpretation of all dominance statistics in the 
{cmd:e(ranking)} vector, {cmd:e(cptdom)} matrix, and corrects the computation of the 
{cmd:e(std)} vector as well as the "strongest dominance designations" list.  
{cmd:domme} assumes by default that higher values on overall fit statistics constitute 
better fit. {opt reverse} is useful for the interpetation of dominance statistics 
based on overall model fit statistics that decrease with better fit (e.g., AIC, BIC).

{marker sav}{...}
{title:4. Saved Results}

{phang}{cmd:domme} saves the following results to {cmd: e()}:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(fitstat_o)}}overall fit statistic value{p_end}
{synopt:{cmd:e(fitstat_a)}}fit statistic value associated with variables in {opt all()}{p_end}
{synopt:{cmd:e(fitstat_c)}}fit statistic value computed by default when the constant model is non-zero{p_end}
{p2col 5 15 19 2: macros}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}{cmd:Dominance analysis for multiple equations}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:domme}{p_end}
{synopt:{cmd:e(fitstat)}}contents of the {opt fitstat()} option{p_end}
{synopt:{cmd:e(reg)}}contents of the {opt reg()} option{p_end}
{synopt:{cmd:e(ropts)}}contents of the {opt ropts()} option{p_end}
{synopt:{cmd:e(properties)}}{cmd:b}{p_end}
{synopt:{cmd:e(set{it:#})}}parameters included in {opt set(#)}{p_end}
{synopt:{cmd:e(all)}}parameters included in {opt all()}{p_end}
{p2col 5 15 19 2: matrices}{p_end}
{synopt:{cmd:e(b)}}general dominance statistics vector{p_end}
{synopt:{cmd:e(std)}}general dominance standardized statistics vector{p_end}
{synopt:{cmd:e(ranking)}}rank ordering based on general dominance statistics vector{p_end}
{synopt:{cmd:e(cdldom)}}conditional dominance statistics matrix{p_end}
{synopt:{cmd:e(cptdom)}}complete dominance designation matrix{p_end}
{p2col 5 15 19 2: functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{marker examp}{...}
{title:5. Examples}

{phang} {stata sysuse auto}{p_end}

{phang}Example 1: Path analysis/seemingly unrelated regression (SUR) with built in McFadden pseudo-R squared{p_end}
{phang} {stata sureg (price = length foreign gear_ratio) (headroom = mpg)} {p_end}
{phang} {stata domme (price = length foreign gear_ratio) (headroom = mpg), reg(sureg (price = length foreign gear_ratio) (headroom = mpg)) fitstat(e())} {p_end}

{phang}Example 2: Zero-inflated Poisson{p_end}
{phang} {stata generate zi_pr = price*foreign} {p_end}
{phang} {stata zip zi_pr headroom trunk, inflate(gear_ratio turn)} {p_end}
{phang} {stata domme (zi_pr = headroom trunk) (inflate = gear_ratio turn), reg(zip zi_pr headroom trunk) f(e()) ropt(inflate(gear_ratio turn))} {p_end}

{phang}Example 3: Path analysis/SUR model with all option{p_end}
{phang} {stata sem (foreign <- headroom) (price <- foreign length weight) (weight <- turn)} {p_end}
{phang} {stata domme (price = length foreign) (foreign = headroom), all((price = weight) (weight = turn)) reg(sem (foreign <- headroom) (price <- foreign length weight) (weight <- turn)) fitstat(e())} {p_end}

{phang}Example 4: Generalized negative binomial with all and parmeters treated as _cons in the dominance analysis (i.e., _b[price:foreign] using {cmd:e(ll)} as fit statistic {p_end}
{phang} {stata gnbreg price foreign weight turn headroom, lnalpha(weight length)} {p_end}
{phang} {stata domme (price = turn headroom) (lnalpha = weight length), reg(gnbreg price foreign weight turn headroom) f(e(ll)) ropt(lnalpha(weight length)) all( (price = weight) )} {p_end}

{phang}Example 5: Generalized structural equation model with factor variables{p_end}
{phang} {stata sysuse nlsw88, clear} {p_end}
{phang} {stata gsem (wage <- union hours, regress) (south <- age ib1.race union, logit)} {p_end}
{phang} {stata domme (wage = union hours) (south = age union), reg(gsem (wage <- union hours, regress) (south <- age ib1.race union, logit)) fitstat(e()) sets([(south = 2.race 3.race)])}{p_end}

{phang}Example 6: Generalized structural equation model with sets to evaluate independent variables{p_end}
{phang} {stata gsem (south union <- wage tenure ttl_exp, logit)} {p_end}
{phang} {stata domme, reg(gsem ( south smsa union <- wage tenure ttl_exp, logit)) fitstat(e()) sets( [(south = wage) (union = wage)] [(south = tenure) (union = tenure)] [(south = ttl_exp) (union = ttl_exp)]) } 
{p_end}

{phang}Examples 7: Replicating results from {cmd:domin}{p_end}
{pmore}7a: Logit model  with factor varaible{p_end}
{pmore} {stata sysuse auto, clear} {p_end}
{pmore} {stata domin foreign price mpg turn trunk, reg(logit) fitstat(e(r2_p)) sets((i.rep78))} {p_end}
{pmore} {stata domme (foreign = price mpg turn trunk), reg(logit foreign price mpg turn trunk ib1.rep78) fitstat(e(), mcf) sets([(foreign = 3.rep78 4.rep78)])} {p_end}

{pmore}7b: Ordered logit model with covariate{p_end}
{pmore} {stata domin rep78 trunk weight length, reg(ologit) fitstat(e(r2_p)) all(turn)} {p_end}
{pmore} {stata domme (rep78 = trunk weight length), reg(ologit rep78 trunk weight length turn) fitstat(e(), mcf) all((rep78 = turn))} {p_end}

{pmore}7c: Poisson regression with log-likelihood fitstat and constant-only comparison using reverse{p_end}
{pmore} {stata domin price mpg rep78 headroom, reg(poisson) fitstat(e(ll)) consmodel reverse} {p_end}
{pmore} {stata domme (price = mpg rep78 headroom), reg(poisson price mpg rep78 headroom) fitstat(e(ll)) reverse} {p_end}

{marker remark}{...}
{title:6. Final Remarks}

{pstd}See {stata help domin:domin's help file} for an extensive discussion of the role of dominance 
analysis as a postestimation method and caveats about its use. All these notes 
and considerations apply to {cmd:domme} as well.

{pstd}Any parameter estimates in the model's {opt reg()} specification but not in 
the initial statements, the {opt sets()}, or {opt all()} are considered to be a 
part of the to a constant-only model (see Examples #4 and #7c). When using {cmd:domme}'s 
built-in fit statistic, the constant-only model will be used to compute the 
baseline model.

{pstd}Note that {cmd:domme} does not check to ensure that the parameters supplied 
it are in the model and it is the user's responsibility to ensure that the 
parameter estimates created in the initial statements, as well as those created by 
{opt sets()} and {opt all()}, are valid parameters in the estimated model. 
{cmd:domme} also attempts to clean-up parameter constraints it creates but 
under certain circumstances, when {cmd:domme} fails to execute in a way that it does 
not capture, parameter constraints will remain in memory. {cmd:domme} also will never 
overwrite existing parameter estimate constraints and, if there are insufficient parameter 
constraints in memory, {cmd:domme} will fail with an error noting insufficient free 
constraints. Use {help constraint dir} to list all defined constraints in memory.


{marker refs}{...}
{title:7. References}

{p 4 8 2}Luchman, J. N., Lei, X., and Kaplan, S. A. (2020). Relative importance analysis with multivariate models: Shifting the focus from independent variables to parameter estimates. 
{it:Journal of Applied Structural Equation Modeling, 4(2)}, 40–59.{p_end}

{title:Development Webpage}

{phang} Additional discussion of results, options, and conceptual issues on: 

{phang}{browse "https://github.com/fmg-jluchman/domin/wiki"}

{phang} Please report bugs, requests for features, and contribute to as well as follow on-going development of {cmd:domme} on:

{phang}{browse "http://github.com/jluchman/domin"}

{title:Article}

Please cite as:

{p 4 8 2}Luchman, J. N. (2021). Determining relative importance in Stata using dominance analysis: domin and domme. {it:The Stata Journal, 21(2)}, 510–538. https://doi.org/10.1177/1536867X211025837{p_end}


{title:Author}

{p 4}Joseph N. Luchman{p_end}
{p 4}Research Fellow{p_end}
{p 4}Fors Marsh{p_end}
{p 4}Arlington, VA{p_end}
{p 4}jluchman@forsmarsh.com{p_end}


{title:See Also}

{browse "https://CRAN.R-project.org/package=domir":R package domir}, {browse "https://cran.r-project.org/web/packages/domir/vignettes/domir_basics.html":Detailed description of Dominance Analysis}


