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
        self.viable_result = ko.observable('y')

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



# Export the class
window.ObjectInformation = ObjectInformation
