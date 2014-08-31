require! <[fs express mongodb body-parser crypto]>
require! <[passport passport-local passport-facebook express-session]>
require! <[nodemailer nodemailer-smtp-transport]>
require! <[./backend-base]>

backend = backend-base

config = do
  clientID: \252332158147402
  clientSecret: \763c2bf3a2a48f4d1ae0c6fdc2795ce6
  session-secret: \featureisameasurableproperty
  url: \http://g0v.photos/
  port: \9000
  mail: do
    host: \box590.bluehost.com
    port: 465
    secure: true
    maxConnections: 5
    maxMessages: 10
    auth: {user: 'noreply@g0v.photos', pass: ''}

backend.init config

backend.router.user
  ..get \/fav, (req, res) ->
  ..put \/fav, (req, res) ->
  ..delete \/fav, (req, res) ->

pic = backend.express.Router!
backend.app.use \/s, pic
backend.router.user
  ..get \/fav, (req, res) -> # get personal fav list. need pagination
  ..put \/fav/:id, (req, res) -> # fav some photo (both user / pic side)
  ..delete \/fav/:id, (req, res) -> # unfav some photo (both user / pic side)

pic
  ..get \/pic, (req, res) -> # get pic list (all site). need pagination
  ..post \/pic, (req, res) -> # upload pic (evnt specified in post data)

  ..get \/pic/:id, (req, res) -> # get specific photo info. JSON or HTML.
  ..put \/pic/:id/fav, (req, res) -> # fav some photo (both user / pic side)
  ..delete \/pic/:id/fav, (req, res) -> # unfav some photo (both user / pic side)

  ..get \/set/:id, (req, res) -> # get pic list (in event). need pagination
  ..post \/set/:id, (req, res) -> # upload pic (to event)

