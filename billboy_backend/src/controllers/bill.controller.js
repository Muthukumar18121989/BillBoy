const { Bill, Warranty, OcrResult, Notification } = require('../models');
const { Op } = require('sequelize');
const { v4: uuidv4 } = require('uuid');
const DepreciationService = require('../services/depreciation.service');
const NotificationService = require('../services/notification.service');
const ExportService = require('../services/export.service');
const logger = require('../utils/logger');

class BillController {
  // GET /bills
  async getBills(req, res, next) {
    try {
      const {
        page = 1,
        pageSize = 20,
        category,
        warrantyStatus,
        startDate,
        endDate,
        minAmount,
        maxAmount,
        sortBy = 'purchaseDate',
        sortOrder = 'DESC',
        search,
      } = req.query;

      const where = { userId: req.user.id, isDeleted: false };

      if (category) where.category = category;
      if (warrantyStatus) where.warrantyStatus = warrantyStatus;
      if (startDate || endDate) {
        where.purchaseDate = {};
        if (startDate) where.purchaseDate[Op.gte] = startDate;
        if (endDate) where.purchaseDate[Op.lte] = endDate;
      }
      if (minAmount || maxAmount) {
        where.purchaseAmount = {};
        if (minAmount) where.purchaseAmount[Op.gte] = parseFloat(minAmount);
        if (maxAmount) where.purchaseAmount[Op.lte] = parseFloat(maxAmount);
      }
      if (search) {
        where[Op.or] = [
          { productName: { [Op.iLike]: `%${search}%` } },
          { serialNumber: { [Op.iLike]: `%${search}%` } },
          { billNumber: { [Op.iLike]: `%${search}%` } },
          { storeName: { [Op.iLike]: `%${search}%` } },
          { gstNumber: { [Op.iLike]: `%${search}%` } },
          { brandName: { [Op.iLike]: `%${search}%` } },
        ];
      }

      const offset = (parseInt(page) - 1) * parseInt(pageSize);

      const { count, rows } = await Bill.findAndCountAll({
        where,
        order: [[sortBy, sortOrder]],
        limit: parseInt(pageSize),
        offset,
        include: [{ model: Warranty, required: false }],
      });

      res.json({
        data: rows,
        pagination: {
          total: count,
          page: parseInt(page),
          pageSize: parseInt(pageSize),
          totalPages: Math.ceil(count / parseInt(pageSize)),
          hasMore: offset + rows.length < count,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  // GET /bills/:id
  async getBillById(req, res, next) {
    try {
      const bill = await Bill.findOne({
        where: { id: req.params.id, userId: req.user.id, isDeleted: false },
        include: [{ model: Warranty, required: false }],
      });

      if (!bill) return res.status(404).json({ error: 'Bill not found' });
      res.json({ data: bill });
    } catch (error) {
      next(error);
    }
  }

  // POST /bills
  async createBill(req, res, next) {
    try {
      const {
        productName, category, brandName, modelNumber, serialNumber, imeiNumber,
        purchaseDate, billNumber, purchaseAmount, taxAmount, storeName, storeAddress,
        gstNumber, warrantyMonths, attachmentUrls, ocrText, notes,
      } = req.body;

      const currentValue = DepreciationService.calculateCurrentValue(
        purchaseAmount,
        category,
        new Date(purchaseDate),
      );

      let warrantyEndDate = null;
      let warrantyStatus = 'noWarranty';
      if (warrantyMonths) {
        const start = new Date(purchaseDate);
        warrantyEndDate = new Date(start);
        warrantyEndDate.setMonth(warrantyEndDate.getMonth() + parseInt(warrantyMonths));
        warrantyStatus = _computeWarrantyStatus(warrantyEndDate);
      }

      const bill = await Bill.create({
        id: uuidv4(),
        userId: req.user.id,
        productName,
        category,
        brandName,
        modelNumber,
        serialNumber,
        imeiNumber,
        purchaseDate,
        billNumber,
        purchaseAmount: parseFloat(purchaseAmount),
        taxAmount: taxAmount ? parseFloat(taxAmount) : null,
        currentValue,
        storeName,
        storeAddress,
        gstNumber,
        warrantyMonths: warrantyMonths ? parseInt(warrantyMonths) : null,
        warrantyStartDate: warrantyMonths ? purchaseDate : null,
        warrantyEndDate,
        warrantyStatus,
        attachmentUrls: attachmentUrls || [],
        ocrText,
        notes,
      });

      // Schedule warranty reminders
      if (warrantyEndDate) {
        await NotificationService.scheduleWarrantyReminders(req.user.id, bill.id, productName, warrantyEndDate);
      }

      res.status(201).json({ data: bill, message: 'Bill created successfully' });
    } catch (error) {
      next(error);
    }
  }

  // PUT /bills/:id
  async updateBill(req, res, next) {
    try {
      const bill = await Bill.findOne({
        where: { id: req.params.id, userId: req.user.id, isDeleted: false },
      });

      if (!bill) return res.status(404).json({ error: 'Bill not found' });

      const { purchaseAmount, category, purchaseDate, warrantyMonths, ...rest } = req.body;

      const currentValue = DepreciationService.calculateCurrentValue(
        parseFloat(purchaseAmount || bill.purchaseAmount),
        category || bill.category,
        new Date(purchaseDate || bill.purchaseDate),
      );

      let warrantyEndDate = bill.warrantyEndDate;
      let warrantyStatus = bill.warrantyStatus;
      if (warrantyMonths !== undefined) {
        const start = new Date(purchaseDate || bill.purchaseDate);
        warrantyEndDate = new Date(start);
        warrantyEndDate.setMonth(warrantyEndDate.getMonth() + parseInt(warrantyMonths));
        warrantyStatus = _computeWarrantyStatus(warrantyEndDate);
      }

      await bill.update({
        ...rest,
        purchaseAmount: parseFloat(purchaseAmount || bill.purchaseAmount),
        category: category || bill.category,
        purchaseDate: purchaseDate || bill.purchaseDate,
        warrantyMonths: warrantyMonths !== undefined ? parseInt(warrantyMonths) : bill.warrantyMonths,
        warrantyEndDate,
        warrantyStatus,
        currentValue,
      });

      res.json({ data: bill, message: 'Bill updated successfully' });
    } catch (error) {
      next(error);
    }
  }

  // DELETE /bills/:id
  async deleteBill(req, res, next) {
    try {
      const bill = await Bill.findOne({
        where: { id: req.params.id, userId: req.user.id, isDeleted: false },
      });

      if (!bill) return res.status(404).json({ error: 'Bill not found' });

      await bill.update({ isDeleted: true });

      res.json({ message: 'Bill deleted successfully' });
    } catch (error) {
      next(error);
    }
  }

  // GET /bills/export/csv
  async exportCsv(req, res, next) {
    try {
      const bills = await Bill.findAll({
        where: { userId: req.user.id, isDeleted: false },
        order: [['purchaseDate', 'DESC']],
      });

      const csv = await ExportService.generateCsv(bills);
      res.setHeader('Content-Type', 'text/csv');
      res.setHeader('Content-Disposition', 'attachment; filename=billboy_export.csv');
      res.send(csv);
    } catch (error) {
      next(error);
    }
  }

  // GET /bills/export/pdf
  async exportPdf(req, res, next) {
    try {
      const bills = await Bill.findAll({
        where: { userId: req.user.id, isDeleted: false },
        order: [['purchaseDate', 'DESC']],
      });

      const pdf = await ExportService.generatePdf(bills, req.user);
      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', 'attachment; filename=billboy_export.pdf');
      res.send(pdf);
    } catch (error) {
      next(error);
    }
  }

  // GET /bills/stats/dashboard
  async getDashboardStats(req, res, next) {
    try {
      const bills = await Bill.findAll({
        where: { userId: req.user.id, isDeleted: false },
      });

      const now = new Date();
      const stats = {
        totalProducts: bills.length,
        totalSpend: bills.reduce((sum, b) => sum + parseFloat(b.purchaseAmount), 0),
        activeWarranties: 0,
        expiredWarranties: 0,
        upcomingExpiries: 0,
        categoryBreakdown: {},
        monthlySpending: {},
        expiringWarranties: [],
      };

      for (const bill of bills) {
        const cat = bill.category;
        stats.categoryBreakdown[cat] = (stats.categoryBreakdown[cat] || 0) + parseFloat(bill.purchaseAmount);

        const monthKey = `${bill.purchaseDate.substring(0, 7)}`;
        stats.monthlySpending[monthKey] = (stats.monthlySpending[monthKey] || 0) + parseFloat(bill.purchaseAmount);

        if (bill.warrantyEndDate) {
          const end = new Date(bill.warrantyEndDate);
          if (end < now) {
            stats.expiredWarranties++;
          } else {
            stats.activeWarranties++;
            const daysLeft = Math.ceil((end - now) / (1000 * 60 * 60 * 24));
            if (daysLeft <= 90) {
              stats.upcomingExpiries++;
              stats.expiringWarranties.push({
                id: bill.id,
                productName: bill.productName,
                daysLeft,
                warrantyEnd: bill.warrantyEndDate,
              });
            }
          }
        }
      }

      stats.expiringWarranties.sort((a, b) => a.daysLeft - b.daysLeft);

      res.json({ data: stats });
    } catch (error) {
      next(error);
    }
  }
}

function _computeWarrantyStatus(warrantyEnd) {
  const now = new Date();
  if (warrantyEnd < now) return 'expired';
  const daysLeft = (warrantyEnd - now) / (1000 * 60 * 60 * 24);
  if (daysLeft <= 30) return 'expiringSoon';
  return 'active';
}

module.exports = new BillController();
