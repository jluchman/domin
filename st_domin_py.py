from sys import argv as use_stata_arguments
import itertools as it
import sfi
#import pickle                                                                                      # for passing data back to Stata without making the result -global- << necessary? >>
#import functools as ft                                                                             # key module for summing << necessary? >>
import statistics as stat
from math import factorial as fctl


#print(use_stata_arguments) #//

Stata_Regression = use_stata_arguments[1]
Dep_Var = use_stata_arguments[2]
Indep_Vars_Unprocessed = use_stata_arguments[3]
AllSubsets_Indep_Vars = use_stata_arguments[4]
If_Conditions = use_stata_arguments[5]
Regress_Options = use_stata_arguments[6]
Fit_Statistic = use_stata_arguments[7]
Mult_Impute_Flag = use_stata_arguments[8]
Mult_Impute_Opts = use_stata_arguments[9]
FitStat_Adjustment = float(use_stata_arguments[10])
Conditional_Flag = not bool(len(use_stata_arguments[11]))
Complete_Flag = not bool(len(use_stata_arguments[12]))



    # ~~ Create independent variable list ~~ #
    
Indep_Var_List = Indep_Vars_Unprocessed.strip().split("<") # parses IV sets, if any (individual IVs unprocessed)

#print(Indep_Var_List) #//

if len(Indep_Var_List[0]) > 0:
    Indep_Var_List = ( Indep_Var_List[0].strip().split(" ") + 
        Indep_Var_List[1:len(Indep_Var_List)] ) # if there are only individual IVs, or if there are invidual IVs and IV sets, parse individual IVs(and include IV sets if any)
else:
    Indep_Var_List = Indep_Var_List[1:len(Indep_Var_List)] # otherwise, remove the "empty" space that's produced by the missing individual IVs

#Indep_Var_List = [i.replace(">","").strip() for i in Indep_Var_List]                                               # the trailing ">"'s still remain from each set; here they is removed   << needed with Python? >>

#print(Indep_Var_List) #//


    # ~~ Create independent variable combination list ~~ #
    
Combination_List = list(map(it.combinations, # use map() function to apply combinations function to ...
                            list(it.repeat(Indep_Var_List, len(Indep_Var_List))), #... the IV list - which is repeated so that...
                            range(1, len(Indep_Var_List)+1))) # ... each number of combinations of a specific number of elements can be applied to get all possible combinations (note: saved as a combination object to be evaluated later and not as the list of combinations)

#print(Combination_List) #//

Total_Indep_Vars = len(Combination_List) # number of IVs in model
Total_Models_to_Estimate = 2**Total_Indep_Vars - 1 # total number of models to estimate

if Total_Indep_Vars > 4:
    sfi.SFIToolkit.stata("display \"{txt}Total of {res}" + str(2**len(Indep_Var_List)-1) + 
        " {txt}regressions\"")
    
    sfi.SFIToolkit.stata("display \"{txt}Progress in running all regression subsets\" _newline " + 
        "\"{res}0%{txt}{hline 6}{res}50%{txt}{hline 6}{res}100%\"")


    # ~~ Define function to call regression model in Stata ~~ #
    
# ~~ adding in model #'s -- for some reason adding in model #'s affects "Model_Increments"  ~~ #
    
def st_model_call(Indep_Var_combination, report): #, print_it, last):             << need to add in the printing business
    #if len(specs)>=5:
    #   if print_it and last: print(".")
    #   elif print_it: print(".", end="")
    
    #print("quietly " + use_stata_arguments[1] + " " + use_stata_arguments[2] + " " + 
    #" ".join(specs) + " " + use_stata_arguments[4] + " if " + use_stata_arguments[5] + "," + 
    #use_stata_arguments[6])
    
    sfi.SFIToolkit.stata( "quietly " +
                         Stata_Regression + " " + 
                         Dep_Var + " " +   
                         " ".join(Indep_Var_combination) + " " +
                         AllSubsets_Indep_Vars +
                         " if " + If_Conditions +
                          "," + Regress_Options )
    
    if report: print(".", end="") #//
    
    #print(sfi.Scalar.getValue(use_stata_arguments[7]))
    
    return( (Indep_Var_combination,
             sfi.Scalar.getValue(Fit_Statistic)) ) # << include coefficients, vcov, others?? >>


    # ~~ Obtain all subsets regression results ~~ #
    
