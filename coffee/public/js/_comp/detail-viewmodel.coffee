# Changes the filename based on the dividor value
change_filename = (fname, suffix) ->
    re = /(\/data\/[a-zA-Z0-9_]+)(_d2|_x2)\.png/
    parts = re.exec fname
    if parts?
        new_name = parts[1] + suffix + '.png'
    else
        re = /(\/data\/[a-zA-Z0-9_]+)\.png/
        parts = re.exec fname
        new_name = parts[1] + suffix + '.png'

    return new_name


class ObjectInformation
    constructor: (id, sessionid) ->
        self = this
        self.id = ko.observable()
        self.obj_id = ko.observable()
        self.lc_filename = ko.observable()
        self.pgram_filename = ko.observable()
        self.phase_filename = ko.observable()
        self.mcmc_titles = ko.observableArray([])
        self.mcmc_values = ko.observableArray([])
        self.orion_titles = ko.observableArray([])
        self.orion_values = ko.observableArray([])

        # Viable option
        self.viable_result = ko.observable('undecided')

        $.getJSON '/api/1.0/objects/' + id, (results) ->

            self.id results._id
            self.obj_id  results.obj_id
            self.lc_filename image_path results.file_info.lc_filename
            self.pgram_filename image_path results.file_info.pg_filename
            self.phase_filename image_path results.file_info.phase_filename

            dp = (val) -> val.toPrecision 5
            split_object results.object_info.mcmc, self.mcmc_titles, self.mcmc_values, dp
            split_object results.object_info.orion, self.orion_titles, self.orion_values, dp

            # Add the user information
            belief = user_belief results, sessionid
            if belief?
                self.viable_result belief

        # Add subscription
        self.viable_result.subscribe (value) ->
            add_user_info self.id(), sessionid, value

    periodUpdateImages: (suffix) ->
        self = this
        self.lc_filename change_filename self.lc_filename(), suffix
        self.pgram_filename change_filename self.pgram_filename(), suffix


# Export the class
window.ObjectInformation = ObjectInformation
