// routes/obligationRoutes.js

const express = require("express");
const protect = require("../middleware/authMiddleware");


const {
createObligationValidator,
createObligation,
getAllObligations,
getSingleObligation,
updateObligation,
patchObligation,
deleteObligation,
} = require("../controllers/obligationController");

const router = express.Router();
router.use(protect);
router.route('/')
.get(getAllObligations)
.post(createObligationValidator, createObligation)


router.route('/:id')
//.get(getAllObligations)
.get(getSingleObligation)
.patch(patchObligation)
.put(updateObligation)
.delete(deleteObligation)


module.exports = router;
