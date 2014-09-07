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
    module.exports = base


About Google cloud service
========

Something that worths noted:

 * datastore don't accept empty object, undefined or null value.
 * indexed items all have length limit. try not index those who need to be lengthy
 * don't know why, but query can't have:
   - more than one order
   - order and filter at the same time.
