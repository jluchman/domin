# Dominance Analysis
## A Stata Implementaion

Dominance analysis (DA) determines the relative importance of independent variables in an estimation model based on contribution to an overall model fit statistic (see Grömping, 2007 for a discussion).  DA is an ensemble method in which importance determinations about independent variables are made by aggregating results across multiple models, though the method usually requires the ensemble contain each possible combination of the independent variables in the full model.  

The all possible combinations ensemble with p independent variables in the full model results in 2^p-1 models estimated.  That is, each combiation of p variables alterating between included versus excluded (i.e., the 2 base to the exponent) where the constant[s]-only model is omitted (i.e., the -1 representing the distinct combination where no independent variables are included; see Budescu, 1993).

`domin` is implemented as a flexible wrapper command that can be used with most Stata estimation commands that follow the standard `depvar indepvars` format and return a scalar-valued fit metric; commands that do not can be accommodated with a sub-wrapper command (an example of this is included below).

Some examples of the command as applied to Stata estimation commands are shown below.

## Simple Linear Regression-based DA

The default analysis for `domin` is `regress` with `fitstat(e(r2))` and these do not need to be typed (though if they are not, `domin` will throw a warning).  The results of the analysis are shown as below including general, conditional, and complete dominance results as well as the strongest dominance designations.

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
-more-
```

### General Dominance Statistics

General dominance statistics are the most commonly reported and easiest to interpret. General dominance statistics are derived as a weighted average marginal/incremental contribution to the overall fit statistic an independent variable makes across all models in which the independent variable is included.  For example, _rep78_ has a larger general dominance statistic than, and thus "generally dominates", independent variable _headroom_.  If general dominance statistics are equal for two independent variables, no general dominance designation can be made between those independent variables.

General dominance statistics distill the entire ensemble of models into a single value for each independent variable, which is why they are easiest to interpret. In addition, a useful property of the general dominance statistics is that they are an additive decomposition of the fit statistic associated with the full model (i.e., the general dominance statistics can be summed to obtain the value of the full model's fit statistic).  Thus, general dominance statistics are equivalent to Shapley values (see `findit shapley`).  General dominance statistics are the arithmetic average of all conditional dominance statistics discussed next.


```
Conditional dominance statistics
-------------------------------------------------------------------------------------

           #indepvars:  #indepvars:  #indepvars:
                    1            2            3
     mpg       0.2079       0.2262       0.2445
   rep78       0.0000       0.0218       0.0436
headroom       0.0124       0.0094       0.0065
-------------------------------------------------------------------------------------
-more-
```

### Conditional Dominance Statistics

Conditional dominance statistics are also derived from the all possible combinations ensemble.  Conditional dominance statistics are computed as the average incremental contributions to the overall model fit statistic within a single "order" for models in which the independent variable is included - where "order" refers to a distinct number of independent variables in the estimation model.  One order is thus all models that include one independent variable.  Another order is all models that include two independent variables, and so on to p - or the order including only the model with all p independent variables.  Each independent variable will then have p different conditional dominance statistics.  In the example above, there are three conditional dominance statistics for each independent variable because there are three independent variables

The evidence conditional dominance statistics provide with respect to relative importance is stronger than that provided by general dominance statistics.  Because general dominance statistics are the arithmetic average of all p conditional dominance statistics, conditional dominance statistics, considered as a set, provide more information about each independent variable or, alternatively, are less "averaged" than general dominance statistics. Conditional dominance statistics also provide information about independent variable redundancy, collinearity, and suppression effects as the user can see how the inclusion of any independent variable is, on average, affected by the inclusion of other independent variables in the estimation model in terms of their effect on model fit.  In the above conditional dominance matrix, observe the difference between the patterns of results for _rep78_ and _headroom_.  _rep78_ shows stronger suppression-like effects in that it grows in predictive usefulness with more independent variables.  By contrast, _headroom_ shows the opposite pattern shrinking in importance.

For example, _mpg_ has larger conditional dominance statistics than independent variable _rep78_ across all three orders and thus "conditionally dominates".  To be more specific, for an independent variable conditionally dominate another, its conditional dominancer statistic must be larger than the other across all p orders.  If, at any order, the conditional dominance statistics for two independent variables are equal or there is a change rank order no conditional dominance designation can be made between those independent variables.  Conditional dominance imples general dominance as well, but the reverse is not true.  An independent variable can generally dominate another, but not conditionally dominate it.  For instance, _rep78_ generally dominance but does not conditionally dominate _headroom_.

```
Complete dominance designation
-------------------------------------------------------------------------------------

                      dominated?:  dominated?:  dominated?:
                             mpg        rep78     headroom
     dominates?:mpg            0            1            1
   dominates?:rep78           -1            0            0
