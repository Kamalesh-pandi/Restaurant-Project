package com.example.backend.order.service;

import com.example.backend.exception.*;
import com.example.backend.inventory.entity.InventoryItem;
import com.example.backend.inventory.entity.Recipe;
import com.example.backend.inventory.repository.InventoryItemRepository;
import com.example.backend.inventory.repository.RecipeRepository;
import com.example.backend.menu.entity.ComboComponent;
import com.example.backend.menu.entity.MenuItem;
import com.example.backend.menu.repository.ComboComponentRepository;
import com.example.backend.menu.repository.MenuItemRepository;
import com.example.backend.menu.repository.ModifierGroupRepository;
import com.example.backend.menu.repository.ModifierOptionRepository;
import com.example.backend.inventory.service.InventoryService;
import com.example.backend.menu.entity.ModifierGroup;
import com.example.backend.menu.entity.ModifierOption;
import com.example.backend.order.entity.*;
import com.example.backend.order.repository.OrderItemRepository;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.order.repository.OrderTimelineRepository;
import com.example.backend.order.dto.OrderItemSplitRequest;
import com.example.backend.staff.entity.Staff;
import com.example.backend.staff.entity.StaffRole;
import com.example.backend.staff.repository.StaffRepository;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.entity.TableStatus;
import com.example.backend.table.repository.RestaurantTableRepository;
import com.example.backend.table.service.TableService;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final RestaurantTableRepository tableRepository;
    private final RecipeRepository recipeRepository;
    private final InventoryItemRepository inventoryRepository;
    private final StaffRepository staffRepository;
    private final PasswordEncoder passwordEncoder;
    private final SimpMessagingTemplate messagingTemplate;
    private final MenuItemRepository menuItemRepository;
    private final ComboComponentRepository comboComponentRepository;
    private final TableService tableService;
    private final ModifierGroupRepository modifierGroupRepository;
    private final ModifierOptionRepository modifierOptionRepository;
    private final OrderTimelineRepository orderTimelineRepository;
    private final InventoryService inventoryService;

    public OrderService(OrderRepository orderRepository,
                        OrderItemRepository orderItemRepository,
                        RestaurantTableRepository tableRepository,
                        RecipeRepository recipeRepository,
                        InventoryItemRepository inventoryRepository,
                        StaffRepository staffRepository,
                        PasswordEncoder passwordEncoder,
                        SimpMessagingTemplate messagingTemplate,
                        MenuItemRepository menuItemRepository,
                        ComboComponentRepository comboComponentRepository,
                        TableService tableService,
                        ModifierGroupRepository modifierGroupRepository,
                        ModifierOptionRepository modifierOptionRepository,
                        OrderTimelineRepository orderTimelineRepository,
                        InventoryService inventoryService) {
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.tableRepository = tableRepository;
        this.recipeRepository = recipeRepository;
        this.inventoryRepository = inventoryRepository;
        this.staffRepository = staffRepository;
        this.passwordEncoder = passwordEncoder;
        this.messagingTemplate = messagingTemplate;
        this.menuItemRepository = menuItemRepository;
        this.comboComponentRepository = comboComponentRepository;
        this.tableService = tableService;
        this.modifierGroupRepository = modifierGroupRepository;
        this.modifierOptionRepository = modifierOptionRepository;
        this.orderTimelineRepository = orderTimelineRepository;
        this.inventoryService = inventoryService;
    }

    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }

    public Order getOrderById(UUID id) {
        return orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found"));
    }

    public List<OrderItem> getOrderItems(UUID orderId) {
        return orderItemRepository.findByOrderId(orderId);
    }

    private void validateModifiers(UUID menuItemId, String modifiersJson) {
        List<ModifierGroup> groups = modifierGroupRepository.findByMenuItemId(menuItemId);
        for (ModifierGroup group : groups) {
            List<ModifierOption> options = modifierOptionRepository.findByModifierGroupId(group.getModifierGroupId());
            int matchCount = 0;
            for (ModifierOption opt : options) {
                if (modifiersJson != null && modifiersJson.contains(opt.getName())) {
                    matchCount++;
                }
            }
            if (group.isMandatory() && matchCount < group.getMinSelections()) {
                throw new RuntimeException("Mandatory modifier group '" + group.getName() + "' requires at least " + group.getMinSelections() + " selections, but got " + matchCount);
            }
            if (matchCount > group.getMaxSelections()) {
                throw new RuntimeException("Modifier group '" + group.getName() + "' allows at most " + group.getMaxSelections() + " selections, but got " + matchCount);
            }
        }
    }

    public void logTimelineEvent(UUID orderId, String eventType, String description, String actorName) {
        OrderTimelineEvent event = OrderTimelineEvent.builder()
                .orderId(orderId)
                .eventType(eventType)
                .description(description)
                .actorName(actorName)
                .timestamp(LocalDateTime.now())
                .build();
        orderTimelineRepository.save(event);
    }

    @Transactional
    public Order createOrder(Order order, List<OrderItem> items) {
        for (OrderItem item : items) {
            validateModifiers(item.getMenuItemId(), item.getModifiers());
        }

        if (order.getOutletId() == null) {
            order.setOutletId(UUID.randomUUID());
        }
        if (order.getStatus() == null) {
            order.setStatus(OrderStatus.NEW);
        }
        if (order.getIsTraining() == null) {
            order.setIsTraining(false);
        }

        if (order.getStatus() == OrderStatus.DRAFT) {
            Order savedOrder = orderRepository.save(order);
            for (OrderItem item : items) {
                item.setOrderId(savedOrder.getOrderId());
                item.setStatus(OrderItemStatus.PENDING);
                orderItemRepository.save(item);
            }
            logTimelineEvent(savedOrder.getOrderId(), "CREATED", "Draft order created", null);
            return savedOrder;
        }

        if (order.getOrderType() == OrderType.DINE_IN && order.getTableId() != null) {
            RestaurantTable table = tableRepository.findById(order.getTableId())
                    .orElseThrow(() -> new RuntimeException("Table not found"));
            if (table.getStatus() == TableStatus.OCCUPIED && table.getCurrentOrderId() != null) {
                throw new TableOccupiedException("Table is already occupied");
            }
            order.setSeatedAt(LocalDateTime.now());
            Order savedOrder = orderRepository.save(order);
            table.setStatus(TableStatus.OCCUPIED);
            table.setCurrentOrderId(savedOrder.getOrderId());
            tableRepository.save(table);
            
            // Also occupy merged secondary tables
            List<RestaurantTable> secondaryTables = tableRepository.findByParentTableId(table.getTableId());
            for (RestaurantTable st : secondaryTables) {
                st.setStatus(TableStatus.OCCUPIED);
                st.setCurrentOrderId(savedOrder.getOrderId());
                tableRepository.save(st);
            }
            
            for (OrderItem item : items) {
                item.setOrderId(savedOrder.getOrderId());
                item.setStatus(OrderItemStatus.PENDING);
                orderItemRepository.save(item);
            }
            logTimelineEvent(savedOrder.getOrderId(), "CREATED", "Order created and table assigned", null);
            return savedOrder;
        } else {
            Order savedOrder = orderRepository.save(order);
            for (OrderItem item : items) {
                item.setOrderId(savedOrder.getOrderId());
                item.setStatus(OrderItemStatus.PENDING);
                orderItemRepository.save(item);
            }
            logTimelineEvent(savedOrder.getOrderId(), "CREATED", "Order created", null);
            return savedOrder;
        }
    }

    @Transactional
    public Order fireKot(UUID orderId) {
        Order order = getOrderById(orderId);
        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);

        // If Dine-In draft and now firing, lock table
        if (order.getStatus() == OrderStatus.DRAFT && order.getOrderType() == OrderType.DINE_IN && order.getTableId() != null) {
            RestaurantTable table = tableRepository.findById(order.getTableId())
                    .orElseThrow(() -> new RuntimeException("Table not found"));
            if (table.getStatus() == TableStatus.OCCUPIED && table.getCurrentOrderId() != null && !table.getCurrentOrderId().equals(orderId)) {
                throw new TableOccupiedException("Table is already occupied");
            }
            table.setStatus(TableStatus.OCCUPIED);
            table.setCurrentOrderId(order.getOrderId());
            tableRepository.save(table);
        }

        boolean hasPending = false;
        StringBuilder kotPrint = new StringBuilder("----- KOT PRINT -----\n");
        kotPrint.append("Order ID: ").append(orderId).append("\n");
        kotPrint.append("Type: ").append(order.getOrderType()).append("\n");
        if (order.getTableId() != null) {
            kotPrint.append("Table ID: ").append(order.getTableId()).append("\n");
        }
        kotPrint.append("Items:\n");

        for (OrderItem item : items) {
            if (item.getStatus() == OrderItemStatus.PENDING) {
                hasPending = true;
                deductInventory(item.getMenuItemId(), item.getQuantity());
                item.setStatus(OrderItemStatus.PREPARING);
                orderItemRepository.save(item);

                MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
                String name = menuItem != null ? menuItem.getName() : "Unknown Item";
                kotPrint.append(" - ").append(name).append(" x ").append(item.getQuantity());
                if (item.getModifiers() != null && !item.getModifiers().isEmpty()) {
                    kotPrint.append(" (").append(item.getModifiers()).append(")");
                }
                kotPrint.append("\n");
            }
        }
        kotPrint.append("---------------------");

        if (hasPending) {
            System.out.println(kotPrint.toString()); // Print KOT simulation
            order.setStatus(OrderStatus.PREPARING);
            order.setKotFiredAt(LocalDateTime.now());
            Order savedOrder = orderRepository.save(order);
            try {
                messagingTemplate.convertAndSend("/topic/orders", savedOrder);
            } catch (Exception e) {
            }
            logTimelineEvent(orderId, "KOT_FIRED", "KOT fired to kitchen: " + kotPrint.toString(), null);
            return savedOrder;
        } else {
            throw new KOTAlreadyFiredException("All items are already fired");
        }
    }

    @Transactional
    public Order modifyOrderItems(UUID orderId, List<OrderItem> proposedItems, String managerPin) {
        Order order = getOrderById(orderId);
        List<OrderItem> existingItems = orderItemRepository.findByOrderId(orderId);

        List<OrderItem> voidedList = new java.util.ArrayList<>();
        List<OrderItem> addedList = new java.util.ArrayList<>();

        for (OrderItem existing : existingItems) {
            if (existing.getStatus() == OrderItemStatus.VOIDED) continue;
            
            OrderItem match = proposedItems.stream()
                    .filter(p -> p.getMenuItemId().equals(existing.getMenuItemId()) 
                              && java.util.Objects.equals(p.getModifiers(), existing.getModifiers()))
                    .findFirst().orElse(null);

            if (match == null) {
                voidedList.add(OrderItem.builder()
                        .menuItemId(existing.getMenuItemId())
                        .quantity(existing.getQuantity())
                        .modifiers(existing.getModifiers())
                        .itemId(existing.getItemId())
                        .build());
            } else if (match.getQuantity() < existing.getQuantity()) {
                int diff = existing.getQuantity() - match.getQuantity();
                voidedList.add(OrderItem.builder()
                        .menuItemId(existing.getMenuItemId())
                        .quantity(diff)
                        .modifiers(existing.getModifiers())
                        .itemId(existing.getItemId())
                        .build());
            }
        }

        for (OrderItem proposed : proposedItems) {
            OrderItem match = existingItems.stream()
                    .filter(e -> e.getStatus() != OrderItemStatus.VOIDED 
                              && e.getMenuItemId().equals(proposed.getMenuItemId()) 
                              && java.util.Objects.equals(e.getModifiers(), proposed.getModifiers()))
                    .findFirst().orElse(null);

            if (match == null) {
                addedList.add(proposed);
            } else if (proposed.getQuantity() > match.getQuantity()) {
                int diff = proposed.getQuantity() - match.getQuantity();
                addedList.add(OrderItem.builder()
                        .menuItemId(proposed.getMenuItemId())
                        .quantity(diff)
                        .modifiers(proposed.getModifiers())
                        .unitPrice(proposed.getUnitPrice())
                        .status(OrderItemStatus.PENDING)
                        .build());
            }
        }

        if (!voidedList.isEmpty()) {
            validateManagerPin(managerPin);
        }

        for (OrderItem add : addedList) {
            validateModifiers(add.getMenuItemId(), add.getModifiers());
        }

        if (!voidedList.isEmpty()) {
            StringBuilder voidKot = new StringBuilder("----- VOID KOT PRINT -----\n");
            voidKot.append("Order ID: ").append(orderId).append("\n");
            voidKot.append("Items Voided:\n");

            for (OrderItem v : voidedList) {
                OrderItem dbItem = orderItemRepository.findById(v.getItemId()).orElseThrow();
                
                int matchQty = proposedItems.stream()
                        .filter(p -> p.getMenuItemId().equals(v.getMenuItemId()) 
                                  && java.util.Objects.equals(p.getModifiers(), v.getModifiers()))
                        .map(OrderItem::getQuantity).findFirst().orElse(0);

                if (matchQty == 0) {
                    dbItem.setStatus(OrderItemStatus.VOIDED);
                } else {
                    dbItem.setQuantity(matchQty);
                }
                orderItemRepository.save(dbItem);

                if (dbItem.getStatus() == OrderItemStatus.PREPARING || dbItem.getStatus() == OrderItemStatus.READY || dbItem.getStatus() == OrderItemStatus.SERVED) {
                    restoreInventory(v.getMenuItemId(), v.getQuantity());
                }

                MenuItem menuItem = menuItemRepository.findById(v.getMenuItemId()).orElse(null);
                voidKot.append(" - [VOID] ").append(menuItem != null ? menuItem.getName() : "Unknown").append(" x ").append(v.getQuantity()).append("\n");
            }
            voidKot.append("--------------------------");
            System.out.println(voidKot.toString());
            logTimelineEvent(orderId, "ITEM_VOIDED", "Items voided: " + voidKot.toString(), "Manager");
        }

        if (!addedList.isEmpty()) {
            StringBuilder newKot = new StringBuilder("----- NEW KOT PRINT -----\n");
            newKot.append("Order ID: ").append(orderId).append("\n");
            newKot.append("New Items Added:\n");

            for (OrderItem a : addedList) {
                OrderItem dbItem = existingItems.stream()
                        .filter(e -> e.getStatus() != OrderItemStatus.VOIDED 
                                  && e.getMenuItemId().equals(a.getMenuItemId()) 
                                  && java.util.Objects.equals(e.getModifiers(), a.getModifiers()))
                        .findFirst().orElse(null);

                if (dbItem != null) {
                    int originalQty = dbItem.getQuantity();
                    dbItem.setQuantity(originalQty + a.getQuantity());
                    orderItemRepository.save(dbItem);
                } else {
                    a.setOrderId(orderId);
                    if (a.getStatus() == null) {
                        a.setStatus(OrderItemStatus.PENDING);
                    }
                    orderItemRepository.save(a);
                }

                if (order.getStatus() == OrderStatus.PREPARING || order.getStatus() == OrderStatus.READY) {
                    deductInventory(a.getMenuItemId(), a.getQuantity());
                }

                MenuItem menuItem = menuItemRepository.findById(a.getMenuItemId()).orElse(null);
                newKot.append(" - ").append(menuItem != null ? menuItem.getName() : "Unknown").append(" x ").append(a.getQuantity()).append("\n");
            }
            newKot.append("-------------------------");
            System.out.println(newKot.toString());
            logTimelineEvent(orderId, "ITEM_ADDED", "New items added: " + newKot.toString(), "Captain");
        }

        return order;
    }

    @Transactional
    public Order splitOrder(UUID orderId, List<OrderItemSplitRequest> splitRequests) {
        Order original = getOrderById(orderId);
        
        Order splitOrder = Order.builder()
                .outletId(original.getOutletId())
                .tableId(original.getTableId())
                .orderType(original.getOrderType())
                .tokenNumber(original.getTokenNumber() != null ? original.getTokenNumber() + "-S" : "SPLIT")
                .status(original.getStatus())
                .cashierId(original.getCashierId())
                .captainId(original.getCaptainId())
                .covers(original.getCovers())
                .build();
        splitOrder = orderRepository.save(splitOrder);

        for (OrderItemSplitRequest req : splitRequests) {
            OrderItem originalItem = orderItemRepository.findById(req.getOrderItemId())
                    .orElseThrow(() -> new RuntimeException("OrderItem not found"));

            if (req.getQuantity() >= originalItem.getQuantity()) {
                originalItem.setOrderId(splitOrder.getOrderId());
                orderItemRepository.save(originalItem);
            } else {
                int originalQty = originalItem.getQuantity();
                originalItem.setQuantity(originalQty - req.getQuantity());
                orderItemRepository.save(originalItem);

                OrderItem newItem = OrderItem.builder()
                        .orderId(splitOrder.getOrderId())
                        .menuItemId(originalItem.getMenuItemId())
                        .quantity(req.getQuantity())
                        .unitPrice(originalItem.getUnitPrice())
                        .modifiers(originalItem.getModifiers())
                        .kotNumber(originalItem.getKotNumber())
                        .status(originalItem.getStatus())
                        .discountAmount(BigDecimal.ZERO)
                        .isComplimentary(originalItem.isComplimentary())
                        .build();
                orderItemRepository.save(newItem);
            }
        }

        logTimelineEvent(original.getOrderId(), "SPLIT", "Order split: items moved to order " + splitOrder.getOrderId(), null);
        logTimelineEvent(splitOrder.getOrderId(), "CREATED", "Created via split from order " + original.getOrderId(), null);

        return splitOrder;
    }

    @Transactional
    public OrderItem applyItemDiscount(UUID orderItemId, BigDecimal discountAmount, String managerPin) {
        validateManagerPin(managerPin);
        OrderItem item = orderItemRepository.findById(orderItemId)
                .orElseThrow(() -> new RuntimeException("OrderItem not found"));
        
        item.setDiscountAmount(discountAmount);
        OrderItem saved = orderItemRepository.save(item);

        logTimelineEvent(item.getOrderId(), "DISCOUNT_APPLIED", "Item discount applied: " + discountAmount + " on item " + orderItemId, "Manager");
        return saved;
    }

    @Transactional
    public OrderItem markItemComplimentary(UUID orderItemId, String managerPin) {
        validateManagerPin(managerPin);
        OrderItem item = orderItemRepository.findById(orderItemId)
                .orElseThrow(() -> new RuntimeException("OrderItem not found"));

        item.setComplimentary(true);
        item.setDiscountAmount(BigDecimal.ZERO);
        OrderItem saved = orderItemRepository.save(item);

        logTimelineEvent(item.getOrderId(), "COMPLIMENTARY", "Item marked as complimentary: item " + orderItemId, "Manager");
        return saved;
    }

    private void deductInventory(UUID menuItemId, int itemQuantity) {
        inventoryService.deductIngredientsForMenuItem(menuItemId, itemQuantity);
    }

    @Transactional
    public OrderItem voidOrderItem(UUID orderItemId, String managerPin) {
        return voidOrderItem(orderItemId, managerPin, "Cancelled by manager");
    }

    @Transactional
    public OrderItem voidOrderItem(UUID orderItemId, String managerPin, String voidReason) {
        validateManagerPin(managerPin);

        OrderItem item = orderItemRepository.findById(orderItemId)
                .orElseThrow(() -> new RuntimeException("Order item not found"));

        if (item.getStatus() == OrderItemStatus.VOIDED) {
            return item;
        }

        if (item.getStatus() == OrderItemStatus.PREPARING || item.getStatus() == OrderItemStatus.READY || item.getStatus() == OrderItemStatus.SERVED) {
            restoreInventory(item.getMenuItemId(), item.getQuantity());
        }

        item.setStatus(OrderItemStatus.VOIDED);
        item.setVoidReason(voidReason != null ? voidReason : "Cancelled by manager");
        OrderItem savedItem = orderItemRepository.save(item);

        logTimelineEvent(item.getOrderId(), "ITEM_VOIDED", "Item voided (Reason: " + item.getVoidReason() + "): item " + orderItemId, "Manager");

        List<OrderItem> allItems = orderItemRepository.findByOrderId(item.getOrderId());
        boolean allVoided = allItems.stream().allMatch(i -> i.getStatus() == OrderItemStatus.VOIDED);
        if (allVoided) {
            Order order = getOrderById(item.getOrderId());
            order.setStatus(OrderStatus.CANCELLED);
            orderRepository.save(order);

            if (order.getOrderType() == OrderType.DINE_IN && order.getTableId() != null) {
                tableService.releaseTable(order.getTableId());
            }
        }

        return savedItem;
    }

    @Transactional
    public Order fireCourse(UUID orderId, String courseName) {
        Order order = getOrderById(orderId);
        List<OrderItem> items = orderItemRepository.findByOrderId(orderId);

        // If Dine-In draft and now firing, lock table
        if (order.getStatus() == OrderStatus.DRAFT && order.getOrderType() == OrderType.DINE_IN && order.getTableId() != null) {
            RestaurantTable table = tableRepository.findById(order.getTableId())
                    .orElseThrow(() -> new RuntimeException("Table not found"));
            if (table.getStatus() == TableStatus.OCCUPIED && table.getCurrentOrderId() != null && !table.getCurrentOrderId().equals(orderId)) {
                throw new TableOccupiedException("Table is already occupied");
            }
            table.setStatus(TableStatus.OCCUPIED);
            table.setCurrentOrderId(order.getOrderId());
            tableRepository.save(table);
        }

        boolean hasPending = false;
        StringBuilder courseKot = new StringBuilder("----- COURSE KOT PRINT -----\n");
        courseKot.append("Order ID: ").append(orderId).append("\n");
        courseKot.append("Course: ").append(courseName).append("\n");
        courseKot.append("Items:\n");

        for (OrderItem item : items) {
            if (item.getStatus() == OrderItemStatus.PENDING && item.getCourse() != null && item.getCourse().equalsIgnoreCase(courseName)) {
                hasPending = true;
                deductInventory(item.getMenuItemId(), item.getQuantity());
                item.setStatus(OrderItemStatus.PREPARING);
                orderItemRepository.save(item);

                MenuItem menuItem = menuItemRepository.findById(item.getMenuItemId()).orElse(null);
                String name = menuItem != null ? menuItem.getName() : "Unknown Item";
                courseKot.append(" - ").append(name).append(" x ").append(item.getQuantity());
                if (item.getModifiers() != null && !item.getModifiers().isEmpty()) {
                    courseKot.append(" (").append(item.getModifiers()).append(")");
                }
                courseKot.append("\n");
            }
        }
        courseKot.append("----------------------------");

        if (hasPending) {
            System.out.println(courseKot.toString()); // Print KOT simulation
            order.setStatus(OrderStatus.PREPARING);
            if (order.getKotFiredAt() == null) {
                order.setKotFiredAt(LocalDateTime.now());
            }
            Order savedOrder = orderRepository.save(order);
            try {
                messagingTemplate.convertAndSend("/topic/orders", savedOrder);
            } catch (Exception e) {
            }
            logTimelineEvent(orderId, "KOT_FIRED", "Course KOT fired for " + courseName + ": " + courseKot.toString(), null);
            return savedOrder;
        } else {
            throw new RuntimeException("No pending items found for course: " + courseName);
        }
    }

    private void restoreInventory(UUID menuItemId, int itemQuantity) {
        inventoryService.restoreIngredientsForMenuItem(menuItemId, itemQuantity);
    }

    public void validateManagerPin(String pin) {
        if (pin == null || pin.isEmpty()) {
            throw new ManagerPINRequiredException("Manager PIN is required");
        }
        List<Staff> staffList = staffRepository.findAll();
        boolean pinMatched = false;
        for (Staff staff : staffList) {
            if (staff.getRole() == StaffRole.MANAGER && passwordEncoder.matches(pin, staff.getPinHash())) {
                pinMatched = true;
                break;
            }
        }
        if (!pinMatched) {
            throw new ManagerPINRequiredException("Invalid Manager PIN");
        }
    }
}
