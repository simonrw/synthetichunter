backend_version = '1.0'

api_path = ->
    '/api/' + backend_version

express = require 'express'
frontend = require './routes/frontend'
backend = require './routes/backend-' + backend_version
http = require 'http'
cluster = require 'cluster'
numCPUs = require('os').cpus().length
path = require 'path'
sessionServer = require('./lib/mongoconnection').sessionServer
MongoStore = require 'express-session-mongo'

worker_process = () ->
    app = express()

    app.configure () ->
        app.set 'port', process.env.PORT || 3000
        app.set 'views', __dirname + '/views'
        app.set 'view engine', 'jade'
        app.use express.favicon()
        app.use express.logger 'dev'
        app.use express.bodyParser()
        app.use express.methodOverride()
        app.use express.cookieParser()
        app.use express.session { 
            secret: 'SyntheticHunter'
            store: new MongoStore { 
                server: sessionServer 
            }
        }
        app.use app.router
        app.use express.static path.join __dirname, 'public'


    app.configure 'development', () ->
        app.use express.errorHandler()

    app.get '/', frontend.index
    app.get '/results', frontend.results
    app.get '/results/:id', frontend.object
    app.get '/results/:id/transits', frontend.transits

    app.post api_path() + '/objects', backend.objects
    app.get api_path() + '/objects/:id', backend.detail
    app.get api_path() + '/objects/:id/transits', backend.transits
    app.put api_path() + '/objects/:id', backend.update

    app.post api_path() + '/user', backend.user
    app.get api_path() + '/user/:username', backend.get_user_from_username
    app.post api_path() + '/user/id', backend.get_user_from_id


    http.createServer(app).listen(app.get('port'), () ->
        console.log 'Express server listening on port ' + app.get 'port'
    )

if process.env.MULTI != undefined
    if cluster.isMaster
        for cpu in [1..numCPUs]
            cluster.fork()

    else
        worker_process()
else
    worker_process()
