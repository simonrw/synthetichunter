class ObjectInfo
    constructor: (data, sessionid) ->
        self = this
        self._id = ko.observable data._id
        self.lc_filename = ko.observable image_path data.file_info.lc_filename
        self.pgram_filename = ko.observable image_path data.file_info.pg_filename

        self.viable_result = ko.observable('y')

        belief = user_belief data, sessionid
        if belief?
            self.viable_result belief

        # Now subscribe to the value change
        self.viable_result.subscribe (value) ->
            add_user_info self._id(), sessionid, value





class ViewModel
    loadData: ->
        self = this

        # Get the username information
        $.post '/api/1.0/user/id', { 
            id: self.sessionid
        }, (data, textStatus, jqXHR) ->
            if data.username?
                self.username(data.username)
            else
                self.username('')



        if self.limit.isValid()
            # Load up the data
            $.ajax {
                url: '/api/1.0/objects'
                type: 'post'
                data: {
                    limit: self.limit()
                    sort: self.sort()
                    # The selected sort object holds an array
                    sort_var: self.selected_sort()[0]
                    sort_direction: self.sort_direction()
                }
                success: (results) ->
                    self.objects _.map results, (r) -> new ObjectInfo r, self.sessionid


                error: (err) ->
                    console.log err

            }
        else
            console.log 'Input invalid'

    constructor: (sessionid) ->
        self = this
        self.sessionid = sessionid
        self.username = ko.observable('')

        self.objects = ko.observableArray([])
        self.limit = ko.observable(20)
        self.sort = ko.observable(true)
        self.sort_var = ko.observableArray(['SDE', 'Planetary radius', 'Orbital period', 'Transit depth'
            'Stellar radius', 'V magnitude', 'Effective temperature'])
        self.selected_sort = ko.observable(['SDE'])
        self.sort_direction = ko.observable(1)

        # Set up validation
        self.limit.extend { required: true, min: 1 }


        for control in [self.limit, self.sort, self.selected_sort, self.sort_direction]
            control.subscribe -> self.loadData()



        self.username.subscribe (value) ->
            console.log 'Username changed'
            $.post '/api/1.0/user', { 
                username: value
                sessionid: self.sessionid
            }, (data, textStatus, jqXHR) ->
                self.username(value)

        self.loadData()


window.ViewModel = ViewModel
