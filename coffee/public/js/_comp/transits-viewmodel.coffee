class ViewModel
    constructor: (id) ->
        self = this
        self.id = ko.observable()
        self.obj_id = ko.observable()
        self.transit_images = ko.observableArray([])

        $.getJSON '/api/1.0/objects/' + id + '/transits', (results) ->

            self.obj_id(results.obj_id)
            self.transit_images _.map results.tr_filenames, image_path

window.ViewModel = ViewModel
