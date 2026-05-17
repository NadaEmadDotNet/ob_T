const User = require('../models/usermodel');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

// Signup
exports.signup = async (req, res) => {
    try {

        const { email, password, username } = req.body;

        const existingUser = await User.findOne({ email });

        if (existingUser) {
            return res.status(400).json({
                message: "Email already exists"
            });
        }

        const hashedPassword = await bcrypt.hash(password, 12);

        const newUser = new User({
            email,
            password: hashedPassword,
            username
        });

        await newUser.save();

        const token = jwt.sign(
            {
                userId: newUser._id,
                email: newUser.email,
            },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(201).json({
            success: true,
            token
        });

    } catch (err) {

        res.status(500).json({
            success: false,
            error: err.message
        });
    }
};

// Login
exports.login = async (req, res) => {

    try {

        const { email, password } = req.body;

        const user = await User.findOne({ email });

        if (!user) {
            return res.status(400).json({
                message: "Wrong email or password"
            });
        }

        const isMatch = await bcrypt.compare(
            password,
            user.password
        );

        if (!isMatch) {
            return res.status(400).json({
                message: "Wrong email or password"
            });
        }

        const token = jwt.sign(
            {
                userId: user._id,
                email: user.email
            },
            process.env.JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(200).json({
            success: true,
            token
        });

    } catch (err) {

        res.status(500).json({
            success: false,
            error: err.message
        });
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