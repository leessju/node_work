let Web3                = require('web3');
let contract            = require("truffle-contract");
let path                = require('path');
let HDWalletProvider    = require("truffle-hdwallet-provider");

let express             = require('express');
let app                 = express();
let http                = require('http').Server(app);
let io                  = require('socket.io')(http);


App = {
    provider     : null,
    web3         : null,
    instance     : null,
    contracts    : {},
    account      : '0x0',
    hasVoted     : false,

    init: function() {
        return App.initWeb3();
    },
    initWeb3: function() {

        let mnemonic    = "grass wedding super kidney answer farm sphere brush rhythm subject file elevator";
        App.provider    = new HDWalletProvider(mnemonic, "https://ropsten.infura.io/NObCJjyiq2gnLbdZCXB2");
        App.web3        = new Web3(App.provider);

        App.web3.eth.getCoinbase(function(err, account) {

            if (err === null) {
                App.account = account;
                console.info("Your Account: " + App.account);
            }
        });

        return App.initContract();
    },
    initContract: function() {
        let contractJson          = require(path.join(__dirname, '../build/contracts/Election.json'));
        App.contracts.Election    = contract(contractJson);
        App.contracts.Election.setProvider(App.provider);
        return App.render();
    },
    render: function() {
        App.contracts.Election.deployed().then(function(instance) {
            App.instance = instance;
            return App.instance.candidatesCount();
        }).then(function(candidatesCount) {
            console.info(`candidatesCount ${candidatesCount}`);

            for (let i = 1; i <= candidatesCount; i++) {
                // App.instance.candidates(i).then(function(candidate) {
                //     let id           = candidate[0];
                //     let name         = candidate[1];
                //     let voteCount    = candidate[2];
                //     console.info(`id: ${id}, ${name},count:${voteCount}`);
                // });

                let abc = async() => {
                    let candidate = await App.instance.candidates(i);
                    let id           = candidate[0];
                    let name         = candidate[1];
                    let voteCount    = candidate[2];
                    console.info(`id: ${id}, ${name},count:${voteCount}`);
                };

                let abc1 = async() => {
                    let candidate = await App.instance.candidates(i);
                    let id           = candidate[0];
                    let name         = candidate[1];
                    let voteCount    = candidate[2];
                    console.info(`id: ${id}, ${name},count:${voteCount}`);
                };

                //abc();

                let aaa = async () => {
                    await abc();
                    await abc1();
                }

                aaa();
            }

            return App.instance.voters(App.account);
        }).then(function(hasVoted) {

            console.info(hasVoted);

        }).catch(function(error) {
            console.warn(error);
        });
    },
};


App.init();


var routes       = require('./routes/index');
var api          = require('./routes/api');

app.set('port', 3000);
app.use(express.json());
app.use('/css', express.static(path.join(__dirname, 'css')));
app.use('/font', express.static(path.join(__dirname, 'font')));
app.use('/images', express.static(path.join(__dirname, 'font')));
app.use('/js', express.static(path.join(__dirname, 'font')));

// app.use('/script', express.static(path.join(__dirname, 'script')));
// app.use('/views', express.static(path.join(__dirname, 'views')));

// app.get('/', function(req, res){
// //     res.sendFile(__dirname + '/test.html');
// // });

app.use('/', routes);
app.use('/api', api);




var crypto = require('crypto');

// var alg = 'des-ede-cbc';
//
// var key = new Buffer('abcdefghijklmnop', 'utf-8');
// var iv = new Buffer('vsh88xVrvB4=', 'base64');
//
// var encrypted = new Buffer('jHw3SE6NYDA=', 'base64');
// var source = '12345';
//
// var cipher = crypto.createCipheriv(alg, key, iv);
// var encoded = cipher.update(source, 'ascii', 'base64');
// encoded += cipher.final('base64');
//
// console.log(encoded, encrypted.toString('base64'));
//
// var decipher = crypto.createDecipheriv(alg, key, iv);
// var decoded = decipher.update(encrypted, 'binary', 'ascii');
// decoded += decipher.final('ascii');
//
// console.log(decoded, source);


