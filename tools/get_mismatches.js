db.objects.find({ object_type: { $ne: 'synthetic' }}).forEach(function(item) {
    var id_val = item._id.str
    print('http://localhost:8080/results/' + id_val);
});
