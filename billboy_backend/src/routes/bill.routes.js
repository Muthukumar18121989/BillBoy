const express = require('express');
const router = express.Router();
const billController = require('../controllers/bill.controller');
const { authenticate } = require('../middleware/auth.middleware');
const { body, query } = require('express-validator');
const validate = require('../middleware/validate');

const billValidation = [
  body('productName').notEmpty().trim().withMessage('Product name is required'),
  body('category').notEmpty().withMessage('Category is required'),
  body('purchaseDate').isDate().withMessage('Valid purchase date is required'),
  body('purchaseAmount').isNumeric().withMessage('Valid purchase amount is required'),
];

router.use(authenticate);

// CRUD
router.get('/', billController.getBills.bind(billController));
router.get('/stats/dashboard', billController.getDashboardStats.bind(billController));
router.get('/export/csv', billController.exportCsv.bind(billController));
router.get('/export/pdf', billController.exportPdf.bind(billController));
router.get('/:id', billController.getBillById.bind(billController));
router.post('/', billValidation, validate, billController.createBill.bind(billController));
router.put('/:id', billController.updateBill.bind(billController));
router.delete('/:id', billController.deleteBill.bind(billController));

module.exports = router;
