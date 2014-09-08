require! <[fs path child_process express mongodb body-parser crypto chokidar]>
require! <[passport passport-local passport-facebook express-session]>
require! <[nodemailer nodemailer-smtp-transport LiveScript]>
require! <[connect-multiparty gcloud]>

datastore = gcloud.datastore
RegExp.escape = -> it.replace /[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"

ls   = if fs.existsSync v=\node_modules/.bin/livescript => v else \livescript
jade = if fs.existsSync v=\node_modules/.bin/jade => v else \jade
sass = if fs.existsSync v=\node_modules/.bin/sass => v else \sass
cwd = path.resolve process.cwd!
cwd-re = new RegExp RegExp.escape "#cwd#{if cwd[* - 1]=='/' => "" else \/}"
if process.env.OS=="Windows_NT" => [jade,sass,ls] = [jade,sass,ls]map -> it.replace /\//g,\\\
log = (error, stdout, stderr) -> if "#{stdout}\n#{stderr}".trim! => console.log that
mkdir-recurse = ->
  if !fs.exists-sync(it) => 
    mkdir-recurse path.dirname it
    fs.mkdir-sync it

sass-tree = do
  down-hash: {}
  up-hash: {}
  parse: (filename) ->
    dir = path.dirname(filename)
    ret = fs.read-file-sync filename .toString!split \\n .map(-> /^ *@import (.+)/.exec it)filter(->it)map(->it.1)
    ret = ret.map -> path.join(dir, it.replace(/(\.sass)?$/, ".sass"))
    @down-hash[filename] = ret
    for it in ret => if not (filename in @up-hash.[][it]) => @up-hash.[][it].push filename
  find-root: (filename) ->
    work = [filename]
    ret = []
    while work.length > 0
      f = work.pop!
      if @up-hash.[][f].length == 0 => ret.push f
      else work ++= @up-hash[f]
    ret

lsc = (path, options, callback) ->
  opt = {} <<< options
  delete opt.settings
  try
    [err,ret] = [null, LiveScript.compile((fs.read-file-sync path .toString!))]
    ret = "var req = #{JSON.stringify(opt)}; #ret"
  catch e
    [err,ret] = [e,""]
  callback err, ret

ftype = ->
  switch
  | /\.ls$/.exec it => "ls"
  | /\.sass$/.exec it => "sass"
  | /\.jade$/.exec it => "jade"
  | otherwise => "other"

session-store = (ds) -> @ <<<
  ds: ds
  get: (sid, cb) ->
    (e,t,n) <- @ds.runQuery (@ds.createQuery <[session]> .filter "__key__ =", @ds.key(\session, sid)), _
    if !e and t and t.length => session = JSON.parse(new Buffer(t.0.data.session, \base64).toString \utf8)
    else => session = null
    if cb => cb e, session
  set: (sid, session, cb) ->
    session = new Buffer(JSON.stringify session).toString \base64
    @ds.save {key: @ds.key(\session, sid), data: {session}}, (e,k) -> if cb => cb e
  destroy: (sid, cb) ->
    @ds.delete @ds.key(\session, sid), (e) -> if cb => cb e
session-store.prototype = express-session.Store.prototype

base = do
  clean: (obj) ->
    for k,v of obj =>
      if typeof(v)=='object' => 
        @clean v
        if [k for k of v]length == 0 => delete obj[k]
      else if v==undefined or v==null => delete obj[k]
    obj

  authorized: (cb) -> (req, res) ->
    if not (req.user and req.user.isStaff) => return res.status(403).render('403', {url: req.originalUrl})
    cb req, res

  context-wrapper: (obj) ->
    "angular.module('backend', []).factory('context', function() { return #{JSON.stringify(obj)}; });"

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

  # sample configuration
  config: -> do
    clientID: \252332158147402
    clientSecret: \763c2bf3a2a48f4d1ae0c6fdc2795ce6
    session-secret: \featureisameasurableproperty
    url: \http://g0v.photos/
    name: \servlet
    mongodbUrl: \mongodb://localhost/
    port: \9000
    debug: true
    limit: '20mb'
    cookie: do
      domain: \.g0v.photos
    gcs: do
      projectId: \keen-optics-617
      keyFilename: \/Users/tkirby/.ssh/google/g0vphotos/key.json
    mail: do
      host: \box590.bluehost.com
      port: 465
      secure: true
      maxConnections: 5
      maxMessages: 10
      auth: {user: 'noreply@g0v.photos', pass: ''}

  getUser: (u, p, usepasswd, detail, done) ->
    p = if usepasswd => crypto.createHash(\md5).update(p).digest(\hex) else ""
    (e,t,n) <~ @dataset.runQuery (@dataset.createQuery <[user]> .filter "email =", u), _
    if !t.length =>
      name = if detail => detail.displayName or detail.username else u.replace(/@.+$/, "")
      @clean detail
      user = {email: u, passwd: p, usepasswd, name, detail}
      (e,k) <~ @dataset.save { key: @dataset.key(\user, null), data: user}, _
      if e => return done {server: "failed to create user"}, false
      delete user.passwd
      user.fav = {}
      return done null, user
    else
      user = t.0.data
      if (usepasswd or user.usepasswd) and user.passwd != p => return done null, false
      delete user.passwd
      (e,t,n) <~ @dataset.runQuery (@dataset.createQuery <[fav]> .filter "email =", u), _
      if e => return done null, false
      user.fav = {}
      # TODO handle next / pagination if necessaary
      t.map -> user.fav[it.data.pic] = true
      return done null, user

  events: {}
  getLatestEvent: (req, cb) ->
    (e,t,n) <~ @dataset.runQuery (@dataset.createQuery <[event]>), _
    if e or !t => return
    for it in t => @events[it.data.event] = it.data

  getEvent: (req, cb) ->
    part = req.headers.host.split \.
    event = if part.length > 2 => part.0 else ""
    if !event => return cb null, "", {}
    if @events[event] => return cb null, event, @events[event]
    (e,t,n) <~ @dataset.runQuery (@dataset.createQuery <[event]> .filter "event =", event), _
    if e or !t or t.length==0 => return cb true, null, {}
    @events[event] = obj = t.0.data
    cb null, event, obj

  init: (config) ->
    config = {} <<< @config! <<< config
    app = express!
    app.use body-parser.json limit: config.limit
    app.use body-parser.urlencoded extended: true, limit: config.limit
    app.use (req, res, next) ~> # retrieve subdomain
      (error, event, obj) <- @getEvent req, _
      if error or !event => return next!
      req.event = {name: event, data: obj}
      next!
    app.set 'view engine', 'jade'
    app.engine \ls, lsc
    app.use \/, express.static("#__dirname/static")
    app.set 'views', path.join(__dirname, 'view')

    passport.use new passport-local.Strategy {
      usernameField: \email
      passwordField: \passwd
    },(u,p,done) ~> @getUser u, p, true, null, done

    passport.use new passport-facebook.Strategy(
      do
        clientID: config.clientID
        clientSecret: config.clientSecret
        callbackURL: "/u/auth/facebook/callback"
        profileFields: ['id', 'displayName', 'link', 'emails']
      , (access-token, refresh-token, profile, done) ~>
        @getUser profile.emails.0.value, null, false, profile, done
    )

    c = {} <<< config.{}gcs{projectId}
    if config.{}gcs.keyFilename and fs.exists-sync(config.gcs.keyFilename) => c.keyFilename = config.gcs.keyFilename
    dataset = new datastore.Dataset c
    # experimental - seems that dataset will be expired for a short period of time
    setTimeout ~>
      @dataset = new datastore.Dataset c
    , 60 * 5

    app.use express-session do
      secret: config.session-secret
      resave: true
      saveUninitialized: true
      store: new session-store dataset
      cookie: do
        #secure: true # TODO: https. also need to dinstinguish production/staging
        path: \/
        httpOnly: true
        maxAge: 86400000 * 30 * 12 
        domain: config.cookie.domain if config.{}cookie.domain
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
      ..get \/auth/facebook, passport.authenticate \facebook, {scope: ['email']}
      ..get \/auth/facebook/callback, passport.authenticate \facebook, do
        successRedirect: \/
        failureRedirect: \/u/403

    postman = nodemailer.createTransport nodemailer-smtp-transport config.mail

    multi = do
      parser: connect-multiparty limit: config.limit
      clean: (req, res, next) ->
        for k,v of req.files => if fs.exists-sync v.path => fs.unlink v.path
      cleaner: (cb) -> (req, res, next) ~>
        if cb => cb req, res, next
        @clean req, res, next

    @watch!
    @ <<< {config, app, express, router, postman, multi, dataset}

  start: (cb) ->

    @getLatestEvent!
    if !@config.debug => 
      @app.use (err, req, res, next) -> if err => res.status 500 .render '500' else next!

    server = @app.listen @config.port, -> console.log "listening on port #{server.address!port}"
    mongodb.MongoClient.connect "#{@config.mongodbUrl}#{@config.name}", (e, db) ~> 
      if !db => 
        console.log "[ERROR] can't connect to mongodb server:"
        throw new Error e
      (e, c) <~ db.collection \user
      cols = {user: c}
      @ <<< {server, db, cols}
      cb {db, server, cols}

  ignore-list: [/^server.ls$/, /^library.jade$/, /^(.+\/)*?\.[^/]+$/, /^node_modules\//, /^static\//]
  ignore-func: (f) -> @ignore-list.filter(-> it.exec f.replace(cwd-re, "")replace(/^\.\/+/, ""))length
  watch-path: \src
  watch: ->
    watcher = chokidar.watch @watch-path, ignored: (~> @ignore-func it), persistent: true
      .on \add, @watch-handler
      .on \change, @watch-handler
  watch-handler: (it) -> 
    (x) <- setTimeout _, 100
    src = if it.0 != \/ => path.join(cwd,it) else it
    src = src.replace path.join(cwd,\/), ""
    [type,cmd,dess] = [ftype(src), "",[]]
    if type == \ls => 
      des = src.replace \src/ls, \static/js
      des = des.replace /\.ls$/, ".js"
      cmd = "#ls -cbp #src > #des"
      dess.push des
    else if type == \sass => 
      sass-tree.parse src
      srcs = sass-tree.find-root src
      cmd = srcs.map (src) ->
        des = src.replace \src/sass, \static/css
        des = des.replace /\.sass/, ".css"
        dess.push des
        "#sass #src #des"
      cmd = cmd.join \;
    else => return
    if !cmd => return
    if dess.length => for dir in dess.map(->path.dirname it) =>
      if !fs.exists-sync dir => mkdir-recurse dir
    console.log "[BUILD] #cmd"
    child_process.exec cmd, log

module.exports = base
