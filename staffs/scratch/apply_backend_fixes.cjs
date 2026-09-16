const fs = require('fs');
const path = require('path');

const backendDir = path.resolve(__dirname, '../../backend');

function updateFile(relPath, transform) {
  const fullPath = path.join(backendDir, relPath);
  if (!fs.existsSync(fullPath)) {
    console.error(`File not found: ${fullPath}`);
    return false;
  }
  const content = fs.readFileSync(fullPath, 'utf8');
  const updated = transform(content);
  if (content === updated) {
    console.log(`No changes needed in: ${relPath}`);
    return true;
  }
  fs.writeFileSync(fullPath, updated, 'utf8');
  console.log(`Successfully updated: ${relPath}`);
  return true;
}

// 1. BillController.java
updateFile('src/main/java/com/example/backend/bill/controller/BillController.java', (c) => {
  let res = c;
  // Replace hasRole('CASHIER') with hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')
  res = res.replace(/@PreAuthorize\("hasRole\('CASHIER'\)"\)/g, `@PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")`);
  
  // Replace receipt and send-digital
  if (!res.includes('/bills/{id}/print')) {
    const oldPart = `@PostMapping("/bills/{id}/send-digital")\r\n    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER')")\r\n    public ResponseEntity<String> sendDigitalReceipt(@PathVariable UUID id,\r\n                                                     @RequestParam String phoneNumber) {\r\n        return ResponseEntity.ok(billService.sendDigitalReceipt(id, phoneNumber));\r\n    }`;
    const newPart = `@PostMapping({"/bills/{id}/send-digital", "/bills/{id}/digital-receipt"})\r\n    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")\r\n    public ResponseEntity<String> sendDigitalReceipt(@PathVariable UUID id,\r\n                                                     @RequestParam String phoneNumber) {\r\n        return ResponseEntity.ok(billService.sendDigitalReceipt(id, phoneNumber));\r\n    }\r\n\r\n    @PostMapping("/bills/{id}/print")\r\n    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")\r\n    public ResponseEntity<String> printBill(@PathVariable UUID id) {\r\n        return ResponseEntity.ok(billService.getReceiptText(id));\r\n    }`;
    if (res.includes(oldPart)) {
      res = res.replace(oldPart, newPart);
    } else {
      // Unix newline fallback
      const oldPartUnix = oldPart.replace(/\r\n/g, '\n');
      const newPartUnix = newPart.replace(/\r\n/g, '\n');
      res = res.replace(oldPartUnix, newPartUnix);
    }
  }

  res = res.replace(
    /@PreAuthorize\("hasAnyRole\('CASHIER', 'MANAGER'\)"\)/g,
    `@PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")`
  );
  return res;
});

// 2. TableController.java
updateFile('src/main/java/com/example/backend/table/controller/TableController.java', (c) => {
  let res = c;
  // createTable
  res = res.replace(
    /@PostMapping\r?\n\s*@PreAuthorize\("hasAnyRole\('MANAGER', 'ADMIN'\)"\)\r?\n\s*public ResponseEntity<RestaurantTable> createTable/g,
    `@PostMapping\n    @PreAuthorize("hasAnyRole('CAPTAIN', 'MANAGER', 'ADMIN')")\n    public ResponseEntity<RestaurantTable> createTable`
  );
  // getAverageTurnTime
  res = res.replace(
    /@GetMapping\("\/analytics\/turn-time"\)\r?\n\s*@PreAuthorize\("hasAnyRole\('MANAGER', 'ADMIN'\)"\)/g,
    `@GetMapping("/analytics/turn-time")\n    @PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")`
  );
  return res;
});

// 3. ReservationController.java
updateFile('src/main/java/com/example/backend/reservation/controller/ReservationController.java', (c) => {
  let res = c;
  res = res.replace(
    /@PreAuthorize\("hasAnyRole\('MANAGER', 'ADMIN'\)"\)/g,
    `@PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")`
  );
  return res;
});

// 4. WaitlistController.java
updateFile('src/main/java/com/example/backend/table/controller/WaitlistController.java', (c) => {
  let res = c;
  res = res.replace(
    /@PreAuthorize\("hasAnyRole\('CAPTAIN', 'MANAGER'\)"\)/g,
    `@PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")`
  );
  res = res.replace(
    /@PreAuthorize\("hasAnyRole\('CASHIER', 'CAPTAIN', 'MANAGER'\)"\)/g,
    `@PreAuthorize("hasAnyRole('CASHIER', 'CAPTAIN', 'MANAGER', 'ADMIN')")`
  );
  return res;
});

// 5. KitchenStationController.java
updateFile('src/main/java/com/example/backend/menu/controller/KitchenStationController.java', (c) => {
  let res = c;
  res = res.replace(
    /@PreAuthorize\("hasRole\('ADMIN'\)"\)/g,
    `@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'KITCHEN')")`
  );
  return res;
});

// 6. ChainService.java
updateFile('src/main/java/com/example/backend/chain/service/ChainService.java', (c) => {
  let res = c;
  if (!res.includes('public List<BrandPromotion> getAllPromotions()')) {
    const target = 'public BrandPromotion createBrandPromotion(BrandPromotion promotion) {';
    const addition = `public List<BrandPromotion> getAllPromotions() {\n        return promotionRepository.findAll();\n    }\n\n    // Brand promotions\n    @Transactional\n    ` + target;
    res = res.replace(target, addition);
  }
  return res;
});

// 7. ChainController.java
updateFile('src/main/java/com/example/backend/chain/controller/ChainController.java', (c) => {
  let res = c;
  // createBrandPromotion allow manager
  res = res.replace(
    /@PostMapping\("\/promotions"\)\r?\n\s*@PreAuthorize\("hasRole\('ADMIN'\)"\)/g,
    `@PostMapping("/promotions")\n    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")`
  );
  if (!res.includes('public ResponseEntity<List<BrandPromotion>> getAllPromotions()')) {
    const target = '@PostMapping("/promotions")';
    const addition = `@GetMapping("/promotions")\n    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'CASHIER')")\n    public ResponseEntity<List<BrandPromotion>> getAllPromotions() {\n        return ResponseEntity.ok(chainService.getAllPromotions());\n    }\n\n    ` + target;
    res = res.replace(target, addition);
  }
  return res;
});

console.log('All backend updates finished.');
