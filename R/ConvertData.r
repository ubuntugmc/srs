#' Converting Input data with different coding scheme to standard format
#'
#' @param input matrix input, the first column is ID, the rest of the columns each represent one symptom
#' @param yesLabel The value(s) coding "Yes" in the input matrix.
#' @param noLabel The value(s) coding "No" in the input matrix.
#' @param missLabel The value(s) coding "Missing" in the input matrix.
#' @param data.type The coding scheme of the output. This can be either "WHO2012" or "WHO2016".
#' @family data conversion
#'
#' @return a data frame coded as follows. For WHO2012 scheme: "Y" for yes, "" for No, and "." for missing. For WHO2016 scheme: "y" for yes, "n" for No, and "-" for missing.
#' @export ConvertData
#'
#' @examples
#' \donttest{
#' # make up a fake 2 by 3 dataset with 2 deaths and 3 symptoms
#' id <- c("d1", "d2")
#' x <- matrix(c("Yes", "No", "Don't know", 
#' 			  "Yes", "Refused to answer", "No"), 
#' 			byrow = TRUE, nrow = 2, ncol = 3)
#' x <- cbind(id, x)
#' colnames(x) <- c("ID", "S1", "S2", "S3")
#' # see possible raw data (or existing data created for other purpose)
#' x
#' new <- ConvertData(x, yesLabel = "Yes", noLabel = "No", 
#' 			missLabel = c("Don't know", "Refused to answer"))
#' new
#' }

ConvertData <- function(input, yesLabel = NULL, noLabel = NULL, missLabel = NULL, data.type = c("WHO2012", "WHO2016")[1]){

	##
	## Help user prepare data from other format into the default
	##
	if(is.null(yesLabel) || is.null(noLabel) || is.null(missLabel)){
		stop("Error: please specify what values are used in the data to represent yes, no, and missing")
	}

	ynm <- c("Y", "", ".")
	if(data.type == "WHO2016") ynm <- c("y", "n", "-")

	
	output <- data.frame(matrix("", dim(input)[1], dim(input)[2]), 
						stringsAsFactors = FALSE)
	unchanged <- NULL
	if(length(unique(input[, 1])) != length(input[, 1])){
		stop("Error: duplicate ID in the first column, please check the first column is ID and contains only unique values.")
	}

	output[, 1] <- input[, 1]
	
	# iterate over all columns
	for(i in 2:dim(input)[2]){
		tmp <- as.character(input[, i])
		# if the column contains other elements
		if(sum(!(tmp %in% c(yesLabel, noLabel, missLabel))) > 0){
			unchanged <- c(unchanged, colnames(input)[i])
			output[, i] <- tmp
		# if the column contains only yes, no, or missing
		}else{
			output[which(tmp %in% yesLabel), i] <- ynm[1]
			output[which(tmp %in% noLabel), i] <- ynm[2]
			output[which(tmp %in% missLabel), i] <- ynm[3]
			}
	}

	if(length(unchanged) > 0){
		warning(paste("The following columns not recognized as symptoms and not modified:\n", paste(unchanged, collapse = ", "), "\n"))
	}

	colnames(output) <- colnames(input)
	return(output)
}

#' Get the URL to the PHMRC dataset
#'
#' @param type adult, child, or neonate
#'
#' @return URL of the corresponding dataset
#' @export getPHMRC_url
#'
#' @examples
#' link <- getPHMRC_url("adult")
#' summary(link)$description
#' 
getPHMRC_url <- function(type){
  
  if(type == "adult"){
    return(url('http://ghdx.healthdata.org/sites/default/files/record-attached-files/IHME_PHMRC_VA_DATA_ADULT_Y2013M09D11_0.csv'))
  }else if(type == "child"){
    return(url('http://ghdx.healthdata.org/sites/default/files/record-attached-files/IHME_PHMRC_VA_DATA_CHILD_Y2013M09D11_0.csv'))
  }else if(type == "neonate"){
    return(url('http://ghdx.healthdata.org/sites/default/files/record-attached-files/IHME_PHMRC_VA_DATA_NEONATE_Y2013M09D11_0.csv'))
  }else{
    stop("Unknown type")
  }
  
}
#' Convert standard PHMRC data into binary indicator format
#'
#' The PHMRC data and the description of the format could be found at \url{https://ghdx.healthdata.org/record/ihme-data/population-health-metrics-research-consortium-gold-standard-verbal-autopsy-data-2005-2011}. This function convert the symptoms into binary indicators of three levels: Yes, No, and Missing. The health care experience (HCE) and free-text columns, i.e., columns named "word_****", are not considered in the current version of data conversion.

#' @param input standard PHMRC data format
#' @param input.test standard PHMRC data format to be transformed in the same way as \code{input}
#' @param cause the column name for the cause-of-death variable to use. For example, "va34", "va46", or "va55". It is used if adaptive cut-offs are to be calculated for continuous variables. See below for details.
#' @param phmrc.type which data input format it is. The three data formats currently available are "adult", "child", and "neonate".
#' @param cutoff This determines how the cut-off values are to be set for continuous variables. "default" sets the cut-off values proposed in the original paper published with the dataset. "adapt" sets the cut-off values using the rules described in the original paper, which calculates the cut-off as being two median absolute deviations above the median of the mean durations across causes. However, we are not able to replicate the default cut-offs following this rule. So we suggest users to use this feature with caution.
#' @param ... not used
#' @family data conversion
#'
#' @return converted dataset with only ID and binary symptoms. Notice that when applying this function to the raw PHMRC data, the returned ID variable corresponds to the row index of the raw PHMRC data (i.e., cleaned data with ID = 10 correspond to the 10th row of the raw dataset), and does not correspond to the "newid" column in the PHMRC data. 
#' @export ConvertData.phmrc
#' @references James, S. L., Flaxman, A. D., Murray, C. J., & Population Health Metrics Research Consortium. (2011). \emph{Performance of the Tariff Method: validation of a simple additive algorithm for analysis of verbal autopsies. } \emph{Population Health Metrics, 9(1), 1-16.}
#' @examples
#' \donttest{
#' # read the raw data files from PHMRC website
#' # notice reading directly from internet could be time consuming
#' # so we only read 100 rows here.
#' # in practice, it is much easier and faster to download the file first,
#' #	and read all at once.
#' raw <- read.csv(getPHMRC_url("adult"), nrows = 100)
#' head(raw[, 1:20])
#' # default way of conversion
#' clean <- ConvertData.phmrc(raw, phmrc.type = "adult")
#' head(clean$output[, 1:20])
#' # using cut-offs calculated from the data (caution)
#' clean2 <- ConvertData.phmrc(raw, phmrc.type = "adult", 
#' 						cause = "va55", cutoff = "adapt")
#' head(clean2$output[, 1:20])
#' 
#' # Now using the first 100 rows of data as training dataset
#' # And the next 100 as testing dataset
#' test <- read.csv(getPHMRC_url("adult"), nrows = 200)
#' test <- test[-(1:100), ]
#' 
#' # For the default transformation it does matter
#' clean <- ConvertData.phmrc(raw, test, phmrc.type = "adult")
#' head(clean$output[, 1:20])
#' head(clean$output.test[, 1:20])
#' # For adaptive transformation, need to make sure both files use the same cutoff
#' clean2 <-ConvertData.phmrc(raw, test, phmrc.type = "adult", 
#' 						cause = "va55", cutoff = "adapt")
#' head(clean2$output[, 1:20])
#' head(clean2$output.test[, 1:20])
#' }

