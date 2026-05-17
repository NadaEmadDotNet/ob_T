const express = require('express');
const router = express.Router();

const {
getAllFeedbacks,
getFeedback,
createFeedback,
updateFeedback,
deleteFeedback
} = require('../controllers/feedbackController');

const { feedbackValidation } = require('../middleware/feedbackMiddleware');
const auth = require('../middleware/authMiddleware');

// GET all
router.get('/', getAllFeedbacks);

// GET one
router.get('/:id', getFeedback);

// CREATE (login required)
router.post('/', auth, feedbackValidation, createFeedback);

// UPDATE (login required)
router.put('/:id', auth, feedbackValidation, updateFeedback);

// DELETE (login required)
router.delete('/:id', auth, deleteFeedback);

module.exports = router;