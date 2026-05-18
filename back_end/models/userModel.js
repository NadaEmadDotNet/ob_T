const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    username: { 
        type: String, 
        required: true,
        trim: true // يفضل إضافتها لمسح أي مسافات زائدة
    },
    email: { 
        type: String, 
        required: true, 
        unique: true,
        lowercase: true // عشان لو اليوزر كتب Email بحروف Capital ميحصلش لبطة
    },
    password: { 
        type: String, 
        required: true 
    },
    profileImageUrl: {
        type: String,
        default: ""
    }
}, {
    timestamps: true // مفيدة جداً لمعرفة وقت تسجيل اليوزر
});

// تأكدي أن الاسم هنا 'User' هو نفسه اللي استخدمناه في الـ ref في ملف الالتزامات
module.exports = mongoose.model('User', userSchema);