ConvertData.phmrc <- function(input, input.test = NULL, cause = NULL, phmrc.type = c("adult", "child", "neonate")[1], cutoff = c("default", "adapt")[1], ...){

	##
	## Convert PHMRC data into binary format
	##
	
	if(phmrc.type == "adult"){
		out <- phmrc_adult_convert(input, input.test, cause = cause, type = cutoff)
	}else if(phmrc.type == "child"){
		out <- phmrc_child_convert(input, input.test, cause = cause, type = cutoff)
		warnings("Child data conversion is experimental.")
	}else if(phmrc.type == "neonate"){
		stop("child data conversion still under development...")
	}

	return(out)

}

#' Converting PHMRC adult data to binary format
#' @param input data with known causes
#' @param input.test test data without known causes
#' @param cause column name of the cause
#' @param type type of cutoff for continuous variables
#' @noRd
phmrc_adult_convert <- function(input, input.test, cause, type = c("default", "adapt")[1]){
  
  ## take care of cause of death
  if(is.null(cause)){
    cause <- "va34"
  }
  
  # if two datasets are to be transformed
  if(!is.null(input.test)){
	  if(length(which(colnames(input) != colnames(input.test)))){
	    stop("Columns do not match in the two dataset")
	  }
    
    N <- dim(input)[1]
    input <- rbind(input, input.test)
  }else{
	  N <- dim(input)[1]
	}
  
  ## take care of ID
	if(colnames(input)[1] != "site"){
		cat("The first column is assumed to be ID by default\n")
		id <- input[, 1]
	}else{
		cat("The first column is site, assign IDs to each row by default\n")
		id <- seq(1:dim(input)[1])
	}
	
	if(cause %in% colnames(input) == FALSE){
		stop("No cause of death column find in data")
	}else{
		gs <- input[, cause] 
	}


	age <- which(colnames(input) == "g1_07a")
	sex <- which(colnames(input) == "g1_05")
	first_symp <- which(colnames(input) == "a1_01_1")
	last_symp <- which(colnames(input) == "a5_04")
	
	if(length(age) != 1){
		stop("Age variable g1_07a not in input data.")
	}
	if(length(sex) != 1){
		stop("Gender variable g1_05 not in input data.")
	}
	if(length(first_symp) != 1 || length(last_symp) != 1){
		stop("Symptoms not correctly specified in input format.")
	}
	symps_raw <- input[, c(sex, age, first_symp : last_symp)]
	symps_raw <- data.frame(symps_raw, stringsAsFactors = FALSE)

	# the output file
	symps_binary <- matrix("", dim(symps_raw)[1], dim(symps_raw)[2])

	# this part has to be before file 9 and 10 to avoid different dimensions
	symps_binary[which(symps_raw == "Yes")] <- "Y"
	symps_binary[which(symps_raw == "No")] <- ""
	symps_binary[which(symps_raw == "Don't Know")] <- "."
	symps_binary[which(symps_raw == "Refused to Answer")] <- "."
	symps_binary[which(symps_raw == "")] <- "."

	symps_binary <- data.frame(symps_binary)
	colnames(symps_binary) <- colnames(as.matrix(symps_raw))
	
	if(type == "default"){
		symps_binary <- toBinary_file9(symps_raw, symps_binary, 
			adapt = FALSE, cause = NULL)
	}else if(type == "adapt"){
		symps_binary <- toBinary_file9(symps_raw, symps_binary, 
			adapt = TRUE, cause = gs)
	}else{
		stop("Unknown cutoff type argument given.")
	}

	symps_binary <- toBinary_file10(symps_raw, symps_binary)
	symps_binary <- toBinary_unhandeled(symps_raw, symps_binary)
	
	
	# to make sure there's no conflict of notations for "Y", "" and "."
	# we use "YesYes", "NoNo", and "MissingMissing" before
	for(i in 1:dim(symps_binary)[2]){
		symps_binary[, i] <- as.character(symps_binary[, i])

		symps_binary[which(symps_binary[,i] == "YesYes"), i] <- "Y"
		symps_binary[which(symps_binary[,i] == "NoNo"), i] <- ""
		symps_binary[which(symps_binary[,i] == "MissingMissing"), i] <- "."
	}

	# check if all cells are filled
	n.empty <- length(which(is.na(symps_binary)))
	n.yes <- length(which(symps_binary == "Y"))
	n.no <- length(which(symps_binary == ""))
	n.notknown <- length(which(symps_binary == "."))

	if(n.empty != 0){
	  cat("There are cells not converted by default rules! Left as NA\n")
	}

  if(N == dim(input)[1]){
    cat(paste0(N, " deaths in input. Format: adult\n"))
  }else{
    cat(paste0(N, " deaths in input. Format: adult\n"))
    cat(paste0(dim(input)[1]-N, " deaths in test input. Format: adult\n"))
    
  }
	cat(paste0(dim(symps_binary)[2], " binary symptoms generated\n"))
	cat(paste0("\nNumber of Yes        ", n.yes, "\n", 
			  "Number of No         ", n.no, "\n",
			  "Number of Not known  ", n.notknown, "\n"))

	
	data.out <- cbind(id, gs, symps_binary)
	colnames(data.out)[1:2] <- c("ID", "Cause")
	
	if(!is.null(input.test)){
	  out <- data.out[1:N, ]
	  out.test <- data.out[-(1:N), ]
	}else{
	  out <- data.out
	  out.test <- NULL
	}
	return(list(output = out, output.test = out.test))
}

