const fs = require('fs');
const path = require('path');
const file = path.resolve(__dirname, '../../backend/src/main/java/com/example/backend/chain/service/ChainService.java');
let c = fs.readFileSync(file, 'utf8');

const target = `        if (promotion.getBrandId() == null) {
            List<Brand> brands = brandRepository.findAll();
            if (!brands.isEmpty()) promotion.setBrandId(brands.get(0).getId());
        }`;

const rep = `        if (promotion.getBrandId() == null) {
            List<Brand> brands = brandRepository.findAll();
            if (brands.isEmpty()) {
                Brand defaultBrand = brandRepository.save(Brand.builder()
                        .name("Royal Resto Corporate")
                        .headquartersAddress("Main HQ")
                        .corporateContact("contact@royalresto.com")
                        .build());
                promotion.setBrandId(defaultBrand.getId());
            } else {
                promotion.setBrandId(brands.get(0).getId());
            }
        }`;

if (c.includes(target)) {
  c = c.replace(target, rep);
  fs.writeFileSync(file, c, 'utf8');
  console.log('Successfully updated brand promotion fallback in ChainService.java');
} else {
  console.log('Target block not found, check line endings');
  const targetNorm = target.replace(/\r\n/g, '\n');
  const cNorm = c.replace(/\r\n/g, '\n');
  if (cNorm.includes(targetNorm)) {
    c = cNorm.replace(targetNorm, rep.replace(/\r\n/g, '\n'));
    fs.writeFileSync(file, c, 'utf8');
    console.log('Successfully updated with normalized line endings');
  }
}
