const mysql=require('mysql');
const bcrypt = require ('bcryptjs');
const jwt = require('jsonwebtoken');
const session = require('express-session');
const cookieParser = require('cookie-parser');
const flash = require('connect-flash');

//====================== Database Connection ===================================

const db = mysql.createConnection ({
    host: process.env.DATABASE_HOST,
    user: process.env.DATABASE_USER,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE,
    port: process.env.DATABASE_PORT,
});

//====================== START LOGIN ===================================
exports.login=(req,res)=>{
        var email = req.body.email;
        var password = req.body.password;
        if(!email || !password){
            req.flash('message','Email and pasword Required');
            return res.redirect('/login');
        }
        db.query("SELECT * FROM users WHERE email = ?", [email], async (error,results) =>{
            if (error) {
                console.log(error)
            };
            if (results.length > 0) {
                // Save the password from Database to a Variable for useing in next steps.
                var dbPassword=results[0]['password'];
                var dbFirstname=results[0]['firstname'];
                // Using bcrypt.compare function to check entry password with recorded password in Database.
                const valid = await bcrypt.compare(req.body.password, dbPassword);
                // if comparing not be valid display a wrong pass message otherwise Logined.  
                if (!valid) {
                    req.flash('message','Pasword is Wrong, Try again!');
                    return res.redirect('/login');
                } else {
                    req.session.user = results[0].firstname;
//                  console.log(req.session.user);
                    req.flash('message', dbFirstname);
                    return res.redirect('../welcome');
                }
            } else {
                req.flash('message', "User Doesn't Exist");
                return res.redirect('/login');
            }
        });
}
//====================== END LOGIN ===================================

//====================== START REGISTER ==============================
exports.register=(req,res)=>{
    const {firstname, lastname, email, password, passwordconfirm} = req.body;
    db.query('SELECT email FROM users WHERE email = ?' , [email], async (error,results) => {
        if (error) {
            console.log(error);
        }
        if ( results.length > 0){
            req.flash('message', 'This Email is Already in USE');
            return res.redirect('../register');
        }
        else if (password !== passwordconfirm){
            req.flash('message', "Password do not match");
            return res.redirect('../register');
        }
        let hashedPassword = await bcrypt.hash(password, 8);
        db.query('INSERT INTO users SET ?', {email: email, password: hashedPassword, firstname: firstname, lastname: lastname}, (error, results)=> {
            if (error) {
                console.log(error);
                return res.redirect("/register");
            } else {
                req.flash('message', "Your Data submited successfully!");
                return res.redirect('../register');
            }

        })
    })
}
//====================== END REGISTER ===================================