#' Converting PHMRC child data to binary format
#' @param input data with known causes
#' @param input.test test data without known causes
#' @param cause column name of the cause
#' @param type type of cutoff for continuous variables
#' 
#' @noRd
phmrc_child_convert <- function(input, input.test, cause, type = c("default", "adapt")[2]) {
  cause <- NULL
  type <- "default"
  
  ## take care of cause of death
  if(is.null(cause)){
    cause <- "va34"
  }
  
  # if two datasets are to be transformed
  if(!is.null(input.test)){
    if(length(which(colnames(input) != colnames(input.test)))){
      stop("Columns do not match in the two dataset")
    }
    
    # attach the second dataset to the below,
    # but with NA in cause variable
    if(cause %in% colnames(input.test)){
      # not making it NA anymore for the implementation of NBC
      # gs.test <- input.test[, cause]
      # input.test[, cause] <- NA
    }
    N <- dim(input)[1]
    input <- rbind(input, input.test)
  }else{
    N <- dim(input)[1]
  }
  
  ## take care of ID
  if(colnames(input)[1] != "site"){
    cat("The first column is assumed to be ID by default\n")
    id <- input[, 1]
  }else{
    cat("The first column is site, assign IDs to each row by default\n")
    id <- seq(1:dim(input)[1])
  }
  
  if(cause %in% colnames(input) == FALSE){
    stop("No cause of death column find in data")
  }else{
    gs <- input[, cause] 
  }
  
  
  age <- which(colnames(input) == "g1_07a")
  sex <- which(colnames(input) == "g1_05")
  first_symp <- which(colnames(input) == "c1_01")
  last_symp <- which(colnames(input) == "c5_19")
  
  if(length(age) != 1){
    stop("Age variable g1_07a not in input data.")
  }
  if(length(sex) != 1){
    stop("Gender variable g1_05 not in input data.")
  }
  if(length(first_symp) != 1 || length(last_symp) != 1){
    stop("Symptoms not correctly specified in input format.")
  }
  symps_raw <- input[, c(sex, age, first_symp : last_symp)]
  symps_raw <- data.frame(symps_raw, stringsAsFactors = FALSE)
  
  ####
  # the output file
  symps_binary <- matrix("", dim(symps_raw)[1], dim(symps_raw)[2])
  
  # this part has to be before file 9 and 10 to avoid different dimensions
  symps_binary[which(symps_raw == "Yes")] <- "Y"
  symps_binary[which(symps_raw == "No")] <- ""
  symps_binary[which(symps_raw == "Don't Know")] <- "."
  symps_binary[which(symps_raw == "Refused to Answer")] <- "."
  symps_binary[which(symps_raw == "")] <- "."
  
  symps_binary <- data.frame(symps_binary)
  colnames(symps_binary) <- colnames(as.matrix(symps_raw))
  
  if(type == "default"){
    symps_binary <- toBinary_file9_child(symps_raw, symps_binary, 
                                          adapt = FALSE, cause = NULL)
  }else if(type == "adapt"){
    symps_binary <- toBinary_file9_child(symps_raw, symps_binary, 
                                          adapt = TRUE, cause = gs)
  }else{
    stop("Unknown cutoff argument given")
  }
  
  symps_binary <- toBinary_file10_child(symps_raw, symps_binary)
  symps_binary <- toBinary_unhandeled_child(symps_raw, symps_binary)
  
  # to make sure there's no conflict of notations for "Y", "" and "."
  # we use "YesYes", "NoNo", and "MissingMissing" before
  # also need to deal with NA values for c1_08b and g1_07a
  for(i in 1:dim(symps_binary)[2]){
    symps_binary[, i] <- as.character(symps_binary[, i])
    symps_binary[which(is.na(symps_binary[,i])), i] <- "MissingMissing"
    symps_binary[which(symps_binary[,i] == "YesYes"), i] <- "Y"
    symps_binary[which(symps_binary[,i] == "NoNo"), i] <- ""
    symps_binary[which(symps_binary[,i] == "MissingMissing"), i] <- "."
  }
  
  # check if all cells are filled
  n.empty <- length(which(is.na(symps_binary)))
  n.yes <- length(which(symps_binary == "Y"))
  n.no <- length(which(symps_binary == ""))
  n.notknown <- length(which(symps_binary == "."))
  
  if(n.empty != 0){
    cat("There are cells not converted by default rules! Left as NA\n")
  }
  
  if(N == dim(input)[1]){
    cat(paste0(N, " deaths in input. Format: adult\n"))
  }else{
    cat(paste0(N, " deaths in input. Format: adult\n"))
    cat(paste0(dim(input)[1]-N, " deaths in test input. Format: adult\n"))
    
  }
  cat(paste0(dim(symps_binary)[2], " binary symptoms generated\n"))
  cat(paste0("\nNumber of Yes        ", n.yes, "\n", 
             "Number of No         ", n.no, "\n",
             "Number of Not known  ", n.notknown, "\n"))
  
  
  data.out <- cbind(id, gs, symps_binary)
  colnames(data.out)[1:2] <- c("ID", "Cause")
  
  if(!is.null(input.test)){
    out <- data.out[1:N, ]
    out.test <- data.out[-(1:N), ]
  }else{
    out <- data.out
    out.test <- NULL
  }
  return(list(output = out, output.test = out.test))
}