Ensemble_of_Models = [] # initialize ensemble list container

"""
'Ensemble_of_Models' is structured such that:
1. Top level is results by number of IVs in the model
2. Middle level is model within a number of IVs
3. Bottom level is a specific result from 'st_model_call'
"""

place_begin = 0
place_end= 0
if Total_Indep_Vars > 4: flag_list = [int(twentieth/20*Total_Models_to_Estimate) for twentieth in range(1,21)]
else: flag_list = []
    
for number_of_Indep_Vars in range(Total_Indep_Vars): # applying the modeling function across all IV combinations at a distinct number of IVs
    
    #print(fctl(Total_Indep_Vars-(number_of_Indep_Vars+1))) #//
    
    place_end = place_end + fctl(Total_Indep_Vars)/(fctl(number_of_Indep_Vars+1)*fctl(Total_Indep_Vars-(number_of_Indep_Vars+1)))
    
    flaggs = [x in flag_list for x in range(int(place_begin), int(place_end))]
    
    #print(flaggs) #//
    
    Models_at_Indep_Var_number = list( map(st_model_call,
                                   list(Combination_List[number_of_Indep_Vars]), flaggs ) )
    
    Ensemble_of_Models.append(Models_at_Indep_Var_number)
    
    place_begin = place_end


#print("All the results:", Ensemble_of_Models) #//

    # ~~ Process all subsets - find the increments  ~~ #
Model_List = [[list(model) for model in Ensemble_of_Models[0]]]  # evaluate the map-ped models and record them - start with the single IV models...
for model in range(len(Model_List[0])): # ...for the single IV models...
    Model_List[0][model][1] = Model_List[0][model][1]-FitStat_Adjustment #... have to remove constant model results as well as all subets results

#print("model list:", Model_List) #//

for number_of_Indep_Vars in range(1, len(Ensemble_of_Models)): # when >1 IV in the model, processing needed...
    Model_Incremented = []  # initialize/reset container for finding subset
    Indep_Var_Set_at_1lessIndep_Var = [set(Candidate_Indep_Var_Set[0]) for Candidate_Indep_Var_Set in Ensemble_of_Models[number_of_Indep_Vars-1]] # collect all sets IVs (coerced to be a set object), specifically all sets at one less IV in the model than the current number of IVs
    #print("subsets less one", Indep_Var_Set_at_1lessIndep_Var) #//
    for model in range(0, len(Ensemble_of_Models[number_of_Indep_Vars])): # loop through all models at a specific number of IVs in the model...
        #print(set(Ensemble_of_Models[number_of_Indep_Vars][model][0])) #//
        Indep_Var_Set = set(Ensemble_of_Models[number_of_Indep_Vars][model][0]) # IV set for a focal model; coerced to be set object
        for at1less_model in range(0, len(Indep_Var_Set_at_1lessIndep_Var)): # loop through all models at one less than the specific number of IVs in the model...
            #print(Indep_Var_Set_at_1lessIndep_Var[sub].isIndep_Var_Set_at_1lessIndep_Var(superset)) #//
            if Indep_Var_Set_at_1lessIndep_Var[at1less_model].issubset(Indep_Var_Set): # if IV set at one less is a subset of the predictors in the focal model...
                Model_Incremented.append( 
                [ Ensemble_of_Models[number_of_Indep_Vars][model][0], # append IV names at focal ...
                  Ensemble_of_Models[number_of_Indep_Vars-1][at1less_model][0], # ...IV names at one less...
                  Ensemble_of_Models[number_of_Indep_Vars][model][1] - Ensemble_of_Models[number_of_Indep_Vars-1][at1less_model][1] ] # ...and the increment to the fit metric
                )
                #print(Model_Incremented)
    Model_List.append(Model_Incremented) 
        
#print("finalized all subsets/increments", Model_List) #//

"""
'Model_List' is structured such that:
1. Top level is results by number of IVs in the model
2. Middle level is model within a number of IVs
3. Bottom level is a specific increment's information (full_model, reduced_model, fit metric difference)
"""

    # ~~ Obtain complete and conditional dominance statistics  ~~ #
