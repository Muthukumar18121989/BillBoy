const vision = require('@google-cloud/vision');
const OpenAI = require('openai');
const fs = require('fs');
const logger = require('../utils/logger');

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
const visionClient = new vision.ImageAnnotatorClient();

class OcrService {
  async extractFromImage(imagePath) {
    const start = Date.now();
    let rawText = '';
    let provider = 'google_vision';

    try {
      // Try Google Vision first
      rawText = await this._googleVisionOcr(imagePath);
    } catch (error) {
      logger.warn('Google Vision failed, trying OpenAI Vision:', error.message);
      try {
        rawText = await this._openAiVisionOcr(imagePath);
        provider = 'openai';
      } catch (e) {
        throw new Error('OCR processing failed: ' + e.message);
      }
    }

    // AI extraction
    const extractedData = await this._aiExtract(rawText);
    const processingTimeMs = Date.now() - start;

    return {
      rawText,
      extractedData,
      confidence: this._calculateConfidence(rawText, extractedData),
      provider,
      processingTimeMs,
    };
  }

  async _googleVisionOcr(imagePath) {
    const [result] = await visionClient.textDetection(imagePath);
    const detections = result.textAnnotations;
    if (!detections || detections.length === 0) return '';
    return detections[0].description || '';
  }

  async _openAiVisionOcr(imagePath) {
    const imageBuffer = fs.readFileSync(imagePath);
    const base64 = imageBuffer.toString('base64');
    const ext = imagePath.split('.').pop().toLowerCase();
    const mimeType = ext === 'png' ? 'image/png' : 'image/jpeg';

    const response = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'image_url',
              image_url: { url: `data:${mimeType};base64,${base64}` },
            },
            {
              type: 'text',
              text: 'Extract all text from this bill/receipt/invoice exactly as it appears.',
            },
          ],
        },
      ],
      max_tokens: 2000,
    });

    return response.choices[0].message.content || '';
  }

  async _aiExtract(rawText) {
    if (!rawText.trim()) return {};

    const prompt = `Extract bill information from this text and return a JSON object with these fields:
    - productName: string
    - category: one of [Electronics, Mobile Phones, Laptops, Appliances, Furniture, Fashion, Jewelry, Vehicles, Home Equipment, Insurance, Healthcare, Grocery, Subscription Services, Others]
    - billNumber: string (invoice/receipt number)
    - purchaseDate: string (ISO format YYYY-MM-DD)
    - warrantyMonths: number (convert years to months)
    - purchaseAmount: number (total amount paid)
    - taxAmount: number (GST/tax amount)
    - serialNumber: string
    - imeiNumber: string (15 digits)
    - modelNumber: string
    - brandName: string
    - storeName: string
    - storeAddress: string
    - gstNumber: string (format: 2 digits + 5 uppercase + 4 digits + 1 + 1 + Z + 1)

    Return only valid JSON, no explanation. If a field is not found, set it to null.

    Text:
    ${rawText.substring(0, 3000)}`;

    try {
      const response = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [{ role: 'user', content: prompt }],
        response_format: { type: 'json_object' },
        max_tokens: 1000,
        temperature: 0,
      });

      return JSON.parse(response.choices[0].message.content || '{}');
    } catch (error) {
      logger.error('AI extraction failed:', error);
      return this._regexExtract(rawText);
    }
  }

  _regexExtract(text) {
    const result = {};

    // Amount
    const amountMatch = text.match(/(?:total|amount|grand total)[:\s]*[₹Rs.]*\s*([\d,]+\.?\d*)/i);
    if (amountMatch) result.purchaseAmount = parseFloat(amountMatch[1].replace(',', ''));

    // GST Number
    const gstMatch = text.match(/[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}/);
    if (gstMatch) result.gstNumber = gstMatch[0];

    // Date
    const dateMatch = text.match(/(\d{1,2})[/-](\d{1,2})[/-](\d{4})/);
    if (dateMatch) {
      result.purchaseDate = `${dateMatch[3]}-${dateMatch[2].padStart(2, '0')}-${dateMatch[1].padStart(2, '0')}`;
    }

    // IMEI
    const imeiMatch = text.match(/IMEI[:\s]*(\d{15})/);
    if (imeiMatch) result.imeiNumber = imeiMatch[1];

    // Invoice number
    const invoiceMatch = text.match(/(?:invoice|bill|invoice no)[#:\s]*([A-Z0-9/-]+)/i);
    if (invoiceMatch) result.billNumber = invoiceMatch[1];

    return result;
  }

  _calculateConfidence(rawText, extractedData) {
    let score = 0;
    const fields = ['productName', 'purchaseAmount', 'purchaseDate', 'storeName', 'billNumber'];
    for (const field of fields) {
      if (extractedData[field]) score += 20;
    }
    return Math.min(score, 100);
  }
}

module.exports = new OcrService();
