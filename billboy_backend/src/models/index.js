const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

// Users
const User = sequelize.define('User', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  firebaseUid: { type: DataTypes.STRING, unique: true, allowNull: false },
  fullName: { type: DataTypes.STRING, allowNull: false },
  email: { type: DataTypes.STRING, unique: true, allowNull: false },
  phone: { type: DataTypes.STRING },
  photoUrl: { type: DataTypes.TEXT },
  emailVerified: { type: DataTypes.BOOLEAN, defaultValue: false },
  fcmToken: { type: DataTypes.TEXT },
  isActive: { type: DataTypes.BOOLEAN, defaultValue: true },
}, { tableName: 'users', underscored: true });

// Categories
const Category = sequelize.define('Category', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  name: { type: DataTypes.STRING, allowNull: false },
  icon: { type: DataTypes.STRING },
  color: { type: DataTypes.STRING },
  isSystem: { type: DataTypes.BOOLEAN, defaultValue: false },
  userId: { type: DataTypes.UUID, references: { model: 'users', key: 'id' } },
}, { tableName: 'categories', underscored: true });

// Bills
const Bill = sequelize.define('Bill', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  userId: { type: DataTypes.UUID, allowNull: false, references: { model: 'users', key: 'id' } },
  productName: { type: DataTypes.STRING, allowNull: false },
  category: { type: DataTypes.STRING, allowNull: false },
  brandName: { type: DataTypes.STRING },
  modelNumber: { type: DataTypes.STRING },
  serialNumber: { type: DataTypes.STRING },
  imeiNumber: { type: DataTypes.STRING },
  purchaseDate: { type: DataTypes.DATEONLY, allowNull: false },
  billNumber: { type: DataTypes.STRING },
  purchaseAmount: { type: DataTypes.DECIMAL(12, 2), allowNull: false },
  taxAmount: { type: DataTypes.DECIMAL(12, 2) },
  currentValue: { type: DataTypes.DECIMAL(12, 2) },
  storeName: { type: DataTypes.STRING },
  storeAddress: { type: DataTypes.TEXT },
  gstNumber: { type: DataTypes.STRING },
  warrantyMonths: { type: DataTypes.INTEGER },
  warrantyStartDate: { type: DataTypes.DATEONLY },
  warrantyEndDate: { type: DataTypes.DATEONLY },
  warrantyStatus: {
    type: DataTypes.ENUM('active', 'expiringSoon', 'expired', 'noWarranty'),
    defaultValue: 'noWarranty',
  },
  attachmentUrls: { type: DataTypes.ARRAY(DataTypes.TEXT), defaultValue: [] },
  thumbnailUrl: { type: DataTypes.TEXT },
  ocrText: { type: DataTypes.TEXT },
  notes: { type: DataTypes.TEXT },
  isDeleted: { type: DataTypes.BOOLEAN, defaultValue: false },
}, { tableName: 'bills', underscored: true });

// Warranties
const Warranty = sequelize.define('Warranty', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  billId: { type: DataTypes.UUID, allowNull: false, references: { model: 'bills', key: 'id' } },
  userId: { type: DataTypes.UUID, allowNull: false, references: { model: 'users', key: 'id' } },
  startDate: { type: DataTypes.DATEONLY, allowNull: false },
  endDate: { type: DataTypes.DATEONLY, allowNull: false },
  durationMonths: { type: DataTypes.INTEGER, allowNull: false },
  status: { type: DataTypes.ENUM('active', 'expiringSoon', 'expired'), defaultValue: 'active' },
  extendedWarrantyDate: { type: DataTypes.DATEONLY },
  providerName: { type: DataTypes.STRING },
  documentUrl: { type: DataTypes.TEXT },
}, { tableName: 'warranties', underscored: true });

// Notifications
const Notification = sequelize.define('Notification', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  userId: { type: DataTypes.UUID, allowNull: false, references: { model: 'users', key: 'id' } },
  billId: { type: DataTypes.UUID, references: { model: 'bills', key: 'id' } },
  type: { type: DataTypes.ENUM('warranty_expiry', 'system', 'reminder'), allowNull: false },
  title: { type: DataTypes.STRING, allowNull: false },
  message: { type: DataTypes.TEXT, allowNull: false },
  isRead: { type: DataTypes.BOOLEAN, defaultValue: false },
  channel: { type: DataTypes.ENUM('push', 'email', 'sms'), defaultValue: 'push' },
  scheduledAt: { type: DataTypes.DATE },
  sentAt: { type: DataTypes.DATE },
}, { tableName: 'notifications', underscored: true });

