# Dominance Analysis
## A Stata Implementaion

Dominance analysis (DA) determines the relative importance of independent variables in an estimation model based on contribution to an overall model fit statistic (see Grömping, 2007 for a discussion).  DA is an ensemble method in which importance determinations about independent variables are made by aggregating results across multiple models, though the method usually requires the ensemble contain each possible combination of the independent variables in the full model.  

The all possible combinations ensemble with p independent variables in the full model results in 2^p-1 models estimated.  That is, each combiation of p variables alterating between included versus excluded (i.e., the 2 base to the exponent) where the constant[s]-only model is omitted (i.e., the -1 representing the distinct combination where no independent variables are included; see Budescu, 1993). domin derives 3 statistics from the 2^p-1 estimation models.

`domin` is a flexible wrapper command that can be used with most Stata estimation commands.  Some examples of the command as applied to Stata estimation commands are shown below.

## Simple linear regression-based DA

The default analysis for `domin` is `regress` with `fitstat(e(r2))` and these do not need to be typed (though they will throw a warning).  The results of the analysis are shown as below including general, conditional, and complete dominance results as well as the strongest dominance designations.

```
.    webuse auto
(1978 Automobile Data)

.     domin price mpg rep78 headroom
Regression type not entered in reg(). 
reg(regress) assumed.

Fitstat type not entered in fitstat(). 
fitstat(e(r2)) assumed.


Total of 7 regressions

General dominance statistics: Linear regression
Number of obs             =                      69
Overall Fit Statistic     =                  0.2575

            |      Dominance      Standardized      Ranking
 price      |      Stat.          Domin. Stat.
------------+------------------------------------------------------------------------
 mpg        |         0.2262      0.8787            1 
 rep78      |         0.0218      0.0847            2 
 headroom   |         0.0094      0.0366            3 
-------------------------------------------------------------------------------------
Conditional dominance statistics
-------------------------------------------------------------------------------------

           #indepvars:  #indepvars:  #indepvars:
                    1            2            3
     mpg       0.2079       0.2262       0.2445
   rep78       0.0000       0.0218       0.0436
headroom       0.0124       0.0094       0.0065
-------------------------------------------------------------------------------------
Complete dominance designation
-------------------------------------------------------------------------------------

                      dominated?:  dominated?:  dominated?:
                             mpg        rep78     headroom
     dominates?:mpg            0            1            1
   dominates?:rep78           -1            0            0
dominates?:headroom           -1            0            0
-------------------------------------------------------------------------------------

Strongest dominance designations

mpg completely dominates rep78
mpg completely dominates headroom
rep78 generally dominates headroom
```
