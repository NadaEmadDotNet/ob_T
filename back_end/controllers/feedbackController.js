const mongoose = require('mongoose');
const Feedback = require('../models/feedbackModel');

exports.getAllFeedbacks = async (req, res) => {
try {
    const feedbacks = await Feedback.find().populate('userId', 'username email');
    res.status(200).json({ success: true, data: feedbacks });
} catch (err) {
    res.status(500).json({ success: false, error: err.message });
}
};

exports.getFeedback = async (req, res) => {
try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
        return res.status(400).json({ success: false, error: 'Invalid ID format' });
    }
    const feedback = await Feedback.findById(req.params.id).populate('userId', 'name email');
    if (!feedback)
    return res.status(404).json({ success: false, error: 'Feedback not found' });
    res.status(200).json({ success: true, data: feedback });
} catch (err) {
    res.status(500).json({ success: false, error: err.message });
}
};

exports.createFeedback = async (req, res) => {
try {
    console.log(req.body);
    const feedback = await Feedback.create({
    ...req.body,
    userId: req.user.id,
    userEmail: req.user.email,
    });

    res.status(201).json({
    success: true,
    data: feedback,
    });
} catch (err) {
    res.status(500).json({
    success: false,
    error: err.message,
    });
}
};

exports.updateFeedback = async (req, res) => {
try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
        return res.status(400).json({ success: false, error: 'Invalid ID format' });
    }
    const feedback = await Feedback.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!feedback)
    return res.status(404).json({ success: false, error: 'Feedback not found' });
    res.status(200).json({ success: true, data: feedback });
} catch (err) {
    res.status(500).json({ success: false, error: err.message });
}
};

exports.deleteFeedback = async (req, res) => {
try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
        return res.status(400).json({ success: false, error: 'Invalid ID format' });
    }
    const feedback = await Feedback.findByIdAndDelete(req.params.id);
    if (!feedback)
    return res.status(404).json({ success: false, error: 'Feedback not found' });
    res.status(200).json({ success: true, message: 'Feedback deleted successfully' });
} catch (err) {
    res.status(500).json({ success: false, error: err.message });
}
};