const express=require('express');
const mysql=require('mysql');
const bodyParser = require("body-parser");
const dotenv = require('dotenv');
const path= require('path');
const urlpages= require('./routes/pages');
const session = require('express-session');
const cookieParser = require('cookie-parser');
const flash = require('connect-flash');

let parsePath= path.parse(__filename);

dotenv.config({ path: './.env'});
const publicDirectory = path.join(__dirname,'./public');
//=====================================================
const app = express();
app.use(express.static(publicDirectory));
app.use(express.urlencoded({extended: true}));
app.use(express.json());
app.set('view engine', 'ejs');

//=============== Session ====================
app.use(cookieParser('SecretStringForCookies'));
app.use(session({
    key: 'user_sid',
    secret: 'SecretStringForSession',
    cookie: {expires:60000},
    resave: false,
    saveUninitialized: true,
}));
app.use(flash());
//=============== End Session ===================

app.use('/',urlpages);
app.use('/auth',require('./routes/auth'));

app.listen(process.env.PORT || 5000, ()=> {
    console.log("server started on port: "+process.env.PORT)
});



