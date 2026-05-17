const { body, validationResult } = require("express-validator");

exports.feedbackValidation = [
body("feedback")
    .notEmpty()
    .withMessage("Feedback is required")
    .isLength({ min: 3 })
    .withMessage("Feedback must be at least 3 characters"),

(req, res, next) => {
    const errors = validationResult(req);
    if (!errors.isEmpty())
    return res.status(400).json({ success: false, errors: errors.array() });
    next();
},
];