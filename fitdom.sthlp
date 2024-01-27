{smcl}
{* *! version 0.1.0 August 14, 2023 J. N. Luchman}{...}
{cmd:help fitdom}
{hline}{...}

{title:Title}

{pstd}
Wrapper program for {cmd:domin} to obtain fit statistics from postestimation commands {p_end}

{title:Syntax}

{phang}
{cmd:fitdom} {it:depvar} {it:indepvars} {it:{help if} {weight}} {cmd:,} 
{opt {ul on}p{ul off}ostestimation(command, command_options)} 
{opt {ul on}r{ul off}eg_fd(command, command_options)} 
{opt {ul on}f{ul off}itstat_fd(scalar)}

{phang}
{help fvvarlist: Factor} and {help tsvarlist:time series variables} are allowed for commands in {opt reg_fd()} 
that accept them. {cmd:aweight}, {cmd:iweight}s, {cmd:pweight}s, and {cmd:fweight}s are also allowed 
(see help {help weights:weights}) for commands in {opt reg_fd()} that accept them.

{title:Description}

{pstd}
{cmd:fitdom} adds an additional layer to {cmd:domin} in which the user calls the {cmd:fitdom} program in 
{cmd:domin} and the {cmd:fitdom} program calls the desired regression model for use in the dominance analysis.

{pstd}
This wrapper command is intended to simplify and extend how {cmd:domin} can be used with official and 
user-contributed commands.  {cmd:fitdom} extends the capabilities of {cmd:domin} by allowing for 
any postestimation command that returns a scalar-valued fit statistic to be used in the dominance 
analysis.  The intention of this wrapper command is to provide a tool that can assist the user in 
avoiding the need for programming a wrapper command to apply a non-built-in fit statistic.

{pstd}
This wrapper command takes inspration from the R package
{browse "https://CRAN.R-project.org/package=domir":domir} and its adaptation of the fitstat concept from Stata's 
{cmd:domin} command.

{marker options}{...}
{title:Options}

{phang}{opt postestimation()} is name of the postestimation command called by {cmd:fitdom}.  The command 
called by this option can also be called with its own options.

{phang}{opt reg_fd()} is the contents of the {opt reg()} option that would normally be supplied to {cmd:domin}.

{phang}{opt fitstat_fd()} is the contents of the {opt fitstat()} option that would normally be supplied 
to {cmd:domin}.

{title:Saved results}

{phang}{cmd:fitdom} retains all the results from the command in {opt reg_fd()} and adds the following results to {cmd: e()}:

{synoptset 16 tabbed}{...}
{p2col 5 15 19 2: scalars}{p_end}
{synopt:{cmd:e(fitstat)}}The value of the fit statistic called by {opt postestimation}{p_end}

{title:Usage and Examples}

{pstd}{ul on}{bf:Usage Principles}{ul off}

{pstd}
{cmd:fitdom} is only intended for use as an entry to the {opt reg()} option of {cmd:domin}.  In situations 
where the user would like to implement {cmd:fitdom} it is used in place of the regression model as the entry 
to the {opt reg()} option in {cmd:domin}.  The usual entries to {cmd:domin} are submitted as options to the 
{cmd:fitdom} command along with the name of the postestimation command.

{pstd}
{cmd:e(fitstat)} is always used as the entry to the {opt fitstat()} option of {cmd:domin}.

{pstd}
Entries in {opt fitstat_fd()} can be ereturned, returned, or other matrcies in memory so long as they are 
subscripted to select a specific scalar from the matrix.

{pstd}{ul on}{bf:Detailed Example}{ul off}

{pstd}
{cmd:fitdom} offers additional flexibility in using official and user-contributed fit statistic-generating 
commands in {cmd:domin} while avoiding programming your own wrapper command when you would like to use a 
fit statistic that is not returned by the command itself.

{pstd}
To illustrate the use of the wrapper command, imagine you were interested in testing a model such as:

{pstd}
{cmd:logit foreign length turn displacement}

{pstd}
with the {stata sysuse auto} data and applying the user contributed command on SSC {cmd:r2o} 
(see {stata findit r2o}) as an alternative fit statistic for the {cmd:logit} model.  Hence, the 
sequence of steps the user wants to do is something like:

{pstd}
{cmd:logit foreign length turn displacement}

{pstd}
{cmd:r2o}

{pstd}
This would run the original model and then call the fit statistic-generating postestimation command.  Encoding 
this into {cmd:domin} to run the dominance analysis with the above logit model but using the {cmd:r2o} fit 
statistic would result in a {cmd:domin} command like:

{pstd}
{cmd:domin foreign length turn displacement, reg(fitdom, reg_fd(ologit) fitstat_fd(r(r2o)) postestimation(r2o)) fitstat(e(fitstat))}

{pstd}
A key first point of note is that the command submitted to {cmd:domin} is {cmd:fitdom} and not {cmd:logit}. 
Rather, {cmd:logit} is submitted as the option {opt reg_fd()} to {cmd:fitdom}.  Similarly, note that the 
{opt fitstat()} submitted to {cmd:domin} is {cmd:e(fitstat)}, the returned value from {cmd:fitdom}, and not 
the returned value from the {cmd:r2o} command we seek to use.  

{pstd}
In order to use the {cmd:r2o} postestimation command, it has to be put into the 
{opt postestimation()} option of {cmd:fitdom}.  This tells {cmd:fitdom} to, after running the command in 
the {opt reg_fd()} option, use the command in the {opt postestimation()} option.  The entry in the 
{opt fitstat_fd()} option points {cmd:fitdom} to the name of the scalar-valued fit statistic 
to rename and return as {cmd:e(fitstat)} so {cmd:domin} can use it in the dominance analysis.

{pstd}
Imagine the analysis also calls for dominance analyzing the Akaike information criterion/AIC with {cmd:estat ic}.  
An approach using the AIC would look something like:

{pstd}
{cmd:domin foreign length turn displacement, reg(fitdom, reg_fd(logit) fitstat_fd(r(S)[1,6]) postestimation(estat ic)) fitstat(e(fitstat)) reverse consmodel}

{pstd}
Because {cmd:estat ic} does not return a single value, but a matrix, the user has to submit not only the returned 
matrix name (i.e., {cmd:r(S)}) but also the matrix subscript selecting the AIC in the first row and sixth column. 

{title:Author}

{p 4}Joseph N. Luchman{p_end}
{p 4}Research Fellow{p_end}
{p 4}Fors Marsh{p_end}
{p 4}Arlington, VA{p_end}
{p 4}jluchman@forsmarsh.com{p_end}