// Depreciation Rules
const DepreciationRule = sequelize.define('DepreciationRule', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  category: { type: DataTypes.STRING, allowNull: false },
  userId: { type: DataTypes.UUID, references: { model: 'users', key: 'id' } },
  ratesPerYear: { type: DataTypes.ARRAY(DataTypes.FLOAT), allowNull: false },
  isCustom: { type: DataTypes.BOOLEAN, defaultValue: false },
}, { tableName: 'depreciation_rules', underscored: true });

// OCR Results
const OcrResult = sequelize.define('OcrResult', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  billId: { type: DataTypes.UUID, references: { model: 'bills', key: 'id' } },
  userId: { type: DataTypes.UUID, allowNull: false, references: { model: 'users', key: 'id' } },
  rawText: { type: DataTypes.TEXT },
  extractedData: { type: DataTypes.JSONB },
  confidence: { type: DataTypes.FLOAT },
  processingTimeMs: { type: DataTypes.INTEGER },
  provider: { type: DataTypes.STRING }, // 'google_vision' | 'aws_textract' | 'openai'
}, { tableName: 'ocr_results', underscored: true });

// User Preferences
const UserPreference = sequelize.define('UserPreference', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  userId: { type: DataTypes.UUID, unique: true, allowNull: false, references: { model: 'users', key: 'id' } },
  currency: { type: DataTypes.STRING, defaultValue: 'INR' },
  themeMode: { type: DataTypes.ENUM('light', 'dark', 'system'), defaultValue: 'system' },
  visibleColumns: { type: DataTypes.ARRAY(DataTypes.STRING), defaultValue: [] },
  emailNotifications: { type: DataTypes.BOOLEAN, defaultValue: true },
  pushNotifications: { type: DataTypes.BOOLEAN, defaultValue: true },
  smsNotifications: { type: DataTypes.BOOLEAN, defaultValue: false },
  customDepreciationRules: { type: DataTypes.JSONB, defaultValue: {} },
}, { tableName: 'user_preferences', underscored: true });

// Audit Logs
const AuditLog = sequelize.define('AuditLog', {
  id: { type: DataTypes.UUID, defaultValue: DataTypes.UUIDV4, primaryKey: true },
  userId: { type: DataTypes.UUID, allowNull: false },
  action: { type: DataTypes.STRING, allowNull: false },
  resource: { type: DataTypes.STRING },
  resourceId: { type: DataTypes.UUID },
  oldValues: { type: DataTypes.JSONB },
  newValues: { type: DataTypes.JSONB },
  ipAddress: { type: DataTypes.STRING },
  userAgent: { type: DataTypes.TEXT },
}, { tableName: 'audit_logs', underscored: true });

// Associations
User.hasMany(Bill, { foreignKey: 'userId', onDelete: 'CASCADE' });
Bill.belongsTo(User, { foreignKey: 'userId' });

User.hasOne(UserPreference, { foreignKey: 'userId', onDelete: 'CASCADE' });
UserPreference.belongsTo(User, { foreignKey: 'userId' });

Bill.hasOne(Warranty, { foreignKey: 'billId', onDelete: 'CASCADE' });
Warranty.belongsTo(Bill, { foreignKey: 'billId' });

Bill.hasMany(Notification, { foreignKey: 'billId' });
Notification.belongsTo(Bill, { foreignKey: 'billId' });

User.hasMany(Notification, { foreignKey: 'userId', onDelete: 'CASCADE' });
Notification.belongsTo(User, { foreignKey: 'userId' });

Bill.hasMany(OcrResult, { foreignKey: 'billId' });
OcrResult.belongsTo(Bill, { foreignKey: 'billId' });

module.exports = { User, Bill, Warranty, Notification, Category, DepreciationRule, OcrResult, UserPreference, AuditLog };