#' Function to convert a vector into T/F when there is "don't know"
#' 
#' The function can adaptively choose the cutoff, but it needs to know the causes
#' @param vec original numerical vector
#' @param cut cutoff point
#' @param cause column name of the cause
#' @param adapt logical indicator whether to choose cutoff adaptively
#' @param missLabel character coding of missing symptoms
#' 
#'@noRd
#'
toBinary_cutoff <- function(vec, cut, missLabel = NULL, 
							 adapt = FALSE, cause = NULL){
	if(is.null(missLabel)){
		missLabel <- c("Don't Know", "Refused to Answer")
	}
	vec <- as.character(vec)
	vec[which(vec %in% missLabel)] <- "."
	# get rid of annoying warning. I want NA stored
	vec.num <- suppressWarnings(as.numeric(vec))
	num <- which(!is.na(vec.num))
	# if adaptively choosing the cutoff value
	# to quote original paper: two median absolute deviations above the median of the mean durations across causes
	if(adapt){
		tmp <- data.frame(cause = cause[num], duration = vec.num[num])
		tmp2 <- aggregate(duration ~ cause, tmp, function(x){
			mean(x)})
		med <- median(tmp2[, 2])
		MAD <- median(abs(tmp[, 2] - med))
		# print(c(cut, med, MAD, med + 2 * MAD))

		if(!(is.na(med) || is.na(MAD))){
			cut <- med + 2 * MAD			
		}
	}
	vec[num] <- as.character(as.numeric(vec[num]) > cut) 
	vec[vec == "TRUE"] <- "YesYes"
	vec[vec == "FALSE"] <- "NoNo"
	return(vec)
}


#' Function to reformulate matrix based on Additional File 10
#' 
#' @param symps_raw raw symptom data frame
#' @param symps new symptom data frame
#' @param cause column name of the cause
#' @param adapt logical indicator whether to choose cutoff adaptively
#' @param missLabel character coding of missing symptoms
#'@noRd
#'
toBinary_file9 <- function(symps_raw, symps, missLabel = NULL, adapt = FALSE, cause = NULL){
##########################################################
## The comments are the transforming rule for the symptoms
##	
## The format of comments read:
## 
##	# Original question
##  	# Cutoff
##
###########################################################	
# For how long was [name] ill before s/he died? [days]	
	# 528.8
	symps$a2_01 <- toBinary_cutoff(symps_raw$a2_01, 528.8, missLabel, adapt, cause)

# How many days did the fever last? [days]	
	# 8.8
	symps$a2_03 <- toBinary_cutoff(symps_raw$a2_03, 8.8, missLabel, adapt, cause)

# How many days did [name] have the rash? [days]	
	# 3.1
	symps$a2_08 <- toBinary_cutoff(symps_raw$a2_08, 3.1, missLabel, adapt, cause)

# For how many days did the ulcer ooze pus? [days]	
	# 0.3
	symps$a2_15 <- toBinary_cutoff(symps_raw$a2_15, 0.3, missLabel, adapt, cause)

# For how long did [name] have the yellow discoloration? [days]	
	# 54.1
	symps$a2_22 <- toBinary_cutoff(symps_raw$a2_22, 54.1, missLabel, adapt, cause) 

# For how long did [name] have ankle swelling? [days]	
	# 55.2
	symps$a2_24 <-  toBinary_cutoff(symps_raw$a2_24, 55.2, missLabel, adapt, cause) 

# For how long did [name] have puffiness of the face? [days]	
	# 36.0
	symps$a2_26 <-  toBinary_cutoff(symps_raw$a2_26, 36, missLabel, adapt, cause)

# For how long did [name] have puffiness all over his/her body? [days]	
	# 20.3
	symps$a2_28 <-  toBinary_cutoff(symps_raw$a2_28, 20.3, missLabel, adapt, cause)

# For how long did [name] have a cough? [days]	
	# 107.0
	symps$a2_33 <-  toBinary_cutoff(symps_raw$a2_33, 107, missLabel, adapt, cause)

# For how long did [name] have difficulty breathing? [days]	
	# 100.3
	symps$a2_37 <-  toBinary_cutoff(symps_raw$a2_37, 100.3, missLabel, adapt, cause)

# For how long did [name] have fast breathing? [days]	
	# 43.0
	symps$a2_41 <-  toBinary_cutoff(symps_raw$a2_41, 43, missLabel, adapt, cause)

# For how long before death did [name] have loose or liquid stools? [days]	
	# 4.9
	symps$a2_48 <-  toBinary_cutoff(symps_raw$a2_48, 4.9, missLabel, adapt, cause)

# For how long before death did [name] vomit? [days]	
	# 3.2
	symps$a2_54 <-  toBinary_cutoff(symps_raw$a2_54, 3.2, missLabel, adapt, cause)

# For how long before death did [name] have difficulty swallowing? [days]	
	# 55.2
	symps$a2_58 <-  toBinary_cutoff(symps_raw$a2_58, 55.2, missLabel, adapt, cause)

# For how long before death did [name] have belly pain? [days]	
	# 16.7
	symps$a2_62 <- toBinary_cutoff(symps_raw$a2_62, 16.7, missLabel, adapt, cause) 

# For how long before death did [name] have a protruding belly? [days]	
	# 45.4
	symps$a2_65 <-  toBinary_cutoff(symps_raw$a2_65, 45.4, missLabel, adapt, cause)

# For how long before death did [name] have a mass in the belly [days]	
	# 34.4
	symps$a2_68 <-  toBinary_cutoff(symps_raw$a2_68, 34.4, missLabel, adapt, cause)

# For how long before death did [name] have headaches? [days]	
	# 3.2
	symps$a2_70 <-  toBinary_cutoff(symps_raw$a2_70, 3.2, missLabel, adapt, cause)

# For how long before death did [name] have stiff neck? [days]	
	# 2.2
	symps$a2_73 <-  toBinary_cutoff(symps_raw$a2_73, 2.2, missLabel, adapt, cause)

# For how long did the period of loss of consciousness last? [days]	
	# 1.1
	symps$a2_76 <- toBinary_cutoff(symps_raw$a2_76, 1.1, missLabel, adapt, cause) 

# For how long did the period of confusion last? [days]	
	# 7.8
	symps$a2_79 <- toBinary_cutoff(symps_raw$a2_79, 7.8, missLabel, adapt, cause) 

# For how long before death did the convulsions last? [days]	
	# 0.0
	symps$a2_83 <-  toBinary_cutoff(symps_raw$a2_83, 0.0, missLabel, adapt, cause)

# For how long before death did [name] have paralysis? [days]	
	# 20.4
	symps$a2_86 <-  toBinary_cutoff(symps_raw$a2_86, 20.4, missLabel, adapt, cause)

# For how many weeks was her period overdue? [days]	
	# 2.9
	symps$a3_08 <- toBinary_cutoff(symps_raw$a3_08, 2.9, missLabel, adapt, cause) 

# How much pipe/chewing tobacco did [name] use daily?	
	# 1.2
	symps$a4_03 <-  toBinary_cutoff(symps_raw$a4_03, 1.2, missLabel, adapt, cause)

# How many cigarettes did [name] smoke daily?	
	# 4.2
	symps$a4_04 <-  toBinary_cutoff(symps_raw$a4_03, 4.2, missLabel, adapt, cause)

# How long did [name] survive after the injury? [days]	
	# 8.5
	symps$a5_04 <-  toBinary_cutoff(symps_raw$a5_04, 8.5, missLabel, adapt, cause)

# Age [years]	
	# 67.6
	symps$g1_07a <- toBinary_cutoff(symps_raw$g1_07a, 67.6, missLabel, adapt, cause)

	return(symps)
}


