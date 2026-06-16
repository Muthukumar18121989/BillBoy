const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const OcrService = require('../services/ocr.service');
const { authenticate } = require('../middleware/auth.middleware');
const logger = require('../utils/logger');

const storage = multer.diskStorage({
  destination: '/tmp/billboy-uploads/',
  filename: (req, file, cb) => {
    cb(null, `${uuidv4()}${path.extname(file.originalname)}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 20 * 1024 * 1024 }, // 20MB
  fileFilter: (req, file, cb) => {
    const allowed = ['.jpg', '.jpeg', '.png', '.pdf'];
    const ext = path.extname(file.originalname).toLowerCase();
    if (allowed.includes(ext)) {
      cb(null, true);
    } else {
      cb(new Error('Only images (JPG, PNG) and PDF files are allowed'));
    }
  },
});

router.use(authenticate);

// POST /ocr/extract - Extract bill from uploaded image/PDF
router.post('/extract', upload.single('file'), async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No file uploaded' });
    }

    const start = Date.now();
    const result = await OcrService.extractFromImage(req.file.path);

    res.json({
      data: result,
      processingTimeMs: Date.now() - start,
    });
  } catch (error) {
    logger.error('OCR extraction error:', error);
    next(error);
  }
});

// POST /ocr/extract-url - Extract from image URL
router.post('/extract-url', async (req, res, next) => {
  try {
    const { imageUrl } = req.body;
    if (!imageUrl) return res.status(400).json({ error: 'imageUrl is required' });

    const result = await OcrService.extractFromImage(imageUrl);
    res.json({ data: result });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
