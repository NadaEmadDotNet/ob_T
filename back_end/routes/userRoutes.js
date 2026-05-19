const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");
const upload = require("../middleware/uploadMiddleware");

const {
    signup,
    login,
    changePassword,
    getAllUsers,
    getProfile,
    updateProfile,
    uploadProfileAvatar,
    uploadProfileAvatarMulter
} = require("../controllers/userControllers");

// Public routes
router.get("/", getAllUsers);
router.post("/signup", signup);
router.post("/login", login);

// Protected route
router.get("/me", authMiddleware, getProfile);
router.put("/me", authMiddleware, updateProfile);
router.put("/me/avatar", authMiddleware, uploadProfileAvatar);
router.put("/me/avatar-multer", authMiddleware, (req, res, next) => {
    upload.single("avatar")(req, res, (err) => {
        if (err) {
            return res.status(400).json({ success: false, error: err.message });
        }
        next();
    });
}, uploadProfileAvatarMulter);
router.put("/change-password", authMiddleware, changePassword);

module.exports = router;
