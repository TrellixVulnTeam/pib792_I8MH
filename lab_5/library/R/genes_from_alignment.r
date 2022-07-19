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
            '-g', '--genome-location'
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

# Homogenize the locations.
if(substr(opt$location, nchar(opt$location), nchar(opt$location)) != '/') {
    opt$location <- paste(c(opt$location, '/'), collapse = '')
}

if(substr(opt$`write-to`, nchar(opt$`write-to`), nchar(opt$`write-to`)) != '/') {
    opt$`write-to` <- paste(c(opt$`write-to`, '/'), collapse = '')
}

# Do we have valid locations?
if(!file.exists(opt$`genome-location`)) {
    cat(paste(c('\nThe path provided for -g/--genome-location (\'', opt$`genome-location`, '\') was not found!  \n\nQuitting...\n\n'), collapse = ''))
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
# genome <- setDT(
#     read.table(
#         file = opt$`genome-location`,
#         sep = '\t',
#         stringsAsFactors = FALSE
#     )
# )

# Load the peaks.
peaks <- lapply(peaks, function(peak) {

    # Read the peak file.
    setDT(
        read.table(
            file = paste(c(opt$location, peak), collapse = ''),
            sep = '\t',
            stringsAsFactors = FALSE
        )
    )

    # Align the peak file to the genome.
    # ...

    # Save the gene names only.

    # # Write out the gene names
    # write.table(
    #     x = control_only,
    #     file = paste(
    #         c(
    #             opt$`write-to`, 
    #             'control_only.m6a.peaks'
    #         ), 
    #         collapse = ''
    #     ),
    #     quote = FALSE,
    #     sep = '\t',
    #     row.names = FALSE
    # )

})