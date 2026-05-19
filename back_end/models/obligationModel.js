// models/Obligation.js

const mongoose = require("mongoose");

//// validation mongoose
const obligationSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: true,
            trim: true,
        },

        amount: {
            type: Number,
            required: true,
            min: 0,
        },

        paid: {
            type: Number,
            default: 0,
            min: 0,
        },

        isPaid: {
            type: Boolean,
            default: false,
        },

        status: {
            type: String,
            enum: ["paid", "unpaid"],
            default: "unpaid",
        },

        priority: {
            type: String,
            enum: ["Low", "Medium", "High", "Overdue", null],
            default: null,
        },

        dueDate: {
            type: Date,
            required: true,
        },

        category: {
            type: String,
            enum: [
                "Bills",
                "Rent",
                "Home",
                "Insurance",
                "Personal",
                "Utilities",
                "Work",
                "Others",
            ],
            required: true,
        },

        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
        },
    },
    {
        timestamps: true,
    }
);

module.exports = mongoose.model("Obligation", obligationSchema);