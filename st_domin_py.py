import sys																							# used to pull in arguments passed to Python from Stata
import itertools as it																				# key module used for collecting all combinations
import sfi																							# Stata function interface
import pickle

print(sys.argv)

iv_mat = sys.argv[3].strip().split("<")

if len(iv_mat[0])>0: iv_mat = iv_mat[0].strip().split(" ") + iv_mat[1:len(iv_mat)]
else: iv_mat = iv_mat[1:len(iv_mat)]

iv_mat = [i.replace(">","").strip() for i in iv_mat]

print(iv_mat)

tupl_agg = list(map(it.combinations, list(it.repeat(iv_mat, len(iv_mat))), 
range(1, len(iv_mat)+1)))

print(tupl_agg)

ls1 = [len(i)> 2 for i in iv_mat] 

print(ls1)

ls2 = [x==len(ls1)-1 for x in list(range(len(ls1)))]

print(ls2)

sfi.SFIToolkit.stata("display \"{txt}Total of {res}" + str(2**len(iv_mat)-1) + 
	" {txt}regressions\"")
	
sfi.SFIToolkit.stata("display \"{txt}Progress in running all regression subsets\" _newline " + 
	"\"{res}0%{txt}{hline 6}{res}50%{txt}{hline 6}{res}100%\"")
	
def st_ensemble(specs): #, print_it, last):				<< need do add in the printing business
	#if len(specs)>=5:
	#	if print_it and last: print(".")
	#	elif print_it: print(".", end="")
	#print(it.chain.from_iterable(specs))
	print("quietly " + sys.argv[1] + " " + sys.argv[2] + " " + 
	" ".join(specs) + " " + sys.argv[4] + " if " + sys.argv[5] + "," + 
	sys.argv[6])
	sfi.SFIToolkit.stata("quietly " + sys.argv[1] + " " + sys.argv[2] + " " + 
	" ".join(specs) + " " + sys.argv[4] + " if " + sys.argv[5] + "," + 
	sys.argv[6])
	print(sfi.Scalar.getValue(sys.argv[7]))
	return((" ".join(specs), sfi.Scalar.getValue(sys.argv[7])))

st_dom_agg = [""]
	
for tp_agg in range(len(tupl_agg)):
	st_dom_ret = list(map(st_ensemble, list(tupl_agg[tp_agg])))
	print(st_dom_ret)
	st_dom_agg.append(st_dom_ret)

print(st_dom_agg)

pickle.dump(st_dom_agg, open(sys.argv[8], "wb"))

