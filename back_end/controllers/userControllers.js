const User = require('../models/usermodel'); 
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs'); 

// 1. Signup
exports.signup = async (req, res) => {
    try {
        const { email, password, username } = req.body;

        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ message: "email already exist" });
        }

        const hashedPassword = await bcrypt.hash(password, 12);

        const newUser = new User({ 
            email, 
            password: hashedPassword, 
            username 
        });

        await newUser.save();

        res.status(201).json({ message: "success" });

    } catch (err) {
        res.status(400).json({ message: "bad request", error: err.message });
    }
};



// 2. Login
exports.login = async (req, res) => {
    const { email, password } = req.body;

    try {
        const user = await User.findOne({ email });

        if (!user) {
            return res.status(401).json({ message: "wrong email or password" });
        }

        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ message: "wrong email or password" });
        }

        const token = jwt.sign(
            { userId: user._id },
            process.env.JWT_SECRET,
            { expiresIn: '1d' }
        );

        res.status(200).json({ 
            message: "Success", 
            token, 
            user: { 
                id: user._id, 
                username: user.username, 
                email: user.email 
            } 
        });

    } catch (err) {
        res.status(500).json({ message: "server error" });
    }
};



// 3. Change Password (FIXED)
exports.changePassword = async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;

        // 👇 توحيدها مع authMiddleware الجديد
        const userId = req.user.id;

        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        const isMatch = await bcrypt.compare(oldPassword, user.password);

        if (!isMatch) {
            return res.status(401).json({ message: "Old password is incorrect" });
        }

        user.password = await bcrypt.hash(newPassword, 12);
        await user.save();

        res.status(200).json({ message: "Password updated successfully" });

    } catch (err) {
        res.status(500).json({ message: "Server error", error: err.message });
    }
};