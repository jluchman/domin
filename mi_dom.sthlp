{smcl}
{* *! version 0.0.4 January 1, 2025 J. N. Luchman}{...}
{cmd:help mi_dom}
{hline}{...}

{title:Title}

{pstd}
Multiple imputation wrapper program for {cmd:domin} {p_end}

{title:Syntax}

{phang}
{cmd:mi_dom} {it:depvar} {it:indepvars} {it:[{help if}] {weight}} {cmd:,} 
{opt {ul on}r{ul off}eg_mi(command[, command_options])} 
{opt {ul on}f{ul off}itstat_mi(scalar)}
[{opt {ul on}mio{ul off}pt(mi_opts)}]

{phang}
{help fvvarlist: Factor} and {help tsvarlist:time series variables} are allowed for commands in {opt reg_mi()} 
that accept them. {cmd:aweight}, {cmd:iweight}s, {cmd:pweight}s, and {cmd:fweight}s are also allowed 
(see help {help weights:weights}) for commands in {opt reg_mi()} that accept them.

{title:Description}

{pstd}
{cmd:mi_dom} is a specialized {help mi estimate:multiple imputation} command that is designed for use in {help domin:dominance analysis}.
{cmd:mi_dom} is an alternative to the {cmd:mi estimate} prefix for the dominance analysis of estimation commands that averages the fit statistics returned by individual imputations so that one submodel returns one fit statistic.
For an example, see {cmd:domin}'s {help domin##examp:Example #10}.

{pstd}
{cmd:mi_dom} is intended to be called directly by {cmd:domin} and will act as an intermediary layer of processing between {cmd:domin} and the estimation command that will use {cmd:mi estimate}.
Specifically, {cmd:mi_dom} will call the command in {opt reg_mi()} and average the results for the scalar in {opt fitstat_mi()} across all imputations.
Thus, {cmd:mi_dom} is called directly in {cmd:domin}'s {opt reg()} option.
{cmd:mi_dom}'s options are then also supplied to {cmd:domin} as command options in the {opt reg()} option.
Addiiontally, the averaged fit staistic scalar {cmd:e(fitstat)} is called directly in {cmd:domin}'s {opt fitstat()} option.

{pstd}
{cmd:mi_dom} is intended for use only as a wrapper program with {cmd:domin} and is not recommended for use as an estimation command outside of {cmd:domin}.
{cmd:mi_dom} is a replacement for the built in {opt mi} option for {cmd:domin} versions prior to 3.5.0.

{marker options}{...}
{title:Options}

{phang}{opt reg_mi()} is the command and command options implementing the predictive model that will be applied to {cmd:mi estimate}.
This option is parsed in the same way as the {opt reg()} option of {help domin##opts:domin}.

{phang}{opt fitstat_mi()} identifies the scalar returned by the command in {opt reg_mi()} that will be averaged.
This option is usedd in the same way as the {opt fitstat()} option of {help domin##opts:domin}.

{phang}{opt miopt()} are options passed to {cmd:mi estimate}. 
For example, the command:

{pmore}{cmd:mi_dom depvar indepvars, miopt(mi_opts) reg_mi(command)} 

{pmore}would be passed to {cmd:mi estimate} as:

{pmore}{cmd:mi estimate, mi_opts: command depvar indepvars}

{title:Saved results}

{phang}{cmd:mi_dom} saves the following results to {cmd: e()}:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:e(fitstat)}}The value of the averaged fit in {opt fitstat_mi()} across all imputations{p_end}
{p2col 5 15 19 2: macros}{p_end}
{synopt:{cmd:e(title)}}Adds "Mulltiply Imputed:" to the {cmd:e(title)} of the command in {opt reg_mi()}{p_end}
{p2col 5 15 19 2: functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample; all missing observations on {it:depvar} and {it:indepvars} are assumed to be complete{p_end}

{title:Author}

{p 4}Joseph N. Luchman{p_end}
{p 4}Research Fellow{p_end}
{p 4}Fors Marsh{p_end}
{p 4}Arlington, VA{p_end}
{p 4}jluchman@forsmarsh.com{p_end}
