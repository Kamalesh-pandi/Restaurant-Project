package com.example.backend.config;

import com.example.backend.admin.entity.Admin;
import com.example.backend.admin.repository.AdminRepository;
import com.example.backend.customer.entity.Customer;
import com.example.backend.customer.repository.CustomerRepository;
import com.example.backend.inventory.entity.InventoryItem;
import com.example.backend.inventory.entity.Recipe;
import com.example.backend.inventory.repository.InventoryItemRepository;
import com.example.backend.inventory.repository.RecipeRepository;
import com.example.backend.menu.entity.Category;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.CategoryRepository;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.staff.entity.Staff;
import com.example.backend.staff.entity.StaffRole;
import com.example.backend.staff.repository.StaffRepository;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.entity.TableStatus;
import com.example.backend.table.repository.RestaurantTableRepository;
import com.example.backend.delivery.entity.DeliveryPartner;
import com.example.backend.delivery.entity.DeliveryPartnerStatus;
import com.example.backend.delivery.repository.DeliveryPartnerRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
public class DataSeeder implements CommandLineRunner {

    private final AdminRepository adminRepository;
    private final StaffRepository staffRepository;
    private final CustomerRepository customerRepository;
    private final CategoryRepository categoryRepository;
    private final MenuItemRepository menuItemRepository;
    private final RestaurantTableRepository tableRepository;
    private final InventoryItemRepository inventoryRepository;
    private final RecipeRepository recipeRepository;
    private final DeliveryPartnerRepository deliveryPartnerRepository;
    private final PasswordEncoder passwordEncoder;

