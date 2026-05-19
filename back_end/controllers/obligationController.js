const mongoose = require("mongoose");
// express-validator helps validate incoming request data
// before saving/updating anything in the database.
const { body, validationResult } = require("express-validator");
// Import Obligation model to interact with MongoDB collection.
const Obligation = require("../models/obligationModel");


// ================= VALIDATORS =================

// Validation rules for creating obligation
const createObligationValidator = [
    // Title is required
    body("title")
        .notEmpty()
        .withMessage("Title is required"),

    // Amount is required and must be a number
    body("amount")
        .notEmpty()
        .withMessage("Amount is required")
        .isNumeric()
        .withMessage("Amount must be a number"),

    // Validate due date
    body("dueDate")
        .custom((value, { req }) => {
            const dateValue = value || req.body.date;
            // Check if date exists
            if (!dateValue) {
                throw new Error("Due date is required");
            }
            // Check if date format is valid
            if (Number.isNaN(Date.parse(dateValue))) {
                throw new Error("Invalid date");
            }

            return true;
        }),

    // Category is required
    body("category")
        .notEmpty()
        .withMessage("Category is required"),
];
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Function to normalize status values
const normalizeStatus = ({ amount, paid, isPaid, status }) => {

    // If marked as paid
    if (isPaid === true || status === "paid" || status === "Paid")
        return "paid";
    // If marked as unpaid
    if (isPaid === false || status === "unpaid" || status === "Unpaid")
        return "unpaid";
    // If paid amount >= total amount => paid
    if (
        paid !== undefined &&
        amount !== undefined &&
        Number(paid || 0) >= Number(amount || 0)
    )
        return "paid";

    // Default الحالة unpaid
    return "unpaid";
};
////////////////////////////////////////////////////////////////////////////////////////////
// Reusable priority calculation used before saving obligations.
const calculatePriority = (dueDate, isPaid) => {
    const today = new Date();
    const finalDueDate = new Date(dueDate);

    const diffDays = Math.ceil(
        (finalDueDate - today) / (1000 * 60 * 60 * 24)
    );

    if (isPaid) {
        return null;
    }

    if (diffDays < 0) {
        return "Overdue";
    }

    if (diffDays <= 3) {
        return "High";
    }

    if (diffDays <= 10) {
        return "Medium";
    }

    return "Low";
};

const hasField = (data, field) =>
    Object.prototype.hasOwnProperty.call(data, field);

const shouldRecalculatePriority = (bodyData) =>
    ["dueDate", "date", "amount", "paid", "isPaid", "status"].some(
        (field) => hasField(bodyData, field)
    );

// Function to add calculated fields to obligation
const enrichObligation = (item) => {
    // Convert mongoose object to plain object   بتحول لاوبجكت عادي
    const plain = item.toObject ? item.toObject() : item;

    // Calculate payment status
    const paid = Number(plain.paid || 0); // Number بتحول القيمة لرقم حتي لو دخلها كده في كوتس 
    const amount = Number(plain.amount || 0);

    const isPaid =
        paid >= amount ||
        plain.isPaid === true ||
        plain.status === "paid";

/////////////////////////////////////////////////////////////////////////////

    // Return updated object
    return {
        ...plain,
        priority: plain.priority,
        status: isPaid ? "paid" : "unpaid",
        displayStatus: isPaid ? "Paid" : "Unpaid",
        isPaid,
    };
};

// Function to prepare update data
const buildUpdateData = (bodyData) => {

    // Copy request body
    const updateData = { ...bodyData };

    // If date exists بدل dueDate
    if (updateData.date && !updateData.dueDate) {
        updateData.dueDate = updateData.date;
    }

    return updateData;
};

