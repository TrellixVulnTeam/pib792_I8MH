# Utilities for analyzing genomic data




# Imports

# Writing files
import os

# Homogenizing file paths
from . import OSUtils

# Random sequences
import random

# Regex
import re

# System calls
import subprocess




# Universal instantiations
OU = OSUtils.OSUtils()




class GenomeUtils:
    

    # Call BLAST+
    def call_blast(
        self,
        db_path,
        name,
        sequence,
        write_to
    ):

        """
        Given a sequence, ask BLAST to look for it in fasta.
        """

        # db_path (string) - Where the BLAST database is
        # name (string) - The filename to use when writing the results
        # sequence (string) - The sequence to search for
        # fasta (string) - The path to the FASTA file
        # write_to (string) - Where to write the results

        # Homogenize write_to right away.
        write_to = OU.homogenize_path(
            p = write_to
        )
        
        if os.path.exists(write_to):
            
            # Call via the OS.
            subprocess.Popen(self.blast_path + "blastn -task 'blastn-short' -db " + db_path + " -query " + sequence + " -num_threads 4 > " + write_to + name + '.BLAST.results', shell = True)
            

    # Parse BLAST+ output
    def parse_blast(
        self,
        where,
        write_to
    ):

        """
        Given BLAST+ output, return chromsomes and coordinates
        of matches.
        """

        # where (string) - the path to the BLAST+ output
        # write_to (string) - the path to write to

        # Homogenize write_to right away.
        write_to = OU.homogenize_path(p = write_to)
        
        # Do where and write_to exist?
        if os.path.exists(where) and os.path.exists(write_to):
            
            # Open the output.
            with open(where, 'r') as f:
                
                # Read line-by-line, capturing the output.
                blast_read = f.readlines()

                # Go over each line, keeping track of whether or not we're
                # reading a match record or not.
                match_record = False

                # Create a dictionary to hold the results.
                matches = {}

                # Open the writing location under the assumption
                # that we will, in fact, write.
                with open(write_to + where.split('/')[-1] + '.matches', 'w') as matches_file:

                    # Write the header.
                    matches_file.write('chromosome\tstart\tstop\n')

                    for line in blast_read:

                        # Check to see if we have a match record starting.
                        check_match = re.match('>\d+', line)

                        # Did we have any match at all?
                        if check_match:
                            if check_match.group() != match_record:
                                
                                # The match record can be parsed to get the
                                # chromosome number.
                                chromosome_number = check_match.group().split('>')[1]

                                # Initialize the dictionary.
                                matches[chromosome_number] = []
                                
                                # We are now in a match record.
                                match_record = True

                        # Only enter logic if there is any match at all.
                        if match_record == True:

                            # Are we reading a line with match information?
                            match_information = re.finditer('Sbjct  \d+(.*?)\d+', line)

                            # Go over each match on the line.
                            if match_information:
                                for m in match_information:

                                    # Store the information.

                                    # First, split the line.
                                    split_up = m.group().split('  ')

                                    # Write the match to file.
                                    matches_file.write('\t'.join([chromosome_number, split_up[1], split_up[3]]) + '\n')


    # Generate a random motif of length n
    def random_motif(
        self,
        n,
        t
    ):

        """
        Generate a random motif of length n.
        """

        # n (int) - the number of nucleotides to generate per sequence
        # t (int) - how many sequences to generate
        
        # Could use weights here for CpG heavy regions???
        return [''.join(random.choices(['A', 'C', 'G', 'T'], k = n)) for s in range(0, t)]
    

    # Given sequences, write FASTA files
    def write_fastas(
        self,
        sequences,
        where,
        custom_name=None
    ):
    
        """
        Given sequences, write FASTA files
        """

        # sequences (list) - the sequences to write to file
        # where (string) - the folder to write to
        # custom_name (string) - a specific name to use for the output file.

        # Homogenize where right away.
        where = OU.homogenize_path(p = where)
                
        # Does where exist?
        if os.path.exists(where):

            # Write the files.
            for sequence in sequences:
                
                if custom_name == None:
                    with open(where + sequence + '.fa', 'w') as f:
                        f.write(
                            '>random_sequence\n' + sequence + '\n'
                        )
                else:
                    with open(where + custom_name + '.fa', 'w') as f:
                        f.write(
                            '>random_sequence\n' + sequence + '\n'
                        )