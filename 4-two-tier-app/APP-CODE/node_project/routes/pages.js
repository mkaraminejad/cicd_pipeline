const express=require("express");
const router=express.Router();
const session = require('express-session');


router.get('/',(req,res)=>{
    res.render('index');
});
router.get('/login',(req,res)=>{
    //req.session.isAuth=true;
    if(req.session.user){
        const msg1=req.session.user; 
        res.redirect('welcome');
     } else{
        const msg1=req.flash('message');
        res.render('login',{msg1});
     }
    
    //const msg1=req.flash('message');
    //res.render('login',{msg1});
});

router.get('/register',(req,res)=>{
    const msg1=req.flash('message');
    res.render('register',{msg1});
});

router.get('/welcome',(req,res)=>{
     if(req.session.user){
        const msg1=req.session.user; 
        res.render('welcome',{msg1});
     } else{
         res.render('index');
     }
});

router.get('/logout',(req,res)=>{
    res.clearCookie("user_sid");
    res.render('index');
});

module.exports = router;