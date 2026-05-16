const express = require("express");
const router = express.Router();

const authMiddleware = require("../middleware/authMiddleware");

const {
    signup,
    login,
    changePassword 
} = require("../controllers/userControllers");

// Public routes
router.post("/signup", signup);
router.post("/login", login);

// Protected route
router.put("/change-password", authMiddleware, changePassword);

module.exports = router;