#' Function to reformulate child matrix based on Additional File 9
#' 
#' @param symps_raw raw symptom data frame
#' @param symps new symptom data frame
#' @param cause column name of the cause
#' @param adapt logical indicator whether to choose cutoff adaptively
#' @param missLabel character coding of missing symptoms
#'@noRd
#'
toBinary_file9_child <- function(symps_raw, symps, missLabel = NULL, adapt = FALSE, cause = NULL){
  ##########################################################
  ## The comments are the transforming rule for the symptoms
  ##	
  ## The format of comments read:
  ## 
  ##	# Original question
  ##  	# Cutoff
  ##
  ###########################################################	
  # How long after delivery did the  mother die? [days]	
  # 21.4
  symps$c1_05 <- toBinary_cutoff(symps_raw$c1_05, 21.4, missLabel, adapt, cause)
  
  # What was the weight of the deceased at birth? [grams]
  # 2623
  symps$c1_08b <- toBinary_cutoff(symps_raw$c1_08b, 2623, missLabel, adapt, cause)
  
  # How old was the deceased when the fatal illness started [days]	
  # 1574.3
  symps$c1_20 <- toBinary_cutoff(symps_raw$c1_20, 1574.3, missLabel, adapt, cause)
  
  # How long did the illness last? [days]
  # 63.4
  symps$c1_21 <- toBinary_cutoff(symps_raw$c1_21, 63.4, missLabel, adapt, cause)
  
  # How old was the deceased at the time of death? [days]
  # 1618.6
  symps$c1_25 <- toBinary_cutoff(symps_raw$c1_25, 1618.6, missLabel, adapt, cause)
  
  # How many days did the fever last? [days]
  # 337.3
  symps$c4_02 <- toBinary_cutoff(symps_raw$c4_02, 337.3, missLabel, adapt, cause)
  
  # How many days before death did the frequest loose or liquid stools start?
  # [days]
  # 99.9
  symps$c4_08 <- toBinary_cutoff(symps_raw$c4_08, 99.9, missLabel, adapt, cause)
  
  
  # How many days before death did the frequest loose or liquid stools stop?
  # [days]
  # 15.6
  symps$c4_10 <- toBinary_cutoff(symps_raw$c4_10, 15.6, missLabel, adapt, cause)
  
  # How many days did the cough last? [days] 
  # 5.7
  symps$c4_13 <- toBinary_cutoff(symps_raw$c4_13, 5.7, missLabel, adapt, cause)
  
  # How many days did the difficult breathing last? [days]
  # 9.1
  symps$c4_17 <- toBinary_cutoff(symps_raw$c4_17, 9.1, missLabel, adapt, cause)
  
  # How many days did the fast breathing last? [days]
  # 1.5
  symps$c4_19 <- toBinary_cutoff(symps_raw$c4_19, 1.5, missLabel, adapt, cause)
  
  # How many days did the rash last? [days]
  # 1.1
  symps$c4_33 <- toBinary_cutoff(symps_raw$c4_33, 1.1, missLabel, adapt, cause)
  
  # How long did the swelling last? [days]
  # 2.2
  symps$c4_37 <- toBinary_cutoff(symps_raw$c4_37, 2.2, missLabel, adapt, cause)
  
  # How long did the decendent survive after the injury or accident? [days]
  # 0.6
  symps$c4_49 <- toBinary_cutoff(symps_raw$c4_49, .6, missLabel, adapt, cause)
  
  # Age [years] (short duration cutoff)
  # 2.4
  symps$g1_07a <- toBinary_cutoff(symps_raw$g1_07a, 2.4, missLabel, adapt, cause)
  
  return(symps)
}

#' Function to map a vector into Y/N/. by customized grouping
#' 
#' @param vec raw symptom data frame
#' @param gtrue value for present symptoms
#' @param gfalse value for absent symptoms
#' @param gna  value for missing symptoms  
#'@noRd
#'
toBinary_group <- function(vec, gtrue, gfalse, gna){
	vec <- as.character(vec)
	for(i in gtrue){
		vec[which(vec == i)] <- "YesYes"
	}
	for(i in gfalse){
		vec[which(vec == i)] <- "NoNo"
	}
	for(i in gna){
		vec[which(vec == i)] <- "MissingMissing"
	}	
	return(vec)
}


#' Function to map two vectors into Y/N/. by customized grouping
#' 
#' 
#' @param vec1 first symptom data frame
#' @param vec2 second symptom data frame. Output is only present if both symptoms present. 
#' @param gtrue value for present symptoms
#' @param gfalse value for absent symptoms
#' @param gna  value for missing symptoms 
#'@noRd
#'