dominates?:headroom           -1            0            0
-------------------------------------------------------------------------------------
```

### Complete Dominance Designations

Complete dominance designations are the final designation derived from the all possible combinations ensemble.  Complete dominance designations are made by comparing all possible incremental contributions to model fit for two independent variables. The evidence the complete dominance designation provides with respect to relative importance is the strongest possible, and supercedes that of general and conditional dominance.  Complete dominance is the strongest evidence as it is completely un-averaged and pits each independent variable against one another in every possible comparison.  Thus, it is not possible for some good incremental contributions to compensate for some poorer incremental contributions as can occur when such data are averaged.  Complete dominance then provides information on a property of the entire ensemble of models, as it relates to a comparison between two independent variables.

For example, _mpg_ has a larger incremental contribution to model fit than _headroom_ across all possible comparisons and "completely dominates" it. As with conditional dominance designations, for an independent variable to completely dominate another, the incremental contribution to fit associated with that independent variable for each of the possible 2^(p-2) comparisons with another must all be larger than another.  If, for any comparison, the incremental contribution to fit for two independent variables are equal or there is a change in rank order, no complete dominance designation can be made between those independent variables.  Complete dominance imples both general and conditional dominance, but, again, the reverse is not true. By comparison to general and conditional dominance designations, the complete dominance designation has no natural statistic.  That said, domin returns a complete dominance matrix which reads from the left to right.  Thus, a value of 1 means that the indepdendent variable in the row completely dominates the independent variable in the column.  Conversely, a value of -1 means the opposite, that the independent variable in the row is completely dominated by the independent variable in the column.  A 0 value means no complete dominance designation could be made as the comparison independent variables' incremental contributions differ in relative magnitude from model to model.

```
Strongest dominance designations

mpg completely dominates rep78
mpg completely dominates headroom
rep78 generally dominates headroom
```

### Strongest Dominance Designtions

Finally, if all three dominance statistics are reported (i.e., `noconditional` and `nocomplete` options are not used), a "strongest dominance designations" list is reported.  The strongest dominance designations list reports the strongest dominance designation between all pairwise, independent variable comparisons.


## Ordered Logistic Regression

A model like `ologit` is easy to accommodate in `domin` like below.

```
. domin rep78 trunk weight length, reg(ologit) fitstat(e(r2_p)) all(turn)

Total of 7 regressions

General dominance statistics: Ordered logistic regression
Number of obs             =                      69
Overall Fit Statistic     =                  0.1209
All Subsets Fit Stat.     =                  0.1003

            |      Dominance      Standardized      Ranking
 rep78      |      Stat.          Domin. Stat.
------------+------------------------------------------------------------------------
 trunk      |         0.0082      0.0680            2 
 weight     |         0.0021      0.0174            3 
 length     |         0.0102      0.0845            1 
-------------------------------------------------------------------------------------
Conditional dominance statistics
-------------------------------------------------------------------------------------

         #indepvars:  #indepvars:  #indepvars:
                  1            2            3
 trunk       0.0131       0.0077       0.0039
weight       0.0027       0.0016       0.0020
length       0.0139       0.0097       0.0070
-------------------------------------------------------------------------------------
Complete dominance designation
-------------------------------------------------------------------------------------

                    dominated?:  dominated?:  dominated?:
                         trunk       weight       length
 dominates?:trunk            0            1           -1
dominates?:weight           -1            0           -1
dominates?:length            1            1            0
-------------------------------------------------------------------------------------

Strongest dominance designations

length completely dominates trunk
trunk completely dominates weight
length completely dominates weight

Variables included in all subsets: turn
```

As compared to the `regress`-based DA reported in the first example, this example includes a covariate that is controlled for across all model subsets.  The `All Subsets Fit Stat.     =                  0.1003` result represents the amount of the McFadden pseudo-R-square that is associated with the variable in all subsets (i.e., in `all()').  Note that the dominance statistics reported are now residualized and reflect the removal of the all fitstats fit statistic.  Variables included in all subsets are also reported at the end of the results display (e.g., `Variables included in all subsets: turn`).

