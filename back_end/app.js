const express = require("express");
const cors = require("cors");

const userRoutes = require("./routes/userRoutes");
const obligationRoutes = require("./routes/obligationRoutes");
const feedbackRoutes = require("./routes/feedbackRoutes");

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Routes
app.use("/api/users", userRoutes);
app.use("/api/obligations", obligationRoutes);
app.use("/api/feedbacks", feedbackRoutes);

// Test route
app.get("/", (req, res) => {
    res.send("API is running...");
});

module.exports = app;