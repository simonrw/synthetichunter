Synthetic hunter
================

Tool for interacting with the [Synthetic Hunter database](http://sirius.astro.warwick.ac.uk:3000).

URL routing
-----------

Here we define the url routing scheme for the backend. All backend routes return json formatted information

### Front end

    GET /                                   -> form page for the options
    GET /results                            -> list of the objects which are returned by the form
    GET /results/:id                        -> object detail page
    GET /results/:id/transits               -> object transit plots

### Back end

    POST /api/:version/objects                  -> returns the objects in json form
    POST /api/:version/objects/:id              -> returns a specific object
    POST /api/:version/objects/:id/transits     -> transit images
    
    PUT /api/:version/objects/:id               -> update the object user inputs

Class structure
---------------

### Index

None

### Detail

* lc image
* pgram image
* phasespace image
* object id
* mcmc parameters
* input/orion parameters
* links
    * back link
    * transit images link

### Transits

* transit images

