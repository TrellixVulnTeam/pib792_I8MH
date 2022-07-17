# Provided control and treatment results, 
# find the genes in which they occured




# Libraries

# Data table
library(data.table)
setDTthreads(threads = 80)

# Command line arguments
library(optparse)




# Define the command line arguments.
# Source: https://www.r-bloggers.com/2015/09/passing-arguments-to-an-r-script-from-command-lines/=
options <- list(
    make_option(
        c(
            '-l', '--location'
        ),
        type = 'character',
        default = './',
        help = 'Where to search for control and treatment files.  Assumes that controls and treatments are in the same folder. (required)'
    ),
    make_option(
        c(
            '-c', '--control-pattern'
        ),
        type = 'character',
        default = NULL,
        help = 'The filename pattern for control files. (required)'
    ),
    make_option(
        c(
            '-t', '--treatment-pattern'
        ),
        type = 'character',
        default = NULL,
        help = 'The filename pattern for treatment files. (required)'
    ),
    make_option(
        c(
            '-w', '--write-to'
        ),
        type = 'character',
        default = './',
        help = 'Where to write the results of the analysis to. (required)'
    )
)

opt_parser <- OptionParser(
    option_list = 
    options
)

opt <- parse_args(
    opt_parser
)

# Homogenize the locations.
if(substr(opt$location, nchar(opt$location), nchar(opt$location)) != '/') {
    opt$location <- paste(c(opt$location, '/'), collapse = '')
}

if(substr(opt$`write-to`, nchar(opt$`write-to`), nchar(opt$`write-to`)) != '/') {
    opt$`write-to` <- paste(c(opt$`write-to`, '/'), collapse = '')
}

# Do we have valid locations?
if(!dir.exists(opt$location)) {
    cat(paste(c('\nThe path provided for -l/--location (\'', opt$location, '\') was not found!  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

if(!dir.exists(opt$`write-to`)) {
    cat(paste(c('\nThe path provided for -w/--write-to (\'', opt$`write-to`, '\') was not found!  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

# Look for the control and treatment files.
if(is.null(opt$`control-pattern`)) {
    cat(paste(c('\nNo control pattern was provided using -c/--control-pattern.  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

if(is.null(opt$`treatment-pattern`)) {
    cat(paste(c('\nNo treatment pattern was provided using -t/--treatment-pattern.  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

controls <- dir(
    path = opt$location,
    pattern = opt$`control-pattern`
)

treatments <- dir(
    path = opt$location,
    pattern = opt$`treatment-pattern`
)

# Only proceed if there are any controls or treatments.
if(length(controls) == 0) {
    cat(paste(c('\nNo controls found at \'', opt$location, '\' using pattern ', opt$`control-pattern`, '  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

if(length(treatments) == 0) {
    cat(paste(c('\nNo treatments found at \'', opt$location, '\' using pattern ', opt$`treatment-pattern`, '  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

# Load the controls and treatments and find the shared genomic
# coordinates.
controls <- lapply(controls, function(control) {

    # Read the control file.
    controlled <- setDT(
        read.table(
            file = paste(c(opt$location, control), collapse = ''),
            sep = '\t',
            stringsAsFactors = FALSE
        )
    )

    # Expand the genomic coordinates based on the first
    # three columns.
    controlled <- controlled[, list(chromosome = V1, index = seq(V2, V3), filename = V4), by = c('V1', 'V2', 'V3')][, c('chromosome', 'index', 'filename')]

    # TODO: abstract this part to command line?
    
    # Use regex to identify -/+ strand.
    # Slooooowwww...
    controlled <- controlled[, strand := unlist(lapply(controlled$filename, function(x) {
        if(gregexpr('plus', x)[[1]][1] > 0) {
            '+'
        } else {
            '-'
        }
    }))]

    # Get rid of the file name.
    controlled[, filename := NULL]

})

# Define the overlap for controls.
controls_overlap <- c()

# Go over each control and join with controls_overlap.

# Start with the first control.
controls_overlap <- controls[[1]]

# Join on any other controls.
if(length(controls) > 1) {

    for(i in seq(2, length(controls))) {
        
        # No copy necessary as we are trimming down
        # using the inner join anyways.
        controls_overlap <- controls_overlap[controls[[i]], on = c('chromosome', 'index', 'strand'), nomatch = NULL]
    }

}

# Same logic for treatments.
treatments <- lapply(treatments, function(treatment) {
    
    treated <- setDT(
        read.table(
            file = paste(c(opt$location, treatment), collapse = ''),
            sep = '\t',
            stringsAsFactors = FALSE
        )
    )
    
    treated <- treated[, list(chromosome = V1, index = seq(V2, V3), filename = V4), by = c('V1', 'V2', 'V3')][, c('chromosome', 'index', 'filename')]
    
    treated <- treated[, strand := unlist(lapply(treated$filename, function(x) {
        if(gregexpr('plus', x)[[1]][1] > 0) {
            '+'
        } else {
            '-'
        }
    }))]
    
    treated[, filename := NULL]

})

treatments_overlap <- c()

treatments_overlap <- treatments[[1]]

if(length(treatments) > 1) {

    for(i in seq(2, length(treatments))) {
        
        treatments_overlap <- treatments_overlap[treatments[[i]], on = c('chromosome', 'index', 'strand'), nomatch = NULL]
    }

}

# Now see what is in common between control and treatment.
control_only <- controls_overlap[!treatments_overlap, on = c('chromosome', 'index', 'strand')]
common <- controls_overlap[treatments_overlap, on = c('chromosome', 'index', 'strand'), nomatch = NULL]
treatment_only <- treatments_overlap[!controls_overlap, on = c('chromosome', 'index', 'strand')]

# Housekeeping step, remove characters from the chromosome
# number.

# Sloooowwww...
control_only$chromosome <- unlist(lapply(control_only$chromosome, function(x) substr(x, 4, nchar(x))))
common$chromosome <- unlist(lapply(common$chromosome, function(x) substr(x, 4, nchar(x))))
treatment_only$chromosome <- unlist(lapply(treatment_only$chromosome, function(x) substr(x, 4, nchar(x))))

# Write out everything.
write.table(
    x = control_only,
    file = paste(
        c(
            opt$`write-to`, 
            'control_only.m6a.peaks'
        ), 
        collapse = ''
    ),
    quote = FALSE,
    sep = '\t',
    row.names = FALSE
)

write.table(
    x = common,
    file = paste(
        c(
            opt$`write-to`, 
            'common.m6a.peaks'
        ), 
        collapse = ''
    ),
    quote = FALSE,
    sep = '\t',
    row.names = FALSE
)

write.table(
    x = treatment_only,
    file = paste(
        c(
            opt$`write-to`, 
            'treatment_only.m6a.peaks'
        ), 
        collapse = ''
    ),
    quote = FALSE,
    sep = '\t',
    row.names = FALSE
)
