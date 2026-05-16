// models/Obligation.js

const mongoose = require("mongoose");

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

    dueDate: {
        type: Date,
        required: true,
    },

    status: {
        type: String,
        enum: ["paid", "unpaid"],
        default: "unpaid",
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
            "Others"
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