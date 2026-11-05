import { pushSyncData } from '../src/services/sync.service.js';
import prisma from '../src/config/db.js';
import { v4 as uuidv4 } from 'uuid';

async function testPush() {
  const user = await prisma.user.findFirst({ where: { role: 'OWNER' } });
  if (!user) {
    console.error('No owner user found');
    return;
  }
  console.log('Testing push for owner:', user.id, user.businessName);

  const partId = uuidv4();
  const saleId = uuidv4();
  const saleItemId = uuidv4();

  const batch = [
    {
      id: partId,
      entity: 'spare_parts',
      action: 'insert',
      data: {
        id: partId,
        owner_id: user.id,
        name: 'Test Oil Filter',
        part_number: 'OF-999',
        purchase_price: 150.0,
        selling_price: 250.0,
        quantity: 10.0,
      },
    },
    {
      id: saleId,
      entity: 'sales',
      action: 'insert',
      data: {
        id: saleId,
        owner_id: user.id,
        receipt_number: 'REC-TEST-001',
        total_amount: 500.0,
        total_profit: 200.0,
        payment_method: 'Cash',
        sold_at: new Date().toISOString(),
        items: [
          {
            id: saleItemId,
            sale_id: saleId,
            part_id: partId,
            part_name_snapshot: 'Test Oil Filter',
            quantity: 2.0,
            unit_cost: 150.0,
            unit_price: 250.0,
            subtotal: 500.0,
            profit: 200.0,
          },
        ],
      },
    },
  ];

  try {
    const result = await pushSyncData(user.id, batch);
    console.log('Push result:', JSON.stringify(result, null, 2));
  } catch (err) {
    console.error('Push error:', err);
  } finally {
    // Clean up test records
    await prisma.saleItem.deleteMany({ where: { id: saleItemId } }).catch(() => {});
    await prisma.sale.deleteMany({ where: { id: saleId } }).catch(() => {});
    await prisma.sparePart.deleteMany({ where: { id: partId } }).catch(() => {});
    await prisma.$disconnect();
  }
}

testPush();