const applyPriorityToUpdateData = (updateData, currentData = {}) => {
    const mergedData = {
        ...currentData,
        ...updateData,
    };

    const hasPaymentUpdate = ["amount", "paid", "isPaid", "status"].some(
        (field) => hasField(updateData, field)
    );

    // Explicit payment flags win; otherwise keep status unless amount/paid changed.
    const finalStatus = normalizeStatus({
        amount: mergedData.amount,
        paid: mergedData.paid,
        isPaid: hasField(updateData, "isPaid")
            ? updateData.isPaid
            : hasPaymentUpdate
                ? undefined
                : currentData.isPaid,
        status: hasField(updateData, "status")
            ? updateData.status
            : hasPaymentUpdate
                ? undefined
                : currentData.status,
    });

    updateData.status = finalStatus;
    updateData.isPaid = finalStatus === "paid";
    updateData.priority = calculatePriority(
        mergedData.dueDate,
        updateData.isPaid
    );

    return updateData;
};

// ================= CREATE OBLIGATION =================

// Create new obligation
const createObligation = async (req, res) => {
    try {

        // Get validation errors
        const errors = validationResult(req);

        // Return errors if validation fails
        if (!errors.isEmpty()) {
            return res.status(400).json({
                errors: errors.array(),
            });
        }

        // Get logged-in user id
        const userId = req.user.id;

        // Extract request body data
        const {
            title,
            amount,
            dueDate,
            date,
            category,
            paid,
            isPaid,
            status,
        } = req.body;

        // Support date or dueDate
        const finalDueDate = dueDate || date;

        // Calculate final status
        const finalStatus = normalizeStatus({
            amount,
            paid,
            isPaid,
            status,
        });
        const finalPaid = paid || (finalStatus === "paid" ? amount : 0);
        const finalIsPaid = finalStatus === "paid";
        const priority = calculatePriority(finalDueDate, finalIsPaid);

        // Create obligation in database
        const obligation = await Obligation.create({
            title,
            amount,
            dueDate: finalDueDate,
            category,
            paid: finalPaid,
            isPaid: finalIsPaid,
            status: finalStatus,
            priority,
            userId,
        });

        // Send success response
        res.status(201).json({
            message: "Obligation created successfully",
            obligation: enrichObligation(obligation),
        });

    } catch (error) {

        // Handle server errors
        res.status(500).json({
            message: error.message,
        });
    }
};

// ================= GET ALL OBLIGATIONS =================

// Get all obligations with filtering/search
const getAllObligations = async (req, res) => {
    try {

        // Get query params
        const {
            title,
            category,
            priority,
            status,
            date,
        } = req.query;

        // Base filter by logged-in user
        const filter = {
            userId: req.user.id,
        };

        // Search by title
        if (title) {
            filter.title = {
                $regex: title,
                $options: "i",
            };
        }

        // Filter by category
        if (category) {
            filter.category = category;
        }

        // Filter by specific date
        if (date) {
            const start = new Date(date);
            const end = new Date(date);

            end.setDate(end.getDate() + 1);

            filter.dueDate = {
                $gte: start,
                $lt: end,
            };
        }

        // Fetch obligations from DB
        let obligations = await Obligation.find(filter);

        // Calculate total amount
        const Total = obligations.reduce(
            (sum, item) => sum + Number(item.amount || 0),
            0
        );

        // Calculate total paid
        const TotalPaid = obligations.reduce(
            (sum, item) => sum + Number(item.paid || 0),
            0
        );

        // Calculate remaining amount
        const Remaining = Total - TotalPaid;

        // Add calculated fields
        obligations = obligations.map(enrichObligation);

        // Filter by priority
        if (priority) {
            obligations = obligations.filter(
                (item) =>
                    item.priority &&
                    item.priority.toLowerCase() ===
                    priority.toLowerCase()
            );
        }

        // Filter by status
        if (status) {
            obligations = obligations.filter(
                (item) =>
                    item.status.toLowerCase() ===
                        status.toLowerCase() ||
                    item.displayStatus.toLowerCase() ===
                        status.toLowerCase()
            );
        }

        // Send response
        res.status(200).json({
            count: obligations.length,

            summary: {
                Total,
                TotalPaid,
                Remaining,
            },

            obligations,
        });

    } catch (error) {

        // Handle server errors
        res.status(500).json({
            message: error.message,
        });
    }
};