toBinary_group2 <- function(vec1, vec2, gtrue, gfalse, gna){
	vec1 <- as.character(vec1)
	vec2 <- as.character(vec2)
	# first set to vec1
	for(i in gtrue){
		vec1[which(vec1 == i)] <- "YesYes"
	}
	for(i in gfalse){
		vec1[which(vec1 == i)] <- "NoNo"
	}
	for(i in gna){
		vec1[which(vec1 == i)] <- "MissingMissing"
	}	
	# then check vec2 only if it is yes
	for(i in gtrue){
		vec1[which(vec2 == i)] <- "YesYes"
	}
	return(vec1)
}


#'  Function to reformulate matrix based on Additional File 10
#' 
#' @param raw original data frame
#' @param new new data frame
#'@noRd
#'
#' 
#' 
toBinary_file10 <- function(raw, new){
##########################################################
## The comments are the transforming rule for the symptoms
##	
## The format of comments read:
## 
##	# Original question
##  # Original answer
##		## New question(s)
##		## ...
##
###########################################################	

# How substantial was the loss of weight?	
# Slight, Moderate, Large, Don't Know	
	##  Was there moderate to large weight loss?
new$a2_19 <- toBinary_group(raw$a2_19, 
							c("Moderate", "Large"), 
							c("Slight"), 
							c("Don't Know"))

# How severe was the fever?	
# Mild, Moderate, Severe, Don't Know	
	##  Was there a moderate to severe fever?
new$a2_04 <- toBinary_group(raw$a2_04, 
							c("Moderate", "Severe"), 
							c("Mild"), 
							c("Don't Know"))

# What was the pattern of the fever?	
# Continuous, On and Off, Only at Night
	##  Was there a continuous fever?
	##  Was there an on and off fever?
new$a2_05  <- toBinary_group(raw$a2_05, 
							c("Continuous"), 
							c("On and Off", "Only at Night"), 
							c("Don't Know"))
new$a2_05_s1 <- toBinary_group(raw$a2_05, 
							c("On and Off"), 
							c("Continuous", "Only at Night"), 
							c("Don't Know"))
# Where was the rash located?	
# Face, Trunk, Extremities, Everywhere, Other, Don't Know	
	##	Was there a rash on the face?
	##	Was there a rash on the trunk?
	##	Was there a rash on the extremities?
	##	Was there a rash everywhere?
new$a2_09_1a  <- toBinary_group2(raw$a2_09_1a, raw$a2_09_2a,
							c("Face"), 
							c("Trunk", "Extremities", "Everywhere", "Other"), 
							c("Don't Know"))
new$a2_09_1a_s1  <- toBinary_group2(raw$a2_09_1a, raw$a2_09_2a,
							c("Trunk"), 
							c("Face", "Extremities", "Everywhere", "Other"), 
							c("Don't Know"))
new$a2_09_1a_s2  <- toBinary_group2(raw$a2_09_1a, raw$a2_09_2a,
							c("Extremities"), 
							c("Trunk", "Face", "Everywhere", "Other"), 
							c("Don't Know"))
new$a2_09_1a_s3  <- toBinary_group2(raw$a2_09_1a, raw$a2_09_2a,
							c("Everywhere"), 
							c("Trunk", "Extremities", "Face", "Other"), 
							c("Don't Know"))
new$a2_09_1b  <- toBinary_group2(raw$a2_09_1a, raw$a2_09_2a,
							c("Other"), 
							c("Trunk", "Extremities", "Face", "Everywhere"), 
							c("Don't Know"))
new <- new[, -which(colnames(new) == "a2_09_2a")]
new <- new[, -which(colnames(new) == "a2_09_2b")]
# new$a2_09_2a  <- toBinary_group(raw$a2_09_2a, 
# 							c("Face"), 
# 							c("Trunk", "Extremities", "Everywhere", "Other"), 
# 							c("Don't Know"))
# new$a2_09_2a_s1  <- toBinary_group(raw$a2_09_2a, 
# 							c("Trunk"), 
# 							c("Face", "Extremities", "Everywhere", "Other"), 
# 							c("Don't Know"))
# new$a2_09_2a_s2  <- toBinary_group(raw$a2_09_2a, 
# 							c("Extremities"), 
# 							c("Trunk", "Face", "Everywhere", "Other"), 
# 							c("Don't Know"))
# new$a2_09_2a_s3  <- toBinary_group(raw$a2_09_2a, 
# 							c("Everywhere"), 
# 							c("Trunk", "Extremities", "Face", "Other"), 
# 							c("Don't Know"))
# new$a2_09_2b  <- toBinary_group(raw$a2_09_2a, 
# 							c("Other"), 
# 							c("Trunk", "Extremities", "Face", "Everywhere"), 
# 							c("Don't Know"))

# In what position did the breathing difficulty get worse?	
# Lying, Sitting, Walking/Exertion, Didn't matter, Refused to answer, Don't know
	##  Did the breathing difficulty get worse in the lying position?
	##	Did the breathing difficulty get worse in the sitting position?
	##	Did the breathing difficulty get worse in the walking position?
	##	Did the breathing difficulty not get worse in any position?
new$a2_39_1  <- toBinary_group2(raw$a2_39_1, raw$a2_39_2,
							c("Lying"), 
							c("Sitting", "Walking/Exertion", "Didn't matter"), 
							c("Didn't matter", "Refused to Answer","Don't Know"))
new$a2_39_1_s1  <- toBinary_group2(raw$a2_39_1, raw$a2_39_2,
							c("Sitting"), 
							c("Lying", "Walking/Exertion", "Didn't matter"), 
							c("Didn't matter", "Refused to Answer","Don't Know"))
new$a2_39_1_s2  <- toBinary_group2(raw$a2_39_1, raw$a2_39_2,
							c("Walking/Exertion"), 
							c("Sitting", "Lying", "Didn't matter"), 
							c("Didn't matter", "Refused to Answer","Don't Know"))
new$a2_39_1_s3  <- toBinary_group2(raw$a2_39_1, raw$a2_39_2,
							c("Didn't matter"), 
							c("Lying", "Sitting", "Walking/Exertion"), 
							c("Refused to Answer","Don't Know"))
new <- new[, -which(colnames(new) == "a2_39_2")]


# Was the breathing difficulty continuous or on and off?	
# Continuous, On and Off, Don't Know	
	##  Was the breathing difficulty continuous?
	##	Was the breathing difficulty on and off?
new$a2_38  <- toBinary_group(raw$a2_38, 
							c("Continuous"), 
							c("On and Off" ), 
							c("Don't Know"))
new$a2_38_s1 <- toBinary_group(raw$a2_38, 
							c("On and Off"), 
							c("Continuous" ), 
							c("Don't Know"))
# How long did the pain in the chest last?	
# <30 minutes, 30 minutes - 24 hours, >24 hours, Refused to Answer, Don't Know	
	##  Did the pain last more than 24 hours?
new$a2_44 <- toBinary_group(raw$a2_44, 
							c(">24 hr" ), 
							c("<30 minutes", "0.5-24 hours"), 
							c("Don't Know", "Refused to Answer"))
# Where was the pain located?	
# Upper/middle chest, Lower chest, Left arm, Other, Refused to Answer, Don't know	##   Was there pain located in the chest?
   ##	Was there pain located in the left arm?
new$a2_46a <- toBinary_group(raw$a2_46a, 
							c("Upper/middle chest", "Lower chest" ), 
							c("Left Arm", "Other" ), 
							c("Don't Know", "Refused to Answer"))
new$a2_46a_s1 <- toBinary_group(raw$a2_46a, 
							c("Left Arm" ), 
							c("Upper/middle chest", "Lower chest", "Other"), 
							c("Don't Know", "Refused to Answer"))
new$a2_46b <- toBinary_group(raw$a2_46a, 
							c("Other" ), 
							c("Left Arm", "Upper/middle chest", "Lower chest" ), 
							c("Don't Know", "Refused to Answer"))

# Was there difficulty swallowing liquids, solids, or both?	
# Liquids, Solids, Both, Refused to Answer, Don't Know	
	##  Was there difficulty swallowing both solids and liquids?
new$a2_59 <- toBinary_group(raw$a2_59, 
							c("Both" ), 
							c("Liquids", "Solids"), 
							c("Don't Know", "Refused to Answer"))

# Was the pain in the upper or lower belly?	
# Upper belly, Lower belly, Refused to answer, Don't know	
	## Was there pain in the lower belly?
new$a2_63_1 <- toBinary_group(raw$a2_63_1, 
							c("Lower belly" ), 
							c("Upper belly"), 
							c("Don't Know", "Refused to Answer"))
new$a2_63_2 <- toBinary_group(raw$a2_63_2, 
							c("Lower belly" ), 
							c("Upper belly"), 
							c("Don't Know", "Refused to Answer"))
# Was the onset of the headache fast or slow?	
# Rapid/Fast, Slow, Refused to Answer, Don't Know	
	##  Was the onset of the headache fast or slow?
new$a2_71 <- toBinary_group(raw$a2_71, 
							c("Rapidly/Fast"), 
							c("Slow(ly)"), 
							c("Don't Know", "Refused to Answer"))
# Did the period of loss of consciousness start suddenly or slowly?	
# Suddenly, Slowly, Don't Know	
	##  Was there a sudden loss of consciousness?
new$a2_75 <- toBinary_group(raw$a2_75, 
							c("Suddenly"), 
							c("Slowly"), 
							c("Don't Know"))
# Did the period of confusion start suddenly or slowly?	
# Suddenly, Slowly, Don't Know	
	##	Was there a sudden start to a period of confusion?
new$a2_80 <- toBinary_group(raw$a2_80, 
							c("Suddenly"), 
							c("Slowly"), 
							c("Don't Know"))
# Would you say the amount of alcohol [name] drank was..?	
# Low, Moderate, High, Don't Know	
	##  Did [name] drink moderate-high amounts of alcohol?
	##	Did [name] drink low amounts of alcohol?
	# levels: Mild, Moderate, Severe, (Don't Know, Refused to Answer)
new$a4_06 <- toBinary_group(raw$a4_06, 
							c("Moderate", "High"), 
							c("Low"), 
							c("Don't Know", "Refused to Answer"))
new$a4_06_s1 <- toBinary_group(raw$a4_06, 
							c("Low"), 
							c("Moderate", "High"),
							c("Don't Know", "Refused to Answer"))

 return(new[, order(colnames(new))])
}


