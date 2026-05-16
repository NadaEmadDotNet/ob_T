const express = require("express");
const cors = require("cors");

const userRoutes = require("./routes/userRoutes");
const obligationRoutes = require("./routes/obligationRoutes");

const app = express();

// middleware
app.use(cors());
app.use(express.json());

// routes
app.use("/api/users", userRoutes);
app.use("/api/obligations", obligationRoutes);

// test route
app.get("/", (req, res) => {
  res.send("API is running...");
});

module.exports = app;