Conditional_Dominance = [] # conditional dominance container
if Complete_Flag: Complete_Dominance = [] # complete dominance container

#print("conditionals + Complete_Dominance") #//

for Indep_Var in range(0, len(Model_List[0])): # for each IV in the model...
    Conditional_atIndep_Var = [] # initialize/reset container for conditional dominance
    Conditional_atIndep_Var.append(Model_List[0][Indep_Var][1]) # for IV alone - copy fit statistic
    #print("When alone FitStat:", Conditional_atIndep_Var)
    Indep_Varname = set(Model_List[0][Indep_Var][0]) # record name of focal IV; coerce to set
    #print("Results for variable:", Indep_Varname) #//
    if Complete_Flag: Complete_atIndep_Var = [
        [Other_Indep_Var[1] < Model_List[0][Indep_Var][1]] # compare fit statistic values (is focal IV larger than other IV?) ...
        for Other_Indep_Var in Model_List[0][0:len(Model_List[0])] ] #... for other IVs alone (will compare to self also)
    #print("\n initialized complete dominance:", Complete_atIndep_Var) #//
    
    for number_of_Indep_Vars in range(1, len(Model_List)): # for all numbers of IVs greater than 1...
        #print("Subsets to search through:",Model_List[number_of_Indep_Vars]) 
        Relevant_Increments = [] # initialize/reset container for collecting specific/relevant conditional dominance increments
        for model in range(0, len(Model_List[number_of_Indep_Vars])): # for each individual model within a specific number of IVs...
            #print("A subset and whether full model has focal in it:",
                  #[set(Model_List[number_of_Indep_Vars][model][0]), Indep_Varname.issubset(set(Model_List[number_of_Indep_Vars][model][0]))]) #//
            #print("A subset and whether reduced model has focal not in it:",
                  #[set(Model_List[number_of_Indep_Vars][model][1]), not Indep_Varname.issubset(set(Model_List[number_of_Indep_Vars][model][1]))]) #//
            proceed_to_record = ( Indep_Varname.issubset( set(Model_List[number_of_Indep_Vars][model][0]) ) and not # flag this entry for recording if the focal IV name is in the IV set...
                         Indep_Varname.issubset( set(Model_List[number_of_Indep_Vars][model][1]) ) ) # ...but is _not_ in the IV set less one - thus, the fit statistic here is a valid "increment" for the focal IV
            #print("both are relevant?:", proceed_to_record, "\n") #//
            if proceed_to_record: 
                Relevant_Increments.append(Model_List[number_of_Indep_Vars][model][2]) # always collect the fit statistic for conditional dominance computations
                if Complete_Flag:
                    for other_model in range(0, len(Model_List[number_of_Indep_Vars])): # also proceed to collect complete dominance data using this loop comparing to all other models within this number of IVs to find relevant comparisons
                        #print("Report 'other model' and does it contain same subset as focal? (cpt):",
                              #[set(Model_List[number_of_Indep_Vars][other_model][0]), set(Model_List[number_of_Indep_Vars][model][0]).issubset(set(Model_List[number_of_Indep_Vars][other_model][0]))]) #//
                        #print("Is the difference between 'other model' and focal one variable?: (cpt)",
                              #[set(Model_List[number_of_Indep_Vars][other_model][1]), len(set(Model_List[number_of_Indep_Vars][model][1]).difference(set(Model_List[number_of_Indep_Vars][other_model][1]))) == 1]) #//
                        relevant_complete = ( # a relevant complete dominance comparsion is found when ...
                            set(Model_List[number_of_Indep_Vars][model][0]).issubset( set(Model_List[number_of_Indep_Vars][other_model][0]) ) and # ...the focal full model and the full other model have the same IV set (the only way they can be a 'subset' here) ...
                            len(set(Model_List[number_of_Indep_Vars][model][1]).difference( set(Model_List[number_of_Indep_Vars][other_model][1])) ) == 1 ) #... but their reduced IV set differs by one IV (this ensures it is not trying to compare the subset to itself)
                        #print("valid for cpt?:", relevant_complete) #//
                        if relevant_complete: 
                            #print("here goes!") #//
                            #print([Position_IV[0] for Position_IV in Model_List[0]]) #//
                            #print((set(Model_List[number_of_Indep_Vars][model][1]).difference(set(Model_List[number_of_Indep_Vars][other_model][1])).pop(),)) #//
                            MatrixLocation_Complete = [Position_IV[0] for Position_IV in Model_List[0]].index(( # when a relevant comparison, obtain the index value for ...
                                       set(Model_List[number_of_Indep_Vars][model][1]).difference( set(Model_List[number_of_Indep_Vars][other_model][1]) ).pop(), )) #... the different element in the reduced model (to place it in the correct "row" for the dominance matrix/list)
                            #print(MatrixLocation_Complete) #//
                            #print(Complete_atIndep_Var[MatrixLocation_Complete]) #//
                            Complete_atIndep_Var[MatrixLocation_Complete].append( #at the correct location in the complete dominance matrix, append...
                                Model_List[number_of_Indep_Vars][other_model][2] < Model_List[number_of_Indep_Vars][model][2] ) # ...whether the other model's increment is bigger than the focal
                            #print(Complete_atIndep_Var) #//
                        
        Conditional_atIndep_Var.append(stat.mean(Relevant_Increments)) # compute conditional dominance at number of IVs for specific IV and append
    
    Conditional_Dominance.append(Conditional_atIndep_Var) # append full row of IV's conditional dominance statistics
    if Complete_Flag: Complete_Dominance.append(Complete_atIndep_Var) # append full row of IV's complete dominance logicals/designations

