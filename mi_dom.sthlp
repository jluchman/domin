{smcl}
{* *! version 0.0.2 August 13, 2024 J. N. Luchman}{...}
{cmd:help mi_dom}
{hline}{...}

{title:Title}

{pstd}
Wrapper program for {cmd:domin} to obtain multiply imputed fit statistics {p_end}

{title:Syntax}

{phang}
{cmd:mi_dom} {it:depvar} {it:indepvars} {it:{help if} {weight}} {cmd:,} 
{opt {ul on}r{ul off}eg_mi(command[, command_options])} 
{opt {ul on}f{ul off}itstat_mi(scalar)}
[{opt {ul on}MIO{ul off}pt(string)}]

{phang}
{help fvvarlist: Factor} and {help tsvarlist:time series variables} are allowed for commands in {opt reg_mi()} 
that accept them. {cmd:aweight}, {cmd:iweight}s, {cmd:pweight}s, and {cmd:fweight}s are also allowed 
(see help {help weights:weights}) for commands in {opt reg_mi()} that accept them.

{title:Description}

{pstd}
{cmd:mi_dom} adds an additional layer to {cmd:domin} in which the user calls the {cmd:mi_dom} program in 
{cmd:domin} and the {cmd:mi_dom} program runs the {cmd:mi estimate} compatible command in {opt reg_mi()}, 
saves results for all multiply imputed datasets, and then averages them before submitting them as 
{cmd:e(fitstat)} for use in the dominance analysis.

{pstd}
This wrapper command is a replacement for the built in {opt mi} in {cmd:domin} versions prior to 3.5 and is 
intended to add flexiblity to how {cmd:domin} can accommodate multiply imputed data. See Example #10 in the 
{cmd:domin} helpfile for an example of {cmd:mi_dom} in use.

{marker options}{...}
{title:Options}

{phang}{opt reg_mi()} is the contents of the {opt reg()} option that would normally be supplied to {cmd:domin}.

{phang}{opt fitstat_mi()} is the contents of the {opt fitstat()} option that would normally be supplied 
to {cmd:domin}.

{phang}{opt miopt()} are the options passed to {cmd:mi estimate} that will be filled in prior to the colon. 
This produces a command structure like {it:mi estimate, miopts: reg_mi} for each run of the command in 
{opt reg_mi()}.

{title:Saved results}

{phang}{cmd:mi_dom} saves the following results to {cmd: e()}:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:e(fitstat)}}The value of the fit statistic called by {opt postestimation}{p_end}
{p2col 5 15 19 2: macros}{p_end}
{synopt:{cmd:e(title)}}Adds "Mulltiply Imputed:" to the {cmd:e(title)} of the command in {opt reg_mi()}{p_end}
{p2col 5 15 19 2: functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{title:Author}

{p 4}Joseph N. Luchman{p_end}
{p 4}Research Fellow{p_end}
{p 4}Fors Marsh{p_end}
{p 4}Arlington, VA{p_end}
{p 4}jluchman@forsmarsh.com{p_end}
