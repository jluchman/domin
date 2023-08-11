# Dominance Analysis
## A Stata Implementaion

Dominance analysis (DA) determines the relative importance of independent variables in an estimation model based on contribution to 
an overall model fit statistic (see Grömping, 2007 for a discussion).  DA is an ensemble method in which importance determinations 
about independent variables are made by aggregating fit metrics across multiple models, though the method usually requires the 
ensemble contain each possible combination of the independent variables in the full model.

The all possible combinations ensemble with _p_ independent variables in the full model results in $2^{p}$ models and fit statistics 
estimated.  That is, each combination of _p_ variables alternating between included versus excluded (see Budescu, 1993).

`domin` is implemented as a flexible wrapper command that can be used with most Stata estimation commands that follow the 
standard `depvar indepvars` format and return a scalar-valued fit statistic; commands that do not either follow this format 
or do not return a scalar-valued fit statistic can be accommodated with a sub-wrapper command (an example of such a command is included below).

Some examples of the command as applied to Stata estimation commands are shown below after the discussion of installation.

# Installation and Updates
## Installing

To install `domin` type:

`ssc install domin` 

In the Stata Command console window.  `domin`, `domme`, and all wrapper programs are supported from Stata version `15`.

Note that the `domme` sub-modle requires the SSC package `moremata` and will ask to install this package if it is not available.

## Updating

To update `domin` once installed type:

`adoupdate domin, update`

In the Stata Command console window.

# Extensive Examples

Please see `domin`'s wiki page for examples of the method in use.

https://github.com/fmg-jluchman/domin/wiki