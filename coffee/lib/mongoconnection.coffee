###
This code creates the mongo and mongoose connections to a common database
###

logger = require('./logger').logger
mongoose = require 'mongoose'
os = require 'os'
mongodb = require 'mongodb'

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
mongoose.connect "mongodb://#{server_url}:#{port}/#{db_name}"

# Now set up the session store
exports.sessionServer = new mongodb.Server( server_url, port, { auto_reconnect: true })

# Exports
exports.db = mongoose.connection


