# Utilities for making requests




# Imports

# Web requests
import requests

from . import OSUtils




# Universal instantations
OU = OSUtils.OSUtils()




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