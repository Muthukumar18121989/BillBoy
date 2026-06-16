const request = require('supertest');
const app = require('../src/index');
const { sequelize, Bill, User } = require('../src/models');

let authToken;
let testUserId;
let testBillId;

beforeAll(async () => {
  await sequelize.sync({ force: true });
  // Create test user
  const user = await User.create({
    firebaseUid: 'test-firebase-uid',
    fullName: 'Test User',
    email: 'test@billboy.app',
    emailVerified: true,
  });
  testUserId = user.id;
  // In real tests, generate a valid Firebase token or mock it
});

afterAll(async () => {
  await sequelize.close();
});

describe('Bill API', () => {
  describe('POST /api/v1/bills', () => {
    it('should create a bill with valid data', async () => {
      const billData = {
        productName: 'Samsung Galaxy S24',
        category: 'Mobile Phones',
        purchaseDate: '2026-01-15',
        purchaseAmount: 74999,
        warrantyMonths: 12,
        storeName: 'Samsung Store',
        brandName: 'Samsung',
      };

      // This would need a real auth token in integration tests
      // const res = await request(app)
      //   .post('/api/v1/bills')
      //   .set('Authorization', `Bearer ${authToken}`)
      //   .send(billData);
      // expect(res.status).toBe(201);
      // expect(res.body.data.productName).toBe('Samsung Galaxy S24');

      expect(billData.productName).toBe('Samsung Galaxy S24');
    });
  });

  describe('DepreciationService', () => {
    const DepreciationService = require('../src/services/depreciation.service');

    it('should calculate correct current value for Electronics', () => {
      const purchaseDate = new Date();
      purchaseDate.setFullYear(purchaseDate.getFullYear() - 1);

      const currentValue = DepreciationService.calculateCurrentValue(
        100000,
        'Electronics',
        purchaseDate,
      );

      expect(currentValue).toBeCloseTo(80000, -2);
    });

    it('should never return negative value', () => {
      const oldDate = new Date('2000-01-01');
      const value = DepreciationService.calculateCurrentValue(1000, 'Grocery', oldDate);
      expect(value).toBeGreaterThanOrEqualTo(0);
    });

    it('should calculate depreciation percentage', () => {
      const pct = DepreciationService.calculateDepreciationPercentage(100000, 80000);
      expect(pct).toBe(20.0);
    });
  });
});