    public DataSeeder(AdminRepository adminRepository,
                      StaffRepository staffRepository,
                      CustomerRepository customerRepository,
                      CategoryRepository categoryRepository,
                      MenuItemRepository menuItemRepository,
                      RestaurantTableRepository tableRepository,
                      InventoryItemRepository inventoryRepository,
                      RecipeRepository recipeRepository,
                      DeliveryPartnerRepository deliveryPartnerRepository,
                      PasswordEncoder passwordEncoder) {
        this.adminRepository = adminRepository;
        this.staffRepository = staffRepository;
        this.customerRepository = customerRepository;
        this.categoryRepository = categoryRepository;
        this.menuItemRepository = menuItemRepository;
        this.tableRepository = tableRepository;
        this.inventoryRepository = inventoryRepository;
        this.recipeRepository = recipeRepository;
        this.deliveryPartnerRepository = deliveryPartnerRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) throws Exception {
        UUID outletId = UUID.fromString("11111111-1111-1111-1111-111111111111");

        // Seed / Reset Admin Credentials
        Optional<Admin> defaultAdminOpt = adminRepository.findByUsername("admin");
        if (defaultAdminOpt.isEmpty()) {
            defaultAdminOpt = adminRepository.findByEmail("admin@restaurant.com");
        }

        if (defaultAdminOpt.isEmpty()) {
            Admin admin = Admin.builder()
                    .username("admin")
                    .password(passwordEncoder.encode("password"))
                    .name("Main Admin")
                    .email("admin@restaurant.com")
                    .isActive(true)
                    .adminAccessLevel("SUPER_ADMIN")
                    .build();
            adminRepository.save(admin);
        } else {
            Admin admin = defaultAdminOpt.get();
            admin.setPassword(passwordEncoder.encode("password"));
            admin.setActive(true);
            adminRepository.save(admin);
        }

        // Seed / Ensure Staff Credentials with BCrypt Encoded PINs
        createOrUpdateStaff("manager", "manager@restaurant.com", "+91 98765 43210", "1111", StaffRole.MANAGER, "All", outletId);
        createOrUpdateStaff("cashier", "cashier@restaurant.com", "+91 98765 43211", "2222", StaffRole.CASHIER, "Front POS", outletId);
        createOrUpdateStaff("captain", "captain@restaurant.com", "+91 98765 43212", "3333", StaffRole.CAPTAIN, "Dining Area", outletId);
        createOrUpdateStaff("kitchen", "chef@restaurant.com", "+91 98765 43213", "4444", StaffRole.KITCHEN, "Main Kitchen", outletId);

        // Seed Customer
        if (customerRepository.count() == 0) {
            Customer customer = Customer.builder()
                    .name("John Doe")
                    .phone("9876543210")
                    .email("john.doe@gmail.com")
                    .birthday(LocalDate.of(1990, 5, 12))
                    .loyaltyPoints(100)
                    .totalVisits(5)
                    .totalSpend(BigDecimal.valueOf(1500.00))
                    .build();
            customerRepository.save(customer);
        }

        // Seed Categories
        List<Category> allCategories = categoryRepository.findAll();
        Category starters = allCategories.stream().filter(c -> "Starters".equalsIgnoreCase(c.getName())).findFirst().orElse(null);
        Category mains = allCategories.stream().filter(c -> "Mains".equalsIgnoreCase(c.getName()) || "Main Course".equalsIgnoreCase(c.getName())).findFirst().orElse(null);
        Category italian = allCategories.stream().filter(c -> "Italian".equalsIgnoreCase(c.getName())).findFirst().orElse(null);
        Category drinks = allCategories.stream().filter(c -> "Drinks".equalsIgnoreCase(c.getName()) || "Beverages".equalsIgnoreCase(c.getName())).findFirst().orElse(null);
        Category desserts = allCategories.stream().filter(c -> "Desserts".equalsIgnoreCase(c.getName())).findFirst().orElse(null);

        if (starters == null) starters = categoryRepository.save(Category.builder().name("Starters").build());
        if (mains == null) mains = categoryRepository.save(Category.builder().name("Main Course").build());
        if (italian == null) italian = categoryRepository.save(Category.builder().name("Italian").build());
        if (drinks == null) drinks = categoryRepository.save(Category.builder().name("Drinks").build());
        if (desserts == null) desserts = categoryRepository.save(Category.builder().name("Desserts").build());

        // Seed Station
        UUID hotKitchenStationId = UUID.fromString("22222222-2222-2222-2222-222222222222");

        // Seed MenuItems
        if (menuItemRepository.count() < 5) {
            MenuItem springRolls = MenuItem.builder()
                    .name("Crispy Vegetable Spring Rolls")
                    .description("Crispy vegetable spring rolls served with sweet chili dipping sauce")
                    .category(starters)
                    .price(BigDecimal.valueOf(180.00))
                    .gstRate(BigDecimal.valueOf(5.00))
                    .foodType("STARTER")
                    .isVeg(true)
                    .isAvailable(true)
                    .isSpecial(false)
                    .imageUrl("https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=600&auto=format&fit=crop")
                    .stationId(hotKitchenStationId)
                    .outletId(outletId)
                    .build();

            MenuItem paneerButterMasala = MenuItem.builder()
                    .name("Paneer Butter Masala")
                    .description("Cottage cheese cubes in rich tomato butter gravy")
                    .category(mains)
                    .price(BigDecimal.valueOf(320.00))
                    .gstRate(BigDecimal.valueOf(5.00))
                    .foodType("MAIN_COURSE")
                    .isVeg(true)
                    .isAvailable(true)
                    .isSpecial(true)
                    .imageUrl("https://images.unsplash.com/photo-1633964913295-ceb43826e7c9?w=600&auto=format&fit=crop")
                    .stationId(hotKitchenStationId)
                    .outletId(outletId)
                    .build();

            MenuItem wagyuBurger = MenuItem.builder()
                    .name("Wagyu Gourmet Burger")
                    .description("Prime Wagyu beef patty with smoked cheddar, caramelized onions & truffle aioli")
                    .category(mains)
                    .price(BigDecimal.valueOf(450.00))
                    .gstRate(BigDecimal.valueOf(5.00))
                    .foodType("MAIN_COURSE")
                    .isVeg(false)
                    .isAvailable(true)
                    .isSpecial(true)
                    .imageUrl("https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600&auto=format&fit=crop")
                    .stationId(hotKitchenStationId)
                    .outletId(outletId)
                    .build();

            MenuItem margheritaPizza = MenuItem.builder()
                    .name("Wood-Fired Margherita Pizza")
                    .description("San Marzano tomato sauce, fresh buffalo mozzarella & aromatic basil leaves")
                    .category(italian)
                    .price(BigDecimal.valueOf(390.00))
                    .gstRate(BigDecimal.valueOf(5.00))
                    .foodType("MAIN_COURSE")
                    .isVeg(true)
                    .isAvailable(true)
                    .isSpecial(false)
                    .imageUrl("https://images.unsplash.com/photo-1604382354936-07c5d9983bd3?w=600&auto=format&fit=crop")
                    .stationId(hotKitchenStationId)
                    .outletId(outletId)
                    .build();

            MenuItem chickenBiryani = MenuItem.builder()
                    .name("Chicken Biryani Special")
                    .description("Fragrant basmati rice cooked with succulent chicken and spices")
                    .category(mains)
                    .price(BigDecimal.valueOf(380.00))
                    .gstRate(BigDecimal.valueOf(5.00))
                    .foodType("MAIN_COURSE")
                    .isVeg(false)
                    .isAvailable(true)
                    .isSpecial(false)
                    .imageUrl("https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600&auto=format&fit=crop")
                    .stationId(hotKitchenStationId)
                    .outletId(outletId)
                    .build();

            MenuItem tiramisu = MenuItem.builder()
                    .name("Classic Italian Tiramisu")
                    .description("Espresso-soaked savoiardi biscuits layered with whipped mascarpone cream")
                    .category(desserts)
                    .price(BigDecimal.valueOf(220.00))
                    .gstRate(BigDecimal.valueOf(5.00))
                    .foodType("DESSERT")
                    .isVeg(true)
                    .isAvailable(true)
                    .isSpecial(true)
                    .imageUrl("https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=600&auto=format&fit=crop")
                    .stationId(hotKitchenStationId)
                    .outletId(outletId)
                    .build();

            menuItemRepository.saveAll(List.of(springRolls, paneerButterMasala, wagyuBurger, margheritaPizza, chickenBiryani, tiramisu));
        }

        // Seed Tables
        if (tableRepository.count() == 0) {
            RestaurantTable table1 = RestaurantTable.builder()
                    .tableNumber("T1")
                    .capacity(4)
                    .section("Indoor")
                    .status(TableStatus.AVAILABLE)
                    .xPos(10)
                    .yPos(20)
                    .outletId(outletId)
                    .build();

            RestaurantTable table2 = RestaurantTable.builder()
                    .tableNumber("T2")
                    .capacity(2)
                    .section("Outdoor")
                    .status(TableStatus.AVAILABLE)
                    .xPos(30)
                    .yPos(40)
                    .outletId(outletId)
                    .build();

            tableRepository.saveAll(List.of(table1, table2));
        }

        // Seed Ingredients & Recipe Mapping
        if (inventoryRepository.count() == 0) {
            InventoryItem paneer = InventoryItem.builder()
                    .name("Paneer")
                    .unit("g")
                    .currentStock(BigDecimal.valueOf(5000.000))
                    .reorderLevel(BigDecimal.valueOf(1000.000))
                    .costPrice(BigDecimal.valueOf(0.40))
                    .outletId(outletId)
                    .lastUpdatedAt(LocalDateTime.now())
                    .build();

            InventoryItem butter = InventoryItem.builder()
                    .name("Butter")
                    .unit("g")
                    .currentStock(BigDecimal.valueOf(2000.000))
                    .reorderLevel(BigDecimal.valueOf(500.000))
                    .costPrice(BigDecimal.valueOf(0.60))
                    .outletId(outletId)
                    .lastUpdatedAt(LocalDateTime.now())
                    .build();

            paneer = inventoryRepository.save(paneer);
            butter = inventoryRepository.save(butter);

            MenuItem pbm = menuItemRepository.findByName("Paneer Butter Masala").orElse(null);
            if (recipeRepository.count() == 0 && pbm != null) {
                Recipe recipePaneer = Recipe.builder()
                        .menuItemId(pbm.getItemId())
                        .ingredientId(paneer.getIngredientId())
                        .quantityPerPortion(BigDecimal.valueOf(200.0000))
                        .unit("g")
                        .build();

                Recipe recipeButter = Recipe.builder()
                        .menuItemId(pbm.getItemId())
                        .ingredientId(butter.getIngredientId())
                        .quantityPerPortion(BigDecimal.valueOf(50.0000))
                        .unit("g")
                        .build();

                recipeRepository.saveAll(List.of(recipePaneer, recipeButter));
            }
        }

        // Seed Delivery Partners
        createOrUpdateDeliveryPartner("Alex Rider", "alex.rider@fastdelivery.com", "+919876543210", "1234", "KA-01-AB-1234", "BIKE", 4.9, 120, outletId);
        createOrUpdateDeliveryPartner("Alex Rider", "alex.local@fastdelivery.com", "9876543210", "1234", "KA-01-AB-1234", "BIKE", 4.9, 120, outletId);
        createOrUpdateDeliveryPartner("Speedy Rider", "speedy@fastdelivery.com", "9876500001", "4321", "KA-01-CD-5678", "BIKE", 4.8, 85, outletId);
    }

