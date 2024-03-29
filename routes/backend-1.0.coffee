os = require 'os'

# Set up logger
mongoose = require 'mongoose'
logger = require('../lib/logger').logger
db = require('../lib/mongoconnection').db


# Bind error commands to the console
db.on 'error', console.error.bind console, 'connection error:'
db.once 'open', ->
    logger.info 'Mongo connection open'

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
        input: {
            width: Number
            epoch: Number
            a: Number
            rstar: Number
            i: Number
            radius: Number
            depth: Number
            period: Number
        }
        orion: {
            delta_chisq: Number
            vmag: Number
            period: Number
            sde: Number
            depth: Number
            ntrans: Number
            teff: Number
        }
        mcmc: {
            clump_idx: Number
            period: Number
            sn_ellipse: Number
            radius: Number
            dchisq_mr: Number
            rstar: Number
            depth: Number
            sn_red: Number
            prob_rp: Number
        }
        obj_id: String
    }
    random: Number
    user_info: [ { sessionid: String, value: String, timestamp: Date } ]
}
userSchema = new mongoose.Schema {
    username: String
    sessionid: String
    time_of_last_change: Date
}

Object = mongoose.model 'Object', objectSchema
User = mongoose.model 'User', userSchema

# Returns a list of objects which match the input sorting/filtering criteria
exports.objects = (req, res) ->
    limit = if req.body.limit != undefined then parseInt req.body.limit else 20
    logger.info 'Sort limit', { value: limit }
    query = Object.find()

    sort_var = req.body.sort_var
    if req.body.sort == 'true'
        _orion_base = 'object_info.orion.'
        _mcmc_base = 'object_info.mcmc.'
        switch sort_var
            when 'SDE' then sort_var = _orion_base + 'sde'
            when 'Planetary radius' then sort_var = _mcmc_base + 'radius'
            when 'Orbital period' then sort_var = _mcmc_base + 'period'
            when 'Transit depth' then sort_var = _mcmc_base + 'depth'
            when 'Stellar radius' then sort_var = _mcmc_base + 'rstar'
            when 'V magnitude' then sort_var = _orion_base + 'vmag'
            when 'Effective temperature' then sort_var = _orion_base + 'teff'

        if req.body.sort_direction == '1' 
            sort_var = sort_var 
        else 
            sort_var = '-' + sort_var

        logger.info "Sorting", { sort_var: sort_var }
        query.sort sort_var
    else
        logger.info 'Not sorting'

    query.limit(limit)

    query.exec (err, results) ->
        if err
            logger.error err

        res.send results

# Just returns the single object requested
exports.detail = (req, res) ->
    Object.findById req.params.id, (err, result) ->
        if err
            logger.error err

        logger.info 'Getting object info', { "function": "detail", id: req.params.id }
        res.send result

# Returns just the required information for an objects transit images
exports.transits = (req, res) ->
    Object.findById req.params.id, (err, result) ->
        if err
            logger.error err

        object = {
            obj_id: result.obj_id
            tr_filenames: result.file_info.tr_filenames
        }

        logger.info 'Getting transits', { "function": "transits", id: req.params.id, obj_id: result.obj_id }

        res.send object

# Updates an objects belief value
exports.update = (req, res) ->
    id = req.params.id
    value = req.body.value
    user = req.body.sessionid

    Object.findById id, (err, result) ->
        if err
            logger.error err

        found = false
        for user_info, i in result.user_info
            if user_info.sessionid == user
                # Change the value
                
                logger.info "Updating value", { 
                    user: user
                    before: result.user_info[i].value
                    after: value
                    id: id 
                }

                result.user_info[i].value = value
                result.user_info[i].timestamp = Date()
                found = true

        if not found
            # Have to append the result to the array
            logger.info "Appending the user's info", {
                user: user
                after: value
                id: id
            }

            result.user_info.push {
                sessionid: user
                value: value
                timestamp: Date()
            }

        # Now save the object
        result.save (err) ->
            if err
                logger.error err

            res.send 'Ok'


exports.user = (req, res) ->
    username = req.body.username
    sessionid = req.body.sessionid

    User.findOne { sessionid: sessionid }, (err, result) ->
        if err
            logger.error err

        logger.info 'User query', { 
            sessionid: sessionid
            found: result?
        }

        if not result?
            User({ username: username, sessionid: sessionid, time_of_last_change: Date() }).save (err) ->
                if err
                    logger.error err
            logger.info 'New user saved', { 
                username: username
                sessionid: sessionid 
            }

        else
            old_username = result.username
            result.username = username
            result.time_of_last_change = Date()
            result.save (err) ->
                if err
                    logger.error err

                logger.info 'Username updated', { 
                    old: old_username
                    new: username
                    sessionid: sessionid
                }


# Gets a single user by id
exports.get_user_from_id = (req, res) ->
    User.findOne { sessionid: req.body.id }, (err, user) ->
        if err
            logger.error err

        res.send user


# Returns a user from their username
exports.get_user_from_username = (req, res) ->
    User.findOne { username: req.params.username }, (err, user) ->
        if err
            logger.error err

        res.send user
