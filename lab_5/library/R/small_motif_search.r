# Provided a genome, search for a small motif.




# Libraries

# Data table
library(data.table)
setDTthreads(threads = 80)

# Command line arguments
library(optparse)

# Parallel lapply
library(parallel)




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
            '-m', '--motifs'
        ),
        type = 'character',
        default = NULL,
        help = 'The motifs to search for.  Their lengths should be multiples of 3. (required)'
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

# Split the motifs on any space, then trim.
opt$`motifs` <- strsplit(' ')[[1]]
opt$`motifs` <- c(unlist(lapply(opt$`motifs`, function(x) if(length(x) > 0) {x.trimws()})))

print(opt$`motifs` == c('ACAGTGATT', 'AGGAGGCTC', 'GGGCTTCCTGCG'))

print(opt)
print(x)

# Testing only start.

# opt <- list()

# opt$`genome` <- '/home/aeros/analyses/genomes/a_thaliana/ensembl/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa'
# opt$`motifs` <- c('ACAGTGATT', 'AGGAGGCTC', 'GGGCTTCCTGCG')
# opt$`write-to` <- './'

# Testing only end.

# Define a function to invert a motif.
invert_motif <- function(x) {

    # x (character) - the motif
    
    # Split up the motif, then go through each
    # nucleotide and invert it.
    split_up <- strsplit(x, '')[[1]]

    split_up <- unlist(lapply(split_up, function(y) {

        if(y == 'A') {
            'T'
        } else if(y == 'T') {
            'A'
        } else if(y == 'C') {
            'G'
        } else {
            'C'
        }

    }))

    return(paste(split_up, collapse = ''))

}


# TODO: command line argument error checking...

# Load the genome.
genome <- setDT(
    setDT(
        read.table(
            file = opt$`genome`,
            sep = '\t',
            stringsAsFactors = FALSE
        )
    )
)

# TODO: should save the flattened FASTA information
# to file...

# (Start) Only done once to flatten the genome...

# Note: could simply this by just downloading each
# chromosome from Ensembl...
chromosome_positions <- unlist(lapply(seq_along(genome$V1), function(s) {
    if(substr(genome$V1[s], 1, 1) == '>') {
        s
    }
}))

# Note: FASTA file has no space between chromosome records
# so don't need to worry about that.
chromosomes <- lapply(seq(1, length(chromosome_positions)), function(x) {
    
    if(x != length(chromosome_positions)) {
        genome[(chromosome_positions[x]+1):(chromosome_positions[x+1]-1), ]$V1
    } else {
        genome[(chromosome_positions[x]+1):nrow(genome), ]$V1
    }

})

# We don't want the MT or chloroplast DNA...
chromosomes <- chromosomes[1:5]

# (Stop) Only done once to flatten the genome...

# Create a list to hold motif matches.
matches <- list()

# We will search both strands, that is,
# we will search for each motif and
# its complement.

for(motif in opt$`motifs`) {
    
    # Parallel lapply.

    # Original motif and its inversion.
    matches[[motif]] <- mclapply(seq(1, 5), function(x) grep(paste(c(motif, invert_motif(x = motif)), collapse = '|'), chromosomes[[x]]), mc.cores = detectCores())

}

# Now write the results similar to what we would get
# from BLAST.

# For each motif, we make a results file at opt$`write-to`.
lapply(names(matches), function(motif) {

    # Create a data table with all of the match
    # information.
    by_chromosome <- lapply(seq_along(matches[[motif]]), function(x) {

        # Establish which chromosome we're pulling matches from.
        c_number <- x

        # Only write anything if we have anything.
        if(length(matches[[motif]][[c_number]]) > 0) {
            
            # Make a data table with the start and stop information.
            starts_stops <- setDT(
                data.frame(
                    chromosome = c_number,
                    start = matches[[motif]][[c_number]]
                )
            )

            # The stop position is based on the length of the motif.
            starts_stops$stop <- starts_stops$start + nchar(motif) - 1

            starts_stops
                    
        }
    })

    # Collapse.
    by_chromosome <- data.table::rbindlist(by_chromosome)
    
    # Write the table.
    write.table(
        x = by_chromosome,
        file = paste(
            c(
                opt$`write-to`, 
                paste(
                    c(
                        motif, 
                        '.r_small_search.results'
                    ), 
                    collapse = ''
                )
            ), 
            collapse = ''
        ),
        quote = FALSE,
        sep = '\t',
        row.names = FALSE
    )

})