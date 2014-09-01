require! <[fs express mongodb body-parser crypto]>
require! <[passport passport-local passport-facebook express-session]>
require! <[nodemailer nodemailer-smtp-transport]>

base = do
  authorized: (cb) -> (req, res) ->
    if not (req.user and req.user.isStaff) => return res.status(403).render('403', {url: req.originalUrl})
    cb req, res

  context-wrapper: (obj) ->
    "angular.module('backend', []) .factory('context', function() { return #{JSON.stringify(obj)}; });"

  stream-writer: (res, stream) ->
    first = true
    res.write("[")
    stream.on \data, (it) ->
      if first == true => first := false
      else res.write(",")
      res.write(JSON.stringify it)
    stream.on \end, -> 
      res.write("]")
      res.send!

  update-user: (req) -> req.logIn req.user, ->

  # sample data, from g0v.photos
  config: -> do
    clientID: \252332158147402
    clientSecret: \763c2bf3a2a48f4d1ae0c6fdc2795ce6
    session-secret: \featureisameasurableproperty
    url: \http://g0v.photos/
    mongodbUrl: \mongodb://localhost/g0vphotos
    port: \9000
    mail: do
      host: \box590.bluehost.com
      port: 465
      secure: true
      maxConnections: 5
      maxMessages: 10
      auth: {user: 'noreply@g0v.photos', pass: ''}

  init: (config) ->
    app = express!
    app.use body-parser.json!
    app.use body-parser.urlencoded extended: true
    app.set 'view engine', 'jade'

    passport.use new passport-local.Strategy {
      usernameField: \email
      passwordField: \passwd
    },(u,p,done) ->
      p = crypto.createHash(\md5).update(p).digest(\hex)
      (e,r) <- base.cols.user.findOne {email: u}
      if !r =>
        user = {email: u, passwd: p, name: u.replace(/@.+$/, "")}
        (e,r) <- base.cols.user.insert user, {w: 1}
        if !r => return done {server: "failed to create user"}, false
        return done null, user
      else
        if r.passwd == p => return done null, r
        done null, false
    passport.use new passport-facebook.Strategy(
      do
        clientID: config.clientID
        clientSecret: config.clientSecret
        callbackURL: "#{config.url}u/auth/facebook/callback"
      , (access-token, refresh-token, profile, done) ->
        done null, profile
    )

    app.use express-session secret: config.session-secret, resave: false, saveUninitialized: false
    app.use passport.initialize!
    app.use passport.session!

    passport.serializeUser (u,done) -> done null, JSON.stringify(u)
    passport.deserializeUser (v,done) -> done null, JSON.parse(v)

    router = do
      user: express.Router!
      api: express.Router!

    app.use "/d", router.api
    app.use "/u", router.user
    app.get "/d/health", (req, res) -> res.json {}

    router.user
      ..get \/null, (req, res) -> res.json {}
      ..get \/me, (req,res) ->
        info = if req.user => req.user{email} else {}
        res.set("Content-Type", "text/javascript").send(
          "angular.module('main').factory('user',function() { return "+JSON.stringify(info)+" });"
        )
      ..get \/200, (req,res) -> res.json(req.user)
      ..get \/403, (req,res) -> res.status(403)send!
      ..get \/login, (req, res) -> res.render \login
      ..post \/login, passport.authenticate \local, do
        successRedirect: \/u/200
        failureRedirect: \/u/403
      ..get \/logout, (req, res) ->
        req.logout!
        res.redirect \/
      ..get \/auth/facebook, passport.authenticate \facebook
      ..get \/auth/facebook/callback, passport.authenticate \facebook, do
        successRedirect: \/u/200
        failureRedirect: \/u/403

    postman = nodemailer.createTransport nodemailer-smtp-transport config.mail

    @ <<< {config, app, express, router, postman}

  start: (cb) ->
    server = @app.listen @config.port, -> console.log "listening on port #{server.address!port}"
    mongodb.MongoClient.connect @config.mongodbUrl, (e, db) ~> 
      if !db => 
        console.log "[ERROR] can't connect to mongodb server:"
        throw new Error e
      (e, c) <~ db.collection \user
      cols = {user: c}
      @ <<< {server, db, cols}
      cb {db, server, cols}

module.exports = base
