g0vphotos
========

A photo / media sharing web service with default CC license. 

Usage
========

need a secret.ls like this

    base = do
      config: do
        clientID: ????
        clientSecret: ???
        gcs:
          projectId: ???
          keyFilename: ???
    module.exports = base


About Google Cloud Service
========

Something that worths noted:

 * datastore don't accept empty object, undefined or null value.
 * indexed items all have length limit. try not index those who need to be lengthy
 * don't know why, but query can't have:
   - more than one order
   - order and filter at the same time.
 * on GCE credential seems to expire periodically, so one shall consider using json key instead.

Todo Items
=========

Event Host Related
 * Subscribe mechanism
 * Purchase / sell photo
 * Editor's choice
 * Photo update push (with redis + websocket)
 * Lightbox photostream *
 * Event CRUD *
 * Organization CRUD
 * GIS View

Retention & Acquisition
 * Social comment box *
 * like / share button *

Ease of Use
 * Android / iOS APP
 * Report of abuse
 * Claim of portrait right
 * Alternative order - by time, by fav count *
 * Face detection

Account Related
 * Profile page
 * Account quota
 * Invitation only mode
 * Download my photo