    private void createOrUpdateDeliveryPartner(String name, String email, String phone, String pin, String vehicleNumber, String vehicleType, Double rating, Integer totalDeliveries, UUID outletId) {
        Optional<DeliveryPartner> opt = deliveryPartnerRepository.findByPhone(phone);
        DeliveryPartner partner;
        if (opt.isPresent()) {
            partner = opt.get();
        } else {
            partner = new DeliveryPartner();
            partner.setPhone(phone);
        }
        partner.setName(name);
        partner.setEmail(email);
        partner.setPinCode(pin);
        partner.setVehicleNumber(vehicleNumber);
        partner.setVehicleType(vehicleType != null ? vehicleType : "BIKE");
        partner.setOutletId(outletId);
        partner.setRating(rating != null ? rating : 5.0);
        partner.setTotalDeliveries(totalDeliveries != null ? totalDeliveries : 0);
        partner.setIsApproved(true);
        partner.setIsActive(true);
        if (partner.getStatus() == null) {
            partner.setStatus(DeliveryPartnerStatus.OFFLINE);
        }
        deliveryPartnerRepository.save(partner);
    }

    private void createOrUpdateStaff(String name, String email, String phone, String pin, StaffRole role, String section, UUID outletId) {
        Optional<Staff> opt = staffRepository.findByName(name);
        if (opt.isEmpty()) {
            opt = staffRepository.findByEmail(email);
        }
        Staff staff;
        if (opt.isPresent()) {
            staff = opt.get();
        } else {
            staff = new Staff();
            staff.setName(name);
        }
        staff.setEmail(email);
        staff.setPhoneNumber(phone);
        staff.setRole(role);
        staff.setSection(section);
        staff.setOutletId(outletId);
        staff.setActive(true);
        staff.setPinHash(passwordEncoder.encode(pin));
        staffRepository.save(staff);
    }
}
