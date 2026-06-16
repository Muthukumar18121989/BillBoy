const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { Category } = require('../models');
const { v4: uuidv4 } = require('uuid');
const { Op } = require('sequelize');

const SYSTEM_CATEGORIES = [
  { name: 'Electronics', icon: 'devices', color: '#6C63FF' },
  { name: 'Mobile Phones', icon: 'smartphone', color: '#42A5F5' },
  { name: 'Laptops', icon: 'laptop', color: '#26C6DA' },
  { name: 'Appliances', icon: 'kitchen', color: '#66BB6A' },
  { name: 'Furniture', icon: 'chair', color: '#FFB74D' },
  { name: 'Fashion', icon: 'checkroom', color: '#FF7043' },
  { name: 'Jewelry', icon: 'diamond', color: '#FFCA28' },
  { name: 'Vehicles', icon: 'directions_car', color: '#8D6E63' },
  { name: 'Home Equipment', icon: 'home_repair_service', color: '#78909C' },
  { name: 'Insurance', icon: 'health_and_safety', color: '#AB47BC' },
  { name: 'Healthcare', icon: 'medical_services', color: '#EF5350' },
  { name: 'Grocery', icon: 'shopping_basket', color: '#26A69A' },
  { name: 'Subscription Services', icon: 'subscriptions', color: '#7E57C2' },
  { name: 'Others', icon: 'receipt_long', color: '#90A4AE' },
];

router.use(authenticate);

router.get('/', async (req, res, next) => {
  try {
    const custom = await Category.findAll({
      where: { userId: req.user.id },
    });

    res.json({
      data: [
        ...SYSTEM_CATEGORIES.map(c => ({ ...c, isSystem: true })),
        ...custom.map(c => ({ ...c.toJSON(), isSystem: false })),
      ],
    });
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const { name, icon, color } = req.body;
    if (!name) return res.status(400).json({ error: 'Name is required' });

    const existing = SYSTEM_CATEGORIES.find(c => c.name.toLowerCase() === name.toLowerCase());
    if (existing) return res.status(409).json({ error: 'Category already exists' });

    const category = await Category.create({
      id: uuidv4(),
      name,
      icon,
      color,
      userId: req.user.id,
      isSystem: false,
    });

    res.status(201).json({ data: category });
  } catch (error) {
    next(error);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const category = await Category.findOne({
      where: { id: req.params.id, userId: req.user.id },
    });
    if (!category) return res.status(404).json({ error: 'Category not found' });

    await category.destroy();
    res.json({ message: 'Category deleted' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
