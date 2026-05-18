const mongoose = require("mongoose");
const { body, validationResult } = require("express-validator");

const Obligation = require("../models/obligationModel");

// ================= VALIDATORS =================

const createObligationValidator = [
    body("title")
        .notEmpty()
        .withMessage("Title is required"),

    body("amount")
        .notEmpty()
        .withMessage("Amount is required")
        .isNumeric()
        .withMessage("Amount must be a number"),

    body("dueDate")
        .custom((value, { req }) => {
            const dateValue = value || req.body.date;
            if (!dateValue) {
                throw new Error("Due date is required");
            }

            if (Number.isNaN(Date.parse(dateValue))) {
                throw new Error("Invalid date");
            }

            return true;
        }),

    body("category")
        .notEmpty()
        .withMessage("Category is required"),
];

const normalizeStatus = ({ amount, paid, isPaid, status }) => {
    if (isPaid === true || status === "paid" || status === "Paid") return "paid";
    if (isPaid === false || status === "unpaid" || status === "Unpaid") return "unpaid";
    if (paid !== undefined && amount !== undefined && Number(paid || 0) >= Number(amount || 0)) return "paid";
    return "unpaid";
};

const enrichObligation = (item) => {
    const plain = item.toObject ? item.toObject() : item;
    const today = new Date();
    const dueDate = new Date(plain.dueDate);
    const diffDays = Math.ceil((dueDate - today) / (1000 * 60 * 60 * 24));

    let dynamicPriority = "Low";
    if (diffDays < 0) {
        dynamicPriority = "Overdue";
    } else if (diffDays <= 3) {
        dynamicPriority = "High";
    } else if (diffDays <= 10) {
        dynamicPriority = "Medium";
    }

    const paid = Number(plain.paid || 0);
    const amount = Number(plain.amount || 0);
    const isPaid = paid >= amount || plain.isPaid === true || plain.status === "paid";

    return {
        ...plain,
        priority: dynamicPriority,
        status: isPaid ? "paid" : "unpaid",
        displayStatus: isPaid ? "Paid" : "Unpaid",
        isPaid,
    };
};

const buildUpdateData = (bodyData) => {
    const updateData = { ...bodyData };

    delete updateData.priority;
    delete updateData.status;

    if (updateData.date && !updateData.dueDate) {
        updateData.dueDate = updateData.date;
    }

    if (updateData.isPaid !== undefined || updateData.paid !== undefined || updateData.amount !== undefined) {
        updateData.status = normalizeStatus(updateData);
        updateData.isPaid = updateData.status === "paid";
    }

    return updateData;
};

// CREATE OBLIGATION
const createObligation = async (req, res) => {
    try {
        const errors = validationResult(req);

        if (!errors.isEmpty()) {
            return res.status(400).json({
                errors: errors.array(),
            });
        }

        const userId = req.user.id;
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

        const finalDueDate = dueDate || date;
        const finalStatus = normalizeStatus({ amount, paid, isPaid, status });

        const obligation = await Obligation.create({
            title,
            amount,
            dueDate: finalDueDate,
            category,
            paid: paid || (finalStatus === "paid" ? amount : 0),
            isPaid: finalStatus === "paid",
            status: finalStatus,
            userId,
        });

        res.status(201).json({
            message: "Obligation created successfully",
            obligation: enrichObligation(obligation),
        });
    } catch (error) {
        res.status(500).json({
            message: error.message,
        });
    }
};

// GET ALL OBLIGATIONS + FILTER + SEARCH
const getAllObligations = async (req, res) => {
    try {
        const {
            title,
            category,
            priority,
            status,
            date,
        } = req.query;

        const filter = {
            userId: req.user.id,
        };

        if (title) {
            filter.title = {
                $regex: title,
                $options: "i",
            };
        }

        if (category) {
            filter.category = category;
        }

        if (date) {
            const start = new Date(date);
            const end = new Date(date);
            end.setDate(end.getDate() + 1);

            filter.dueDate = {
                $gte: start,
                $lt: end,
            };
        }

        let obligations = await Obligation.find(filter);

        const Total = obligations.reduce(
            (sum, item) => sum + Number(item.amount || 0),
            0
        );

        const TotalPaid = obligations.reduce(
            (sum, item) => sum + Number(item.paid || 0),
            0
        );

        const Remaining = Total - TotalPaid;

        obligations = obligations.map(enrichObligation);

        if (priority) {
            obligations = obligations.filter(
                (item) => item.priority.toLowerCase() === priority.toLowerCase()
            );
        }

        if (status) {
            obligations = obligations.filter(
                (item) =>
                    item.status.toLowerCase() === status.toLowerCase() ||
                    item.displayStatus.toLowerCase() === status.toLowerCase()
            );
        }

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
        res.status(500).json({
            message: error.message,
        });
    }
};

// GET SINGLE OBLIGATION
const getSingleObligation = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: "Invalid ID",
            });
        }

        const obligation = await Obligation.findOne({
            _id: id,
            userId: req.user.id,
        });

        if (!obligation) {
            return res.status(404).json({
                message: "Obligation not found",
            });
        }

        res.status(200).json(enrichObligation(obligation));
    } catch (error) {
        res.status(500).json({
            message: error.message,
        });
    }
};

// UPDATE OBLIGATION
const updateObligation = async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = buildUpdateData(req.body);

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: "Invalid ID",
            });
        }

        const obligation = await Obligation.findOneAndUpdate(
            {
                _id: id,
                userId: req.user.id,
            },
            updateData,
            {
                new: true,
                runValidators: true,
            }
        );

        if (!obligation) {
            return res.status(404).json({
                message: "Obligation not found",
            });
        }

        res.status(200).json({
            message: "Obligation updated successfully",
            obligation: enrichObligation(obligation),
        });
    } catch (error) {
        res.status(500).json({
            message: error.message,
        });
    }
};

// PATCH OBLIGATION
const patchObligation = async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = buildUpdateData(req.body);

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: "Invalid ID",
            });
        }

        const obligation = await Obligation.findOne({
            _id: id,
            userId: req.user.id,
        });

        if (!obligation) {
            return res.status(404).json({
                message: "Obligation not found",
            });
        }

        Object.assign(obligation, updateData);

        await obligation.save();

        res.status(200).json({
            message: "Obligation updated successfully",
            obligation: enrichObligation(obligation),
        });
    } catch (error) {
        res.status(500).json({
            message: error.message,
        });
    }
};

// DELETE OBLIGATION
const deleteObligation = async (req, res) => {
    try {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: "Invalid ID",
            });
        }

        const obligation = await Obligation.findOneAndDelete({
            _id: id,
            userId: req.user.id,
        });

        if (!obligation) {
            return res.status(404).json({
                message: "Obligation not found",
            });
        }

        res.status(200).json({
            message: "Obligation deleted successfully",
        });
    } catch (error) {
        res.status(500).json({
            message: error.message,
        });
    }
};

module.exports = {
    createObligationValidator,
    createObligation,
    getAllObligations,
    getSingleObligation,
    updateObligation,
    patchObligation,
    deleteObligation,
};
