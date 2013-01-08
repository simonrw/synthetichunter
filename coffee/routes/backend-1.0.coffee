os = require 'os'

mongoose = require 'mongoose'


# Development/Production check
hostname = os.hostname()
if hostname == 'mbp.lan' or hostname == 'sirius'
    server_url = 'localhost'
else
    server_url = 'sirius.astro.warwick.ac.uk'

console.log "Connecting to mongo on hostname: #{server_url}"

# Some configuration variables
port = 27017
db_name = 'hunter'
ObjectID = mongodb.ObjectID

# Function to get a collection with given name from the database
mongo_connection = (collection_name, next) ->
    server = new mongodb.Server server_url, port
    mongodb.Db(db_name, server, { w: 1}).open (err, client) ->
        if err
            throw err

        collection = new mongodb.Collection client, collection_name
        next collection

# Simplification of getting an object by id
get_single_object = (id, next) ->
    mongo_connection 'objects', (collection) ->
        if id == undefined
            next 404

        collection.findOne { _id: ObjectID id }, (err, result) ->
            if err
                console.log err

            if !result
                next 404

            next result

# Gets a single random object
get_random_object = (next) ->
    mongo_connection 'objects', (collection) ->
        rand = Math.random()

        collection.findOne { random: { $gte: rand }}, (err, result) ->
            if err
                console.log err

            if result?
                next(result)
            else
                collection.findOne { random: { $lte: rand }}, (err, result2) ->
                    if err
                        console.log err

                        next(result)


# Returns a list of objects which match the input sorting/filtering criteria
exports.objects = (req, res) ->
    #console.log req.body

    limit = if req.body.limit != undefined then parseInt req.body.limit else 2

    mongo_connection 'objects', (collection) ->
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

            sort_direction = if req.body.sort_direction == '1' then 1 else -1
            console.log 'Sort direction: ' + sort_direction
            console.log 'Sort variable: ' + sort_var


            console.log sort_var
            # Run the find query
            cursor = collection.find()
            cursor.limit limit
            cursor.sort sort_var, sort_direction
            cursor.toArray (err, results) ->

                if err
                    throw err

                results.status = 'Ok'
                res.send results
        else
            console.log 'Not sorting'

            collection.find().limit(limit).toArray (err, results) ->
                if err
                    throw err

                results.status = 'Ok'
                res.send results

# Just returns the single object requested
exports.detail = (req, res) ->
    get_single_object req.params.id, (result) ->
        res.send result

# Returns just the required information for an objects transit images
exports.transits = (req, res) ->
    get_single_object req.params.id, (result) ->
        object = {
            obj_id: result.obj_id
            tr_filenames: result.file_info.tr_filenames
        }

        res.send object

# Updates an objects belief value
exports.update = (req, res) ->
    id = ObjectID req.params.id
    value = req.body.value
    user = req.body.sessionid

    # update the document
    mongo_connection 'objects', (collection) ->
        collection.findOne {_id: id}, (err, result) ->
            # Get the current users object
            user_info = result.user_info

            if result.user_info?
                console.log 'User info found, updating value'
                result.user_info[user] = value
            else
                console.log 'User info missing, creating'
                result['user_info'] = {}
                result.user_info[user] = value

            collection.save result, (err) ->
                if err
                    throw err

            #collection.update { _id: id }, { $set: { user_key:  value }}, { safe: true }, (err) ->
                #throw err


    res.send 'Updating ' + req.params.id  + ' to ' + req.body.value + ' with user ' + req.body.sessionid

# Returns a user object
exports.user = (req, res) ->
    mongo_connection 'users', (collection) ->
        username = req.body.username
        sessionid = req.body.sessionid

        collection.find({ username: username, sessionid: sessionid }).count (err, count) ->
            if err
                console.log err

            if count < 1
                collection.insert {username: username, sessionid: sessionid}, (err, docs) ->
                    if err
                        console.log err

                    res.send {
                        message: "Inserted"
                        username: username
                        sessionid: sessionid
                    }
            else
                # See if the username is different
                collection.findOne { sessionid: sessionid }, (err, doc) ->
                    if err
                        console.log err

                    if doc.username != username
                        collection.update { sessionid: sessionid }, { $set : { username: username } }, { safe: true }, (err, result) ->
                            if err
                                console.log err

                            res.send {
                                message: "Updated"
                            }

# Gets a single user by id
exports.get_user_from_id = (req, res) ->
    mongo_connection 'users', (collection) ->
        collection.findOne { sessionid: req.body.id }, (err, user) ->
            if err
                console.log err

            if user?
                res.send user
            else
                res.send null


# Returns a user from their username
exports.get_user_from_username = (req, res) ->
    mongo_connection 'users', (collection) ->
        collection.findOne { username: req.params.username }, (err, user) ->
            if err
                console.log err

            if user?
                res.send user
            else
                res.send 404
