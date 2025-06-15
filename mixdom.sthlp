{smcl}
{* *! version 2.2.0 December 26, 2024 J. N. Luchman}{...}
{cmd:help mixdom}
{hline}{...}

{title:Title}

{pstd}
Linear mixed effects regression wrapper program for {cmd:domin}{p_end}

{title:Syntax}

{phang}
{cmd:mixdom} {it:{help varname:depvar}} {it:{help varlist:indepvars}} [{it:{help if}}] {weight} {cmd:,} 
{opt id(levelvar)} [{opt {ul on}re{ul off}opt(re_options)} {opt {ul on}m{ul off}opt(mixed_options)}]

{phang}{cmd:pweight}s and {cmd:fweight}s are allowed (see help {help weights:weights}).  {help fvvarlist:Factor} and 
{help tsvarlist:time series variables} are allowed.  

{title:Description}

{pstd}
{cmd:mixdom} is a specialized {help mixed:linear mixed effects regression} command that is designed with a syntax structure that can be used in {help domin:dominance analysis}.
{cmd:mixdom} also returns two model fit metrics recommended for use by Luo and Azen (2013).
These two fit metrics are the the within- and between-cluster R2 metrics (Snijders & Bosker, 1994).
In addition, consistent with Luo and Azen, {cmd:mixdom} only allows for one a random intercept associated with the cluster identifier variable in {opt id()}.
For an example, see {cmd:domin}'s {help domin##examp:Example #8}.

{pstd}
{cmd:mixdom} is intended for use only as a wrapper program with {cmd:domin} and is not recommended for use as an estimation command outside of {cmd:domin}. 
As of version 2.2.0, {cmd:mixdom} is compatible with {cmd:domin}'s {help mi_dom} wrapper command. 
To do so, {cmd:mixdom} returns uninformative {cmd:b} and {cmd:V} matrices that are both values of 1.
This is because {cmd:mixdom} is intended to be used only for its fit statistics and these two matrices are irrelevant for dominance analysis.

{pstd}
Note that negative R2 values indicate likely model misspecification.

{marker options}{...}
{title:Options}

{phang}{opt id()} is a required option that passes the clustering variable, {it:levelvar}, or cluster "id"entifier to {cmd:mixed}. 
This is the variable that would appear after the random effects specification (i.e., {cmd:||}) in the {cmd:mixed} syntax. 
For example, the command:

{pmore}{cmd:mixdom depvar indepvars, id(levelvar)} 

{pmore}would be passed to {cmd:mixed} as:

{pmore}{cmd:mixed depvar indepvars || levelvar:}

{phang}{opt reopt()} passes options to the random intercept of {cmd:mixed} that will be included following its comma (e.g., {opt pweight()}).

{phang}{opt mopt()} passes options to {cmd:mixed} that will be included following its comma (e.g., {opt pwscale()}).
This option was named {opt xtmopt()} in {cmd:mixdom} versions previous to 2.0.0 and is now defunct.

{title:Saved results}

{phang}{cmd:mixdom} saves the following results to {cmd: e()}:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:e(r2_w)}}within-cluster R2{p_end}
{synopt:{cmd:e(r2_b)}}between-cluster R2{p_end}
{p2col 5 15 19 2: macros}{p_end}
{synopt:{cmd:e(title)}}title in estimation output{p_end}
{synopt:{cmd:e(cmd)}}{cmd:mixdom}{p_end}
{p2col 5 15 19 2: matrices}{p_end}
{synopt:{cmd:e(b)}}1; required for {cmd:mi_dom}{p_end}
{synopt:{cmd:e(V)}}1; required for {cmd:mi_dom}{p_end}
{p2col 5 15 19 2: functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{title:References}

{p 4 8 2}Luo, W., & Azen, R. (2013). Determining predictor importance in hierarchical linear models using dominance analysis. {it:Journal of Educational and Behavioral Statistics, 38(1)}, 3-31.{p_end}
{p 4 8 2}Snijders, T. A. B., & Bosker, R. J. (1994). Modeled variance in two-level models. {it:Sociological Methods & Research, 22(3)}, 342-363.{p_end}

{title:Author}

{p 4}Joseph N. Luchman{p_end}
{p 4}Research Fellow{p_end}
{p 4}Fors Marsh{p_end}
{p 4}Arlington, VA{p_end}
{p 4}jluchman@forsmarsh.com{p_end}

{title:Also see}

{psee}
{manhelp mixed R}.
{p_end}
