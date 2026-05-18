const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");

const {
    signup,
    login,
    changePassword,
    getAllUsers,
    getProfile,
    updateProfile,
    uploadProfileAvatar
} = require("../controllers/userControllers");

// Public routes
router.get("/", getAllUsers);
router.post("/signup", signup);
router.post("/login", login);

// Protected route
router.get("/me", authMiddleware, getProfile);
router.put("/me", authMiddleware, updateProfile);
router.put("/me/avatar", authMiddleware, uploadProfileAvatar);
router.put("/change-password", authMiddleware, changePassword);

module.exports = router;
