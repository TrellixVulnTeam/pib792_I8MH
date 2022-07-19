# Utilities for interacting with the operating system




# Imports

# globbing
import glob

# gzip decompression
import gzip

# Absolute paths
import os

# TAR decompression
import tarfile




class OSUtils:
    

    def decompress_gzip(
        self,
        source_file,
        where
    ):

        """
        Decompress a gzip archive.
        """

        # source_file - the file path
        # where - the path to decompress to
        
        # Source: https://stackoverflow.com/a/69006457
        with gzip.open(source_file, 'rt') as f:
                        
            # Write the contents.
            with open(where + '.'.join(source_file.split('/')[-1].split('.')[:-1]), 'w') as g:
                g.write(
                    f.read()
                )
    

    def decompress_tar(
        self,
        source_file,
        where
    ):

        """
        Decompress a tar archive.
        """

        # source_file - the file path
        # where - the path to extract to
        
        with tarfile.open(source_file) as f:
            f.extractall(
                path = where
            )
    

    # Homogenize file paths, i.e. make sure 
    # path names end in '/'.
    def homogenize_path(
        self, 
        p
    ):

        """
        Homogenize file paths.
        """

        # If there is not a forward slash, add one.
        if p[-1] != '/':
            return p + '/'
        else:
            return p
    

    def file_list_by_extension(
        self,
        p,
        xtnsn
    ):

        """
        Get all of the files at path p by extension xtnsn.
        """

        # p - the path to look in
        # xtnsn - the extension to look for
        
        return glob.glob(
            pathname = p + '*.' + xtnsn
        )
    

    def pathalize(
        self,
        pth
    ):

        """
        Convert a relative path to an absolute path.
        """

        # p - the path

        return self.homogenize_path(
            p = os.path.abspath(
                pth
            )
        )

