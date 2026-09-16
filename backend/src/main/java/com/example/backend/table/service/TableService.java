package com.example.backend.table.service;

import com.example.backend.order.entity.Order;
import com.example.backend.order.repository.OrderRepository;
import com.example.backend.staff.entity.Staff;
import com.example.backend.staff.entity.StaffRole;
import com.example.backend.staff.repository.StaffRepository;
import com.example.backend.table.entity.RestaurantTable;
import com.example.backend.table.entity.TableStatus;
import com.example.backend.table.entity.WaitlistEntry;
import com.example.backend.table.entity.WaitlistStatus;
import com.example.backend.table.repository.RestaurantTableRepository;
import com.example.backend.table.repository.WaitlistRepository;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class TableService {

    private final RestaurantTableRepository tableRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final OrderRepository orderRepository;
    private final WaitlistRepository waitlistRepository;
    private final StaffRepository staffRepository;

    public TableService(RestaurantTableRepository tableRepository,
                        SimpMessagingTemplate messagingTemplate,
                        OrderRepository orderRepository,
                        WaitlistRepository waitlistRepository,
                        StaffRepository staffRepository) {
        this.tableRepository = tableRepository;
        this.messagingTemplate = messagingTemplate;
        this.orderRepository = orderRepository;
        this.waitlistRepository = waitlistRepository;
        this.staffRepository = staffRepository;
    }

    public List<RestaurantTable> getAllTables() {
        return tableRepository.findAll();
    }

    public List<RestaurantTable> getTablesByOutlet(UUID outletId) {
        return tableRepository.findByOutletId(outletId);
    }

    public List<RestaurantTable> getTablesForStaff(String staffName, UUID outletId) {
        Optional<Staff> staffOpt = staffRepository.findByName(staffName);
        if (staffOpt.isPresent()) {
            Staff staff = staffOpt.get();
            if (staff.getRole() == StaffRole.CAPTAIN && staff.getSection() != null && !staff.getSection().trim().isEmpty()) {
                if (outletId != null) {
                    return tableRepository.findByOutletIdAndSectionIgnoreCase(outletId, staff.getSection().trim());
                } else {
                    return tableRepository.findBySectionIgnoreCase(staff.getSection().trim());
                }
            }
        }
        return outletId != null ? getTablesByOutlet(outletId) : getAllTables();
    }

    public RestaurantTable getTableById(UUID id) {
        return tableRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Table not found"));
    }

    @Transactional
    public RestaurantTable createTable(RestaurantTable table) {
        if (table.getOutletId() == null) {
            table.setOutletId(UUID.randomUUID());
        }
        if (table.getStatus() == null) {
            table.setStatus(TableStatus.AVAILABLE);
        }
        RestaurantTable saved = tableRepository.save(table);
        notifyTableUpdate(saved);
        return saved;
    }

    @Transactional
    public RestaurantTable updateTable(UUID id, RestaurantTable updated) {
        RestaurantTable table = getTableById(id);
        table.setTableNumber(updated.getTableNumber());
        table.setCapacity(updated.getCapacity());
        table.setSection(updated.getSection());
        table.setXPos(updated.getXPos());
        table.setYPos(updated.getYPos());
        if (updated.getOutletId() != null) {
            table.setOutletId(updated.getOutletId());
        }
        if (updated.getStatus() != null) {
            table.setStatus(updated.getStatus());
        }
        RestaurantTable saved = tableRepository.save(table);
        notifyTableUpdate(saved);
        return saved;
    }

    @Transactional
    public void deleteTable(UUID id) {
        tableRepository.deleteById(id);
    }

    @Transactional
    public List<RestaurantTable> bulkUpdateTables(List<RestaurantTable> tables) {
        for (RestaurantTable t : tables) {
            if (t.getTableId() != null) {
                updateTable(t.getTableId(), t);
            } else {
                createTable(t);
            }
        }
        return tableRepository.findAll();
    }

    @Transactional
    public RestaurantTable updateTableStatus(UUID id, TableStatus status) {
        RestaurantTable table = getTableById(id);
        table.setStatus(status);
        if (status == TableStatus.AVAILABLE) {
            table.setCurrentOrderId(null);
        }
        RestaurantTable saved = tableRepository.save(table);
        notifyTableUpdate(saved);

        // Sync with merged tables
        List<RestaurantTable> secondaryTables = tableRepository.findByParentTableId(id);
        for (RestaurantTable st : secondaryTables) {
            st.setStatus(status);
            if (status == TableStatus.AVAILABLE) {
                st.setCurrentOrderId(null);
            }
            tableRepository.save(st);
            notifyTableUpdate(st);
        }

        if (status == TableStatus.AVAILABLE) {
            checkWaitlistAndNotify(saved);
        }
        return saved;
    }

    @Transactional
    public RestaurantTable assignTableOrder(UUID id, UUID orderId) {
        RestaurantTable table = getTableById(id);
        table.setStatus(TableStatus.OCCUPIED);
        table.setCurrentOrderId(orderId);

        // Update the order's seatedAt time if it's not set
        Order order = orderRepository.findById(orderId).orElse(null);
        if (order != null && order.getSeatedAt() == null) {
            order.setSeatedAt(LocalDateTime.now());
            orderRepository.save(order);
        }

        RestaurantTable saved = tableRepository.save(table);
        notifyTableUpdate(saved);

        // Sync order to merged secondary tables
        List<RestaurantTable> secondaryTables = tableRepository.findByParentTableId(id);
        for (RestaurantTable st : secondaryTables) {
            st.setStatus(TableStatus.OCCUPIED);
            st.setCurrentOrderId(orderId);
            tableRepository.save(st);
            notifyTableUpdate(st);
        }

        return saved;
    }

    @Transactional
    public RestaurantTable releaseTable(UUID tableId) {
        RestaurantTable table = getTableById(tableId);
        table.setStatus(TableStatus.AVAILABLE);
        table.setCurrentOrderId(null);
        RestaurantTable saved = tableRepository.save(table);
        notifyTableUpdate(saved);

        // Also release any merged secondary tables!
        List<RestaurantTable> secondaryTables = tableRepository.findByParentTableId(tableId);
        for (RestaurantTable st : secondaryTables) {
            st.setStatus(TableStatus.AVAILABLE);
            st.setCurrentOrderId(null);
            tableRepository.save(st);
            notifyTableUpdate(st);
        }

        checkWaitlistAndNotify(saved);
        return saved;
    }

    @Transactional
    public void mergeTables(UUID primaryTableId, List<UUID> secondaryTableIds) {
        RestaurantTable primaryTable = getTableById(primaryTableId);
        for (UUID sId : secondaryTableIds) {
            RestaurantTable secTable = getTableById(sId);
            if (secTable.getStatus() != TableStatus.AVAILABLE) {
                throw new RuntimeException("Secondary table is not available: " + secTable.getTableNumber());
            }
            secTable.setParentTableId(primaryTableId);
            secTable.setStatus(primaryTable.getStatus());
            secTable.setCurrentOrderId(primaryTable.getCurrentOrderId());
            tableRepository.save(secTable);
            notifyTableUpdate(secTable);
        }
    }

    @Transactional
    public void unmergeTables(UUID primaryTableId) {
        List<RestaurantTable> secondaryTables = tableRepository.findByParentTableId(primaryTableId);
        for (RestaurantTable st : secondaryTables) {
            st.setParentTableId(null);
            st.setStatus(TableStatus.AVAILABLE);
            st.setCurrentOrderId(null);
            tableRepository.save(st);
            notifyTableUpdate(st);
        }
    }

    @Transactional
    public RestaurantTable transferTable(UUID sourceTableId, UUID destinationTableId) {
        RestaurantTable source = getTableById(sourceTableId);
        RestaurantTable dest = getTableById(destinationTableId);

        if (source.getCurrentOrderId() == null) {
            throw new RuntimeException("Source table has no active order");
        }
        if (dest.getStatus() != TableStatus.AVAILABLE) {
            throw new RuntimeException("Destination table is not available");
        }

        UUID orderId = source.getCurrentOrderId();
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new RuntimeException("Order not found"));

        // Update order with new table ID
        order.setTableId(destinationTableId);
        orderRepository.save(order);

        // Setup destination table
        dest.setStatus(TableStatus.OCCUPIED);
        dest.setCurrentOrderId(orderId);
        RestaurantTable savedDest = tableRepository.save(dest);
        notifyTableUpdate(savedDest);

        // Sync destination merged tables
        List<RestaurantTable> destMerged = tableRepository.findByParentTableId(destinationTableId);
        for (RestaurantTable st : destMerged) {
            st.setStatus(TableStatus.OCCUPIED);
            st.setCurrentOrderId(orderId);
            tableRepository.save(st);
            notifyTableUpdate(st);
        }

        // Release source table (and unmerge secondary tables)
        unmergeTables(sourceTableId);
        source.setStatus(TableStatus.AVAILABLE);
        source.setCurrentOrderId(null);
        RestaurantTable savedSource = tableRepository.save(source);
        notifyTableUpdate(savedSource);

        checkWaitlistAndNotify(savedSource);

        return savedDest;
    }

    public void checkWaitlistAndNotify(RestaurantTable table) {
        if (table.getStatus() != TableStatus.AVAILABLE) {
            return;
        }
        List<WaitlistEntry> waitingList = waitlistRepository.findByOutletIdAndStatusOrderByCreatedAtAsc(table.getOutletId(), WaitlistStatus.WAITING);
        if (waitingList.isEmpty()) {
            waitingList = waitlistRepository.findByStatusOrderByCreatedAtAsc(WaitlistStatus.WAITING);
        }
        for (WaitlistEntry entry : waitingList) {
            if (entry.getPartySize() <= table.getCapacity()) {
                entry.setStatus(WaitlistStatus.NOTIFIED);
                entry.setNotifiedAt(LocalDateTime.now());
                waitlistRepository.save(entry);

                String smsText = String.format("Hello %s, table %s (capacity %d) is now available for your party of %d. Please proceed to the host stand.",
                        entry.getGuestName(), table.getTableNumber(), table.getCapacity(), entry.getPartySize());
                sendSms(entry.getGuestPhone(), smsText);
                break;
            }
        }
    }

    public Double getAverageTurnTimeMinutes() {
        List<Order> orders = orderRepository.findAll();
        long totalMinutes = 0;
        long count = 0;
        for (Order order : orders) {
            if (order.getSeatedAt() != null && order.getBilledAt() != null) {
                long minutes = java.time.Duration.between(order.getSeatedAt(), order.getBilledAt()).toMinutes();
                totalMinutes += minutes;
                count++;
            }
        }
        return count == 0 ? 0.0 : (double) totalMinutes / count;
    }

    private void sendSms(String phone, String message) {
        System.out.println("[SMS ALERT] Sent to " + phone + ": " + message);
    }

    private void notifyTableUpdate(RestaurantTable table) {
        try {
            messagingTemplate.convertAndSend("/topic/tables", table);
        } catch (Exception e) {
            // WebSocket might not be active in test environments, ignore.
        }
    }
}
