const mongoose = require('mongoose');

const feedbackSchema = new mongoose.Schema(
{
    userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    },

    userEmail: {
    type: String,
required: true,
    },

    feedback: {
type: String,
trim: true,
required: true,

    },
},

{
    timestamps: true,
}
);

module.exports = mongoose.model('Feedback', feedbackSchema);