if Complete_Flag:
    #print(Complete_Dominance) #//
    #print(Complete_Dominance[0]) #//
    #print(list(map(all, Complete_Dominance[0]))) #//
    Complete_Dominance = [list(map(all, Indep_Var)) for Indep_Var in Complete_Dominance] # for each focal IV, make list comprehension that flags whether at each comparison (i.e., other IV) are all entries (i.e., specific comarisons between similar models) in list True?
    #print(Complete_Dominance) #//
    Complete_Dominance = [[int(IV_Other_Compare) for IV_Other_Compare in Indep_Var] for Indep_Var in Complete_Dominance] # for each IV and other comparison, change boolean to integer for use in Stata
    #print(Complete_Dominance) #//

if Conditional_Flag:
    sfi.Matrix.create('r(cdldom)', len(Ensemble_of_Models), len(Ensemble_of_Models), 0) # create conditional dominance matrix container in Stata
    sfi.Matrix.store('r(cdldom)', Conditional_Dominance) # post conditional dominance matrix
    #print("conditional doms:", Conditional_Dominance) #//

if Complete_Flag:
    sfi.Matrix.create('r(cptdom)', len(Ensemble_of_Models), len(Ensemble_of_Models), 0) # create complete dominance matrix container in Stata
    sfi.Matrix.store('r(cptdom)', Complete_Dominance) # post complete dominance matrix
    #print("complete doms:", Complete_Dominance) #//

    ## ~~ Compute general dominance and fit statistic  ~~ ##
general = list(map(stat.mean, Conditional_Dominance)) # average conditional dominance statistics to produce general dominance
#print("general doms:", general) #//

#print(stat.fsum(general) + FitStat_Adjustment) #//
FitStat = stat.fsum(general) + FitStat_Adjustment # adjust overall fit statistic by replacing all subsets component and constant model component
sfi.Scalar.setValue('r(fs)', FitStat) # post overall fitstat

sfi.Matrix.create('r(domwgts)', 1, len(Ensemble_of_Models), 0) # create general dominance matrix container in Stata
sfi.Matrix.store('r(domwgts)', general)

sfi.Matrix.create('r(sdomwgts)', 1, len(Ensemble_of_Models), 0) # create standardized general dominance matrix container in Stata
sfi.Matrix.store('r(sdomwgts)', list(map(lambda x: x/FitStat, general)) )

general_ranks = [sorted(general, reverse = True).index(iv)+1 for iv in general]
#print(general_ranks) #//
sfi.Matrix.create('r(ranks)', 1, len(Ensemble_of_Models), 0)
sfi.Matrix.store('r(ranks)', general_ranks)