//n1bIL6zXup3wbc7zaNUp4LnddDwyFIeSNB+x0tRIcM+Z3uY6CGJh9ddvp2d8X6r4b2O1MaMPPVm49mXUysNtWg==
//n1bIL6zXup3wbc7zaNUp4LnddDwyFIeSNB+x0tRIcM+Z3uY6CGJh9ddvp2d8X6r4b2O1MaMPPVm49mXUysNtWg==

//aes256
var cipher = crypto.createCipher('aes-256-cbc', 'This is my password.');
var encrypted = cipher.update("안녕하세용 감사합니당 이승주입니다.", 'utf8', 'base64') + cipher.final('base64');

console.info(encrypted);

var decipher = crypto.createDecipher('aes-256-cbc', 'This is my password.');
var plain = decipher.update(encrypted, 'base64', 'utf8') + decipher.final('utf8');

console.info(plain);






function hex2a(hex) {
    var str = '';
    for (var i = 0; i < hex.length; i += 2)
        str += String.fromCharCode(parseInt(hex.substr(i, 2), 16));
    return str;
}

// //Raw cookie
// var cookie = "B417B464CA63FE780584563D2DA4709B03F6195189044C26A29770F3203881DD90B1428139088D945CF6807CA408F201DABBADD59CE1D740F853A894692273F1CA83EC3F26493744E3D25D720374E03393F71E21BE2D96B6110CB7AC12E44447FFBD810D3D57FBACA8DF5249EB503C3DFD255692409F084650EFED205388DD8C08BF7B941E1AC1B3B70B9A8E09118D756BEAFF25834E72357FD40E80E76458091224FAE8";
//
// //decryptionKey from issuers <machineKey>
// var deckey = "FFA87B82D4A1BEAA15C06F6434A7EB2251976A838784E134900E6629B9F954B7";
//
//
// //var crypto = require('crypto');
//
// var ivc = cookie, iv, cipherText, ivSize = 16, res = "";
//
// ivc = new Buffer(ivc, 'hex');
// iv = new Buffer(ivSize);
// cipherText = new Buffer(ivc.length - ivSize);
// ivc.copy(iv, 0, 0, ivSize);
// ivc.copy(cipherText, 0, ivSize);
//
// c = crypto.createDecipheriv('aes-256-cbc', hex2a(deckey), iv.toString('binary'));
// res = c.update(cipherText, "binary", "utf8");
// res += c.final('utf8');
//
//
// console.log(res);


//https://www.npmjs.com/package/aspxauth




// app.get('/socket.io.js', function(req, res){
//     res.sendFile(__dirname + '/socket.io.js');
// });
//
//
// io.on('connection', function(socket){
//     console.log('a user connected ' + socket.id);
//
//     // to #client
//     socket.emit('chat message', "hi :" + socket.id);
//
//     socket.on('disconnect', function(){
//         console.log('user disconnected');
//     });
//
//     socket.on('chat message', function(msg) {
//         io.emit('chat message', msg);
//         console.log('message: ' + msg);
//     });
// });

http.listen(app.get('port'), function(){
    console.log('listening on *:3000');
});














// var str = '{ "name": "John Doe", "age": 42 }';
// var obj = JSON.parse(str);
// console.info(obj.name);

// http get json 1번
// const jsdom             = require("jsdom");
// const { window }        = new jsdom.JSDOM(`...`);
// var $                   = require("jquery")(window);

// http get json 2번
// const jsdom = require("jsdom");
// const dom   = new jsdom.JSDOM(`<!DOCTYPE html>`);
// var $       = require("jquery")(dom.window);

// $.getJSON('https://api.github.com/users/nhambayi',function(data) {
//     console.log(data);
// });

