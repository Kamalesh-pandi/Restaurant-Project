import React, { useState, useEffect, useMemo } from 'react';
import { apiRequest } from '../../services/apiClient';
import { wsService } from '../../services/websocketService';
import { useAuth } from '../../context/AuthContext';
import Sidebar from '../../components/layout/Sidebar';
import Header from '../../components/layout/Header';
import MenuCatalogManager from '../../components/menu/MenuCatalogManager';
import FloorPlanManager from '../../components/floor/FloorPlanManager';
import ChainOutletManager from '../../components/chain/ChainOutletManager';
import KitchenStationManager from '../../components/kitchen/KitchenStationManager';
import ReservationWaitlistManager from '../../components/reservation/ReservationWaitlistManager';
import InventoryStockManager from '../../components/inventory/InventoryStockManager';
import ReportsAnalyticsManager from '../../components/reports/ReportsAnalyticsManager';
import StaffShiftManager from '../../components/staff/StaffShiftManager';
import HotkeyHandler from '../../components/common/HotkeyHandler';
import { 
  BarChart3, 
  Users, 
  ShoppingBag, 
  Grid, 
  TrendingUp, 
  Settings, 
  DollarSign, 
  Clock, 
  Utensils, 
  Plus, 
  Search, 
  Filter, 
  Download, 
  CheckCircle2, 
  XCircle, 
  Edit3, 
  Trash2, 
  Printer, 
  FileText, 
  Lock, 
  Shield, 
  RefreshCw, 
  Eye, 
  ChevronRight, 
  Sliders, 
  Percent, 
  Calendar,
  AlertTriangle,
  Award,
  CreditCard,
  Mail,
  Phone,
  Globe,
  MapPin,
  Building,
  Flame,
  Send,
  QrCode,
  Package,
  Layers,
  Check,
  Radio,
  Zap,
  PieChart
} from 'lucide-react';

