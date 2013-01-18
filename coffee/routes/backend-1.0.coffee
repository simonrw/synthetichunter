os = require 'os'

# Set up winston
winston = require 'winston'

# Only log to a file
winston.add winston.transports.File, { filename: "hunter.log" }

mongoose = require 'mongoose'


# Development/Production check
hostname = os.hostname()
if hostname == 'mbp.local' or hostname == 'sirius'
    server_url = 'localhost'
else
    server_url = 'sirius.astro.warwick.ac.uk'

winston.log 'info', "Connecting to mongo on hostname: #{server_url}"

# Some configuration variables
port = 27017
db_name = 'hunter'
mongoose.connect "mongodb://#{server_url}:#{port}/#{db_name}"
db = mongoose.connection

# Bind error commands to the console
db.on 'error', console.error.bind console, 'connection error:'
db.once 'open', ->
    winston.log 'info', 'Mongo connection open'

# Define the schema
objectSchema = new mongoose.Schema {
    obj_id: String
    file_info: {
        phase_filename: String
        pg_filename: String
        tr_filenames: [String]
        lc_filename: String
        data_filename: String
    }
    object_info: {
        orion: {
            delta_chisq: Number
            vmag: Number
            period: Number
            sde: Number
            radius: Number
            a: Number
            rstar: Number
            i: Number
            epoch: Number
            width: Number
            depth: Number
            ntrans: Number
        }
        mcmc: {
            clump_idx: Number
            teff: Number
            period: Number
            sn_ellipse: Number
            radius: Number
            dchisq_mr: Number
            rstar: Number
            depth: Number
            sn_red: Number
            epoch: Number
            prob_rp: Number
        }
        obj_id: String
    }
    random: Number
    user_info: [ { sessionid: String, value: String } ]
}
userSchema = new mongoose.Schema {
    username: String
    sessionid: String
}

Object = mongoose.model 'Object', objectSchema
User = mongoose.model 'User', userSchema

# Returns a list of objects which match the input sorting/filtering criteria
exports.objects = (req, res) ->
    limit = if req.body.limit != undefined then parseInt req.body.limit else 20
    query = Object.find()

    sort_var = req.body.sort_var
    if req.body.sort == 'true'
        console.log 'Sorting'
        _orion_base = 'object_info.orion.'
        _mcmc_base = 'object_info.mcmc.'
        switch sort_var
            when 'SDE' then sort_var = _orion_base + 'sde'
            when 'Planetary radius' then sort_var = _orion_base + 'radius'
            when 'Orbital period' then sort_var = _orion_base + 'period'
            when 'Transit depth' then sort_var = _orion_base + 'depth'
            when 'Stellar radius' then sort_var = _orion_base + 'rstar'
            when 'V magnitude' then sort_var = _orion_base + 'vmag'
            when 'Effective temperature' then sort_var = _mcmc_base + 'teff'

        if req.body.sort_direction == '1' 
            sort_var = sort_var 
        else 
            sort_var = '-' + sort_var

        query.sort sort_var
    else
        console.log 'Not sorting'

    query.limit(limit)

    query.exec (err, results) ->
        if err
            winston.log 'error', err

        res.send results

# Just returns the single object requested
exports.detail = (req, res) ->
    Object.findById req.params.id, (err, result) ->
        if err
            winston.log 'error', err

        res.send result

# Returns just the required information for an objects transit images
exports.transits = (req, res) ->
    Object.findById req.params.id, (err, result) ->
        if err
            winston.log 'error', err

        object = {
            obj_id: result.obj_id
            tr_filenames: result.file_info.tr_filenames
        }

        res.send object

# Updates an objects belief value
exports.update = (req, res) ->
    id = req.params.id
    value = req.body.value
    user = req.body.sessionid

    Object.findById id, (err, result) ->
        if err
            winston.log 'error', err

        found = false
        for user_info, i in result.user_info
            if user_info.sessionid == user
                # Change the value
                console.log "Updating value for user #{user} from #{result.user_info[i].value} to #{value}"
                result.user_info[i].value = value
                found = true

        if not found
            # Have to append the result to the array
            console.log "Appending the user's info"
            result.user_info.push {
                sessionid: user
                value: value
            }

        # Now save the object
        result.save (err) ->
            if err
                winston.log 'error', err

            res.send 'Ok'


exports.user = (req, res) ->
    #mongo_connection 'users', (collection) ->
    username = req.body.username
    sessionid = req.body.sessionid

    User.findOne { username: username, sessionid: sessionid }, (err, result) ->
        if err
            winston.log 'error', err

        if result?
            User.findOne { sessionid: sessionid }, (err, result) ->
                if err
                    winston.log 'error', err

                if result.username != username
                    result.username = username
                    result.save (err) ->
                        if err
                            winston.log 'error', err

                        res.send {
                            message: "Updated"
                        }

        else
            User({ username: username, sessionid: sessionid }).save (err) ->
                if err
                    winston.log 'error', err

                    res.send {
                        message: "Inserted"
                        username: username
                        sessionid: sessionid
                    }

# Gets a single user by id
exports.get_user_from_id = (req, res) ->
    User.findOne { sessionid: req.body.id }, (err, user) ->
        res.send user


# Returns a user from their username
exports.get_user_from_username = (req, res) ->
    User.findOne { username: req.params.username }, (err, user) ->
        res.send user
