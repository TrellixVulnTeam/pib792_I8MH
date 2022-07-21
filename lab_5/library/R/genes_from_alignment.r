# Provided a file with peak locations, 
# the genes in which the peaks occured.




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
            '-g', '--genome'
        ),
        type = 'character',
        default = './',
        help = 'The full path to the genome file, e.g. /some/path/to/the/genome/file.gff3. (required)'
    ),
    make_option(
        c(
            '-l', '--location'
        ),
        type = 'character',
        default = './',
        help = 'Where to search for the peak files. (required)'
    ),
    make_option(
        c(
            '-r', '--regex'
        ),
        type = 'character',
        default = NULL,
        help = 'The filename regex for the peak files. (required)'
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

# Testing only start.

# opt <- list()

# opt$`genome` <- '/home/aeros/analyses/genomes/a_thaliana/from_chris/from_chris456w0oiatmp'
# opt$`location` <- '/home/aeros/analyses/lab_5/batches/578aca5b-eca1-4585-9fa4-422e304ae641/treatment_match/'
# opt$`regex` <- 'peaks'
# opt$`write-to` <- './'

# Testing only end.

# Homogenize the locations.
if(substr(opt$location, nchar(opt$location), nchar(opt$location)) != '/') {
    opt$location <- paste(c(opt$location, '/'), collapse = '')
}

if(substr(opt$`write-to`, nchar(opt$`write-to`), nchar(opt$`write-to`)) != '/') {
    opt$`write-to` <- paste(c(opt$`write-to`, '/'), collapse = '')
}

# Do we have valid locations?
if(!file.exists(opt$`genome`)) {
    cat(paste(c('\nThe path provided for -g/--genome (\'', opt$`genome`, '\') was not found!  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

if(!dir.exists(opt$location)) {
    cat(paste(c('\nThe path provided for -l/--location (\'', opt$location, '\') was not found!  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

if(!dir.exists(opt$`write-to`)) {
    cat(paste(c('\nThe path provided for -w/--write-to (\'', opt$`write-to`, '\') was not found!  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

# Look for the peak files.
if(is.null(opt$`regex`)) {
    cat(paste(c('\nNo regex was provided using -r/--regex.  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

peaks <- dir(
    path = opt$location,
    pattern = opt$`regex`
)

# Only proceed if there are any peak files.
if(length(peaks) == 0) {
    cat(paste(c('\nNo peak files found at \'', opt$location, '\' using regex ', opt$`regex`, '  \n\nQuitting...\n\n'), collapse = ''))
    return(-1)
}

# Load the genome.
genome <- setDT(
    read.table(
        file = opt$`genome`,
        header = TRUE,
        sep = '\t',
        stringsAsFactors = FALSE
    )
)

# Load the peaks and align them to the genome.
lapply(peaks, function(peak) {

    # Read the peak file.
    peak_file <- setDT(
        read.table(
            file = paste(c(opt$location, peak), collapse = ''),
            header = TRUE,
            sep = '\t',
            stringsAsFactors = FALSE
        )
    )

    # Slight error in type..
    peak_file$chromosome <- as.character(peak_file$chromosome)
    peak_file$index <- as.character(peak_file$index)
    peak_file$strand <- as.character(peak_file$strand)

    # Align the peak file to the genome (inner join) and write out
    # the match position along with the gene name.

    # Make the file name based on the peaks file.
    file_split <- strsplit(x = peak, split = '.', fixed = TRUE)[[1]]
    motif <- file_split[1]
    category <- strsplit(x = file_split[4], split = '-')[[1]][2]
    file_name <- paste(c(motif, category, 'genome_align'), collapse = '.')

    write.table(
        x = peak_file[genome, on = c('chromosome', 'index', 'strand'), nomatch = NULL],
        file = paste(
            c(
                opt$`write-to`,
                file_name
            ), 
            collapse = ''
        ),
        quote = FALSE,
        sep = '\t',
        row.names = FALSE
    )

})