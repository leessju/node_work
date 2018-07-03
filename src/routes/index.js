let express = require('express');
let router  = express.Router();
let path    = require('path');

router.get('/', function(req, res, next) {
    //res.send('Hello World!');
    //res.sendFile(__dirname + '../test.html');
    res.sendFile(path.join(__dirname, '../', 'test.html'));
});

module.exports = router;
