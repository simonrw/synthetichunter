###
This code creates the mongo and mongoose connections to a common database
###

logger = require('./logger').logger
mongoose = require 'mongoose'
os = require 'os'

# Development/Production check
hostname = os.hostname()
if hostname == 'mbp.local' or hostname == 'sirius' or hostname == 'mbp.lan'
    server_url = 'localhost'
else
    server_url = 'sirius.astro.warwick.ac.uk'

logger.log 'info', "Connecting to mongo on hostname: #{server_url}"

# Some configuration variables
port = 27017
db_name = 'hunter'

exports.session_db_config = {
    db: 'huntersessions'
    host: server_url
    port: port
    collection: 'sessions'
}


mongoose.connect "mongodb://#{server_url}:#{port}/#{db_name}"

exports.db = mongoose.connection


