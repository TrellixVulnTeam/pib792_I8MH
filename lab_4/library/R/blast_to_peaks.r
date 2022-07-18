# Take BLAST results and align them to peaks
# to see what overlap there is.




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
            '-b', '--blast-matches'
        ),
        type = 'character',
        default = './',
        help = 'The full path to the BLAST matches file, e.g. /some/path/to/the/results/BLAST.results.matches. (required)'
    ),
    make_option(
        c(
            '-p', '--peaks'
        ),
        type = 'character',
        default = './',
        help = 'The full path to the peaks file, e.g. /some/path/to/the/results/treatment.peaks. (required)'
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
if(substr(opt$`write-to`, nchar(opt$`write-to`), nchar(opt$`write-to`)) != '/') {
    opt$`write-to` <- paste(c(opt$`write-to`, '/'), collapse = '')
}

# Do we have valid locations?
if(!file.exists(opt$`blast-matches`)) {
    cat(paste(c('\nThe path provided for -b/--blast-matches (\'', opt$`blast-matches`, '\') was not found!  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

if(!file.exists(opt$peaks)) {
    cat(paste(c('\nThe path provided for -p/--peaks (\'', opt$peaks, '\') was not found!  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

if(!dir.exists(opt$`write-to`)) {
    cat(paste(c('\nThe path provided for -w/--write-to (\'', opt$`write-to`, '\') was not found!  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}




# Load the BLAST matches.
blast <- setDT(
    read.table(
        file = opt$`blast-matches`,
        header = TRUE,
        sep = '\t',
        stringsAsFactors = FALSE
    )
)

# Load the peaks.
peaks <- setDT(
    read.table(
        file = opt$`peaks`,
        header = TRUE,
        sep = '\t',
        stringsAsFactors = FALSE
    )
)

# Align BLAST file to the peak file.

# BLAST needs to be expanded along 
# the long axis.
blast <- blast[, list(chromosome = chromosome, index = seq(start, stop)), by = c('chromosome', 'start')][, c('chromosome', 'index')]

# Small type error...
blast$chromosome <- as.character(blast$chromosome)

# Get the BLAST results filename from the end of the 
# path.
blast_name <- strsplit(opt$`blast-matches`, '/')[[1]]
blast_name <- blast_name[length(blast_name)]
blast_name <- paste(c(blast_name, '.compare'), collapse = '')

# Get the peak filename from the end of the
# path.
peak <- strsplit(opt$`peaks`, '/')[[1]]
peak <- peak[length(peak)]

# Combine the two names to make one filename.
combined_name <- paste(c(blast_name, peak), collapse = '-')

# Write what matches.
write.table(
    x = blast[peaks, on = c('chromosome', 'index'), nomatch = NULL],
    file = paste(
        c(
            opt$`write-to`, 
            combined_name
        ), 
        collapse = ''
    ),
    quote = FALSE,
    sep = '\t',
    row.names = FALSE
)