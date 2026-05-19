const User = require('../models/userModel');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const fs = require('fs');
const path = require('path');

// Signup
exports.signup = async (req, res) => {
    try {

        const { email, password, username, profileImageUrl } = req.body;

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
            username,
            profileImageUrl: profileImageUrl || ""
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
            token,
            user: {
                id: newUser._id,
                username: newUser.username,
                email: newUser.email,
                profileImageUrl: newUser.profileImageUrl
            }
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
            token,
            user: {
                id: user._id,
                username: user.username,
                email: user.email,
                profileImageUrl: user.profileImageUrl || ""
            }
        });

    } catch (err) {

        res.status(500).json({
            success: false,
            error: err.message
        });
    }
};

// Get all users
exports.getAllUsers = async (req, res) => {
    try {
        const users = await User.find().select("-password");

        res.status(200).json({
            success: true,
            data: users
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
};

exports.getProfile = async (req, res) => {
    try {
        const user = await User.findById(req.user.id).select("-password");

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        res.status(200).json({
            success: true,
            data: user
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
};

exports.updateProfile = async (req, res) => {
    try {
        const { username, profileImageUrl } = req.body;
        const updateData = {};

        if (username !== undefined) updateData.username = username;
        if (profileImageUrl !== undefined) updateData.profileImageUrl = profileImageUrl;

        const user = await User.findByIdAndUpdate(
            req.user.id,
            updateData,
            { new: true, runValidators: true }
        ).select("-password");

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        res.status(200).json({
            success: true,
            data: user
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
};

exports.uploadProfileAvatar = async (req, res) => {
    try {
        const { imageBase64, fileName } = req.body || {};

        if (!imageBase64) {
            return res.status(400).json({ message: "Image is required" });
        }

        const uploadsDir = path.join(__dirname, "..", "uploads", "avatars");
        fs.mkdirSync(uploadsDir, { recursive: true });

        const cleanBase64 = imageBase64.replace(/^data:image\/\w+;base64,/, "");
        const buffer = Buffer.from(cleanBase64, "base64");
        const extension = path.extname(fileName || "").toLowerCase() || ".png";
        const safeExtension = [".jpg", ".jpeg", ".png", ".webp"].includes(extension)
            ? extension
            : ".png";
        const avatarFileName = `avatar_${req.user.id}_${Date.now()}${safeExtension}`;
        const avatarPath = path.join(uploadsDir, avatarFileName);

        fs.writeFileSync(avatarPath, buffer);

        const profileImageUrl = `${req.protocol}://${req.get("host")}/uploads/avatars/${avatarFileName}`;
        const user = await User.findByIdAndUpdate(
            req.user.id,
            { profileImageUrl },
            { new: true, runValidators: true }
        ).select("-password");

        if (!user) {
            return res.status(404).json({ message: "User not found" });
        }

        res.status(200).json({
            success: true,
            profileImageUrl,
            data: user
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
};

// Upload Avatar using Multer (Bonus endpoint)
exports.uploadProfileAvatarMulter = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: "No file uploaded or file type not allowed" });
        }

        const profileImageUrl = `${req.protocol}://${req.get("host")}/uploads/avatars/${req.file.filename}`;

        const user = await User.findByIdAndUpdate(
            req.user.id,
            { profileImageUrl },
            { new: true, runValidators: true }
        ).select("-password");

        if (!user) {
            return res.status(404).json({ success: false, message: "User not found" });
        }

        res.status(200).json({
            success: true,
            message: "Avatar uploaded successfully using Multer",
            profileImageUrl,
            data: user
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
