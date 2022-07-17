# Utilities for making requests




# Imports

# Web requests
import requests

from OSUtils import OSUtils




class RequestUtils:
    
    # Download a requested resource
    # Source: https://www.codementor.io/@aviaryan/downloading-files-from-urls-in-python-77q3bs0un
    def download_url(
        self,
        where,
        url
    ):

        """
        Download a URL.
        """

        # where - where we want the download to go
        # url - the URL to download

        # Return the downloaded content directly.
        # TODO: homogenize path...
        with open(where + url.split('/')[-1], 'wb') as f:
            f.write(
                requests.get(
                    url, 
                    allow_redirects=True
                ).content
            )
    

    # Get the filename from the URL
    def filename_from_url(
        self,
        url
    ):

        """
        Extract the filename from a URL.
        """

        # url - the URL from which to extract the filename

        return url.split('/')[-1]
    
    
    # Check downloadability of a requested resource
    # Source: https://www.codementor.io/@aviaryan/downloading-files-from-urls-in-python-77q3bs0un
    def is_downloadable(
        self,
        url
    ):
        
        """
        Does the url contain a downloadable resource?
        """

        # url - the URL to check for downloadability

        # Use headers to get the content type, then 
        # determine if we can download based on 
        # the content type.
        h = requests.head(
            url, 
            allow_redirects=True
        )

        header = h.headers

        content_type = header.get('content-type')

        # Multi-return allowed because of simple logic.
        
        # Can't download the URL.
        if 'text' in content_type.lower():
            return False
        if 'html' in content_type.lower():
            return False
        
        # Can download the URL.
        return True




# Instantations.
OU = OSUtils()
RU = RequestUtils()

# The URL to try.
dwnld = 'https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE116334&format=file'

# Establish where to download URLs.
url_path = OU.pathalize(
    pth = './'
)

# Can we even download the URL?
RU.is_downloadable(
    url = dwnld
)

# If so, download the URL.
RU.download_url(
    where = url_path,
    url = dwnld
)

# Decompress the tar.
OU.decompress_tar(
    source_file = RU.filename_from_url(
        url = dwnld
    ),
    where = url_path
)

# Decompress each of the .gz files.
for f in OU.file_list_by_extension(
    p = OU.homogenize_path(
            p = '/home/helios/Desktop/workspace/pib792/library'
        ), 
    xtnsn = 'gz'
    ):
        
        OU.decompress_gzip(
            source_file = f,
            where = url_path
        )