#'  Function to reformulate child matrix based on Additional File 10
#' @param raw original data frame
#' @param new new data frame
#'@noRd
#'
#' 
#' 
toBinary_file10_child <- function(raw, new){
  ##########################################################
  ## The comments are the transforming rule for the symptoms
  ##	
  ## The format of comments read:
  ## 
  ##	# Original question
  ##  # Original answer
  ##		## New question(s)
  ##		## ...
  ##
  ###########################################################	
  
  # Was the deceased a singleton or multiple birth?
  # Singletone, Multiple, Don't Know
  ## Was the deceased a multiple birth?
  new$c1_01 <- toBinary_group(raw$c1_01, 
                               c("Multiple"), 
                               c("Singleton"), 
                               c("Don't Know", ""))
  
  # Was this the first, second, or later in the birth order?
  # First, Second, Third or More, Don't Know
  ## Was this birth the second or more in the birth order?
  new$c1_02 <- toBinary_group(raw$c1_02, 
                               c("Second", "Third or More"), 
                               c("First"), 
                               c("Don't Know"))
  
  # Did the mother die during or after the delivery?
  # During, After, Don't Know
  ## Did the mother die after the delivery?
  new$c1_04 <- toBinary_group(raw$c1_04, 
                               c("After"), 
                               c("During"), 
                               c("Don't Know"))
  # Where was the deceased born?
  # Hospital, Other Health Facility, On Route to Health Facility, Home, Other, Don't Know
  ## Was the deceased born at home or in another non-health facility?
  new$c1_06a <- toBinary_group(raw$c1_06a, 
                                c("Home", "Other"), 
                                c("Hospital", "On Route to Health Facility",
                                  "Other Health Facility"), 
                                c("Don't Know"))
  # At the time of the delivery, what was the size of the deceased?
  # Very small, smaller than usual, about average, larger than usual, don't know
  ## At the time of the delivery, was the deceased small or very small?
  new$c1_07 <- toBinary_group(raw$c1_07, 
                               c("Very small", "smaller than usual"), 
                               c("About average", "larger than usual"), 
                               c("Don't Know", ""))
  # Where did the deceased die?
  # Hospital, Other Health Facility, On Route to Health Facility, Home, Other, Don't Know
  ## Did the deceased die at home or on route to a health facility?
  new$c1_22a <- toBinary_group(raw$c1_22a, 
                                c("Home", "On Route to Health Facility"), 
                                c("Hospital", "Other",
                                  "Other Health Facility"), 
                                c("Don't Know"))
  # How severe was the fever?
  # Mild, Moderate, Severe, Don't Know
  ## Was there a severe fever?
  new$c4_04 <- toBinary_group(raw$c4_04, 
                               c("Severe"), 
                               c("Mild", "Moderate"), 
                               c("Don't Know"))
  
  # What was the pattern of the fever?
  # Continuous, On and Off, Only at Night
  ## Was the fever on and off or only at night?
  new$c4_05 <- toBinary_group(raw$c4_05, 
                               c("On and Off", "Only at Night"), 
                               c("Continuous"), 
                               c("Don't Know"))
  
  # How many stools did [name] have on the day that loose liquid stools were most frequent?
  # 0-30
  ## Did [name] have 2 or more stools on the day that loose liquid stools were most frequent?
  new$c4_07b <- toBinary_group(raw$c4_07b, 
                                2:30, 
                                0:1, 
                                NA)
  
  # Where was the rash?
  # Face, Trunk, Extremities, Everywhere, Other, Don't Know
  ## Was there a rash on the face?
  new$c4_31_1 <- toBinary_group(raw$c4_31_1, 
                                 c("Face"), 
                                 c("Everywhere", "Extremities",
                                   "Other", "Trunk"), 
                                 c("Don't Know"))
  
  # Where did the rash start?
  # Face, Trunk, Extremities, Everywhere, Other, Don't Know
  ## Did the rash start on the face?
  new$c4_32 <- toBinary_group(raw$c4_32, 
                               c("Face"), 
                               c("Everywhere", "Extremities",
                                 "Other", "Trunk"), 
                               c("Don't Know"))
  return(new[, order(colnames(new))])
}