export default function AdminDashboard() {
  const { showToast } = useAuth();
  
  // Active sub-view: 'dashboard', 'staff', 'menu', 'floor', 'chain', 'stations', 'reservations', 'inventory', 'reports', 'settings'
  const [activeView, setActiveView] = useState('dashboard');
  const [loading, setLoading] = useState(false);

  // -------------------------------------------------------------
  // 1. DATA STATES
  // -------------------------------------------------------------
  // Dashboard Metrics
  const [dashboardMetrics, setDashboardMetrics] = useState({
    totalRevenue: 0,
    revenueGrowth: '+0%',
    totalOrders: 0,
    ordersGrowth: '+0%',
    activeTables: '0/0',
    activeTablesGrowth: '0%',
    staffOnline: 0,
    monthlySales: 0,
    monthlyGrowth: '+0%',
    pendingOrders: 0,
    pendingGrowth: '0%'
  });

  // Staff & Admin Management State
  const [staffList, setStaffList] = useState([]);
  const [adminList, setAdminList] = useState([]);
  const [staffSearch, setStaffSearch] = useState('');
  const [staffRoleFilter, setStaffRoleFilter] = useState('ALL');
  const [staffStatusFilter, setStaffStatusFilter] = useState('ALL');
  const [showAddStaffModal, setShowAddStaffModal] = useState(false);
  const [showAddAdminModal, setShowAddAdminModal] = useState(false);
  const [newStaff, setNewStaff] = useState({ name: '', email: '', phone: '', role: 'WAITER', pin: '1234' });
  const [newAdmin, setNewAdmin] = useState({ username: '', password: '', name: '', email: '', accessLevel: 'SUPER_ADMIN' });

  // Menu Catalog & QR State
  const [categories, setCategories] = useState([]);
  const [menuItems, setMenuItems] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState('ALL');
  const [menuSearch, setMenuSearch] = useState('');
  const [showAddDishModal, setShowAddDishModal] = useState(false);
  const [showAddCategoryModal, setShowAddCategoryModal] = useState(false);
  const [newDish, setNewDish] = useState({ name: '', categoryId: '', price: '', description: '', isAvailable: true, isSpicy: false });
  const [newCategoryName, setNewCategoryName] = useState('');

  // Floor Plan State
  const [tables, setTables] = useState([]);
  const [selectedFloor, setSelectedFloor] = useState('Ground Floor');
  const [selectedTable, setSelectedTable] = useState(null);
  const [tableActiveOrder, setTableActiveOrder] = useState(null);
  const [showAddTableModal, setShowAddTableModal] = useState(false);
  const [newTable, setNewTable] = useState({ tableNumber: 'T-10', capacity: 4, section: 'Main Hall', seatingType: 'Standard' });

  // Chain & Outlets State
  const [outlets, setOutlets] = useState([]);
  const [showAddOutletModal, setShowAddOutletModal] = useState(false);
  const [newOutlet, setNewOutlet] = useState({ name: '', outletCode: 'OUT-01', city: '', address: '', phone: '' });

  // Analytics & Sales Trends State
  const [dailySalesSummary, setDailySalesSummary] = useState(null);
  const [salesTimeframe, setSalesTimeframe] = useState('today'); // 'today' | '7d' | '30d'
  const [salesMetric, setSalesMetric] = useState('revenue'); // 'revenue' | 'orders'
  const [hoveredPoint, setHoveredPoint] = useState(null);
  const [orderStatusFilter, setOrderStatusFilter] = useState('ALL'); // 'ALL' | 'NEW' | 'PREPARING' | 'READY' | 'COMPLETED' | 'CANCELLED'

  // Kitchen Stations State
  const [kitchenStations, setKitchenStations] = useState([]);
  const [showAddStationModal, setShowAddStationModal] = useState(false);
  const [newStationName, setNewStationName] = useState('');

  // Reservations & Waitlist State
  const [reservations, setReservations] = useState([]);
  const [waitlist, setWaitlist] = useState([]);
  const [showAddReservationModal, setShowAddReservationModal] = useState(false);
  const [newReservation, setNewReservation] = useState({ customerName: '', customerPhone: '', partySize: 2, reservationTime: '', tableNumber: 'T1' });

  // Inventory & Stock State
  const [inventoryItems, setInventoryItems] = useState([]);
  const [inventoryAlerts, setInventoryAlerts] = useState([]);
  const [showAddGrnModal, setShowAddGrnModal] = useState(false);
  const [grnForm, setGrnForm] = useState({ ingredientId: '', quantityReceived: '', costPrice: '' });

  // Reports & Settings State
  const [ordersList, setOrdersList] = useState([]);
  const [billsList, setBillsList] = useState([]);
  const [reportTemplate, setReportTemplate] = useState('Daily Sales Summary');
  const [dateRange, setDateRange] = useState('Oct 20, 2026 - Oct 27, 2026');
  const [settingsTab, setSettingsTab] = useState('general');
  const [restaurantProfile, setRestaurantProfile] = useState({
    name: 'Spice Haven',
    email: 'admin@spicehaven.com',
    address: '42nd Culinary Avenue, Food District, Manhattan, NY',
    phone: '+1 (555) 123-4567',
    website: 'https://spicehaven.com'
  });

  // -------------------------------------------------------------
  // 2. INITIAL DATA FETCH & WEBSOCKET SUBSCRIPTIONS
  // -------------------------------------------------------------
  useEffect(() => {
    fetchInitialData();

    const unsubscribeTables = wsService.subscribe('/topic/tables', (updatedTable) => {
      setTables((prev) => prev.map((t) => ((t.tableId || t.id) === (updatedTable.tableId || updatedTable.id) ? updatedTable : t)));
      if (selectedTable && (selectedTable.tableId || selectedTable.id) === (updatedTable.tableId || updatedTable.id)) setSelectedTable(updatedTable);
      fetchAnalytics();
    });

    const unsubscribeOrders = wsService.subscribe('/topic/orders', () => {
      fetchTables();
      fetchAnalytics();
      if (selectedTable) fetchOrderForTable(selectedTable.tableId || selectedTable.id);
    });

    return () => {
      unsubscribeTables();
      unsubscribeOrders();
    };
  }, []);

  const fetchInitialData = async () => {
    setLoading(true);
    try {
      await Promise.all([
        fetchStaff(),
        fetchAdmins(),
        fetchCategories(),
        fetchMenuItems(),
        fetchTables(),
        fetchOutlets(),
        fetchKitchenStations(),
        fetchReservations(),
        fetchWaitlist(),
        fetchInventory(),
        fetchAnalytics()
      ]);
    } catch (err) {
      console.error('Failed to fetch initial admin data:', err);
    } finally {
      setLoading(false);
    }
  };

  const fetchAnalytics = async () => {
    try {
      const [billsData, ordersData, tablesData, staffData, salesSummaryData] = await Promise.all([
        apiRequest('/api/v1/bills').catch(() => []),
        apiRequest('/api/v1/orders').catch(() => []),
        apiRequest('/api/v1/tables').catch(() => []),
        apiRequest('/api/staff').catch(() => []),
        apiRequest('/api/v1/analytics/daily-sales').catch(() => null),
      ]);

      const bills = Array.isArray(billsData) ? billsData : [];
      const orders = Array.isArray(ordersData) ? ordersData : [];
      const tbls = Array.isArray(tablesData) ? tablesData : [];
      const stff = Array.isArray(staffData) ? staffData : [];

      setOrdersList(orders);
      setBillsList(bills);
      if (salesSummaryData) setDailySalesSummary(salesSummaryData);

      const calculatedRev = bills.filter(b => b.isSettled || b.settled).reduce((acc, b) => acc + (Number(b.total) || 0), 0);
      const totalRev = calculatedRev || (salesSummaryData?.gmv ? Number(salesSummaryData.gmv) : 0);
      const pendingOrds = orders.filter(o => o.status === 'NEW' || o.status === 'PREPARING' || o.status === 'READY').length;
      const occupiedTbls = tbls.filter(t => t.status === 'OCCUPIED').length;

      setDashboardMetrics({
        totalRevenue: totalRev,
        revenueGrowth: '+12.5%',
        totalOrders: orders.length || (salesSummaryData?.totalCovers || 0),
        ordersGrowth: '+5.2%',
        activeTables: `${occupiedTbls}/${tbls.length || 0}`,
        activeTablesGrowth: '0%',
        staffOnline: stff.filter(s => s.active !== false).length,
        monthlySales: totalRev,
        monthlyGrowth: '+18.7%',
        pendingOrders: pendingOrds,
        pendingGrowth: '0%'
      });
    } catch (err) {
      console.error('Error fetching analytics:', err);
    }
  };

  const fetchStaff = async () => {
    try {
      const data = await apiRequest('/api/staff');
      if (Array.isArray(data)) setStaffList(data);
    } catch (err) {
      console.error('Error fetching staff:', err);
    }
  };

  const fetchAdmins = async () => {
    try {
      const data = await apiRequest('/api/v1/admin');
      if (Array.isArray(data)) setAdminList(data);
    } catch (err) {
      console.error('Error fetching admins:', err);
    }
  };

  const fetchCategories = async () => {
    try {
      const data = await apiRequest('/api/v1/menu/categories');
      if (Array.isArray(data)) setCategories(data);
    } catch (err) {
      console.error('Error fetching categories:', err);
    }
  };

  const fetchMenuItems = async () => {
    try {
      const data = await apiRequest('/api/v1/menu/items');
      if (Array.isArray(data)) setMenuItems(data);
    } catch (err) {
      console.error('Error fetching menu items:', err);
    }
  };

  const fetchTables = async () => {
    try {
      const data = await apiRequest('/api/v1/tables');
      if (Array.isArray(data)) setTables(data);
    } catch (err) {
      console.error('Error fetching tables:', err);
    }
  };

  const fetchOutlets = async () => {
    try {
      const data = await apiRequest('/api/v1/chain/outlets');
      if (Array.isArray(data)) setOutlets(data);
    } catch (err) {
      console.error('Error fetching outlets:', err);
    }
  };

  const fetchKitchenStations = async () => {
    try {
      const data = await apiRequest('/api/v1/kitchen-stations');
      if (Array.isArray(data)) setKitchenStations(data);
    } catch (err) {
      console.error('Error fetching kitchen stations:', err);
    }
  };

  const fetchReservations = async () => {
    try {
      const data = await apiRequest('/api/v1/reservations');
      if (Array.isArray(data)) setReservations(data);
    } catch (err) {
      console.error('Error fetching reservations:', err);
    }
  };

  const fetchWaitlist = async () => {
    try {
      const data = await apiRequest('/api/v1/waitlist');
      if (Array.isArray(data)) setWaitlist(data);
    } catch (err) {
      console.error('Error fetching waitlist:', err);
    }
  };

  const fetchInventory = async () => {
    try {
      const [items, alerts] = await Promise.all([
        apiRequest('/api/v1/inventory').catch(() => []),
        apiRequest('/api/v1/inventory/alerts').catch(() => [])
      ]);
      if (Array.isArray(items)) setInventoryItems(items);
      if (Array.isArray(alerts)) setInventoryAlerts(alerts);
    } catch (err) {
      console.error('Error fetching inventory:', err);
    }
  };

  const fetchOrderForTable = async (tableId) => {
    try {
      const orders = await apiRequest('/api/v1/orders');
      const found = orders.find((o) => o.tableId === tableId && (o.status === 'PREPARING' || o.status === 'NEW' || o.status === 'READY'));
      setTableActiveOrder(found || null);
    } catch (err) {
      console.error('Error fetching table order:', err);
    }
  };

  // -------------------------------------------------------------
  // 3. ACTION HANDLERS
  // -------------------------------------------------------------
  // Staff & Admin
  const handleAddStaffSubmit = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/staff', 'POST', {
        name: newStaff.name,
        email: newStaff.email,
        phoneNumber: newStaff.phone,
        role: newStaff.role,
        pin: newStaff.pin
      });
      showToast(`New Staff member ${newStaff.name} created! Secret PIN sent to ${newStaff.email}`, 'success');
      setShowAddStaffModal(false);
      setNewStaff({ name: '', email: '', phone: '', role: 'WAITER', pin: '1234' });
      fetchStaff();
    } catch (err) {
      showToast(err.message || 'Failed to add staff member', 'error');
    }
  };

  const handleAddAdminSubmit = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/v1/admin', 'POST', {
        username: newAdmin.username,
        password: newAdmin.password,
        name: newAdmin.name,
        email: newAdmin.email,
        adminAccessLevel: newAdmin.accessLevel
      });
      showToast(`New Admin account ${newAdmin.name} created!`, 'success');
      setShowAddAdminModal(false);
      setNewAdmin({ username: '', password: '', name: '', email: '', accessLevel: 'SUPER_ADMIN' });
      fetchAdmins();
    } catch (err) {
      showToast(err.message || 'Failed to create admin account', 'error');
    }
  };

  const handleToggleStaffActive = async (id) => {
    try {
      await apiRequest(`/api/staff/${id}/toggle-active`, 'PATCH');
      showToast('Staff status updated', 'success');
      fetchStaff();
    } catch (err) {
      showToast(err.message || 'Action failed', 'error');
    }
  };

  const handleToggleAdminActive = async (id) => {
    if (!id) {
      showToast('Admin ID is missing', 'error');
      return;
    }
    try {
      await apiRequest(`/api/v1/admin/${id}/toggle-active`, 'PATCH');
      showToast('Admin account status updated successfully!', 'success');
      fetchAdmins();
    } catch (err) {
      console.error('Toggle admin active error:', err);
      showToast(err.message || 'Action failed', 'error');
    }
  };

  const [showEditStaffModal, setShowEditStaffModal] = useState(false);
  const [editStaff, setEditStaff] = useState({ staffId: '', name: '', email: '', phone: '', role: 'WAITER', pin: '' });

  const handleEditStaffClick = (staffMember) => {
    setEditStaff({
      staffId: staffMember.staffId || staffMember.id,
      name: staffMember.name || staffMember.staffName || '',
      email: staffMember.email || '',
      phone: staffMember.phoneNumber || staffMember.phone || '',
      role: staffMember.role || staffMember.staffRole || 'WAITER',
      pin: ''
    });
    setShowEditStaffModal(true);
  };

  const handleEditStaffSubmit = async (e) => {
    e.preventDefault();
    try {
      await apiRequest(`/api/staff/${editStaff.staffId}`, 'PUT', {
        name: editStaff.name,
        email: editStaff.email,
        phoneNumber: editStaff.phone,
        role: editStaff.role,
        pin: editStaff.pin || '1234'
      });
      showToast(`Staff member ${editStaff.name} updated! PIN email sent.`, 'success');
      setShowEditStaffModal(false);
      fetchStaff();
    } catch (err) {
      showToast(err.message || 'Failed to update staff member', 'error');
    }
  };

  const handleDeleteAdmin = async (id) => {
    if (!window.confirm('Are you sure you want to delete this System Admin account?')) return;
    try {
      await apiRequest(`/api/v1/admin/${id}`, 'DELETE');
      showToast('System Admin deleted', 'info');
      fetchAdmins();
    } catch (err) {
      showToast(err.message || 'Delete failed', 'error');
    }
  };

  const handleDeleteStaff = async (id) => {
    if (!window.confirm('Are you sure you want to delete this staff member?')) return;
    try {
      await apiRequest(`/api/staff/${id}`, 'DELETE');
      showToast('Staff member deleted', 'info');
      fetchStaff();
    } catch (err) {
      showToast(err.message || 'Delete failed', 'error');
    }
  };

  const handleExportPayroll = async () => {
    try {
      const csvData = await apiRequest('/api/staff/payroll/export');
      const csvString = typeof csvData === 'string' ? csvData : JSON.stringify(csvData);
      const blob = new Blob([csvString], { type: 'text/csv;charset=utf-8;' });
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.style.display = 'none';
      link.href = url;
      link.setAttribute('download', `payroll_report_${new Date().toISOString().slice(0, 10)}.csv`);
      document.body.appendChild(link);
      link.click();
      setTimeout(() => {
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
      }, 100);
      showToast('Payroll CSV exported successfully!', 'success');
    } catch (err) {
      console.error('Payroll CSV export error:', err);
      showToast(err.message || 'Export failed', 'error');
    }
  };

  // Menu Catalog & QR
  const handleAddDishSubmit = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/v1/menu/items', 'POST', {
        name: newDish.name,
        categoryId: newDish.categoryId || (categories[0] ? categories[0].id : null),
        price: parseFloat(newDish.price) || 10.0,
        description: newDish.description,
        isAvailable: newDish.isAvailable
      });
      showToast(`New dish ${newDish.name} created!`, 'success');
      setShowAddDishModal(false);
      setNewDish({ name: '', categoryId: '', price: '', description: '', isAvailable: true, isSpicy: false });
      fetchMenuItems();
    } catch (err) {
      showToast(err.message || 'Failed to create menu item', 'error');
    }
  };

  const handleToggleDishAvailability = async (itemId) => {
    try {
      await apiRequest(`/api/v1/menu/items/${itemId}/toggle-availability`, 'PATCH');
      showToast('Item availability toggled', 'success');
      fetchMenuItems();
    } catch (err) {
      showToast(err.message || 'Toggle failed', 'error');
    }
  };

  const handleAddCategorySubmit = async (e) => {
    e.preventDefault();
    if (!newCategoryName) return;
    try {
      await apiRequest('/api/v1/menu/categories', 'POST', { name: newCategoryName });
      showToast(`Category '${newCategoryName}' created!`, 'success');
      setShowAddCategoryModal(false);
      setNewCategoryName('');
      fetchCategories();
    } catch (err) {
      showToast(err.message || 'Failed to create category', 'error');
    }
  };


  // Chain & Outlets
  const handleCreateOutletSubmit = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/v1/chain/outlets', 'POST', {
        name: newOutlet.name,
        outletCode: newOutlet.outletCode,
        city: newOutlet.city,
        address: newOutlet.address,
        phoneNumber: newOutlet.phone
      });
      showToast(`New outlet '${newOutlet.name}' created!`, 'success');
      setShowAddOutletModal(false);
      setNewOutlet({ name: '', outletCode: 'OUT-01', city: '', address: '', phone: '' });
      fetchOutlets();
    } catch (err) {
      showToast(err.message || 'Failed to create outlet', 'error');
    }
  };


  // Kitchen Stations
  const handleCreateStationSubmit = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/v1/kitchen-stations', 'POST', { name: newStationName });
      showToast(`Kitchen station '${newStationName}' created!`, 'success');
      setShowAddStationModal(false);
      setNewStationName('');
      fetchKitchenStations();
    } catch (err) {
      showToast(err.message || 'Failed to create station', 'error');
    }
  };

  const handleDeleteStation = async (id) => {
    if (!window.confirm('Delete this kitchen station?')) return;
    try {
      await apiRequest(`/api/v1/kitchen-stations/${id}`, 'DELETE');
      showToast('Station deleted', 'info');
      fetchKitchenStations();
    } catch (err) {
      showToast(err.message || 'Delete failed', 'error');
    }
  };

  // Reservations
  const handleCreateReservationSubmit = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/v1/reservations', 'POST', {
        guestName: newReservation.customerName,
        phoneNumber: newReservation.customerPhone,
        partySize: parseInt(newReservation.partySize) || 2,
        reservationTime: newReservation.reservationTime || new Date().toISOString(),
        tableNumber: newReservation.tableNumber
      });
      showToast(`Reservation for ${newReservation.customerName} created!`, 'success');
      setShowAddReservationModal(false);
      setNewReservation({ customerName: '', customerPhone: '', partySize: 2, reservationTime: '', tableNumber: 'T1' });
      fetchReservations();
    } catch (err) {
      showToast(err.message || 'Failed to create reservation', 'error');
    }
  };

  const handleUpdateReservationStatus = async (id, status) => {
    try {
      await apiRequest(`/api/v1/reservations/${id}/status?status=${status}`, 'PUT');
      showToast(`Reservation status updated to ${status}!`, 'success');
      fetchReservations();
    } catch (err) {
      showToast(err.message || 'Failed to update status', 'error');
    }
  };

  // Inventory
  const handleRecordGRN = async (e) => {
    e.preventDefault();
    try {
      await apiRequest(`/api/v1/inventory/grn?ingredientId=${grnForm.ingredientId}&quantityReceived=${grnForm.quantityReceived}&costPrice=${grnForm.costPrice}`, 'POST');
      showToast('GRN Stock Received recorded!', 'success');
      setShowAddGrnModal(false);
      setGrnForm({ ingredientId: '', quantityReceived: '', costPrice: '' });
      fetchInventory();
    } catch (err) {
      showToast(err.message || 'Failed to record GRN', 'error');
    }
  };

  // Floor Plan
  const handleSelectTableOnMap = (tbl) => {
    setSelectedTable(tbl);
    fetchOrderForTable(tbl.id);
  };

  const handleAddTableSubmit = async (e) => {
    e.preventDefault();
    try {
      await apiRequest('/api/v1/tables', 'POST', {
        tableNumber: newTable.tableNumber,
        capacity: parseInt(newTable.capacity) || 4,
        section: newTable.section,
        seatingType: newTable.seatingType,
        status: 'AVAILABLE'
      });
      showToast(`Table ${newTable.tableNumber} added!`, 'success');
      setShowAddTableModal(false);
      fetchTables();
    } catch (err) {
      showToast(err.message || 'Failed to add table', 'error');
    }
  };

  const handleSaveSettings = (e) => {
    e.preventDefault();
    showToast('Restaurant settings saved successfully!', 'success');
  };

  // Filtered lists
  const filteredStaff = staffList.filter((s) => {
    const nameMatch = (s.staffName || s.name || '').toLowerCase().includes(staffSearch.toLowerCase()) ||
                      (s.email || '').toLowerCase().includes(staffSearch.toLowerCase());
    const roleMatch = staffRoleFilter === 'ALL' || (s.staffRole || s.role) === staffRoleFilter;
    const statusMatch = staffStatusFilter === 'ALL' || (staffStatusFilter === 'ACTIVE' ? s.active !== false : s.active === false);
    return nameMatch && roleMatch && statusMatch;
  });

  const filteredMenuItems = menuItems.filter((i) => {
    const catMatch = selectedCategory === 'ALL' || i.categoryId === selectedCategory || i.categoryName === selectedCategory;
    const nameMatch = (i.name || '').toLowerCase().includes(menuSearch.toLowerCase());
    return catMatch && nameMatch;
  });

  // -------------------------------------------------------------
  // ANALYTICS & TRENDS COMPUTATIONS
  // -------------------------------------------------------------
  const trendData = useMemo(() => {
    if (salesTimeframe === 'today') {
      const hours = [8, 10, 12, 14, 16, 18, 20, 22];
      return hours.map((hour) => {
        const hourLabel = `${hour % 12 === 0 ? 12 : hour % 12}${hour >= 12 ? 'pm' : 'am'}`;
        const nextHour = hour + 2;

        let rev = 0;
        let ordCount = 0;

        if (dailySalesSummary?.hourlyRevenueTrend) {
          rev += Number(dailySalesSummary.hourlyRevenueTrend[hour] || 0);
          rev += Number(dailySalesSummary.hourlyRevenueTrend[hour + 1] || 0);
        }

        billsList.forEach((bill) => {
          if (bill.createdAt) {
            const bHour = new Date(bill.createdAt).getHours();
            if (bHour >= hour && bHour < nextHour) {
              if (!dailySalesSummary?.hourlyRevenueTrend) {
                rev += Number(bill.total || 0);
              }
            }
          }
        });

        ordersList.forEach((ord) => {
          const timestamp = ord.billedAt || ord.kotFiredAt || ord.createdAt;
          if (timestamp) {
            const oHour = new Date(timestamp).getHours();
            if (oHour >= hour && oHour < nextHour) {
              ordCount++;
            }
          }
        });

        return {
          label: hourLabel,
          subLabel: `${hour}:00 - ${nextHour}:00`,
          revenue: Math.round(rev),
          orders: ordCount,
          value: salesMetric === 'revenue' ? Math.round(rev) : ordCount,
        };
      });
    } else if (salesTimeframe === '7d') {
      const days = [];
      const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      for (let i = 6; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const dateStr = d.toISOString().substring(0, 10);
        const dayLabel = i === 0 ? 'Today' : dayNames[d.getDay()];

        let rev = 0;
        let ordCount = 0;

        billsList.forEach((b) => {
          if (b.createdAt && b.createdAt.substring(0, 10) === dateStr) {
            rev += Number(b.total || 0);
          }
        });

        ordersList.forEach((o) => {
          const t = o.billedAt || o.kotFiredAt || o.createdAt;
          if (t && t.substring(0, 10) === dateStr) {
            ordCount++;
          }
        });

        if (i === 0 && rev === 0 && dailySalesSummary?.gmv) {
          rev = Number(dailySalesSummary.gmv);
          if (ordCount === 0) ordCount = ordersList.length;
        }

        days.push({
          label: dayLabel,
          subLabel: dateStr,
          revenue: Math.round(rev),
          orders: ordCount,
          value: salesMetric === 'revenue' ? Math.round(rev) : ordCount,
        });
      }
      return days;
    } else {
      // 30 Days: 6 5-day intervals
      const periods = [];
      for (let i = 5; i >= 0; i--) {
        const dEnd = new Date();
        dEnd.setDate(dEnd.getDate() - i * 5);
        const dStart = new Date();
        dStart.setDate(dStart.getDate() - (i + 1) * 5 + 1);

        const startStr = dStart.toISOString().substring(0, 10);
        const endStr = dEnd.toISOString().substring(0, 10);
        const label = `${dStart.getDate()} ${dStart.toLocaleString('default', { month: 'short' })}`;

        let rev = 0;
        let ordCount = 0;

        billsList.forEach((b) => {
          if (b.createdAt) {
            const bDate = b.createdAt.substring(0, 10);
            if (bDate >= startStr && bDate <= endStr) {
              rev += Number(b.total || 0);
            }
          }
        });

        ordersList.forEach((o) => {
          const t = o.billedAt || o.kotFiredAt || o.createdAt;
          if (t) {
            const oDate = t.substring(0, 10);
            if (oDate >= startStr && oDate <= endStr) {
              ordCount++;
            }
          }
        });

        if (i === 0 && rev === 0 && dailySalesSummary?.gmv) {
          rev = Number(dailySalesSummary.gmv);
          if (ordCount === 0) ordCount = ordersList.length;
        }

        periods.push({
          label,
          subLabel: `${startStr} to ${endStr}`,
          revenue: Math.round(rev),
          orders: ordCount,
          value: salesMetric === 'revenue' ? Math.round(rev) : ordCount,
        });
      }
      return periods;
    }
  }, [salesTimeframe, salesMetric, billsList, ordersList, dailySalesSummary]);

  // Chart Coordinates & Path Calculations
  const chartCoordinates = useMemo(() => {
    const chartW = 515;
    const chartH = 135;
    const originX = 55;
    const originY = 25;

    const values = trendData.map((d) => d.value);
    const maxVal = Math.max(...values, salesMetric === 'revenue' ? 500 : 5);
    const niceCeil = salesMetric === 'revenue' 
      ? Math.ceil(maxVal / 500) * 500 
      : Math.ceil(maxVal / 5) * 5;

    const peakIndex = values.indexOf(Math.max(...values));

    const points = trendData.map((d, i) => {
      const x = originX + (i / Math.max(trendData.length - 1, 1)) * chartW;
      const y = originY + chartH - (d.value / niceCeil) * chartH;
      return {
        ...d,
        x,
        y,
        isPeak: i === peakIndex && d.value > 0,
      };
    });

    let linePath = '';
    if (points.length > 0) {
      linePath = `M ${points[0].x},${points[0].y}`;
      for (let i = 0; i < points.length - 1; i++) {
        const p0 = points[i];
        const p1 = points[i + 1];
        const cpX = (p0.x + p1.x) / 2;
        linePath += ` C ${cpX},${p0.y} ${cpX},${p1.y} ${p1.x},${p1.y}`;
      }
    }

    const areaPath = points.length > 0
      ? `${linePath} L ${points[points.length - 1].x},${originY + chartH} L ${points[0].x},${originY + chartH} Z`
      : '';

    const yGridLines = [
      { y: originY, label: niceCeil.toLocaleString() },
      { y: originY + chartH * 0.33, label: Math.round(niceCeil * 0.67).toLocaleString() },
      { y: originY + chartH * 0.67, label: Math.round(niceCeil * 0.33).toLocaleString() },
      { y: originY + chartH, label: '0' },
    ];

    return { points, linePath, areaPath, yGridLines, maxVal: niceCeil };
  }, [trendData, salesMetric]);

  // Period Summary Metrics
  const periodSummary = useMemo(() => {
    const gmv = trendData.reduce((acc, cur) => acc + cur.revenue, 0) || (dailySalesSummary?.gmv ? Number(dailySalesSummary.gmv) : 0);
    const totalOrders = trendData.reduce((acc, cur) => acc + cur.orders, 0) || ordersList.length;
    const aov = totalOrders > 0 ? Math.round(gmv / totalOrders) : 0;
    
    let peakLabel = 'None';
    let peakVal = -1;
    trendData.forEach((d) => {
      if (d.value > peakVal && d.value > 0) {
        peakVal = d.value;
        peakLabel = `${d.label} (${salesMetric === 'revenue' ? '₹' + d.revenue.toLocaleString() : d.orders + ' ords'})`;
      }
    });

    return { gmv, totalOrders, aov, peakLabel };
  }, [trendData, ordersList, dailySalesSummary, salesMetric]);

  // Order Status Counts & Kitchen Efficiency
  const statusCounts = useMemo(() => {
    const total = ordersList.length;
    const newCount = ordersList.filter((o) => o.status === 'NEW').length;
    const prepCount = ordersList.filter((o) => o.status === 'PREPARING' || o.status === 'ASSIGNED').length;
    const readyCount = ordersList.filter((o) => o.status === 'READY').length;
    const completedCount = ordersList.filter((o) => o.status === 'SERVED' || o.status === 'DELIVERED' || o.status === 'PAID' || o.status === 'BILLED').length;
    const cancelledCount = ordersList.filter((o) => o.status === 'CANCELLED').length;

    const efficiency = total > 0 ? Math.round(((completedCount + readyCount) / total) * 100) : 100;

    return {
      total,
      new: newCount,
      prep: prepCount,
      ready: readyCount,
      completed: completedCount,
      cancelled: cancelledCount,
      efficiency,
    };
  }, [ordersList]);

  // Donut SVG Segments
  const donutSegments = useMemo(() => {
    if (statusCounts.total === 0) return [];
    const segments = [
      { key: 'READY', count: statusCounts.ready, color: '#10b981', label: 'Ready' },
      { key: 'PREPARING', count: statusCounts.prep, color: '#f59e0b', label: 'In Kitchen' },
      { key: 'NEW', count: statusCounts.new, color: '#0ea5e9', label: 'New' },
      { key: 'COMPLETED', count: statusCounts.completed, color: '#8b5cf6', label: 'Completed' },
      { key: 'CANCELLED', count: statusCounts.cancelled, color: '#ef4444', label: 'Cancelled' },
    ].filter((s) => s.count > 0);

    let cumulativePct = 0;
    return segments.map((seg) => {
      const pct = (seg.count / statusCounts.total) * 100;
      const offset = cumulativePct;
      cumulativePct += pct;
      return {
        ...seg,
        pct: Math.round(pct),
        strokeDasharray: `${pct} ${100 - pct}`,
        strokeDashoffset: -offset,
      };
    });
  }, [statusCounts]);

  // Filtered Orders for Table Feed
  const filteredOrders = useMemo(() => {
    return ordersList.filter((ord) => {
      if (orderStatusFilter === 'ALL') return true;
      if (orderStatusFilter === 'NEW') return ord.status === 'NEW';
      if (orderStatusFilter === 'PREPARING') return ord.status === 'PREPARING' || ord.status === 'ASSIGNED';
      if (orderStatusFilter === 'READY') return ord.status === 'READY';
      if (orderStatusFilter === 'COMPLETED') return ord.status === 'SERVED' || ord.status === 'DELIVERED' || ord.status === 'PAID' || ord.status === 'BILLED';
      if (orderStatusFilter === 'CANCELLED') return ord.status === 'CANCELLED';
      return true;
    });
  }, [ordersList, orderStatusFilter]);

  return (
    <div className="d-flex min-vh-100 bg-primary-custom">
      {/* Sidebar Navigation */}
      <Sidebar activeView={activeView} setActiveView={setActiveView} roleLogo="Spice Haven" />

      <div className="flex-grow-1 d-flex flex-column overflow-hidden">
        <Header title={
          activeView === 'dashboard' ? 'System Overview' :
          activeView === 'staff' ? 'Staff & Admin Accounts' :
          activeView === 'menu' ? 'Menu Catalog & Digital QR' :
          activeView === 'floor' ? 'Floor Plan Canvas' :
          activeView === 'chain' ? 'Chain & Multi-Outlet Management' :
          activeView === 'stations' ? 'Kitchen Stations' :
          activeView === 'reservations' ? 'Reservations & Waitlist' :
          activeView === 'inventory' ? 'Inventory & Stock Control' :
          activeView === 'reports' ? 'Reports & Analytics' : 'Settings'
        } />
        <HotkeyHandler />

        <div className="flex-grow-1 p-4 overflow-auto">
          {/* ========================================================= */}
          {/* 1. SYSTEM OVERVIEW / DASHBOARD                             */}
          {/* ========================================================= */}
          {activeView === 'dashboard' && (
            <div className="row g-4">
              {/* TOP 6 KPI METRICS */}
              <div className="col-12 col-sm-6 col-lg-2">
                <div className="card bg-surface border-custom shadow-sm p-3">
                  <div className="d-flex align-items-center justify-content-between mb-1">
                    <div className="p-2 rounded-2 bg-blue-light text-blue"><DollarSign size={18} /></div>
                    <span className="text-success small fw-bold">{dashboardMetrics.revenueGrowth}</span>
                  </div>
                  <span className="text-muted-custom small fw-semibold d-block">Total Revenue</span>
                  <h4 className="fw-extrabold text-main m-0">₹{dashboardMetrics.totalRevenue.toLocaleString()}</h4>
                </div>
              </div>

              <div className="col-12 col-sm-6 col-lg-2">
                <div className="card bg-surface border-custom shadow-sm p-3">
                  <div className="d-flex align-items-center justify-content-between mb-1">
                    <div className="p-2 rounded-2 bg-blue-light text-blue"><ShoppingBag size={18} /></div>
                    <span className="text-success small fw-bold">{dashboardMetrics.ordersGrowth}</span>
                  </div>
                  <span className="text-muted-custom small fw-semibold d-block">Total Orders</span>
                  <h4 className="fw-extrabold text-main m-0">{dashboardMetrics.totalOrders}</h4>
                </div>
              </div>

              <div className="col-12 col-sm-6 col-lg-2">
                <div className="card bg-surface border-custom shadow-sm p-3">
                  <div className="d-flex align-items-center justify-content-between mb-1">
                    <div className="p-2 rounded-2 bg-blue-light text-blue"><Utensils size={18} /></div>
                    <span className="text-danger small fw-bold">{dashboardMetrics.activeTablesGrowth}</span>
                  </div>
                  <span className="text-muted-custom small fw-semibold d-block">Active Tables</span>
                  <h4 className="fw-extrabold text-main m-0">{dashboardMetrics.activeTables}</h4>
                </div>
              </div>

              <div className="col-12 col-sm-6 col-lg-2">
                <div className="card bg-surface border-custom shadow-sm p-3">
                  <div className="d-flex align-items-center justify-content-between mb-1">
                    <div className="p-2 rounded-2 bg-blue-light text-blue"><Users size={18} /></div>
                    <span className="text-muted-custom small fw-bold">0%</span>
                  </div>
                  <span className="text-muted-custom small fw-semibold d-block">Staff Online</span>
                  <h4 className="fw-extrabold text-main m-0">{dashboardMetrics.staffOnline}</h4>
                </div>
              </div>

              <div className="col-12 col-sm-6 col-lg-2">
                <div className="card bg-surface border-custom shadow-sm p-3">
                  <div className="d-flex align-items-center justify-content-between mb-1">
                    <div className="p-2 rounded-2 bg-blue-light text-blue"><TrendingUp size={18} /></div>
                    <span className="text-success small fw-bold">{dashboardMetrics.monthlyGrowth}</span>
                  </div>
                  <span className="text-muted-custom small fw-semibold d-block">Monthly Sales</span>
                  <h4 className="fw-extrabold text-main m-0">₹{(dashboardMetrics.monthlySales / 1000).toFixed(1)}k</h4>
                </div>
              </div>

              <div className="col-12 col-sm-6 col-lg-2">
                <div className="card bg-surface border-custom shadow-sm p-3">
                  <div className="d-flex align-items-center justify-content-between mb-1">
                    <div className="p-2 rounded-2 bg-blue-light text-blue"><Clock size={18} /></div>
                    <span className="text-success small fw-bold">{dashboardMetrics.pendingGrowth}</span>
                  </div>
                  <span className="text-muted-custom small fw-semibold d-block">Pending Orders</span>
                  <h4 className="fw-extrabold text-main m-0">{dashboardMetrics.pendingOrders}</h4>
                </div>
              </div>

              {/* QUICK ADMIN ACTIONS TOOLBAR */}
              <div className="col-12">
                <div className="card bg-surface border-custom shadow-sm p-3">
                  <div className="d-flex align-items-center justify-content-between mb-2">
                    <div className="d-flex align-items-center gap-2">
                      <Zap size={16} className="text-primary" />
                      <h6 className="fw-bold text-main m-0 style-heading">QUICK SYSTEM ACTIONS</h6>
                    </div>
                    <span className="badge bg-card-custom border border-custom text-muted-custom small">Operational Shortcuts</span>
                  </div>
                  <div className="d-flex flex-wrap gap-2">
                    <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setShowAddDishModal(true)}>
                      <Plus size={14} className="me-1" /> Add Dish
                    </button>
                    <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setShowAddTableModal(true)}>
                      <Grid size={14} className="me-1" /> Add Table
                    </button>
                    <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setShowAddReservationModal(true)}>
                      <Calendar size={14} className="me-1" /> New Reservation
                    </button>
                    <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setShowAddGrnModal(true)}>
                      <Package size={14} className="me-1" /> Stock GRN Entry
                    </button>
                    <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setShowAddAdminModal(true)}>
                      <Shield size={14} className="me-1" /> Add System Admin
                    </button>
                    <button className="btn btn-sm btn-outline-blue touch-btn" onClick={() => setShowAddStationModal(true)}>
                      <Flame size={14} className="me-1" /> Add Kitchen Station
                    </button>
                    <button className="btn btn-sm btn-outline-secondary border-custom text-main touch-btn" onClick={fetchAnalytics}>
                      <RefreshCw size={13} className="me-1" /> Refresh Metrics
                    </button>
                  </div>
                </div>
              </div>

              {/* DAILY SALES TRENDS */}
              <div className="col-12 col-lg-8">
                <div className="card bg-surface border-custom shadow-sm p-3 h-100">
                  {/* Top Bar with Title, Timeframe & Metric Switchers */}
                  <div className="d-flex flex-wrap justify-content-between align-items-center gap-2 mb-3">
                    <div>
                      <div className="d-flex align-items-center gap-2">
                        <TrendingUp size={18} className="text-primary" />
                        <h6 className="fw-bold text-main m-0">Daily Sales & Volume Trends</h6>
                      </div>
                      <span className="text-muted-custom small">Real-time revenue, order trajectory & peak performance</span>
                    </div>

                    <div className="d-flex flex-wrap align-items-center gap-2">
                      {/* Metric Toggle */}
                      <div className="btn-group btn-group-sm p-1 bg-card-custom rounded-pill border border-custom" role="group">
                        <button 
                          type="button" 
                          className={`btn btn-sm rounded-pill px-3 ${salesMetric === 'revenue' ? 'btn-primary fw-bold text-white shadow-sm' : 'btn-link text-muted-custom text-decoration-none'}`}
                          onClick={() => setSalesMetric('revenue')}
                        >
                          ₹ Revenue
                        </button>
                        <button 
                          type="button" 
                          className={`btn btn-sm rounded-pill px-3 ${salesMetric === 'orders' ? 'btn-primary fw-bold text-white shadow-sm' : 'btn-link text-muted-custom text-decoration-none'}`}
                          onClick={() => setSalesMetric('orders')}
                        >
                          Orders
                        </button>
                      </div>

                      {/* Timeframe Toggle */}
                      <div className="btn-group btn-group-sm p-1 bg-card-custom rounded-pill border border-custom" role="group">
                        <button 
                          type="button" 
                          className={`btn btn-sm rounded-pill px-2 ${salesTimeframe === 'today' ? 'btn-secondary fw-bold text-white shadow-sm' : 'btn-link text-muted-custom text-decoration-none'}`}
                          onClick={() => setSalesTimeframe('today')}
                        >
                          Today
                        </button>
                        <button 
                          type="button" 
                          className={`btn btn-sm rounded-pill px-2 ${salesTimeframe === '7d' ? 'btn-secondary fw-bold text-white shadow-sm' : 'btn-link text-muted-custom text-decoration-none'}`}
                          onClick={() => setSalesTimeframe('7d')}
                        >
                          7 Days
                        </button>
                        <button 
                          type="button" 
                          className={`btn btn-sm rounded-pill px-2 ${salesTimeframe === '30d' ? 'btn-secondary fw-bold text-white shadow-sm' : 'btn-link text-muted-custom text-decoration-none'}`}
                          onClick={() => setSalesTimeframe('30d')}
                        >
                          30 Days
                        </button>
                      </div>
                    </div>
                  </div>

                  {/* Summary Metric Strip */}
                  <div className="row g-2 mb-3">
                    <div className="col-6 col-md-3">
                      <div className="p-2 bg-card-custom rounded-2 border border-custom">
                        <span className="text-muted-custom small style-micro d-block">Period GMV</span>
                        <span className="fw-extrabold text-main fs-6">₹{periodSummary.gmv.toLocaleString()}</span>
                      </div>
                    </div>
                    <div className="col-6 col-md-3">
                      <div className="p-2 bg-card-custom rounded-2 border border-custom">
                        <span className="text-muted-custom small style-micro d-block">Total Orders</span>
                        <span className="fw-extrabold text-main fs-6">{periodSummary.totalOrders}</span>
                      </div>
                    </div>
                    <div className="col-6 col-md-3">
                      <div className="p-2 bg-card-custom rounded-2 border border-custom">
                        <span className="text-muted-custom small style-micro d-block">Avg Order (AOV)</span>
                        <span className="fw-extrabold text-main fs-6">₹{periodSummary.aov.toLocaleString()}</span>
                      </div>
                    </div>
                    <div className="col-6 col-md-3">
                      <div className="p-2 bg-card-custom rounded-2 border border-custom">
                        <span className="text-muted-custom small style-micro d-block">Peak Period</span>
                        <span className="fw-bold text-primary small text-truncate d-block" title={periodSummary.peakLabel}>
                          {periodSummary.peakLabel}
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* SVG Chart Container */}
                  <div className="position-relative bg-card-custom rounded-3 border border-custom p-2" style={{ minHeight: '230px' }}>
                    <svg width="100%" height="220" viewBox="0 0 600 220" preserveAspectRatio="none" className="overflow-visible">
                      <defs>
                        <linearGradient id="salesTrendGrad" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="0%" stopColor="#ea580c" stopOpacity="0.4" />
                          <stop offset="85%" stopColor="#ea580c" stopOpacity="0.03" />
                          <stop offset="100%" stopColor="#ea580c" stopOpacity="0.0" />
                        </linearGradient>
                        <filter id="glowEffect" x="-20%" y="-20%" width="140%" height="140%">
                          <feDropShadow dx="0" dy="2" stdDeviation="2" floodColor="#ea580c" floodOpacity="0.35" />
                        </filter>
                      </defs>

                      {/* Horizontal Gridlines */}
                      {chartCoordinates.yGridLines.map((grid, idx) => (
                        <g key={idx}>
                          <line
                            x1="55"
                            y1={grid.y}
                            x2="585"
                            y2={grid.y}
                            stroke="currentColor"
                            strokeOpacity="0.08"
                            strokeDasharray="4 4"
                          />
                          <text
                            x="48"
                            y={grid.y + 4}
                            textAnchor="end"
                            fill="currentColor"
                            opacity="0.6"
                            fontSize="10"
                            fontFamily="sans-serif"
                          >
                            {salesMetric === 'revenue' ? `₹${grid.label}` : grid.label}
                          </text>
                        </g>
                      ))}

                      {/* Area Fill */}
                      {chartCoordinates.points.length > 1 && (
                        <path d={chartCoordinates.areaPath} fill="url(#salesTrendGrad)" />
                      )}

                      {/* Smooth Trend Line */}
                      {chartCoordinates.points.length > 1 && (
                        <path
                          d={chartCoordinates.linePath}
                          fill="none"
                          stroke="#ea580c"
                          strokeWidth="3"
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          filter="url(#glowEffect)"
                        />
                      )}

                      {/* Interactive Data Points */}
                      {chartCoordinates.points.map((pt, idx) => {
                        const isHovered = hoveredPoint?.index === idx;
                        const isPeak = pt.isPeak;
                        return (
                          <g key={idx}>
                            {/* X-axis Label */}
                            <text
                              x={pt.x}
                              y="212"
                              textAnchor="middle"
                              fill="currentColor"
                              opacity={isHovered ? '1' : '0.65'}
                              fontWeight={isHovered ? '700' : '500'}
                              fontSize="10.5"
                            >
                              {pt.label}
                            </text>

                            {/* Peak indicator dot ring */}
                            {isPeak && (
                              <circle
                                cx={pt.x}
                                cy={pt.y}
                                r="8"
                                fill="#ea580c"
                                fillOpacity="0.2"
                              />
                            )}

                            {/* Center Point */}
                            <circle
                              cx={pt.x}
                              cy={pt.y}
                              r={isHovered ? 6 : 4}
                              fill="#ffffff"
                              stroke="#ea580c"
                              strokeWidth={isHovered ? 3 : 2}
                              style={{ cursor: 'pointer', transition: 'all 0.15s ease' }}
                              onMouseEnter={() => setHoveredPoint({ ...pt, index: idx })}
                              onMouseLeave={() => setHoveredPoint(null)}
                            />
                          </g>
                        );
                      })}
                    </svg>

                    {/* Tooltip Overlay */}
                    {hoveredPoint && (
                      <div 
                        className="position-absolute bg-surface border-custom shadow-lg p-2 rounded-2 text-start pointer-events-none"
                        style={{
                          left: `${(hoveredPoint.x / 600) * 100}%`,
                          top: `${Math.max(10, (hoveredPoint.y / 220) * 100 - 32)}%`,
                          transform: 'translate(-50%, -100%)',
                          zIndex: 10,
                          minWidth: '135px'
                        }}
                      >
                        <div className="fw-bold text-main small">{hoveredPoint.label} <span className="text-muted-custom fw-normal">({hoveredPoint.subLabel})</span></div>
                        <div className="d-flex justify-content-between align-items-center gap-2 mt-1">
                          <span className="text-muted-custom style-micro">Revenue:</span>
                          <span className="fw-bold text-primary small">₹{hoveredPoint.revenue.toLocaleString()}</span>
                        </div>
                        <div className="d-flex justify-content-between align-items-center gap-2">
                          <span className="text-muted-custom style-micro">Orders:</span>
                          <span className="fw-bold text-main small">{hoveredPoint.orders}</span>
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* ORDER STATUS ANALYTICS */}
              <div className="col-12 col-lg-4">
                <div className="card bg-surface border-custom shadow-sm p-3 h-100 d-flex flex-column justify-content-between">
                  <div>
                    <div className="d-flex justify-content-between align-items-center mb-1">
                      <h6 className="fw-bold text-main m-0">Order Status Analytics</h6>
                      <span className={`badge ${statusCounts.efficiency >= 80 ? 'bg-success bg-opacity-10 text-success border border-success' : 'bg-warning bg-opacity-10 text-warning border border-warning'} small`}>
                        {statusCounts.efficiency >= 80 ? 'Optimal Flow' : 'Kitchen Lag'}
                      </span>
                    </div>
                    <span className="text-muted-custom small d-block mb-3">Kitchen turnaround & active order pipeline</span>

                    {/* Donut & Efficiency Header */}
                    <div className="d-flex align-items-center justify-content-center gap-4 py-2">
                      <div className="position-relative d-inline-block" style={{ width: '120px', height: '120px' }}>
                        <svg width="120" height="120" viewBox="0 0 36 36" className="d-block">
                          {/* Background Track */}
                          <path
                            d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                            fill="none"
                            stroke="currentColor"
                            strokeOpacity="0.08"
                            strokeWidth="3.6"
                          />
                          {/* Colored Segments */}
                          {donutSegments.map((seg) => (
                            <path
                              key={seg.key}
                              d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                              fill="none"
                              stroke={seg.color}
                              strokeWidth="3.8"
                              strokeDasharray={seg.strokeDasharray}
                              strokeDashoffset={seg.strokeDashoffset}
                              strokeLinecap="round"
                              style={{ transition: 'stroke-dasharray 0.4s ease, stroke-dashoffset 0.4s ease' }}
                            />
                          ))}
                        </svg>
                        <div className="position-absolute top-50 start-50 translate-middle text-center" style={{ pointerEvents: 'none' }}>
                          <span className="fw-extrabold fs-4 text-main d-block lh-1">{statusCounts.efficiency}%</span>
                          <span className="text-muted-custom style-micro fw-semibold" style={{ fontSize: '0.62rem' }}>Fulfillment</span>
                        </div>
                      </div>

                      {/* Quick Snapshot Metrics */}
                      <div className="d-flex flex-column gap-2">
                        <div className="d-flex align-items-center gap-2">
                          <span className="rounded-circle" style={{ width: '8px', height: '8px', backgroundColor: '#10b981' }}></span>
                          <span className="small text-muted-custom">Ready:</span>
                          <span className="small fw-bold text-main ms-auto">{statusCounts.ready}</span>
                        </div>
                        <div className="d-flex align-items-center gap-2">
                          <span className="rounded-circle" style={{ width: '8px', height: '8px', backgroundColor: '#f59e0b' }}></span>
                          <span className="small text-muted-custom">In Kitchen:</span>
                          <span className="small fw-bold text-main ms-auto">{statusCounts.prep}</span>
                        </div>
                        <div className="d-flex align-items-center gap-2">
                          <span className="rounded-circle" style={{ width: '8px', height: '8px', backgroundColor: '#0ea5e9' }}></span>
                          <span className="small text-muted-custom">New Orders:</span>
                          <span className="small fw-bold text-main ms-auto">{statusCounts.new}</span>
                        </div>
                        <div className="d-flex align-items-center gap-2">
                          <span className="rounded-circle" style={{ width: '8px', height: '8px', backgroundColor: '#8b5cf6' }}></span>
                          <span className="small text-muted-custom">Completed:</span>
                          <span className="small fw-bold text-main ms-auto">{statusCounts.completed}</span>
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Interactive Status Filter Workflow Buttons */}
                  <div className="mt-3 pt-3 border-top border-custom">
                    <div className="d-flex align-items-center justify-content-between mb-2">
                      <span className="text-muted-custom style-micro fw-bold">TRIAGE & FILTER ORDERS:</span>
                      {orderStatusFilter !== 'ALL' && (
                        <button 
                          className="btn btn-sm btn-link text-decoration-none p-0 text-primary style-micro fw-bold"
                          onClick={() => setOrderStatusFilter('ALL')}
                        >
                          Show All ({statusCounts.total})
                        </button>
                      )}
                    </div>
                    <div className="d-grid gap-1">
                      <div className="d-flex gap-1">
                        <button
                          className={`btn btn-sm flex-fill d-flex align-items-center justify-content-between px-2 py-1 rounded-2 border ${orderStatusFilter === 'ALL' ? 'btn-primary text-white fw-bold shadow-sm' : 'bg-card-custom border-custom text-main'}`}
                          onClick={() => setOrderStatusFilter('ALL')}
                        >
                          <span className="small">All Active</span>
                          <span className="badge bg-white bg-opacity-25 rounded-pill">{statusCounts.total}</span>
                        </button>
                        <button
                          className={`btn btn-sm flex-fill d-flex align-items-center justify-content-between px-2 py-1 rounded-2 border ${orderStatusFilter === 'NEW' ? 'btn-primary text-white fw-bold shadow-sm' : 'bg-card-custom border-custom text-main'}`}
                          onClick={() => setOrderStatusFilter('NEW')}
                          style={{ borderColor: orderStatusFilter === 'NEW' ? '' : '#0ea5e940' }}
                        >
                          <span className="small d-flex align-items-center gap-1">
                            <span className="rounded-circle" style={{ width: '6px', height: '6px', backgroundColor: '#0ea5e9' }}></span>
                            New
                          </span>
                          <span className="badge rounded-pill" style={{ backgroundColor: '#0ea5e9', color: '#fff' }}>{statusCounts.new}</span>
                        </button>
                      </div>

                      <div className="d-flex gap-1">
                        <button
                          className={`btn btn-sm flex-fill d-flex align-items-center justify-content-between px-2 py-1 rounded-2 border ${orderStatusFilter === 'PREPARING' ? 'btn-primary text-white fw-bold shadow-sm' : 'bg-card-custom border-custom text-main'}`}
                          onClick={() => setOrderStatusFilter('PREPARING')}
                          style={{ borderColor: orderStatusFilter === 'PREPARING' ? '' : '#f59e0b40' }}
                        >
                          <span className="small d-flex align-items-center gap-1">
                            <span className="rounded-circle" style={{ width: '6px', height: '6px', backgroundColor: '#f59e0b' }}></span>
                            Cooking
                          </span>
                          <span className="badge rounded-pill" style={{ backgroundColor: '#f59e0b', color: '#000' }}>{statusCounts.prep}</span>
                        </button>
                        <button
                          className={`btn btn-sm flex-fill d-flex align-items-center justify-content-between px-2 py-1 rounded-2 border ${orderStatusFilter === 'READY' ? 'btn-primary text-white fw-bold shadow-sm' : 'bg-card-custom border-custom text-main'}`}
                          onClick={() => setOrderStatusFilter('READY')}
                          style={{ borderColor: orderStatusFilter === 'READY' ? '' : '#10b98140' }}
                        >
                          <span className="small d-flex align-items-center gap-1">
                            <span className="rounded-circle" style={{ width: '6px', height: '6px', backgroundColor: '#10b981' }}></span>
                            Ready
                          </span>
                          <span className="badge rounded-pill" style={{ backgroundColor: '#10b981', color: '#fff' }}>{statusCounts.ready}</span>
                        </button>
                        <button
                          className={`btn btn-sm flex-fill d-flex align-items-center justify-content-between px-2 py-1 rounded-2 border ${orderStatusFilter === 'COMPLETED' ? 'btn-primary text-white fw-bold shadow-sm' : 'bg-card-custom border-custom text-main'}`}
                          onClick={() => setOrderStatusFilter('COMPLETED')}
                          style={{ borderColor: orderStatusFilter === 'COMPLETED' ? '' : '#8b5cf640' }}
                        >
                          <span className="small d-flex align-items-center gap-1">
                            <span className="rounded-circle" style={{ width: '6px', height: '6px', backgroundColor: '#8b5cf6' }}></span>
                            Served
                          </span>
                          <span className="badge rounded-pill" style={{ backgroundColor: '#8b5cf6', color: '#fff' }}>{statusCounts.completed}</span>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* LIVE ORDERS & TRANSACTION FEED */}
              <div className="col-12 col-lg-8">
                <div className="card bg-surface border-custom shadow-sm p-3">
                  <div className="d-flex justify-content-between align-items-center mb-2">
                    <div>
                      <div className="d-flex align-items-center gap-2">
                        <h6 className="fw-bold text-main m-0">Live Orders & Transactions ({filteredOrders.length})</h6>
                        {orderStatusFilter !== 'ALL' && (
                          <span className="badge bg-primary text-white small px-2 py-0">Filter: {orderStatusFilter}</span>
                        )}
                      </div>
                      <span className="text-muted-custom small">Real-time active orders across Dine-in, Takeaway & Delivery</span>
                    </div>
                    <div className="d-flex align-items-center gap-2">
                      {orderStatusFilter !== 'ALL' && (
                        <button className="btn btn-sm btn-outline-secondary border-custom text-main" onClick={() => setOrderStatusFilter('ALL')}>
                          Clear Filter
                        </button>
                      )}
                      <button className="btn btn-sm btn-outline-secondary border-custom text-main" onClick={fetchAnalytics}>
                        <RefreshCw size={13} className="me-1" /> Refresh
                      </button>
                    </div>
                  </div>

                  {orderStatusFilter !== 'ALL' && (
                    <div className="d-flex align-items-center justify-content-between px-3 py-2 mb-3 bg-card-custom rounded-2 border border-custom small">
                      <span className="text-main">
                        Filtered by status: <strong>{orderStatusFilter}</strong> ({filteredOrders.length} of {ordersList.length} orders)
                      </span>
                      <button className="btn btn-sm btn-link text-decoration-none p-0 text-primary fw-bold" onClick={() => setOrderStatusFilter('ALL')}>
                        Show All Orders
                      </button>
                    </div>
                  )}

                  <div className="table-responsive">
                    <table className="table table-hover align-middle mb-0">
                      <thead>
                        <tr>
                          <th>Order #</th>
                          <th>Type</th>
                          <th>Table / Guest</th>
                          <th>Covers</th>
                          <th>Status</th>
                          <th>Payment</th>
                          <th>Time</th>
                        </tr>
                      </thead>
                      <tbody>
                        {filteredOrders.length === 0 ? (
                          <tr>
                            <td colSpan="7" className="text-center py-4 text-muted-custom">
                              No orders found {orderStatusFilter !== 'ALL' ? `for status "${orderStatusFilter}"` : 'in the database'}.
                            </td>
                          </tr>
                        ) : (
                          filteredOrders.slice(0, 8).map((ord) => {
                            const oId = ord.orderId || ord.id;
                            const tableObj = tables.find(t => (t.tableId || t.id) === ord.tableId);
                            const tableName = tableObj ? tableObj.tableNumber : (ord.orderType === 'DELIVERY' ? (ord.customerName || 'Delivery') : 'Counter');

                            const getStatusBadge = (st) => {
                              switch (st) {
                                case 'NEW': return 'bg-info text-dark';
                                case 'PREPARING': return 'bg-warning text-dark';
                                case 'READY': return 'bg-primary text-white';
                                case 'SERVED': return 'bg-success text-white';
                                case 'DELIVERED': return 'bg-success text-white';
                                case 'PAID': return 'bg-secondary text-white';
                                default: return 'bg-dark text-white';
                              }
                            };

                            return (
                              <tr key={oId}>
                                <td>
                                  <span className="badge bg-card-custom text-main border border-custom font-monospace">
                                    #{oId ? oId.substring(0, 8) : '---'}
                                  </span>
                                </td>
                                <td>
                                  <span className="badge bg-surface border border-custom text-muted-custom small">
                                    {ord.orderType}
                                  </span>
                                </td>
                                <td className="fw-semibold text-main">
                                  {tableName}
                                </td>
                                <td>{ord.covers || 1}</td>
                                <td>
                                  <span className={`badge ${getStatusBadge(ord.status)} small`}>
                                    {ord.status}
                                  </span>
                                </td>
                                <td>
                                  <span className={`badge ${ord.paymentStatus === 'PAID' ? 'bg-success bg-opacity-10 text-success border border-success' : 'bg-warning bg-opacity-10 text-warning border border-warning'} small`}>
                                    {ord.paymentStatus || 'PENDING'}
                                  </span>
                                </td>
                                <td className="small text-muted-custom">
                                  {ord.kotFiredAt ? ord.kotFiredAt.substring(11, 16) : (ord.billedAt ? ord.billedAt.substring(11, 16) : 'Live')}
                                </td>
                              </tr>
                            );
                          })
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>

              {/* TABLE OCCUPANCY MATRIX */}
              <div className="col-12 col-lg-4">
                <div className="card bg-surface border-custom shadow-sm p-3">
                  <div className="d-flex justify-content-between align-items-center mb-3">
                    <div>
                      <h6 className="fw-bold text-main m-0">Floor Status ({tables.length} Tables)</h6>
                      <span className="text-muted-custom small">Live occupancy & seating</span>
                    </div>
                    <button className="btn btn-sm btn-link text-decoration-none p-0 text-secondary-custom" onClick={() => setActiveView('floor')}>
                      View Floor <ChevronRight size={14} />
                    </button>
                  </div>

                  <div className="row g-2">
                    {tables.length === 0 ? (
                      <div className="text-center py-4 text-muted-custom small">No tables configured.</div>
                    ) : (
                      tables.map((t) => {
                        const tId = t.tableId || t.id;
                        const isOcc = t.status === 'OCCUPIED';
                        const isRes = t.status === 'RESERVED';
                        const badgeColor = isOcc ? 'bg-danger text-white' : (isRes ? 'bg-primary text-white' : 'bg-success text-white');
                        return (
                          <div key={tId} className="col-4">
                            <div className={`p-2 rounded-2 border text-center ${isOcc ? 'border-danger bg-danger bg-opacity-10' : 'border-custom bg-card-custom'}`}>
                              <span className="fw-bold text-main d-block">{t.tableNumber}</span>
                              <span className="text-muted-custom" style={{ fontSize: '0.7rem' }}>{t.section} • {t.capacity}p</span>
                              <span className={`badge ${badgeColor} d-block mt-1`} style={{ fontSize: '0.65rem' }}>
                                {t.status || 'AVAILABLE'}
                              </span>
                            </div>
                          </div>
                        );
                      })
                    )}
                  </div>
                </div>
              </div>

              {/* ON-DUTY STAFF & OUTLETS STRIP */}
              <div className="col-12">
                <div className="card bg-surface border-custom shadow-sm p-3">
                  <div className="d-flex justify-content-between align-items-center mb-3">
                    <div>
                      <h6 className="fw-bold text-main m-0">Staff On Duty & System Outlets ({staffList.length} Staff, {outlets.length} Outlets)</h6>
                      <span className="text-muted-custom small">Active roster & infrastructure status</span>
                    </div>
                    <button className="btn btn-sm btn-link text-decoration-none p-0 text-secondary-custom" onClick={() => setActiveView('staff')}>
                      Manage Staff <ChevronRight size={14} />
                    </button>
                  </div>

                  <div className="row g-2">
                    {staffList.slice(0, 6).map((s) => (
                      <div key={s.staffId || s.id} className="col-12 col-sm-6 col-md-4 col-lg-2">
                        <div className="p-2 rounded-2 border border-custom bg-card-custom d-flex align-items-center gap-2">
                          <div className="p-2 rounded-circle bg-blue text-white" style={{ width: '32px', height: '32px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '0.75rem', fontWeight: 'bold' }}>
                            {(s.name || 'S')[0].toUpperCase()}
                          </div>
                          <div className="overflow-hidden">
                            <span className="fw-bold text-main small d-block text-truncate">{s.name}</span>
                            <span className="badge bg-surface border border-custom text-muted-custom" style={{ fontSize: '0.65rem' }}>{s.role}</span>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ========================================================= */}
          {/* 2. STAFF & ADMIN MANAGEMENT                                */}
          {/* ========================================================= */}
          {activeView === 'staff' && (
            <StaffShiftManager showToast={showToast} />
          )}

          {/* ========================================================= */}
          {/* 3. MENU CATALOG & DIGITAL QR                               */}
          {/* ========================================================= */}
          {activeView === 'menu' && (
            <MenuCatalogManager showToast={showToast} />
          )}

          {/* ========================================================= */}
          {/* 4. FLOOR PLAN CANVAS                                       */}
          {/* ========================================================= */}
          {activeView === 'floor' && (
            <FloorPlanManager showToast={showToast} />
          )}

          {/* ========================================================= */}
          {/* 5. CHAIN & MULTI-OUTLET MANAGEMENT                          */}
          {/* ========================================================= */}
          {activeView === 'chain' && (
            <ChainOutletManager showToast={showToast} />
          )}

          {/* ========================================================= */}
          {/* 6. KITCHEN STATIONS CONFIGURATION                          */}
          {/* ========================================================= */}
          {activeView === 'stations' && (
            <KitchenStationManager showToast={showToast} />
          )}

          {/* ========================================================= */}
          {/* 7. RESERVATIONS & WAITLIST MANAGER                        */}
          {/* ========================================================= */}
          {activeView === 'reservations' && (
            <ReservationWaitlistManager showToast={showToast} />
          )}

          {/* ========================================================= */}
          {/* 8. INVENTORY & STOCK CONTROL                               */}
          {/* ========================================================= */}
          {activeView === 'inventory' && (
            <InventoryStockManager showToast={showToast} />
          )}

          {/* ========================================================= */}
          {/* 9. REPORTS & ANALYTICS                                     */}
          {/* ========================================================= */}
          {activeView === 'reports' && (
            <ReportsAnalyticsManager showToast={showToast} />
          )}

          {/* ========================================================= */}
          {/* 10. RESTAURANT SETTINGS                                    */}
          {/* ========================================================= */}
          {activeView === 'settings' && (
            <div className="row g-4">
              <div className="col-12 col-lg-3">
                <div className="card bg-surface border-custom shadow-sm p-3">
                  <h6 className="fw-bold text-main mb-3">SETTINGS</h6>
                  <div className="nav flex-column gap-1">
                    {['general', 'tax', 'payments', 'integrations', 'security'].map((t) => (
                      <button key={t} className={`btn text-start p-2 rounded-2 ${settingsTab === t ? 'btn-primary text-white fw-bold' : 'btn-outline-secondary text-main border-custom'}`} onClick={() => setSettingsTab(t)}>
                        {t.toUpperCase()}
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              <div className="col-12 col-lg-9">
                <div className="card bg-surface border-custom shadow-sm p-4">
                  <h5 className="fw-bold text-main mb-3">Restaurant Profile Settings</h5>
                  <form onSubmit={handleSaveSettings}>
                    <div className="row g-3 mb-3">
                      <div className="col-md-6">
                        <label className="form-label text-muted-custom small fw-semibold">Restaurant Name</label>
                        <input type="text" className="form-control" value={restaurantProfile.name} onChange={(e) => setRestaurantProfile({ ...restaurantProfile, name: e.target.value })} />
                      </div>
                      <div className="col-md-6">
                        <label className="form-label text-muted-custom small fw-semibold">Business Email</label>
                        <input type="email" className="form-control" value={restaurantProfile.email} onChange={(e) => setRestaurantProfile({ ...restaurantProfile, email: e.target.value })} />
                      </div>
                    </div>
                    <div className="mb-3">
                      <label className="form-label text-muted-custom small fw-semibold">Physical Address</label>
                      <input type="text" className="form-control" value={restaurantProfile.address} onChange={(e) => setRestaurantProfile({ ...restaurantProfile, address: e.target.value })} />
                    </div>
                    <div className="row g-3 mb-4">
                      <div className="col-md-6">
                        <label className="form-label text-muted-custom small fw-semibold">Contact Number</label>
                        <input type="text" className="form-control" value={restaurantProfile.phone} onChange={(e) => setRestaurantProfile({ ...restaurantProfile, phone: e.target.value })} />
                      </div>
                      <div className="col-md-6">
                        <label className="form-label text-muted-custom small fw-semibold">Website URL</label>
                        <input type="text" className="form-control" value={restaurantProfile.website} onChange={(e) => setRestaurantProfile({ ...restaurantProfile, website: e.target.value })} />
                      </div>
                    </div>
                    <button type="submit" className="btn btn-primary touch-btn fw-bold px-4">Save Settings</button>
                  </form>
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ========================================================= */}
      {/* ALL MODALS                                                */}
      {/* ========================================================= */}
      {/* Add Staff Modal */}
      {showAddStaffModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom"><h5 className="modal-title fw-bold text-main">Add New Staff Member</h5><button type="button" className="btn-close" onClick={() => setShowAddStaffModal(false)}></button></div>
              <form onSubmit={handleAddStaffSubmit}>
                <div className="modal-body">
                  <div className="alert alert-info py-2 small d-flex align-items-center gap-2 mb-3">
                    <Mail size={16} />
                    <span>An automated email with terminal credentials & PIN code will be sent to the staff member's email address upon creation.</span>
                  </div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Full Name</label><input type="text" className="form-control" required value={newStaff.name} onChange={(e) => setNewStaff({ ...newStaff, name: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Staff Email (PIN Will Be Sent Here)</label><input type="email" className="form-control" required placeholder="staff@restaurant.com" value={newStaff.email} onChange={(e) => setNewStaff({ ...newStaff, email: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Phone Number</label><input type="text" className="form-control" value={newStaff.phone} onChange={(e) => setNewStaff({ ...newStaff, phone: e.target.value })} /></div>
                  <div className="mb-3">
                    <div className="d-flex justify-content-between align-items-center mb-1">
                      <label className="form-label text-muted-custom small fw-semibold m-0">Staff Login PIN Code (4 Digits)</label>
                      <button type="button" className="btn btn-sm btn-link text-blue p-0 text-decoration-none fw-bold" onClick={() => setNewStaff({ ...newStaff, pin: String(Math.floor(1000 + Math.random() * 9000)) })}>Generate Random PIN</button>
                    </div>
                    <input type="text" maxLength="6" className="form-control font-monospace" required placeholder="e.g. 1234" value={newStaff.pin} onChange={(e) => setNewStaff({ ...newStaff, pin: e.target.value })} />
                    <span className="text-muted-custom micro-text">This secret PIN code will be emailed to the staff member to log in at terminals and clock in.</span>
                  </div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Role</label>
                    <select className="form-select" value={newStaff.role} onChange={(e) => setNewStaff({ ...newStaff, role: e.target.value })}>
                      <option value="WAITER">Waiter</option><option value="CASHIER">Cashier</option><option value="CHEF">Chef</option><option value="MANAGER">Manager</option><option value="ADMIN">Admin</option>
                    </select>
                  </div>
                </div>
                <div className="modal-footer border-custom"><button type="button" className="btn btn-outline-secondary" onClick={() => setShowAddStaffModal(false)}>Cancel</button><button type="submit" className="btn btn-primary fw-bold">Create Staff & Send PIN</button></div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Edit Staff & Change PIN Modal */}
      {showEditStaffModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom"><h5 className="modal-title fw-bold text-main">Edit Staff & Reset PIN</h5><button type="button" className="btn-close" onClick={() => setShowEditStaffModal(false)}></button></div>
              <form onSubmit={handleEditStaffSubmit}>
                <div className="modal-body">
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Full Name</label><input type="text" className="form-control" required value={editStaff.name} onChange={(e) => setEditStaff({ ...editStaff, name: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Email</label><input type="email" className="form-control" required value={editStaff.email} onChange={(e) => setEditStaff({ ...editStaff, email: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Phone Number</label><input type="text" className="form-control" value={editStaff.phone} onChange={(e) => setEditStaff({ ...editStaff, phone: e.target.value })} /></div>
                  <div className="mb-3">
                    <div className="d-flex justify-content-between align-items-center mb-1">
                      <label className="form-label text-muted-custom small fw-semibold m-0">New Terminal PIN Code</label>
                      <button type="button" className="btn btn-sm btn-link text-blue p-0 text-decoration-none fw-bold" onClick={() => setEditStaff({ ...editStaff, pin: String(Math.floor(1000 + Math.random() * 9000)) })}>Generate Random PIN</button>
                    </div>
                    <input type="text" maxLength="6" className="form-control font-monospace" placeholder="Leave blank to keep existing PIN" value={editStaff.pin} onChange={(e) => setEditStaff({ ...editStaff, pin: e.target.value })} />
                    <span className="text-muted-custom micro-text">Updating the PIN will automatically send an email with the new credentials to the staff.</span>
                  </div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Role</label>
                    <select className="form-select" value={editStaff.role} onChange={(e) => setEditStaff({ ...editStaff, role: e.target.value })}>
                      <option value="WAITER">Waiter</option><option value="CASHIER">Cashier</option><option value="CHEF">Chef</option><option value="MANAGER">Manager</option><option value="ADMIN">Admin</option>
                    </select>
                  </div>
                </div>
                <div className="modal-footer border-custom"><button type="button" className="btn btn-outline-secondary" onClick={() => setShowEditStaffModal(false)}>Cancel</button><button type="submit" className="btn btn-primary fw-bold">Save Changes</button></div>
              </form>
            </div>
          </div>
        </div>
      )}


      {/* Add Admin Modal */}
      {showAddAdminModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom"><h5 className="modal-title fw-bold text-main">Add System Administrator</h5><button type="button" className="btn-close" onClick={() => setShowAddAdminModal(false)}></button></div>
              <form onSubmit={handleAddAdminSubmit}>
                <div className="modal-body">
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Admin Full Name</label><input type="text" className="form-control" required value={newAdmin.name} onChange={(e) => setNewAdmin({ ...newAdmin, name: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Username</label><input type="text" className="form-control" required value={newAdmin.username} onChange={(e) => setNewAdmin({ ...newAdmin, username: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Email</label><input type="email" className="form-control" required value={newAdmin.email} onChange={(e) => setNewAdmin({ ...newAdmin, email: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Password</label><input type="password" className="form-control" required value={newAdmin.password} onChange={(e) => setNewAdmin({ ...newAdmin, password: e.target.value })} /></div>
                </div>
                <div className="modal-footer border-custom"><button type="button" className="btn btn-outline-secondary" onClick={() => setShowAddAdminModal(false)}>Cancel</button><button type="submit" className="btn btn-primary fw-bold">Create Admin</button></div>
              </form>
            </div>
          </div>
        </div>
      )}


      {/* Add Outlet Modal */}
      {showAddOutletModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom"><h5 className="modal-title fw-bold text-main">Add New Franchise Outlet</h5><button type="button" className="btn-close" onClick={() => setShowAddOutletModal(false)}></button></div>
              <form onSubmit={handleCreateOutletSubmit}>
                <div className="modal-body">
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Outlet Name</label><input type="text" className="form-control" required value={newOutlet.name} onChange={(e) => setNewOutlet({ ...newOutlet, name: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Outlet Code</label><input type="text" className="form-control" required value={newOutlet.outletCode} onChange={(e) => setNewOutlet({ ...newOutlet, outletCode: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">City</label><input type="text" className="form-control" value={newOutlet.city} onChange={(e) => setNewOutlet({ ...newOutlet, city: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Phone Number</label><input type="text" className="form-control" value={newOutlet.phone} onChange={(e) => setNewOutlet({ ...newOutlet, phone: e.target.value })} /></div>
                </div>
                <div className="modal-footer border-custom"><button type="button" className="btn btn-outline-secondary" onClick={() => setShowAddOutletModal(false)}>Cancel</button><button type="submit" className="btn btn-primary fw-bold">Create Outlet</button></div>
              </form>
            </div>
          </div>
        </div>
      )}


      {/* Add Kitchen Station Modal */}
      {showAddStationModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom"><h5 className="modal-title fw-bold text-main">Add Kitchen Station</h5><button type="button" className="btn-close" onClick={() => setShowAddStationModal(false)}></button></div>
              <form onSubmit={handleCreateStationSubmit}>
                <div className="modal-body">
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Station Name (e.g. HOT KITCHEN, GRILL, PASTRY)</label><input type="text" className="form-control" required value={newStationName} onChange={(e) => setNewStationName(e.target.value)} /></div>
                </div>
                <div className="modal-footer border-custom"><button type="button" className="btn btn-outline-secondary" onClick={() => setShowAddStationModal(false)}>Cancel</button><button type="submit" className="btn btn-primary fw-bold">Save Station</button></div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Record GRN Stock Modal */}
      {showAddGrnModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom"><h5 className="modal-title fw-bold text-main">Record GRN Stock Received</h5><button type="button" className="btn-close" onClick={() => setShowAddGrnModal(false)}></button></div>
              <form onSubmit={handleRecordGRN}>
                <div className="modal-body">
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Select Ingredient</label>
                    <select className="form-select" required value={grnForm.ingredientId} onChange={(e) => setGrnForm({ ...grnForm, ingredientId: e.target.value })}>
                      <option value="">-- Choose Ingredient --</option>
                      {inventoryItems.map((inv) => (
                        <option key={inv.ingredientId || inv.id} value={inv.ingredientId || inv.id}>{inv.name} (Current: {inv.currentStock} {inv.unit})</option>
                      ))}
                    </select>
                  </div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Quantity Received</label><input type="number" step="0.001" className="form-control" required value={grnForm.quantityReceived} onChange={(e) => setGrnForm({ ...grnForm, quantityReceived: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Unit Cost Price (₹)</label><input type="number" step="0.01" className="form-control" value={grnForm.costPrice} onChange={(e) => setGrnForm({ ...grnForm, costPrice: e.target.value })} /></div>
                </div>
                <div className="modal-footer border-custom"><button type="button" className="btn btn-outline-secondary" onClick={() => setShowAddGrnModal(false)}>Cancel</button><button type="submit" className="btn btn-primary fw-bold">Record Stock</button></div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Add Dish Modal */}
      {showAddDishModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom"><h5 className="modal-title fw-bold text-main">Add New Dish</h5><button type="button" className="btn-close" onClick={() => setShowAddDishModal(false)}></button></div>
              <form onSubmit={handleAddDishSubmit}>
                <div className="modal-body">
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Dish Name</label><input type="text" className="form-control" required value={newDish.name} onChange={(e) => setNewDish({ ...newDish, name: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Price (₹)</label><input type="number" step="0.01" className="form-control" required value={newDish.price} onChange={(e) => setNewDish({ ...newDish, price: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Category</label>
                    <select className="form-select" value={newDish.categoryId} onChange={(e) => setNewDish({ ...newDish, categoryId: e.target.value })}>
                      {categories.map((c) => (<option key={c.id} value={c.id}>{c.name}</option>))}
                    </select>
                  </div>
                </div>
                <div className="modal-footer border-custom"><button type="button" className="btn btn-outline-secondary" onClick={() => setShowAddDishModal(false)}>Cancel</button><button type="submit" className="btn btn-primary fw-bold">Save Dish</button></div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Add Table Modal */}
      {showAddTableModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.5)' }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom"><h5 className="modal-title fw-bold text-main">Add New Table</h5><button type="button" className="btn-close" onClick={() => setShowAddTableModal(false)}></button></div>
              <form onSubmit={handleAddTableSubmit}>
                <div className="modal-body">
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Table Number</label><input type="text" className="form-control" required value={newTable.tableNumber} onChange={(e) => setNewTable({ ...newTable, tableNumber: e.target.value })} /></div>
                  <div className="mb-3"><label className="form-label text-muted-custom small fw-semibold">Capacity</label><input type="number" className="form-control" required value={newTable.capacity} onChange={(e) => setNewTable({ ...newTable, capacity: e.target.value })} /></div>
                </div>
                <div className="modal-footer border-custom"><button type="button" className="btn btn-outline-secondary" onClick={() => setShowAddTableModal(false)}>Cancel</button><button type="submit" className="btn btn-primary fw-bold">Save Table</button></div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
