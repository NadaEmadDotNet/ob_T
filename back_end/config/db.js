const mongoose = require('mongoose');

// Connection URL
const url = 'mongodb://127.0.0.1:27017/obligation_tracker';

const connectDb = () => {
    mongoose.connect(url).then(() => {
        console.log('Connected mongo database');
    });
}

module.exports = connectDb;