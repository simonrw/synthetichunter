backend_version = '1.0'

api_path = ->
    '/api/' + backend_version

express = require 'express'
frontend = require './routes/frontend'
backend = require './routes/backend-' + backend_version
http = require 'http'
Cluster = require 'cluster2'
numCPUs = require('os').cpus().length
path = require 'path'
db_config = require('./lib/mongoconnection').session_db_config
MongoStore = require('connect-mongo')(express)

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
        secret: '15e6a705-6424-11e2-b1dd-d49a20b7f7f2'
        store: new MongoStore db_config
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

# Start the app with cluster
c = new Cluster {
    port: app.get 'port'
}

# Cluster events
c.on 'forked', (pid) ->
    logger.info 'Server process forked', { pid: pid }

c.on 'died', (pid) ->
    logger.info 'Server process died', { pid: pid }

c.listen (cb) ->
    cb app
