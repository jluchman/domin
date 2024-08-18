{smcl}
{* *! version 3.5.2 August 13, 2024 J. N. Luchman}{...}
{cmd:help domin}

{title:Title}

{phang}
{bf:domin} {hline 2} Dominance analysis


{title:Syntax}

{p 8 16 2}
{cmd:domin} {depvar} [{indepvars}] {ifin} {weight} [{it:, options}]

{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt r:eg(command, command_options)}}preditive model command to call{p_end}
{synopt :{opt f:itstat(scalar)}}fit statistic returned by {opt reg()}{p_end}
{synopt :{opt s:ets((IVset_1) ... (IVset_x))}}sets of indepdendent variables{p_end}
{synopt :{opt a:ll(IVall)}}indepdendent variables included in all subets{p_end}
{synopt :{opt cons:model}}adjusts {opt fitstat()} value when {bf:_cons}-only model is not 0{p_end}
{synopt :{opt eps:ilon}}uses the epsilon or relative weights estimator{p_end}
{synopt :{opt noesamp:leok}}allow computation when estimation sample is not set in {opt reg()}{p_end}

{syntab:Reporting}
{synopt :{opt nocon:ditional}}suppresses computation of conditional dominance statistics{p_end}
{synopt :{opt nocom:plete}}suppresses computation of complete dominance designations{p_end}
{synopt :{opt rev:erse}}reverses interpretation for statistics that decrease with better fit{p_end}
{synoptline}
{p 4 6 2}
{it:indepvars} in {opt sets()} and {opt all()} may contain factor variables; see 
{help fvvarlist}.  Factor variable use is restricted to commands in {opt reg()} 
that accept them.{p_end}
{p 4 6 2}
{it:depvar} and {it:indepvars} may contain time-series operators; see 
{help tsvarlist}.  Such operators are restricted to commands in {opt reg()} 
that accept them.{p_end}
{marker weight}{...}
{p 4 6 2}
{cmd:aweight}s, {cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are
allowed; see {help weight}.  Weight use is restricted to commands in {opt reg()} 
that accept them.{p_end}

{p 4 6 2}
Note that {cmd:domin} requires at least two indepvars or sets of indepvars 
(see option {opt sets()} below).  Because it is possible to submit only sets 
of {it:indepvars}, the initial {it:indepvars} statement is optional.


{title:Table of Contents}

{space 4}{help domin##desc: 1. Description}
{space 4}{help domin##disp: 2. Display}
{space 4}{help domin##opts: 3. Options}
{space 4}{help domin##sav: 4. Saved Results}
{space 4}{help domin##examp: 5. Examples}
{space 4}{help domin##remark: 6. Final Remarks}
{space 4}{help domin##refs: 7. References}


{marker desc}{...}
{title:1. Description}

{pstd}
Dominance analysis (DA) is a methodology for determining the relative importance of independent 
variables (IVs)/predictors/features in a predictive model. DA determines relative 
importance based on each IV's contribution to prediction using several results that decompose and compare 
the contribution each IV makes to an overall fit statistic compared to one another. Conceptually, DA is an 
extension of Shapley value decomposition from Cooperative Game Theory (see Gr{c o:}mping, 2007 for a 
discussion) which seeks to find solutions of how to subdivide "payoffs" (i.e., the fit statistic) 
to "players" (i.e., the IVs) based on their relative contribution; the payoff is usually 
assumed to be a single value (i.e., scalar valued).

{pstd}
The DA implementation of Shapley value decomposition works by using a pre-selected 
predictive model and applying an experimental design to evaluate how IVs contribute. 
The DA treats the predictive model as a data generating process with the fit statistic as the 
dependent variable.  The IVs of the predictive model are used as factors with a within-subjects 
full-factorial design (i.e., all possible combinations of the IVs are applied to the data). Another 
way of describing the process is as a brute force method where sub-models reflecting all possible 
combinations of the IVs being included or excluded is estimated from the data and the fit statistic 
associated with each sub-model is collected. Given {it:p} IVs in the pre-selected model, 
obtaining all possible combinations of the IVs results in 2^{it:p} sub-models to be estimated 
(see Budescu, 1993).

{pstd}
There are three dominance designations obtained using the fit statistics from all the sub-models.

{space 4}{title:1a] General Dominance}

{pstd}
General dominance is designated/determined using general dominance statistics.  General dominance 
statistics divide up the overall fit statistic associated with the pre-selected model into contributions 
associated with each IV. General dominance is designated from these general dominance statistics by 
comparing the magnitude of the statistic associated with each IV to the general dominance statistics 
associated with each other IV.  If IV {it:X_v} has a larger general dominance statistic than 
IV {it:X_z}, then {it:X_v} generally dominates {it:X_z}.  If general dominance statistics 
are equal for two IVs, then no general dominance designation can be made between those IVs.

{pstd}
General dominance statistics are the Shapley values decomposing the overall fit statistic from the 
pre-selected model.  As such, the general dominance statistics are an additive decomposition of the 
overall fit statistic and can be summed to obtain overall fit statistic's value.  General dominance, 
of the three dominance desinations, is least stringent or the weakest designation.  This is because 
it is possible to rank order IVs in almost any situation except when two IVs are exactly equal in terms 
of their contributons to fit across all sub-models.

{pstd}
General dominance statistics are computed by averaging across {it:all} sub-models for each IV. 
This makes general dominance statistics an IV combination-weighted average of the 
marginal/incremental contributions the IV makes to the overall fit statistic across all sub-models in 
which it is included. How the IV combination weighting works and how that affects the 
computations is discussed more below.  It is imporant to note that general dominance statistics are 
the arithmetic average of all conditional dominance statistics discussed next.

{space 4}{title:1b] Conditional Dominance}

{pstd}
Conditional dominance is designated using conditional dominance statistics.  Conditional dominance 
statistics are further decompositions of the pre-selected model's fit statistic that are ascribed to 
each IV but based on that IV's contribiton when a specific number of IVs are included in a sub-model. 
Each IV then has {it:p} conditional dominance statistics associated with it.  Conditional dominance is 
designated by comparing the magnitide of an IV's conditional dominance statistics, at a specific number 
of IVs included in the sub-model, to the magnitude of another IV's conditional dominance statistics at 
that same number of IVs included in the sub-model.  If IV {it:X_v} has larger conditional dominance 
statistics than IV {it:X_z} across all {it:p} valid/within-number of IVs in a sub-model comparisons, 
{it:X_v} conditionally dominates IV {it:X_z}.  If, at any of the valid {it:p} comparisons, the conditional 
dominance statistics for two IVs are equal or there is a change rank order (i.e., {it:X_v}'s conditional 
dominance statistic is smaller than {it:X_z}'s), no conditional dominance designation can be made 
between those IVs. 

{pstd}
Conditional dominance statistics are an extension of Shapley values that further decompose the 
fit statistic to obtain a stronger importance designation and provide more information about each IV.  
Although the conditional dominance statistics do not sum to the pre-selected model's overall fit statistic 
as do general dominance statistics, conditional dominance statistics reveal the effect that IV redundancy, 
as well as IV interactions when they are included in the pre-selected model, have on prediction. 

{pstd}
Conditional dominance statistics are more challenging to interpret than general dominance statistics as they are 
evaluated as an IV's predtive trajectory across different numbers of IVs included in sub-models.  
Conditional dominance is also a more stringent/stronger dominance designation than general dominance as it 
is more difficult for one IV to conditionally dominate than it is for one IV to generally dominate another IV. 
Conditional dominance is a more stringent criterion as there are more ways in which conditional dominance can fail 
to be achieved as all {it:p} conditional dominance statistics for an IV must be greater than another IV's statistics.  
Conditional dominance also implies general dominance–but the reverse is not true. 
An IV can generally, but not conditionally, dominate another IV.
 
{pstd}
Conditional dominance statistics are computed as the average incremental contribution to prediction an IV 
makes within all possible combinations of the IVs in where the focal IV is included similar to general dominance 
statistics.  What makes conditional dominance statistics different from general dominance is that there are {it:p}
conditional dominance statistics reflecting the average contribution the IV makes when a set number of IVs 
are allowed to be used in the sub-model.  Hence, the averages will reflect different numbers of individual 
sub-models.  When there are more possible combinations of IVs for a specific number of IVs allowed in the sub-model, 
the average it produces are based on more sub-models.  Thus, when the arithmetic average of all the 
conditional dominance statistics is used to obtain general dominance statistics, each sub-model in the 
general dominance statistics is IV combination-weighted where specific sub-models that are included along with 
greater numbers of other sub-models (i.e., more combinations at that number of IVs) are down-weighted relative to 
those that are included with fewer (i.e., fewer combinations at that number of IVs).  

{space 4}{title:1c] Complete Dominance}

{pstd}
Complete dominance is designated differently from general and conditional dominance as there are 
no statistics computed for this designation.  Complete dominance is designated by comparing the 
fit statistics produced by {it:all} sub-models between two IVs where the IV's not under consideration 
are held constant.  This results in 2^({it:p} - 2) comparisons between the two IVs reflecting comparisons 
between sub-models including both focal IVs across all possible combinations of the other {it:p} - 2 IVs. 
If IV {it:X_v} has a larger incremental contribution to model fit than IV {it:X_z} across all possible sub-models 
of different combinations of the other {it:p} - 2 IVs, then IV {it:X_v} completely dominates IV {it:X_z}. 
If, for any specific sub-model comparison, the incremental contribution to fit for two IVs are equal or there is a 
change in rank order (i.e., {it:X_v}'s incremental contribution to fit is smaller than {it:X_z}'s), no complete 
dominance designation can be made between those IVs. 

{pstd}
Complete dominance designations are also extensions of Shapley values that use specific sub-model comparisons 
to obtain the strongest dominance designation possible.  Complete dominance is strongest as there are a great 
number of ways in which it can fail to be achieved.  This is because every comparison must be greater for one IV 
than another for complete dominance to be designated.  Complete dominance also imples both general and 
conditional dominance, but, again, the reverse is not true.  An IV can generally and/or conditionally 
dominate another, but not completely dominate it.

{marker disp}{...}
{title:2. Display}

{pstd}
{cmd:domin}, by default, will produce all three types (i.e., general, conditional, and complete) of 
dominance statistics or designations.  The general dominance statistics are considered the primary 
statistics produced by {cmd:domin}, are returned as the {res}e(b){txt} vector, cannot be 
suppressed in the output, and are the first set of statistics to be displayed.  Two additional results 
are produced along with the general dominance statistics: a vector of standardized general dominance 
statistics and a set of ranks.  The standardized vector is general dominance statistic vector normed 
or standardized to be out of 100%.  The ranking vector reflects the general dominance designations 
reported as a set of rank values.

{pstd}
The conditional dominance statistics are reported second, can be suppressed by the {opt noconditional} 
option, and are displayed in matrix format.  The first column displays the average marginal contribution 
to the overall model fit statistic with 1 IV in the model, the second column displays the average 
marginal contribution to the overall model fit statistic with 2 IVs in the model, and so on until 
column {it:p} which displays the average marginal contribution to the overall model fit statistic with 
all {it:p} IVs in the model.  Each row corresponds to the conditional dominance statistics for a different 
IV.

{pstd}
Complete dominance designations are reported third, can be suppressed by the {opt nocomplete} option, and are also 
displayed in matrix format.  The rows of the complete dominance matrix correspond to dominance of the 
IV in that row over the IV in each column.  If a row entry has a 1, the IV associated with 
the row completely dominates the IV associated with the column.  By contrast, if a row entry has a -1, the 
IV associated with the row is completely dominated by the IVassociated with the column.  A 0 indicates no 
complete dominance relationship between the IV associated with the row and the IV associated with the column.

{pstd}
Finally, if all three dominance statistics/designations are reported, a strongest dominance designations 
list is reported.  The strongest dominance designations list reports the strongest dominance designation 
between all IV pairs.


{marker opts}{...}
{title:3. Options}

{dlgtab:Model}

{phang}{opt reg(command, command_options)} is the command implementing the predictive model on which 
the DA is based.  The command can be any official Stata command, any community-contributed command from SSC, 
or any user-written {help program:program}.  All commands must follow the traditional Stata single predictive 
equation {it: cmd depvar indepvars} syntax.  

{pmore}{opt reg()} also allows the user to pass options to the preditive modeling command.  When a comma is 
added in {opt reg()}, all the arguments following the comma will be passed to each run of the command as 
options. 

{pmore}As of version 3.5, when {opt reg()} is omitted, {cmd:domin} defaults to using a very fast built-in method 
for linear regression-based dominance analysis with the explained variance R2. Using the built-in method is 
strongly recommended over using {opt reg(regress)}. The user must omit both {opt reg()} and {opt fitstat()} 
to invoke the built-in method.

{phang}{opt fitstat(scalar)} refers {cmd:domin} to the scalar valued model fit summary statistic used to 
compute all dominance statistics/designations.  The scalar in {opt fitstat()} can be any {help return:returned}, 
{help ereturn:ereturned}, or other {help scalar:scalar}. 

{pmore}As is noted in the {opt reg()} section, when {opt reg()} and {opt fitstat()} are omitted, 
{cmd:domin} defaults to using a very fast built-in method for linear regression-based dominance analysis with the 
explained variance R2.

{pmore}See {help fitdom} for wrapper command to use fit statistics computed as postestimation commands such 
as {cmd: estat ic} (see Example #9b).

{phang}{opt sets((IVset_1) ... (IVset_N))} binds together IVs as a set in the DA. All IVs in a 
set will always appear together in sub-models and are considered a single IV for the purpose of determining 
the number of sub-models.

{pmore}All sets must be bound by parentheses in the {opt sets()} option.  That is, the IVs comprising each 
set must appear between a left paren "(" and a right paren ")".  All parethenesis bound sets must 
be separated by at least one space.  For example, the following: {opt sets((x1 x2) (x3 x4))} creates two 
sets denoted "set1" and "set2" in the output.  {it:set1} will be created from the variables {it:x1} and
{it:x2} whereas {it:set2} will be created from the variables {it:x3} and {it:x4}. There is no limit to the 
number of IVs that can be in an individual {it:IVset} and there are no limits to the number of {it:IVset}s 
that can be created.

{pmore}The {opt sets()} option is commonly used for obtaining dominance statistics/designations for IVs
that are more interpretable when combined, such as several dummy or effects codes reflecting mutually 
exclusive groups as well as non-linear or interaction terms.  {help Factor variables} can be included in 
any {opt sets()} (see Examples #3 and #4b below).

{phang}{opt all(IVall)} defines a set of IVs to be included in all sub-models.  The value of the fit 
statistic associated with the {it:IVall} set are subtracted from the value of the fit statistic for each 
sub-model.  The value of the fit statistic associated with the {it:IVall} set is considered a component 
of the overall fit statistic but are reported as an overall result (i.e., not reported with other IVs 
and {it:IVset}s) and the IVs in the {it:IVall} set are not considered a "set" for the purposes of 
determining the number of sub-models.

{pmore}The {opt all()} option is most commonly used a way to control for a set of covariates in all sub-models.  
{opt all()} also accepts {help factor variables} (see Example #2).

{phang}{opt consmodel} uses the model with no IVs as an adjustment to the overall fit statistic.  
{opt consomdel} changes the interpretation of the overall fit statistic on which the DA is run.  When 
invoked the DA will be computed on the difference between the overall fit statistic's value 
for the full pre-selected model and the fit statistic value for the constant[s]-only model.

{pmore}{opt consmodel} subtracts out the value of the overall fit statistic with no IVs from the 
value of the fit statistic associated with all sub-models in the DA as well as those associated 
with the {it:IVall} set, its value is not considered a part of the overall fit statistic, and it 
is reported along with the overall model results.

{pmore}{opt consmodel} is commonly used obtaining dominance statistics/designations using overall 
model fit statistics that are not 0 when a constant[s]-only model is estimated (e.g., AIC, BIC) 
and the user wants to obtain dominance statistics/designations adjusting for the constant[s]-only 
baseline value.

{phang}{opt epsilon} is an alternative Shapley value decomposition estimator also known as 
"Relative Weights Analysis" (Johnson, 2000).  {opt epsilon} is a faster implementation as it does not 
estimate all sub-models to ascertain the effect of each IV independent of each other IV, but rather 
orthogonalizes the IVs prior to analysis using singular value decomposition (see {help matrix svd}) 
to make them independent.  

{pmore}{opt epsilon}'s singular value decomposition approach is not equivalent to standard Shapley 
value decomposition using the DA approach but is many fold faster for models with many IVs/potential 
sub-models and tends to produce similar answers regarding relative importance 
(LeBreton, Ployhart, & Ladd, 2004) and Shapley values.  

{pmore}Because {opt epsilon} uses a different approach than DA that is not based on sub-models some options that 
only apply to sub-model approaches cannot be applied.  Specifically, {opt epsilon} does not allow {opt all()} or 
{opt sets()} and is a traditional Shapley value estimator only (i.e., does not produce DA's conditional and 
complete extentions of to Shapley value decomposition; hence requires {opt noconditional} and {opt nocomplete}). 

{pmore}{opt epsilon} also requires built-in estimators (i.e., cannot be applied to any model like DA).  
Currently, {opt epsilon} works with commands {cmd:regress}, {cmd:glm} (for any {opt link()} and 
{opt family()}; see Tonidandel & LeBreton, 2010), as well as {cmd:mvdom} (the user-written wrapper 
program for multivariate regression; see LeBreton & Tonidandel, 2008; see also Example #6).  
By default, {opt epsilon} assumes {opt reg(regress)} and {opt fitstat(e(r2))}.  Note that {opt epsilon} 
ignores entries in {opt fitstat()} as it produces its own fit statistic.  {opt episilon}'s implementation 
does not allow {opt consmodel} or {opt reverse}. As of version 3.5, {opt epsilon} does allow {help weights}.   

{pmore}{cmd:Note:} The {opt epsilon} approach has been criticized for being conceptually flawed and biased 
(see Thomas, Zumbo, Kwan, & Schweitzer, 2014) as an estimator of Shapley values.  Despite this criticism 
research also shows similarity between DA and {opt epsilon}-based methods in terms of the results they produce 
(i.e., LeBreton et al., 2004).  {opt epsilon} is offered in {cmd:domin} as it produces useful approximations 
to general dominance statistics/Shapley values. Ultimately, the user is cautioned in the use of 
{opt epsilon} as its speed may come at the cost of bias.

{phang}{opt noesampleok} allows {cmd:domin} to proceed in computing dominance statistics despite the underlying 
command in {opt reg()} not setting the esimation sample. {cmd:domin} uses the {cmd:e(sample)} result to restrict 
the observation prior to estimating all sub-models. This behavior is new as of version 3.5. 

{pmore} When {opt noesampleok} is invoked, {cmd:domin} will attempt to mark the estimation sample using all variables 
the {it:depvar} and {it:indepvars} lists as well as the {opt all()} and the {opt sets()} options. This is {cmd:domin}'s 
approach to sample marking in versions prior to 3.5.

{dlgtab:Reporting}

{phang}{opt noconditional} suppresses the computation and display of of the conditional dominance 
statistics.  Suppressing the computation of the conditional dominance statistics can save 
computation time when conditional dominance statistics are not desired.  Suppressing the computation 
of conditional dominance statistics also suppresses the "strongest dominance designations" list.

{phang}{opt nocomplete} suppresses the computation of the complete dominance designations.  
Suppressing the computation of the complete dominance designations can save computation time when 
complete dominance designations are not desired.  Suppressing the computation of complete dominance 
designations also suppresses the "strongest dominance designations" list.

{phang}{opt reverse} reverses the interpretation of all dominance statistics/designations in the 
{cmd:e(ranking)} vector, {cmd:e(cptdom)} matrix, the {cmd:e(std)} vector, and the 
"strongest dominance designations" list.  {cmd:domin} assumes by default that higher values on 
overall fit statistics constitute better fit, as DA has historically been based on the explained-variance 
R^2 metric. {opt reverse} accommodates metrics that show the opposite pattern.

{pmore}{opt reverse} is most commonly applied to assist interpretation of dominance statistics/designations 
when overall model fit statistics are used that decrease with better fit (e.g., AIC, BIC).


{marker sav}{...}
{title:4. Saved Results}

{phang}{cmd:domin} stores the following results to {cmd: e()}:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(fitstat_o)}}overall fit statistic value{p_end}
{synopt:{cmd:e(fitstat_a)}}fit statistic value associated with variables in {opt all()}{p_end}
{synopt:{cmd:e(fitstat_c)}}constant(s)-only fit statistic value computed with {opt consmodel}{p_end}
{p2col 5 15 19 2: macros}{p_end}
{synopt:{cmd:e(cmdline)}}command as typed{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(cmd)}}{cmd:domin}{p_end}
{synopt:{cmd:e(fitstat)}}contents of the {opt fitstat()} option{p_end}
{synopt:{cmd:e(reg)}}contents of the {opt reg()} option (before comma){p_end}
{synopt:{cmd:e(regopts)}}contents of the {opt reg()} option (after comma){p_end}
{synopt:{cmd:e(estimate)}}estimation method ({cmd:dominance} or {cmd:epsilon}){p_end}
{synopt:{cmd:e(properties)}}{cmd:b}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(set{it:#})}}variables included in {opt set(#)}{p_end}
{synopt:{cmd:e(all)}}variables included in {opt all()}{p_end}
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

{phang}Example 1: linear regression dominance analysis using built-in method{p_end}
{phang} {stata domin price mpg rep78 headroom} {p_end}

{phang}Example 2: Ordered outcome dominance analysis with covariate (e.g., Luchman, 2014){p_end}
{phang} {stata domin rep78 trunk weight length, reg(ologit) fitstat(e(r2_p)) all(turn)} {p_end}

{phang}Example 3: Binary outcome dominance analysis with factor varaible (e.g., Azen & Traxel, 2009) {p_end}
{phang} {stata domin foreign trunk weight, reg(logit) fitstat(e(r2_p)) sets((i.rep78))} {p_end}

{phang}Example 4a: Comparison of interaction and non-linear variables using residualization {p_end}
{phang} {stata generate mpg2 = mpg^2} {p_end}
{phang} {stata generate headr2 = headroom^2} {p_end}
{phang} {stata generate mpg_headr = mpg*headroom} {p_end}
{phang} {stata regress mpg2 mpg} {p_end}
{phang} {stata predict mpg2r, resid} {p_end}
{phang} {stata regress headr2 headroom} {p_end}
{phang} {stata predict headr2r, resid} {p_end}
{phang} {stata regress mpg_headr mpg headroom} {p_end}
{phang} {stata predict mpg_headrr, resid} {p_end}
{phang} {stata domin price mpg headroom mpg2r headr2r mpg_headrr} {p_end}

{phang}Example 4b: Experimental Comparison of IVs containing interaction and non-linear terms using sets {p_end}
{phang} {stata "domin price, sets((mpg c.mpg#c.mpg c.mpg#c.headroom) (headroom c.headroom#c.headroom c.mpg#c.headroom))"} {p_end}

{phang}Example 5: Epsilon-based linear regression approach to dominance with bootstrapped standard errors{p_end}
{phang} {stata "bootstrap, reps(500): domin price mpg headroom trunk turn gear_ratio foreign length weight, epsilon""} {p_end}
{phang} {stata estat bootstrap}{p_end}

{phang}Example 6: Multivariate regression with wrapper {help mvdom}; using default Rxy metric (e.g., Azen & Budescu, 2006; LeBreton & Tonidandel, 2008){p_end}
{phang} {stata domin price mpg headroom trunk turn, reg(mvdom, dvs(gear_ratio foreign length weight)) fitstat(e(r2))} {p_end}
{phang}Comparison dominance analysis with Pxy metric{p_end}
{phang} {stata domin price mpg headroom trunk turn, reg(mvdom, dvs(gear_ratio foreign length weight) pxy) fitstat(e(r2))} {p_end}
{phang}Comparison dominance analysis with {opt epsilon}{p_end}
{phang} {stata domin price mpg headroom trunk turn, reg(mvdom, dvs(gear_ratio foreign length weight)) epsilon} {p_end}

{phang}Example 7: Gamma regression with deviance fitstat and constant-only comparison using {opt reverse}{p_end}
{phang} {stata domin price mpg rep78 headroom, reg(glm, family(gamma) link(power -1)) fitstat(e(deviance)) consmodel reverse} {p_end}
{phang} Comparison dominance analysis with {opt epsilon} {p_end}
{phang} {stata domin price mpg rep78 headroom, reg(glm, family(gamma) link(power -1)) epsilon} {p_end}

{phang}Example 8: Mixed effects regression with wrapper {help mixdom} (e.g., Luo & Azen, 2013){p_end}
{phang} {stata webuse nlswork, clear}{p_end}
{phang} {stata domin ln_wage tenure hours age collgrad, reg(mixdom, id(id)) fitstat(e(r2_w)) sets((i.race))} {p_end}

{phang}Example 9a: Multinomial logistic regression with simple program to return BIC {p_end}
{phang} {stata program define myprog, eclass}{p_end}
{phang} {stata syntax varlist if , [option]}{p_end}
{phang} {stata tempname estlist}{p_end}
{phang} {stata mlogit `varlist' `if'}{p_end}
{phang} {stata estat ic}{p_end}
{phang} {stata matrix `estlist' = r(S)}{p_end}
{phang} {stata ereturn scalar bic = `estlist'[1,6]}{p_end}
{phang} {stata end}{p_end}
{phang} {stata domin race tenure hours age nev_mar, reg(myprog) fitstat(e(bic)) consmodel reverse} {p_end}

{phang}Example 9b: Multinomial logistic regression with {cmd:fitdom} {p_end}
{phang} {stata "domin race tenure hours age nev_mar, reg(fitdom, fitstat_fd(r(S)[1,6]) reg_fd(mlogit) postestimation(estat ic)) consmodel reverse fitstat(e(fitstat))"} {p_end}

{phang}Example 9c: Comparison dominance analysis with McFadden's pseudo-R2 {p_end}
{phang} {stata domin race tenure hours age nev_mar, reg(mlogit) fitstat(e(r2_p))} {p_end}

{phang}Example 10: Multiply imputed dominance analysis using {cmd:mi_dom}{p_end}
{phang} {stata webuse mheart1s20, clear} {p_end}
{phang} {stata domin attack smokes age bmi hsgrad female, reg(mi_dom, reg_mi(logit) fitstat_mi(e(r2_p))) fitstat(e(fitstat))} {p_end}
{phang} Comparison dominance analysis without {cmd:mi} ("in 1/154" keeps only original observations for comparison as in 
{bf:{help mi_intro_substantive:[MI] intro substantive}}) {p_end}
{phang} {stata domin attack smokes age bmi hsgrad female in 1/154, reg(logit) fitstat(e(r2_p))} {p_end}

{phang}Example 11: Random forest with custom in-sample R2 postestimation command (requires {stata ssc install rforest:rforest}){p_end}
{phang} {stata sysuse auto, clear} {p_end}
{phang} {stata program define myRFr2, eclass} {p_end}
{phang} {stata tempvar rfpred} {p_end}
{phang} {stata predict `rfpred'} {p_end}
{phang} {stata correlate `rfpred' `e(depvar)'} {p_end}
{phang} {stata ereturn scalar r2 = `=r(rho)^2'} {p_end}
{phang} {stata end} {p_end}
{phang} {stata rforest price mpg headroom weight, type(reg)} {p_end}
{phang} {stata matrix list e(importance)} {p_end}
{phang} {stata domin price mpg headroom weight, reg(fitdom, reg_fd(rforest, type(reg)) postestimation(myRFr2) fitstat_fd(e(r2))) fitstat(e(fitstat)) noesampleok} {p_end}


{marker remark}{...}
{title:6. Final Remarks}
{space 4}{title:6a] Conceptual Considerations}

{pstd}
DA is most appropriate for model evaluation and is not well suited for model selection purposes.  
That is, DA is best used to evaluate the effects of IVs in the context of a pre-selected model.  This 
is because DA evaluates not only the full pre-selected model (the focus of many importance methods) 
but also all combinations of sub-models.  By examining all sub-models, DA assumes that all IVs should 
be "players" who are given the chance to contribute to the "payoff"/predict the DV.  IVs that are 
trivial (i.e., have no predictive usefulness) may still be assigned non-0 shares of the fit statistic 
with DA.  Other methods better suited to identifying such trivial IVs should be used to filter IVs prior 
to DA.

{pstd}
R2 and pseudo-R2 statistics are good choices as a fit statistic for DA and, hisorically, have been the 
{it:only} statistics used for DA in published methodological research.  Given that DA is an extension 
of Shapley value decomposition, a general methodology for dividing up contributions between "players" 
to a "payoff," R2 statistics are not the only fit statistic that could be used.  

{pstd}
If the predictive model used does not have an R2-like statistics that can be used to evaluate its 
performance, there are three criteria to that methodologists consider useful for Shapley value 
decomposition: a] {it:monononicity} or that the statistic increases/does not decrease with inclusion 
of more IVs (without a degree of freedom adjustment such as those in information criteria), b] 
{it:linear invariance} or that the fit statistic remains the same for non-singular, linear 
transformations of the IVs, and the statistic's c] {it:information content} or that the interpretation 
of the statistic provides information about overall model fit to the data. Fit metrics that do not meet 
all three are not necessarily invalid, but may require extra caution in interpretation and may produce 
unexpected results (i.e., negative contributions to Shapley values).

{space 4}{title:6b] Considerations for Use of Dominance Analysis}

{pstd}
When using DA with cateorical or non-addtive IVs (e.g., interaction terms) the user must 
be deliberate in how they are incorporated.  In general, all indicator codes from a {help factor variable} 
should be included and excluded together as a set unless the user has a compelling reason not to do so 
(i.e., it is important for the research question to understand importance differences between categories 
of a categorical independent variable).  Similarly, DA with non-additive factor variables such as 
interactions or non-linear variables (e.g., {it:c.iv##c.iv}) could be included, as a set, with lower order 
terms or users can follow the residualization method laid out by LeBreton, Tonidandel, and Krasikova (2013; 
see Example #4) unless there is a compelling reason not to do so.  Note that the set-based approach to 
grouping interactions, in particular, is experimental for linear models.

{pstd}
Models that are intrinsically non-additive such as {stata findit rforest:rforest} (see Example #11) or 
{stata findit boost:boost} can also be used with Shapley value decomposition methods and several 
implementations such as the {browse "https://pypi.org/project/sage-importance/":Python package SAGE} and 
the {browse "https://CRAN.R-project.org/package=vimp":R package vimp} are available to do so.  Such methods 
focus on estimating general dominance statistics and are approximations like the {opt epsilon} method.  As 
such, DA is not an identical, but similar method to each of these implementations that 
can be applied to smaller-scale machine learning models; it is recommended that the user not exceed 
around 25 IVs simultaneously.  This recommendation also applies to any linear models as well.

{pstd}
{help bootstrap}ping can also be applied to DA to produce standard errors for any dominance statistics 
(see Example #5).  Although standard errors {it:can} be produced, the sampling distribution for dominance 
statistics have not been extensively studied and the information provided by the standard errors is usually 
similar to that offered by conditional and complete dominance results.  Obtaining standard errors is 
thus most useful, and practical to implement, for the {opt episilon} method.  {help permute} tests 
can also be obtained to evaluate statistical differences between dominance statistics.

{pstd}
Although {cmd:domin} does not accept the {help svy} prefix it does accept {cmd:pweight}s for commands 
in {opt reg()} that also accept them.  To adjust the DA for a sampling design in complex survey data the 
user need only provide {cmd:domin} the {cmd:pweight} variable for commands that accept {cmd:pweight}s 
(see Luchman, 2015).  

{space 4}{title:6c] Extending Models that can be Dominance Analyzed}

{pstd}{cmd:domin} comes with 4 wrapper programs {cmd:mvdom}, {cmd:mixdom}, {cmd:fitdom}, and {cmd:mi_dom}.  

{pstd}{cmd:mvdom} implements multivariate regression-based dominance analysis described by Azen and Budescu (2006; see {help mvdom}).  

{pstd}{cmd:mixdom} implements linear mixed effects regression-based dominance analysis described by Luo and Azen (2013; see {help mixdom}).  

{pstd}Both programs are intended to be used as wrappers into {cmd:domin} and serve to illustrate how the user can 
also adapt existing regressions (by Stata Corp or user-written) to evaluate in a relative importance analysis 
when they do not follow the traditional {it:depvar indepvars} format.  As long as the wrapper program can 
be expressed in some way that can be evaluated in {it:depvar indepvars} format, any analysis could be 
dominance analyzed. 

{pstd}Any program used as a wrapper by {cmd:domin} must accept an {help if} statement, a comma, and at least one (possibly optional) option argument in its {help syntax}.
It is recommended that wrapper programs parse the inputs as a {it:varlist} as well (see Example #9a).

{pstd}A third wrapper program, {cmd:fitdom}, takes inspiration from the 
{browse "https://CRAN.R-project.org/package=domir":R package domir} as it serves as a wrapper for a postestimation 
command that produces a fit metric such as {help estat ic} or {help estat classification} (see Example #9b and #11; see also {help fitdom}).

{pstd}This program allows postestimation commands that return fit metrics to be used directly in {cmd:domin} 
without having to make a wrapper program for the entire model (i.e., as in Example #9a).

{pstd}The fourth wrapper program, {cmd:mi_dom}, is a replacement for {cmd:domin}'s built in {opt mi} in versions 
previous to 3.5  (see Example #10; see also {help mi_dom}).  

{pstd}This program allows multiply imputed model fit statistics to be used in place 
of fit statistics with missing data. Use of multiply imputed fit statistics can 
reduce the bias of coefficient estimates and dominance statistics when the imputation model is informative.

{marker refs}{...}
{title:7. References}

{p 4 8 2}Azen, R. & Budescu D. V. (2003). The dominance analysis approach for comparing predictors in multiple regression. {it:Psychological Methods, 8}, 129-148.{p_end}
{p 4 8 2}Azen, R., & Budescu, D. V. (2006). Comparing predictors in multivariate regression models: An extension of dominance analysis. {it:Journal of Educational and Behavioral Statistics, 31(2)}, 157-180.{p_end}
{p 4 8 2}Azen, R. & Traxel, N. M. (2009). Using dominance analysis to determine predictor importance in logistic regression. {it:Journal of Educational and Behavioral Statistics, 34}, pp 319-347.{p_end}
{p 4 8 2}Budescu, D. V. (1993). Dominance analysis: A new approach to the problem of relative importance of predictors in multiple regression, {it:Psychological Bulletin, 114}, 542-551.{p_end}
{p 4 8 2}Gr{c o:}mping, U. (2007). Estimators of relative importance in linear regression based on variance decomposition. {it:The American Statistician, 61(2)}, 139-147.{p_end}
{p 4 8 2}Johnson, J. W. (2000). A heuristic method for estimating the relative weight of predictor variables in multiple regression. {it:Multivariate Behavioral Research, 35(1)}, 1-19.{p_end}
{p 4 8 2}LeBreton, J. M., Ployhart, R. E., & Ladd, R. T. (2004). A Monte Carlo comparison of relative importance methodologies. {it:Organizational Research Methods, 7(3)}, 258-282.{p_end}
{p 4 8 2}LeBreton, J. M., & Tonidandel, S. (2008). Multivariate relative importance: Extending relative weight analysis to multivariate criterion spaces. {it:Journal of Applied Psychology, 93(2)}, 329-345.{p_end}
{p 4 8 2}LeBreton, J. M., Tonidandel, S., & Krasikova, D. V. (2013). Residualized relative importance analysis a technique for the comprehensive decomposition of variance in higher order regression models. {it:Organizational Research Methods}, 16(3)}, 449-473.{p_end}
{p 4 8 2}Luchman, J. N. (2015). Determining subgroup difference importance with complex survey designs: An application of weighted dominance analysis. {it:Survey Practice, 8(5)}, 1–10.{p_end}
{p 4 8 2}Luchman, J. N. (2014). Relative importance analysis with multicategory dependent variables: An extension and review of best practices. {it:Organizational Research Methods, 17(4)}, 452-471.{p_end}
{p 4 8 2}Luo, W., & Azen, R. (2013). Determining predictor importance in hierarchical linear models using dominance analysis. {it:Journal of Educational and Behavioral Statistics, 38(1)}, 3-31.{p_end}
{p 4 8 2}Tonidandel, S., & LeBreton, J. M. (2010). Determining the relative importance of predictors in logistic regression: An extension of relative weight analysis. {it:Organizational Research Methods, 13(4)}, 767-781.{p_end}
{p 4 8 2}Thomas, D. R., Zumbo, B. D., Kwan, E., & Schweitzer, L. (2014). On Johnson's (2000) relative weights method for assessing variable importance: A reanalysis. {it:Multivariate Behavioral Research, 49(4)}, 329-338.{p_end} 

{title:Development Webpage}

{phang} Additional discussion of results, options, and conceptual issues on: 

{phang}{browse "https://github.com/fmg-jluchman/domin/wiki"}

{phang} Please report bugs, requests for features, and contribute to as well as follow on-going development of {cmd:domin} on:

{phang}{browse "http://github.com/fmg-jluchman/domin"}

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

{pstd}{stata findit shapley:shapley}, 
{browse "http://www.marco-sunder.de/stata/rego.html":rego}, 
{browse "https://ideas.repec.org/c/boc/bocode/s457543.html":shapley2}, 
{browse "https://CRAN.R-project.org/package=domir":R package domir}, 
{browse "https://CRAN.R-project.org/package=relaimpo":R package relaimpo},
{browse "https://cran.r-project.org/web/packages/domir/vignettes/domir_basics.html": Detailed description of Dominance Analysis}

{title:Acknowledgements}

{pstd}Thanks to Nick Cox, Ariel Linden, Amanda Yu, Torsten Neilands, Arlion N, 
Eric Melse, De Liu, Patricia "Economics student", Annesa Flentje, Felix Bittman, 
and Katherine/Kathy Chan for suggestions and bug reporting.




