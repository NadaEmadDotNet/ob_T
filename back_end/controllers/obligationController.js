
const mongoose = require("mongoose");
const Obligation = require('../models/obligationModel');


// CREATE OBLIGATION
const createObligation = async (req, res) => {
try {
    const userId = req.user.id;
    const { title, amount, dueDate, status, category,  } = req.body;

    if (!title || !amount || !dueDate || !category ) {
    return res.status(400).json({
        message: "Missing required fields",
    });
    }

    const obligation = await Obligation.create({
    title,
    amount,
    dueDate,
    status,
    category,
    userId,
    });

    res.status(201).json({
    message: "Obligation created successfully",
    obligation,
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
    status,
    priority,
    date
    } = req.query;

    let filter = {
        userId: req.user.id
    };

    // 🔍 title search (partial match anywhere)
    if (title) {
    filter.title = { $regex: title, $options: "i" };
    }

    // 📁 category filter (exact match)
    if (category) {
    filter.category = category;
    }

    // 📌 status filter
    if (status) {
    filter.status = status;
    }

    // ⚡ priority filter
    if (priority) {
    filter.priority = priority;
    }

    // 📅 exact day date filter
    if (date) {
    const start = new Date(date);
    const end = new Date(date);
    end.setDate(end.getDate() + 1);

    filter.dueDate = {
        $gte: start,
        $lt: end
    };
    }

    const obligations = await Obligation.find(filter);

    res.status(200).json({
    count: obligations.length,
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
    userId: req.user.id
    });

    if (!obligation) {
    return res.status(404).json({
        message: "Obligation not found",
    });
    }

    res.status(200).json(obligation);

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


if (!mongoose.Types.ObjectId.isValid(id)) {
return res.status(400).json({
    message: "Invalid ID",
});
}

    const obligation = await Obligation.findOneAndUpdate(
{
    _id: id,
    userId: req.user.id
},
req.body,
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
    obligation,
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


if (!mongoose.Types.ObjectId.isValid(id)) {
return res.status(400).json({
    message: "Invalid ID",
});
}
    const obligation = await Obligation.findOne({
        _id: id,
        userId: req.user.id
    });

    if (!obligation) {
    return res.status(404).json({
        message: "Obligation not found",
    });
    }

    Object.assign(obligation, req.body);

    await obligation.save();

    res.status(200).json({
    message: "Obligation updated successfully",
    obligation,
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
    userId: req.user.id
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
createObligation,
getAllObligations,
getSingleObligation,
updateObligation,
patchObligation,
deleteObligation,
};