exports.index = (req, res) ->
    res.render 'index', { title: 'Synthetic Hunter', sessionid: req.sessionID }

exports.results = (req, res) ->
    res.send 'Results'

exports.object = (req, res) ->
    res.render 'detail', { id: req.params.id, sessionid: req.sessionID }

exports.transits = (req, res) ->
    res.render 'transits', { id: req.params.id, sessionid: req.sessionID }