"""	
for combn in tupl_agg:
	print(combn)
	print(list(combn))
	ls1 = [len(i)> 2 for i in list(combn)]
	print(ls1)
	collect = list(map(st_ensemble, list(combn))) #, ls1, ls2))
	print(collect)

	


	
	/*parse the predictor inputs*/	
	t = tokeninit(wchars = (" "), pchars = (" "), qchars = ("<>")) //set up parsing rules
	
	tokenset(t, ivs) //register the "ivs" matrix as the one to be parsed
	
	iv_mat = tokengetall(t)' //obtain all IV sets and IVs
	
	/*remove characters binding sets together (i.e., "<>")*/
	for (x = 1; x <= rows(iv_mat); x++) {
	
		if (substr(iv_mat[x], 1, 1) == "<") { //if any entry begins with "<"...
		
			iv_mat[x] = substr(iv_mat[x], 1, strlen(iv_mat[x]) - 1) //first character removed ("<")
			
			iv_mat[x] = substr(iv_mat[x], 2, strlen(iv_mat[x])) //last character removed (">")
			
		}
		
	}
	
	/*set-up and compute all n-tuples of predictors and predictor sets*/
	nvars = rows(iv_mat) //compute total # of IV sets and IVs
	
	ntuples = 2^nvars - 1 //compute total # of regressions
	
	printf("\n{txt}Total of {res}%f {txt}regressions\n", ntuples)
	
	if (nvars > 12) printf("\n{txt}Computing all predictor combinations\n")

	indicators = J(nvars, 2^nvars, .)	//set up matrix to be filled in which will generate all subsets 
	
	for (x = 1; x <= rows(indicators); x++) {	//for each row in indicators matrix...
	
		combin = J(1, 2^(x-1), 0), J(1, 2^(x-1), 1)	//make a binary matrix - start small, a zero and a 1, then 2 0's and 2 1's, etc...
		
		indicators[x, .] = J(1, 2^(nvars-x), combin)	//spread the binary matrix just created across all rows - net effect is staggering all binaries to obtain all subsets in the final matrix
		
	}
	
	indicators = indicators[|., 2\ ., .|]	//omit the first, null column
	
	indicators = (colsum(indicators) \ indicators)'	//create a "counts" column on which to sort
	
	indicators = sort(indicators, (1..cols(indicators)))	//sort, beginning with counts, followed by all other rows - net effect results in same sort order as cvpermute()
	
	indicators = indicators[|1, 2\ ., .|]'	//omit count's column created before
	
	indicators = sort(((cols(indicators)::1), indicators'), 1)[., 2..rows(indicators)+1]'	//reverse sort order, dominance() expects reversed order
	
	tuples = indicators:*iv_mat	//apply string variable names to all subsets indicator matrix
	
	/*all subsets regressions and progress bar syntax if predictors or sets of predictors is above 5*/
	display = 1 //for the display of dots during estimation - keeps track of where the regressions are - every 5% there is another "." added
	
	if (nvars > 4) {
	
		printf("\n{txt}Progress in running all regression subsets\n{res}0%%{txt}{hline 6}{res}50%%{txt}{hline 6}{res}100%%\n")
		
		printf(".")
		
		displayflush()
		
	}

	fits = (.) //dummy vector that will contain fitstats across all 
	
	for (x = 1; x <= ntuples; x++) { //here all regressions 
	
		if (nvars > 4) {
	
			if (floor(x/ntuples*20) > display) {
			
				printf(".")
				
				displayflush()
				
				display++	
				
			}
			
		}

		preds = tuples[., x]' //take the names in column "x" and transpose into row
	
		ivuse = invtokens(preds) //collpase names into single string separated by spaces
	
		if (strlen(mi) == 0) { //regular regression
		
			stata("\`reg' \`dv' \`all' " + ivuse + " [\`weight'\`exp'] if \`touse', \`regopts'", 1) //conduct regression
		
			fs = st_numscalar(st_local("fitstat")) - allfs - consfs //record fitstat omitting constant and "all" subsets values
			
		}
		
		else { //regression with "mi estimate:"
		
			stata("mi estimate, saving(\`mifile', replace) \`miopt': \`reg' \`dv' \`all' " + ivuse + ///
			" [\`weight'\`exp'] if \`keep', \`regopts'", 1) //conduct regression with "mi estimate:"
		
			stata("mi_dom, name(\`mifile') fitstat(\`fitstat') list(\`=e(m_est_mi)')", 1) //use built-in program to obtain average fitstat across imputations
			
			fs = st_numscalar("r(passstat)") - allfs - consfs //record fitstat omitting constant and "all" subsets values with "mi estimate:"
		
		}
	
		fits = (fits, fs) //add fitstat to vector of fitstats

	}
	
	fits = fits[2..ntuples + 1] //only keep non-empty fitstats (i.e., omit the first empty one)

	/*define the incremental prediction matrices and combination rules*/
	include = sign(strlen(tuples)) // matrix indicating whether variable included in any regression associated with the "fits" vector

	counts = colnonmissing(exp(ln(include))) //# of variables in each regression

	noinclude = (include:-1) //matrix indicating whether variable not included in any regression associated with the "fits" vector
	
	combsinc = J(1, ntuples, 1):*comb(nvars, counts) //matrix indicating the number of combinations at each "order"/# of predictors
	
	combsinc2 = J(1, ntuples, 1):*comb(nvars - 1, counts) //matrix indicating the number of combinations at each "order"/# of predictors - 1
	
	combsinc2 = (0, combsinc2[., 2..ntuples]) //add a 0 to # combinations.. omit first "." value
	
	combsinc = combsinc - combsinc2 //remove # of combinations for the "order" less the value at "order" - 1
	
	include = include:*combsinc //put all the adjusted combination counts into matrix when the variable is included
	
	noinclude = noinclude:*combsinc2 //put all the "order" - 1 combination counts into matrix when the variable is not included
	
	/*compute conditional dominance*/
	if (strlen(cdlcompu) == 0) {
	
		if (nvars > 5) printf("\n\n{txt}Computing conditional dominance\n")
	
		cdl = J(nvars, nvars, 0) //dummy matrix to hold conditional dominance stats
		
		/*loop over orders (i.e., # of predictors) to obtain average incremental prediction within order*/
		for (x = 1; x <= nvars; x++) { //proceed order by order
		
			cdl1 = include:^-1 //invert the counts for indluded (as it makes the within-order averages)
				
			cdl2 = noinclude:^-1 //invert the counts for non-indluded (as it makes the within-order averages)
			
			cdl1 = select(cdl1:*fits, counts:==x) //at the focal order, obtain weighted fitstats
			
			if (x > 1) { // at all orders (>1) where the marginal contribution != to the fitstat itself
			
				cdl2 = select(cdl2:*fits, counts:==x-1) //weighted marginal contribution to fitstat at order - 1
				
				cdl3 = rowsum(cdl1) + rowsum(cdl2) //sum the marginal contributions (cdl2 values are negative)
				
			}
				
			else cdl3 = rowsum(cdl1) //sum the marginal contributions @ order 1
						
			cdl[., x] = cdl3 //replace the entries in cdl with the current values of cdl3, these are the within-order averages
		
		}
		
		st_matrix("r(cdldom)", cdl) //return r-class matrix "cdldom"
	
	}
	
	/*define the full design matrix - compute general dominance (average conditional dominance across orders)*/
	design = (include + noinclude):*nvars //create matrix that will have positive and negative signs in the correct places to obtain marginals - weight by number of variables total (between-order average of within-order averages)
	
	design = design:^-1 //invert design matrix to create weights
	
	domwgts = colsum((design:*fits)') //general dominance weights created by computing product of weights and fitstats and summing for each IV
	
	fs = rowsum(domwgts) + allfs + consfs //total fitstat is then sum of gen. dom. wgts replacing the constant-only model and the "all" subsets stat

	st_matrix("r(domwgts)", domwgts) //return the general dom. wgts as r-class matrix

	sdomwgts = domwgts:*fs^-1 //generate the standardized gen. dom. wgts
	
	st_matrix("r(sdomwgts)", sdomwgts) //return the stdzd general dom. wgts as r-class matrix
	
	st_matrix("r(ranks)", mm_ranks(domwgts'*-1, 1, 1)') //return the ranks of the general dom. wgts as r-class matrix

	st_numscalar("r(fs)", fs) //return overall fit statistic in r-class scalar
	
	/*compute complete dominance*/
	if (strlen(cptcompu) == 0) {
	
		if (nvars > 5) printf("\n{txt}Computing complete dominance\n")

		cpt = J(nvars, nvars, 0) //dummy matrix for complete dominance
		
		basecpt = (J(2, 1, 1) \ J(nvars - 2, 1, 0)) //generate the "base" of the compare each 2 IVs
	
		basiscpt = cvpermutesetup(basecpt) //setup for the permutations
		
		indicator = (1::nvars) //generate "indicator" for which variables are being compared
		
		for (x = 1; x <= comb(nvars, 2); x++) {  
		
			combincpt = cvpermute(basiscpt) //invoke the current combination of 2 variables
		
			rowcol = select(combincpt:*indicator, combincpt:==1) //note the row in which both variables being comapred are located
		
			focus = select(sign(strlen(tuples)), combincpt:==1) //make a selector (1 vs. 0) matrix for pulling out all fitstats, only on focal IVs
		
			rest = select(sign(strlen(tuples)), combincpt:==0) //make a selector (1 vs. 0) matrix for pulling out all fitstats, only on non-focal IVs
			
			cptsum = 0 //used as a index for determining complete dominance for the current comparison of 2 IVs
			
			compare = focus:*fits //create matrix of fitstats that correspond only to the focal comparisons
			
			for (y = 1; y <= nvars - 1; y++) { //for each order (up to # IVs - 1)
			
				eval = select(compare, counts:==y) //on the filtered fitstat matrix, pull out comparisons at a specific order
				
				selector1 = select(focus, counts:==y) //on the indicator matrix, pull out comparisons at a specific order
				
				selector1 = colsum(selector1) //on the filtered indicator matrix of order "y", enumerate # of IVs in each model
				
				selector2 = select(rest, counts:==y) //on the indicator matrix of non-focal vars, pull out comparisons at a specific order
				
				comparecount = 1 //counter to keep track of # of comparisons
				
				basecpt2 = (J(y - 1, 1, 1) \ J(nvars - y - 1, 1, 0)) //another looped permutation to make all the specific comparisons w/in order
				
				/*make comparisons between fitstat's - matching on predictors*/
				while ((comparecount <= comb(nvars - 2, y - 1)) & (nvars > 2)) { //so long as there are > 2 IVs... loop for all comparisons
					
					if (y == 1) eval2 = select(eval, selector2[comparecount, .]:==0) //fitstats when only focal IV is in the model (y = 1 per row, i.e., the focal IVs)
					
					else if (y == 2) { //fitstats when 1 other non-focal variable is in the model
					
						eval2 = select(eval, selector1:==1)	//select the fitstats when only the focal IVs are in the model (i.e., not both IVs)
						
						selector3 = select(selector2, selector1:==1) //pull out the columns where there also the other non-focal IV
					
						eval2 = select(eval2, selector3[comparecount, .]:==1) //then select the fitstats where there are only the focal IVs (alone) with the non-focal IV
					
					}
					
					else { //fitstats when >=2 variables are in the model
						
						eval2 = select(eval, selector1:==1) //select the fitstats when only the focal IVs are in the model (i.e., not both IVs)
						
						selector3 = select(selector2, selector1:==1) //pull out the columns where there also the other non-focal IV
						
						basiscpt2 = cvpermutesetup(basecpt2) //set-up permutation of >1 variable to select all possible combinations
						
						combincpt2 = cvpermute(basiscpt2)*10 //activate permutation of >1 variable to select all possible combinations (rescaled by 10 for use in exponentiating)
										
						revind = (nvars - 2::1) //used for exponentiation below
						
						selector4 = J(nvars - 2, 1, 10) //base matrix to use for selecting fitstats - adjusted below
						
						combincpt2 = combincpt2:^revind*(1/10) //matrix which now indicates location of a variable positionally by # of 0s (re-scaled back down by 10)
						
						selector4 = selector4:^revind*(1/10) //obtain a selection matrix which is scaled the sdame as the combination matrix above
						
						selector4 = selector3:*selector4 //rescale the "selector3" matrix with only the current non-focal IVs are selected
						
						selector4 = colsum(selector4) //make selector4 a rowmat so select() can use it
						
						combincpt2 = colsum(combincpt2)	//make combincpt2 a rowmat so select() can use it
						
						eval2 = select(eval2, selector4:==combincpt2) //obtain only one specific combination of the non-focal IVs for the comparison				
					
					}
				
					/*here the comparison is actually made and "cptsum" is updated*/
					var1 = rowsum(eval2[1, .]) //all the fitstats in row 1 call "var1" - sum them (there should only be 1)
				
					var2 = rowsum(eval2[2, .]) //all the fitstats in row 2 call "var2" - sum them (there should only be 1)
				
					cptdom = sign(var1 - var2) //is one bigger than the other? Keep sign only 
								
					cptsum = cptsum + cptdom //add sign to current sum
					
					comparecount++ //increment comparecount and evaluate the while statement above...
					
				}
				
			}
			
			/*determine completely dominate, dominated by or none*/
			if (nvars == 2) cptsum = sign(rowsum(compare[1, .]) - rowsum(compare[2, .])) //simple situation w/ 2 predictors
		
			if (cptsum == 2^(nvars - 2)) cpt[rowcol[1, 1], rowcol[2, 1]] = 1 //if all the cptdom comarisons were "+" then, there is complete dominance for "var1"
		
			else if (cptsum == -2^(nvars - 2)) cpt[rowcol[1, 1], rowcol[2, 1]]= -1 //if all the cptdom comarisons were "-" then, there is complete dominance for "var2"
		
			else cpt[rowcol[1, 1], rowcol[2, 1]] = 0 //otherwise no complete dominance
	
		}
		
		cpt = cpt + cpt'*-1 ///*make cptdom matrix symmetric in what it is telling the user*/
	
		st_matrix("r(cptdom)", cpt) //return r-class matrix "cptdom"
	
	}
	
}

end
"""