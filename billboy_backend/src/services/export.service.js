const { stringify } = require('csv-stringify/sync');
const PDFDocument = require('pdfkit');

class ExportService {
  generateCsv(bills) {
    const headers = [
      'Product Name', 'Category', 'Brand', 'Purchase Date', 'Bill Number',
      'Amount (₹)', 'Tax (₹)', 'Current Value (₹)', 'Warranty (months)',
      'Warranty End', 'Store', 'GST Number', 'Serial Number', 'Status',
    ];

    const rows = bills.map(b => [
      b.productName,
      b.category,
      b.brandName || '',
      b.purchaseDate,
      b.billNumber || '',
      b.purchaseAmount,
      b.taxAmount || '',
      b.currentValue || '',
      b.warrantyMonths || '',
      b.warrantyEndDate || '',
      b.storeName || '',
      b.gstNumber || '',
      b.serialNumber || '',
      b.warrantyStatus,
    ]);

    return stringify([headers, ...rows]);
  }

  generatePdf(bills, user) {
    return new Promise((resolve, reject) => {
      const doc = new PDFDocument({ margin: 40 });
      const chunks = [];

      doc.on('data', chunk => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      // Header
      doc.fontSize(20).font('Helvetica-Bold').text('BillBoy - Purchase Summary', { align: 'center' });
      doc.fontSize(10).font('Helvetica').text('Never lose a bill. Never miss a warranty.', { align: 'center' });
      doc.moveDown();

      // User info
      if (user) {
        doc.fontSize(10).text(`Generated for: ${user.fullName} (${user.email})`);
        doc.text(`Generated on: ${new Date().toLocaleString()}`);
        doc.text(`Total bills: ${bills.length}`);
      }
      doc.moveDown();

      // Summary stats
      const totalSpend = bills.reduce((sum, b) => sum + parseFloat(b.purchaseAmount), 0);
      const activeWarranties = bills.filter(b => b.warrantyStatus === 'active').length;

      doc.fontSize(12).font('Helvetica-Bold').text('Summary');
      doc.fontSize(10).font('Helvetica');
      doc.text(`Total Spend: ₹${totalSpend.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`);
      doc.text(`Active Warranties: ${activeWarranties}`);
      doc.moveDown();

      // Bills table
      doc.fontSize(12).font('Helvetica-Bold').text('Bill Details');
      doc.moveDown(0.5);

      for (const bill of bills) {
        doc.fontSize(11).font('Helvetica-Bold').text(bill.productName, { continued: true });
        doc.font('Helvetica').fontSize(10).text(` (${bill.category})`);
        doc.fontSize(9).fillColor('#666666');
        doc.text(`Date: ${bill.purchaseDate}  |  Amount: ₹${parseFloat(bill.purchaseAmount).toLocaleString('en-IN')}  |  Store: ${bill.storeName || 'N/A'}`);
        if (bill.warrantyEndDate) {
          doc.text(`Warranty: ${bill.warrantyMonths} months (ends: ${bill.warrantyEndDate})  |  Status: ${bill.warrantyStatus}`);
        }
        doc.fillColor('#000000');
        doc.moveDown(0.5);
      }

      doc.end();
    });
  }
}

module.exports = new ExportService();
