*! fitdom version 0.1.1  12/20/2024 Joseph N. Luchman
**# Program definition
program define fitdom, eclass
version 16
syntax varlist(min = 1 ts fv) if [aw pw iw fw] , [Reg_fd(string) Postestimation(string) Fitstat_fd(string)]
**# Parse varlist
gettoken dv ivs: varlist	//parse varlist line to separate out dependent from independent variables
gettoken reg regopts: reg_fd, parse(",")	//parse reg() option to pull out estimation command options
if strlen("`regopts'") gettoken erase regopts: regopts, parse(",")	//parse out comma if one is present
**# Implement estimation command
`reg' `dv' `ivs' [`weight'`exp'] `if', `regopts'
**# Postestimation command for estimation command
`postestimation'
**# Return values
ereturn scalar fitstat = `=`fitstat_fd''
end
/* programming notes and history
- fitdom version 0.0.0 - Nov 21, 2021 
 ---
 fitdom version 0.1.0 - August 14, 2023
-  minimum version 15 consistent with base -domin-
// 0.1.1 - December 20, 2024
-  minimum version to 16 consistent with base -domin-