#'  Function to reformulate matrix not specified by any documents
#' 
#' @param raw original data frame
#' @param new new data frame
#'@noRd
#'
#' 
#' 
#' 
toBinary_unhandeled <- function(raw, new){
##########################################################
## The comments are the transforming rule for the symptoms
##	
## The format of comments read:
## 
##	# Original question
##  # Original answer
##		## New question(s)
##		## ...
##
###########################################################	

# How rapidly did [name] develop the protruding belly?
#  Don't Know, Rapidly/Fast,     Slow(ly)
	##  Was it rapid?
new$a2_66 <- toBinary_group(raw$a2_66, 
							c("Rapidly/Fast"), 
							c("Slow(ly)"), 
							c("Don't Know"))
# remove these symptoms
# a2_87_10b: Paralyzed other, specify
# a3_11a	For how many months was she pregnant? [specify units]
# a3_16a	For how long was she in labor? [specify units]
# a4_02_5b	Type of tobacco used: other, specify
new <- new[, -which(colnames(new) == "a2_87_10b")]
new <- new[, -which(colnames(new) == "a3_11")]
new <- new[, -which(colnames(new) == "a3_16")]
new <- new[, -which(colnames(new) == "a4_02_5b")]

# add sex
new$g1_05   <- toBinary_group(raw$g1_05 , 
							c("Female"), 
							c("Male" ), 
							c("Don't Know", ""))
new$g1_05_s1  <- toBinary_group(raw$g1_05 , 
							c("Male"), 
							c("Female" ), 
							c("Don't Know", ""))
 return(new[, order(colnames(new))])
}



#'  Function to reformulate child matrix not specified by any documents
#' @param raw original data frame
#' @param new new data frame
#' 
#'@noRd
#'
#' 
#' 
#' 
toBinary_unhandeled_child <- function(raw, new){
  ##########################################################
  ## The comments are the transforming rule for the symptoms
  ##	
  ## The format of comments read:
  ## 
  ##	# Original question
  ##  # Original answer
  ##		## New question(s)
  ##		## ...
  ##
  ###########################################################	
  
  #### columns not handled by default Y/N/DK/RA/NA, or additionals files 9 or 10
  # c1_08a, c1_09, c1_10, c1_10d, c1_10m, c1_10y, c1_11, c1_19_4b,
  # c1_24, c1_24d, c1_24m, c1_24y, c1_26, c4_07a, c4_27, c4_31_2, c4_45, 
  # c4_47_8b, c5_06_1d, c5_06_1m, c5_06_1y, c5_06_2d, ct_96_2m, ct_06_2y, 
  # c5_07_1, c5_07_2, c5_08d, c5_08m, c5_08y
  
  cols.to.remove <- c("c1_08a", "c1_10", "c1_11", "c1_10d", "c1_10m", "c1_10y",
                      "c1_194b", "c1_24", paste0("c1_24", c("d", "m", "y")),
                      "c1_26", "c4_07a", "c4_31_2", "c4_45", "c4_47_8b",
                      paste0("c5_06_1", c("d", "m", "y")),
                      paste0("c5_06_2", c("d", "m", "y")),
                      "c5_07_1", "c5_07_2",
                      paste0("c5_08", c("d", "m", "y")))
  
  new <- new[, -which(colnames(new) %in% cols.to.remove)]
  
  # How long before death did unconsciousness start?
  # < 6 hours, 6-23 hours, 24 hours or more, Don't Know
  ## Did unconsciousness start less than 6 hours before death?
  new$c4_27 <- toBinary_group(raw$c4_27,
                               c("<6 hours"),
                               c("24 hours or more", "6-23 hours"),
                               c("Don't Know"))
  
  # add sex
  new$g1_05   <- toBinary_group(raw$g1_05 , 
                                 c("Female"), 
                                 c("Male" ), 
                                 c("Don't Know", ""))
  new$g1_05_s1  <- toBinary_group(raw$g1_05 , 
                                   c("Male"), 
                                   c("Female" ), 
                                   c("Don't Know", ""))
  return(new[, order(colnames(new))])
}