// ================= GET SINGLE OBLIGATION =================

// Get one obligation by ID
const getSingleObligation = async (req, res) => {
    try {

        // Extract ID from params
        const { id } = req.params;

        // Validate MongoDB ObjectId
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: "Invalid ID",
            });
        }

        // Find obligation by id and user
        const obligation = await Obligation.findOne({
            _id: id,
            userId: req.user.id,
        });

        // If not found
        if (!obligation) {
            return res.status(404).json({
                message: "Obligation not found",
            });
        }

        // Send obligation
        res.status(200).json(
            enrichObligation(obligation)
        );

    } catch (error) {

        // Handle server errors
        res.status(500).json({
            message: error.message,
        });
    }
};

// ================= UPDATE OBLIGATION =================

// Full update using PUT
const updateObligation = async (req, res) => {
    try {

        // Extract ID
        const { id } = req.params;

        // Prepare updated data
        const updateData = buildUpdateData(req.body);

        // Validate ID
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: "Invalid ID",
            });
        }

        // Find existing obligation so recalculation can use old values.
        const obligation = await Obligation.findOne({
            _id: id,
            userId: req.user.id,
        });

        // If not found
        if (!obligation) {
            return res.status(404).json({
                message: "Obligation not found",
            });
        }

        if (shouldRecalculatePriority(req.body)) {
            applyPriorityToUpdateData(updateData, obligation.toObject());
        }

        // Save updated fields with validators.
        Object.assign(obligation, updateData);
        await obligation.save();

        // Send updated obligation
        res.status(200).json({
            message: "Obligation updated successfully",
            obligation: enrichObligation(obligation),
        });

    } catch (error) {

        // Handle server errors
        res.status(500).json({
            message: error.message,
        });
    }
};

// ================= PATCH OBLIGATION =================

// Partial update using PATCH
const patchObligation = async (req, res) => {
    try {

        // Extract ID
        const { id } = req.params;

        // Prepare updated data
        const updateData = buildUpdateData(req.body);

        // Validate ID
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: "Invalid ID",
            });
        }

        // Find obligation first
        const obligation = await Obligation.findOne({
            _id: id,
            userId: req.user.id,
        });

        // If not found
        if (!obligation) {
            return res.status(404).json({
                message: "Obligation not found",
            });
        }

        if (shouldRecalculatePriority(req.body)) {
            applyPriorityToUpdateData(updateData, obligation.toObject());
        }

        // Merge old data with new data
        Object.assign(obligation, updateData);

        // Save changes
        await obligation.save();

        // Send updated obligation
        res.status(200).json({
            message: "Obligation updated successfully",
            obligation: enrichObligation(obligation),
        });

    } catch (error) {

        // Handle server errors
        res.status(500).json({
            message: error.message,
        });
    }
};

// ================= DELETE OBLIGATION =================

// Delete obligation
const deleteObligation = async (req, res) => {
    try {

        // Extract ID
        const { id } = req.params;

        // Validate ID
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: "Invalid ID",
            });
        }

        // Find and delete obligation
        const obligation = await Obligation.findOneAndDelete({
            _id: id,
            userId: req.user.id,
        });

        // If not found
        if (!obligation) {
            return res.status(404).json({
                message: "Obligation not found",
            });
        }

        // Success response
        res.status(200).json({
            message: "Obligation deleted successfully",
        });

    } catch (error) {

        // Handle server errors
        res.status(500).json({
            message: error.message,
        });
    }
};

// Export all controller functions
module.exports = {
    createObligationValidator,
    createObligation,
    getAllObligations,
    getSingleObligation,
    updateObligation,
    patchObligation,
    deleteObligation,
};