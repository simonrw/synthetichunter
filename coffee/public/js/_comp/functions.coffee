# Function to return the static path
window.image_path = (path) ->
    parts = path.split('/')
    '/data/' + parts[parts.length - 1]

window.split_object = (comb, a, b, fn) ->
    for key, value of comb
        a.push(key)
        b.push(fn(value))

window.add_user_info = (object_id, sessionid, value) ->
    # Updates the entry for the object to add the user and their validity result
    $.ajax {
        type: 'put',
        url: '/api/1.0/objects/' + object_id
        data: {
            sessionid: sessionid,
            value: value
        }
        success: (data, textstatus, jqXHR) ->
            console.log 'AJAX call result: ' + data

    }

window.user_belief = (object, sessionid) ->
    user_info = object.user_info
    if user_info?
        belief = user_info[sessionid]
        if belief?
            return belief

    return null
