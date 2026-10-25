import { describe, it, expect } from 'vitest';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

describe('Admin Data Isolation & Hard Separation Rule', () => {
  const adminServicesDir = path.resolve(__dirname, '../src/services/admin');

  it('No admin service except adminStatsService.js may reference SparePart, StockMovement, Sale, or SaleItem', () => {
    const files = fs.readdirSync(adminServicesDir).filter((f) => f.endsWith('.js'));
    const forbiddenModels = [
      'sparePart',
      'SparePart',
      'stockMovement',
      'StockMovement',
      'saleItem',
      'SaleItem',
      'prisma.sale.',
      'prisma.saleItem.',
      'prisma.sparePart.',
      'prisma.stockMovement.',
    ];

    for (const file of files) {
      if (file === 'adminStatsService.js') {
        continue; // allowed file
      }

      const content = fs.readFileSync(path.join(adminServicesDir, file), 'utf-8');

      for (const pattern of forbiddenModels) {
        const found = content.includes(pattern);
        expect(
          found,
          `File '${file}' violates isolation rule by referencing '${pattern}'. Only adminStatsService.js is permitted to touch inventory and sales.`
        ).toBe(false);
      }
    }
  });

  it('adminStatsService.js ONLY uses count and never queries rows of parts or sales', () => {
    const statsContent = fs.readFileSync(
      path.join(adminServicesDir, 'adminStatsService.js'),
      'utf-8'
    );

    const forbiddenQueries = [
      /\.findMany\s*\(/,
      /\.findUnique\s*\(/,
      /\.findFirst\s*\(/,
      /\.create\s*\(/,
      /\.update\s*\(/,
      /\.delete\s*\(/,
      /\.deleteMany\s*\(/,
      /\.updateMany\s*\(/,
    ];

    for (const regex of forbiddenQueries) {
      expect(
        regex.test(statsContent),
        `adminStatsService.js must only use count or aggregates, but found query method '${regex}'`
      ).toBe(false);
    }
  });
});
