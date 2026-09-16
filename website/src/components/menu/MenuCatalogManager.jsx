import React, { useState, useEffect } from 'react';
import { apiRequest } from '../../services/apiClient';
import { 
  Search, 
  Plus, 
  QrCode, 
  Send, 
  Edit, 
  Star, 
  Layers, 
  Clock, 
  Flame, 
  Utensils, 
  Printer, 
  Download, 
  Copy, 
  RefreshCw, 
  Check, 
  X,
  Sparkles,
  Sliders,
  CheckCircle2,
  XCircle,
  Package,
  FileText,
  Trash2
} from 'lucide-react';

export default function MenuCatalogManager({ showToast }) {
  // Main Data States
  const [categories, setCategories] = useState([]);
  const [menuItems, setMenuItems] = useState([]);
  const [outlets, setOutlets] = useState([]);
  const [stations, setStations] = useState([]);

  // Filter & Search States
  const [filterCategory, setFilterCategory] = useState('ALL');
  const [filterTab, setFilterTab] = useState('ALL'); // ALL, SPECIALS, COMBOS, OUT_OF_STOCK, VEG, NON_VEG
  const [searchQuery, setSearchQuery] = useState('');
  const [timeFilter, setTimeFilter] = useState('');
  const [loading, setLoading] = useState(false);

  // Modal Controls
  const [showDishModal, setShowDishModal] = useState(false);
  const [editingDishId, setEditingDishId] = useState(null);
  const [dishForm, setDishForm] = useState({
    name: '',
    description: '',
    categoryId: '',
    price: '',
    priceTakeaway: '',
    priceDelivery: '',
    gstRate: '5.00',
    hsnCode: '2106',
    foodType: 'MAIN_COURSE',
    isVeg: true,
    isAvailable: true,
    isSpecial: false,
    specialPrice: '',
    availableFrom: '',
    availableTo: '',
    calories: '',
    allergens: '',
    isCombo: false,
    stationId: '',
    imageUrl: ''
  });

  const [showCategoryModal, setShowCategoryModal] = useState(false);
  const [categoryForm, setCategoryForm] = useState({ name: '', parentId: '' });

  const [showQrModal, setShowQrModal] = useState(false);
  const [qrOutletId, setQrOutletId] = useState('');

  const [showSpecialModal, setShowSpecialModal] = useState(false);
  const [specialTargetItem, setSpecialTargetItem] = useState(null);
  const [specialFormPrice, setSpecialFormPrice] = useState('');

  // Modifiers Modal State
  const [showModifiersModal, setShowModifiersModal] = useState(false);
  const [selectedItemForModifiers, setSelectedItemForModifiers] = useState(null);
  const [modifierGroups, setModifierGroups] = useState([]);
  const [groupOptionsMap, setGroupOptionsMap] = useState({});
  const [newGroupForm, setNewGroupForm] = useState({
    name: '',
    isMandatory: false,
    minSelections: 0,
    maxSelections: 1
  });
  const [newOptionForms, setNewOptionForms] = useState({});

  // Combos Modal State
  const [showComboModal, setShowComboModal] = useState(false);
  const [selectedItemForCombo, setSelectedItemForCombo] = useState(null);
  const [comboComponents, setComboComponents] = useState([]);
  const [comboForm, setComboForm] = useState({ componentItemId: '', quantity: 1 });

  useEffect(() => {
    fetchAllData();
  }, []);

  const fetchAllData = async () => {
    setLoading(true);
    try {
      const [catsRes, itemsRes, outletsRes, stationsRes] = await Promise.all([
        apiRequest('/api/v1/menu/categories').catch(() => []),
        apiRequest('/api/v1/menu/items').catch(() => []),
        apiRequest('/api/v1/chain/outlets').catch(() => []),
        apiRequest('/api/v1/kitchen-stations').catch(() => []),
      ]);

      const cats = Array.isArray(catsRes) ? catsRes : [];
      const items = Array.isArray(itemsRes) ? itemsRes : [];
      const outs = Array.isArray(outletsRes) ? outletsRes : [];
      const stns = Array.isArray(stationsRes) ? stationsRes : [];

      setCategories(cats);
      setMenuItems(items);
      setOutlets(outs);
      setStations(stns);

      if (outs.length > 0 && !qrOutletId) {
        setQrOutletId(outs[0].id || outs[0].outletId);
      }
    } catch (err) {
      console.error('Error loading menu catalog data:', err);
    } finally {
      setLoading(false);
    }
  };

  // Filter time active items
  const handleTimeFilterQuery = async (timeVal) => {
    setTimeFilter(timeVal);
    if (!timeVal) {
      fetchAllData();
      return;
    }
    try {
      const res = await apiRequest(`/api/v1/menu/items/active?time=${timeVal}:00`);
      if (Array.isArray(res)) {
        setMenuItems(res);
        if (showToast) showToast(`Showing items active at ${timeVal}`, 'info');
      }
    } catch (err) {
      console.error('Time filter error:', err);
    }
  };

  // Handle Save Dish (Create / Update)
  const handleSaveDish = async (e) => {
    e.preventDefault();
    try {
      const selectedCategoryObj = categories.find(c => c.categoryId === dishForm.categoryId || c.id === dishForm.categoryId);

      const payload = {
        name: dishForm.name,
        description: dishForm.description,
        price: parseFloat(dishForm.price) || 0.0,
        priceTakeaway: dishForm.priceTakeaway ? parseFloat(dishForm.priceTakeaway) : null,
        priceDelivery: dishForm.priceDelivery ? parseFloat(dishForm.priceDelivery) : null,
        gstRate: parseFloat(dishForm.gstRate) || 5.0,
        hsnCode: dishForm.hsnCode || '2106',
        foodType: dishForm.foodType || 'MAIN_COURSE',
        isVeg: Boolean(dishForm.isVeg),
        isAvailable: Boolean(dishForm.isAvailable),
        isSpecial: Boolean(dishForm.isSpecial),
        specialPrice: dishForm.specialPrice ? parseFloat(dishForm.specialPrice) : null,
        availableFrom: dishForm.availableFrom ? `${dishForm.availableFrom}:00` : null,
        availableTo: dishForm.availableTo ? `${dishForm.availableTo}:00` : null,
        calories: dishForm.calories ? parseInt(dishForm.calories) : null,
        allergens: dishForm.allergens || null,
        isCombo: Boolean(dishForm.isCombo),
        stationId: dishForm.stationId || null,
        imageUrl: dishForm.imageUrl || null,
        category: selectedCategoryObj ? { categoryId: selectedCategoryObj.categoryId || selectedCategoryObj.id } : null
      };

      if (editingDishId) {
        await apiRequest(`/api/v1/menu/items/${editingDishId}`, 'PUT', payload);
        if (showToast) showToast(`Dish '${dishForm.name}' updated successfully!`, 'success');
      } else {
        await apiRequest('/api/v1/menu/items', 'POST', payload);
        if (showToast) showToast(`New dish '${dishForm.name}' created successfully!`, 'success');
      }

      setShowDishModal(false);
      resetDishForm();
      fetchAllData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to save dish', 'error');
    }
  };

  const openAddDishModal = () => {
    setEditingDishId(null);
    setDishForm({
      name: '',
      description: '',
      categoryId: categories[0]?.categoryId || categories[0]?.id || '',
      price: '',
      priceTakeaway: '',
      priceDelivery: '',
      gstRate: '5.00',
      hsnCode: '2106',
      foodType: 'MAIN_COURSE',
      isVeg: true,
      isAvailable: true,
      isSpecial: false,
      specialPrice: '',
      availableFrom: '',
      availableTo: '',
      calories: '',
      allergens: '',
      isCombo: false,
      stationId: stations[0]?.id || '',
      imageUrl: ''
    });
    setShowDishModal(true);
  };

  const openEditDishModal = (item) => {
    setEditingDishId(item.itemId || item.id);
    setDishForm({
      name: item.name || '',
      description: item.description || '',
      categoryId: item.category?.categoryId || item.category?.id || item.categoryId || '',
      price: item.price ? item.price.toString() : '',
      priceTakeaway: item.priceTakeaway ? item.priceTakeaway.toString() : '',
      priceDelivery: item.priceDelivery ? item.priceDelivery.toString() : '',
      gstRate: item.gstRate ? item.gstRate.toString() : '5.00',
      hsnCode: item.hsnCode || '2106',
      foodType: item.foodType || 'MAIN_COURSE',
      isVeg: (item.isVeg ?? item.veg) !== false,
      isAvailable: (item.isAvailable ?? item.available) !== false,
      isSpecial: Boolean(item.isSpecial ?? item.special),
      specialPrice: item.specialPrice ? item.specialPrice.toString() : '',
      availableFrom: item.availableFrom ? item.availableFrom.substring(0, 5) : '',
      availableTo: item.availableTo ? item.availableTo.substring(0, 5) : '',
      calories: item.calories ? item.calories.toString() : '',
      allergens: item.allergens || '',
      isCombo: Boolean(item.isCombo ?? item.combo),
      stationId: item.stationId || '',
      imageUrl: item.imageUrl || ''
    });
    setShowDishModal(true);
  };

  const resetDishForm = () => {
    setEditingDishId(null);
    setDishForm({
      name: '',
      description: '',
      categoryId: '',
      price: '',
      priceTakeaway: '',
      priceDelivery: '',
      gstRate: '5.00',
      hsnCode: '2106',
      foodType: 'MAIN_COURSE',
      isVeg: true,
      isAvailable: true,
      isSpecial: false,
      specialPrice: '',
      availableFrom: '',
      availableTo: '',
      calories: '',
      allergens: '',
      isCombo: false,
      stationId: '',
      imageUrl: ''
    });
  };

  // Toggle Item Availability
  const handleToggleAvailability = async (itemId) => {
    try {
      await apiRequest(`/api/v1/menu/items/${itemId}/toggle-availability`, 'PATCH');
      if (showToast) showToast('Item availability status updated & synced!', 'success');
      fetchAllData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Toggle failed', 'error');
    }
  };

  // Explicit 86'ing
  const handleExplicit86 = async (itemId, currentAvailability) => {
    const nextStatus = !currentAvailability;
    try {
      await apiRequest(`/api/v1/menu/items/${itemId}/86?available=${nextStatus}`, 'PATCH');
      if (showToast) showToast(nextStatus ? 'Item restored to active stock!' : 'Item 86\'d (Marked Out of Stock)! Pushed to Aggregators.', 'warning');
      fetchAllData();
    } catch (err) {
      if (showToast) showToast(err.message || '86 action failed', 'error');
    }
  };

  // Open Daily Special Setter Modal
  const openSpecialModal = (item) => {
    setSpecialTargetItem(item);
    setSpecialFormPrice(item.specialPrice ? item.specialPrice.toString() : item.price.toString());
    setShowSpecialModal(true);
  };

  const handleSaveSpecial = async (e) => {
    e.preventDefault();
    if (!specialTargetItem) return;
    const itemId = specialTargetItem.itemId || specialTargetItem.id;
    const isNowSpecial = !specialTargetItem.isSpecial;
    try {
      await apiRequest(`/api/v1/menu/items/${itemId}/special?special=${isNowSpecial}&specialPrice=${parseFloat(specialFormPrice) || 0}`, 'PUT');
      if (showToast) showToast(isNowSpecial ? `'${specialTargetItem.name}' tagged as Daily Special!` : `'${specialTargetItem.name}' removed from Daily Specials`, 'success');
      setShowSpecialModal(false);
      fetchAllData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to update special status', 'error');
    }
  };

  // Handle Save Category
  const handleSaveCategory = async (e) => {
    e.preventDefault();
    if (!categoryForm.name.trim()) return;
    try {
      const payload = {
        name: categoryForm.name.trim(),
        parentCategory: categoryForm.parentId ? { categoryId: categoryForm.parentId } : null
      };
      await apiRequest('/api/v1/menu/categories', 'POST', payload);
      if (showToast) showToast(`Category '${categoryForm.name}' created!`, 'success');
      setShowCategoryModal(false);
      setCategoryForm({ name: '', parentId: '' });
      fetchAllData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to create category', 'error');
    }
  };

  // Delete Dish
  const handleDeleteDish = async (dishId, dishName) => {
    if (!window.confirm(`Are you sure you want to delete '${dishName}' from the menu?`)) return;
    try {
      await apiRequest(`/api/v1/menu/items/${dishId}`, 'DELETE');
      if (showToast) showToast(`Dish '${dishName}' deleted successfully`, 'warning');
      fetchAllData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to delete dish', 'error');
    }
  };

  // Delete Category
  const handleDeleteCategory = async (catId, catName) => {
    if (!window.confirm(`Delete category '${catName}'?`)) return;
    try {
      await apiRequest(`/api/v1/menu/categories/${catId}`, 'DELETE');
      if (showToast) showToast(`Category '${catName}' deleted!`, 'warning');
      if (filterCategory === catId) setFilterCategory('ALL');
      fetchAllData();
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to delete category', 'error');
    }
  };

  // Download QR PNG
  const handleDownloadQr = () => {
    const activeOutlet = qrOutletId || (outlets[0]?.id || outlets[0]?.outletId) || '11111111-1111-1111-1111-111111111111';
    const link = document.createElement('a');
    link.href = `/api/v1/menu/outlets/${activeOutlet}/qr`;
    link.download = `Digital_Menu_QR_${activeOutlet}.png`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    if (showToast) showToast('QR Code PNG download initiated!', 'success');
  };

  // Master Menu Push to Chain Outlets
  const handlePushMasterMenu = async () => {
    try {
      const outletIds = outlets.map(o => o.id || o.outletId);
      await apiRequest('/api/v1/chain/menu/push', 'POST', { outletIds });
      if (showToast) showToast('Master menu pushed to all chain outlets live!', 'success');
    } catch (err) {
      if (showToast) showToast(err.message || 'Push menu failed', 'error');
    }
  };

  // Modifiers Management Logic
  const openModifiersModal = async (item) => {
    setSelectedItemForModifiers(item);
    setShowModifiersModal(true);
    fetchModifiersForItem(item.itemId || item.id);
  };

  const fetchModifiersForItem = async (itemId) => {
    try {
      const groups = await apiRequest(`/api/v1/menu/items/${itemId}/modifier-groups`).catch(() => []);
      const grps = Array.isArray(groups) ? groups : [];
      setModifierGroups(grps);

      const optionsMap = {};
      await Promise.all(grps.map(async (g) => {
        const gId = g.modifierGroupId || g.id;
        const opts = await apiRequest(`/api/v1/menu/modifier-groups/${gId}/options`).catch(() => []);
        optionsMap[gId] = Array.isArray(opts) ? opts : [];
      }));
      setGroupOptionsMap(optionsMap);
    } catch (err) {
      console.error('Error fetching modifier groups:', err);
    }
  };

  const handleCreateModifierGroup = async (e) => {
    e.preventDefault();
    if (!selectedItemForModifiers) return;
    try {
      const payload = {
        menuItemId: selectedItemForModifiers.itemId || selectedItemForModifiers.id,
        name: newGroupForm.name,
        isMandatory: newGroupForm.isMandatory,
        minSelections: parseInt(newGroupForm.minSelections) || 0,
        maxSelections: parseInt(newGroupForm.maxSelections) || 1
      };
      await apiRequest('/api/v1/menu/modifier-groups', 'POST', payload);
      if (showToast) showToast(`Modifier group '${newGroupForm.name}' added!`, 'success');
      setNewGroupForm({ name: '', isMandatory: false, minSelections: 0, maxSelections: 1 });
      fetchModifiersForItem(selectedItemForModifiers.itemId || selectedItemForModifiers.id);
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to create group', 'error');
    }
  };

  const handleCreateModifierOption = async (groupId) => {
    const optForm = newOptionForms[groupId];
    if (!optForm || !optForm.name) return;
    try {
      const payload = {
        modifierGroupId: groupId,
        name: optForm.name,
        price: parseFloat(optForm.price) || 0,
        isAvailable: optForm.isAvailable !== false
      };
      await apiRequest('/api/v1/menu/modifier-options', 'POST', payload);
      if (showToast) showToast(`Option '${optForm.name}' added!`, 'success');
      setNewOptionForms(prev => ({ ...prev, [groupId]: { name: '', price: '0', isAvailable: true } }));
      fetchModifiersForItem(selectedItemForModifiers.itemId || selectedItemForModifiers.id);
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to create option', 'error');
    }
  };

  // Combo Management Logic
  const openComboModal = async (item) => {
    setSelectedItemForCombo(item);
    setShowComboModal(true);
    fetchComboComponents(item.itemId || item.id);
  };

  const fetchComboComponents = async (comboItemId) => {
    try {
      const res = await apiRequest(`/api/v1/menu/items/${comboItemId}/combo-components`).catch(() => []);
      setComboComponents(Array.isArray(res) ? res : []);
    } catch (err) {
      console.error('Error fetching combo components:', err);
    }
  };

  const handleAddComboComponent = async (e) => {
    e.preventDefault();
    if (!selectedItemForCombo || !comboForm.componentItemId) return;
    try {
      const payload = {
        comboItemId: selectedItemForCombo.itemId || selectedItemForCombo.id,
        componentItemId: comboForm.componentItemId,
        quantity: parseInt(comboForm.quantity) || 1
      };
      await apiRequest('/api/v1/menu/combo-components', 'POST', payload);
      if (showToast) showToast('Combo component attached!', 'success');
      setComboForm({ componentItemId: '', quantity: 1 });
      fetchComboComponents(selectedItemForCombo.itemId || selectedItemForCombo.id);
    } catch (err) {
      if (showToast) showToast(err.message || 'Failed to add combo component', 'error');
    }
  };

  // Filter items for display
  const filteredItems = menuItems.filter((item) => {
    const itemCatId = item.category?.categoryId || item.category?.id || item.categoryId;
    const itemCatName = item.category?.name || item.categoryName;
    const matchesCat = filterCategory === 'ALL' || 
                       itemCatId === filterCategory || 
                       itemCatName === filterCategory ||
                       (filterCategory === 'UNCATEGORIZED' && !itemCatId);

    let matchesTab = true;
    const isSpecial = Boolean(item.isSpecial ?? item.special);
    const isCombo = Boolean(item.isCombo ?? item.combo);
    const isAvailable = (item.isAvailable ?? item.available) !== false;
    const isVeg = (item.isVeg ?? item.veg) !== false;

    if (filterTab === 'SPECIALS') matchesTab = isSpecial;
    else if (filterTab === 'COMBOS') matchesTab = isCombo;
    else if (filterTab === 'OUT_OF_STOCK') matchesTab = !isAvailable;
    else if (filterTab === 'VEG') matchesTab = isVeg;
    else if (filterTab === 'NON_VEG') matchesTab = !isVeg;

    const matchesSearch = (item.name || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
                          (item.description || '').toLowerCase().includes(searchQuery.toLowerCase());

    return matchesCat && matchesTab && matchesSearch;
  });

  const getOutletName = (id) => {
    const o = outlets.find(x => (x.id === id || x.outletId === id));
    return o ? `${o.name} (${o.city || 'Default'})` : 'Main Outlet';
  };

  return (
    <div className="menu-catalog-container">
      {/* Top Header Toolbar */}
      <div className="card bg-surface border-custom shadow-sm p-3 mb-4">
        <div className="d-flex flex-wrap align-items-center justify-content-between gap-3">
          <div>
            <h5 className="fw-bold text-main m-0 d-flex align-items-center gap-2">
              <Utensils size={20} className="text-secondary-custom" />
              Menu Catalog & Digital QR Control
            </h5>
            <span className="text-muted-custom small">
              Manage live dishes, 86 stock status, combo components, modifiers, daily specials & QR menus
            </span>
          </div>

          <div className="d-flex flex-wrap gap-2">
            <button className="btn btn-outline-secondary touch-btn px-3" onClick={handlePushMasterMenu}>
              <Send size={15} className="me-1" /> Sync All Outlets
            </button>
            <button className="btn btn-outline-secondary touch-btn px-3" onClick={() => setShowCategoryModal(true)}>
              <Plus size={15} className="me-1" /> Category
            </button>
            <button className="btn btn-outline-secondary touch-btn px-3" onClick={() => setShowQrModal(true)}>
              <QrCode size={15} className="me-1 text-danger" /> Digital QR Menu
            </button>
            <button className="btn btn-secondary touch-btn px-3 fw-bold" onClick={openAddDishModal}>
              <Plus size={15} className="me-1" /> Add New Dish
            </button>
          </div>
        </div>

        <hr className="my-3 border-custom" />

        {/* Filter Controls Row */}
        <div className="row g-2 align-items-center">
          <div className="col-12 col-md-4">
            <div className="input-group">
              <span className="input-group-text bg-card-custom border-custom text-muted-custom">
                <Search size={16} />
              </span>
              <input
                type="text"
                className="form-control bg-card-custom border-custom text-main"
                placeholder="Search by dish name, description..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
            </div>
          </div>

          <div className="col-12 col-md-3">
            <div className="input-group">
              <span className="input-group-text bg-card-custom border-custom text-muted-custom small">
                <Clock size={14} className="me-1" /> Time Slot:
              </span>
              <input
                type="time"
                className="form-control bg-card-custom border-custom text-main small"
                value={timeFilter}
                onChange={(e) => handleTimeFilterQuery(e.target.value)}
              />
              {timeFilter && (
                <button className="btn btn-outline-secondary btn-sm" onClick={() => handleTimeFilterQuery('')}>
                  <X size={14} />
                </button>
              )}
            </div>
          </div>

          <div className="col-12 col-md-5 d-flex gap-1 overflow-auto pb-1">
            {[
              { id: 'ALL', label: 'All Items' },
              { id: 'SPECIALS', label: '★ Specials' },
              { id: 'COMBOS', label: 'Combos' },
              { id: 'OUT_OF_STOCK', label: '86\'d (Out of Stock)' },
              { id: 'VEG', label: 'Veg' },
              { id: 'NON_VEG', label: 'Non-Veg' },
            ].map((t) => (
              <button
                key={t.id}
                className={`btn btn-sm text-nowrap rounded-pill px-3 ${filterTab === t.id ? 'btn-secondary text-white fw-bold' : 'btn-outline-secondary text-main border-custom'}`}
                onClick={() => setFilterTab(t.id)}
              >
                {t.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Main Content Layout */}
      <div className="row g-4">
        {/* Left Sidebar: Categories Navigation */}
        <div className="col-12 col-lg-3">
          <div className="card bg-surface border-custom shadow-sm p-3 mb-3 sticky-top" style={{ top: '80px', zIndex: 10 }}>
            <div className="d-flex justify-content-between align-items-center mb-3">
              <h6 className="fw-bold text-main m-0">CATEGORIES</h6>
              <span className="badge bg-secondary-light text-secondary-custom small fw-bold">
                {categories.length} Total
              </span>
            </div>

            <div className="d-flex flex-column gap-1 max-vh-60 overflow-auto pe-1">
              <button
                className={`btn w-100 text-start d-flex justify-content-between align-items-center p-2 rounded-2 ${filterCategory === 'ALL' ? 'btn-secondary text-white fw-bold' : 'btn-outline-secondary border-custom text-main'}`}
                onClick={() => setFilterCategory('ALL')}
              >
                <span>All Categories</span>
                <span className="badge bg-card-custom text-main">{menuItems.length}</span>
              </button>
              {categories.map((c) => {
                const cId = c.categoryId || c.id;
                const count = menuItems.filter(i => {
                  const iCatId = i.category?.categoryId || i.category?.id || i.categoryId;
                  return iCatId === cId || i.category?.name === c.name;
                }).length;
                return (
                  <div key={cId} className="d-flex align-items-center gap-1">
                    <button
                      className={`btn w-100 text-start d-flex justify-content-between align-items-center p-2 rounded-2 ${filterCategory === cId ? 'btn-secondary text-white fw-bold' : 'btn-outline-secondary border-custom text-main'}`}
                      onClick={() => setFilterCategory(cId)}
                    >
                      <span className="text-truncate">{c.name}</span>
                      <span className="badge bg-card-custom text-main ms-1">{count}</span>
                    </button>
                    <button
                      className="btn btn-sm btn-outline-danger p-1 rounded-2"
                      onClick={() => handleDeleteCategory(cId, c.name)}
                      title={`Delete category '${c.name}'`}
                    >
                      <Trash2 size={13} />
                    </button>
                  </div>
                );
              })}
            </div>

            <button className="btn btn-outline-secondary w-100 touch-btn mt-3 border-custom text-main" onClick={() => setShowCategoryModal(true)}>
              + Add New Category
            </button>
          </div>
        </div>

        {/* Right Grid: Menu Items Display */}
        <div className="col-12 col-lg-9">
          {loading ? (
            <div className="text-center py-5">
              <div className="spinner-border text-danger" role="status"></div>
              <p className="text-muted-custom mt-2">Loading menu catalog...</p>
            </div>
          ) : filteredItems.length === 0 ? (
            <div className="card bg-surface border-custom p-5 text-center shadow-sm">
              <Utensils size={40} className="text-muted-custom mx-auto mb-3" />
              <h5 className="fw-bold text-main">No Menu Items Found</h5>
              <p className="text-muted-custom small">No dishes match your selected filters or search query.</p>
              <button className="btn btn-secondary touch-btn mx-auto fw-bold" onClick={openAddDishModal}>
                + Add First Dish
              </button>
            </div>
          ) : (
            <div className="row g-3">
              {filteredItems.map((item) => {
                const itemId = item.itemId || item.id;
                const catName = item.category?.name || categories.find(c => (c.categoryId || c.id) === item.categoryId)?.name || 'General';
                const isOut = (item.isAvailable ?? item.available) === false;
                const isVeg = (item.isVeg ?? item.veg) !== false;
                const isSpecial = Boolean(item.isSpecial ?? item.special);
                const isCombo = Boolean(item.isCombo ?? item.combo);

                return (
                  <div key={itemId} className="col-12 col-md-6 col-xl-4">
                    <div className={`card bg-surface border-custom shadow-sm h-100 overflow-hidden position-relative ${isOut ? 'opacity-75' : ''}`}>
                      {/* Top Badges overlay */}
                      <div className="position-absolute top-0 start-0 m-2 d-flex flex-column gap-1" style={{ zIndex: 5 }}>
                        <span className={`badge ${isVeg ? 'bg-success text-white' : 'bg-danger text-white'}`}>
                          {isVeg ? '● VEG' : '▲ NON-VEG'}
                        </span>
                        {isSpecial && (
                          <span className="badge bg-warning text-dark fw-bold d-flex align-items-center gap-1">
                            <Star size={10} fill="currentColor" /> SPECIAL
                          </span>
                        )}
                        {isCombo && (
                          <span className="badge bg-purple bg-primary text-white">
                            <Layers size={10} className="me-1" /> COMBO
                          </span>
                        )}
                      </div>

                      <div className="position-absolute top-0 end-0 m-2" style={{ zIndex: 5 }}>
                        <span className={`badge ${!isOut ? 'bg-success' : 'bg-danger'}`}>
                          {!isOut ? 'AVAILABLE' : '86\'D OUT'}
                        </span>
                      </div>

                      {/* Image */}
                      <img
                        src={item.imageUrl || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=400&q=80'}
                        alt={item.name}
                        className="card-img-top"
                        style={{ height: '150px', objectFit: 'cover' }}
                      />

                      {/* Content */}
                      <div className="card-body p-3 d-flex flex-column justify-content-between">
                        <div>
                          <div className="d-flex justify-content-between align-items-center mb-1">
                            <span className="text-muted-custom small fw-semibold">{catName}</span>
                            <span className="badge bg-card-custom text-muted-custom border border-custom small">
                              {item.foodType || 'MAIN'}
                            </span>
                          </div>

                          <h6 className="fw-bold text-main m-0 mb-1">{item.name}</h6>
                          <p className="text-muted-custom small mb-2 text-truncate-2" style={{ fontSize: '0.8rem', minHeight: '38px' }}>
                            {item.description || 'No description provided.'}
                          </p>

                          {/* Pricing Grid */}
                          <div className="p-2 bg-card-custom rounded-2 border border-custom mb-3">
                            <div className="d-flex justify-content-between align-items-center mb-1">
                              <span className="small text-muted-custom">Dine-in:</span>
                              <span className="fw-bold text-danger">₹{item.price ? Number(item.price).toFixed(2) : '0.00'}</span>
                            </div>
                            {(item.priceTakeaway || item.priceDelivery) && (
                              <div className="d-flex justify-content-between align-items-center small text-muted-custom border-top border-custom pt-1 mt-1">
                                {item.priceTakeaway && <span>Takeaway: ₹{Number(item.priceTakeaway).toFixed(2)}</span>}
                                {item.priceDelivery && <span>Delivery: ₹{Number(item.priceDelivery).toFixed(2)}</span>}
                              </div>
                            )}
                            {item.isSpecial && item.specialPrice && (
                              <div className="d-flex justify-content-between align-items-center small text-warning fw-bold border-top border-custom pt-1 mt-1">
                                <span>Special Offer Price:</span>
                                <span>₹{Number(item.specialPrice).toFixed(2)}</span>
                              </div>
                            )}
                          </div>

                          {/* Attributes Tags */}
                          <div className="d-flex flex-wrap gap-1 mb-3">
                            <span className="badge bg-surface border border-custom text-muted-custom small">GST: {item.gstRate || 5}%</span>
                            {item.hsnCode && <span className="badge bg-surface border border-custom text-muted-custom small">HSN: {item.hsnCode}</span>}
                            {item.calories && <span className="badge bg-surface border border-custom text-muted-custom small">{item.calories} kcal</span>}
                            {item.availableFrom && item.availableTo && (
                              <span className="badge bg-surface border border-custom text-muted-custom small">
                                {item.availableFrom.substring(0, 5)} - {item.availableTo.substring(0, 5)}
                              </span>
                            )}
                          </div>
                        </div>

                        {/* Actions Toolbar */}
                        <div className="pt-2 border-top border-custom d-flex flex-column gap-2">
                          <div className="d-flex justify-content-between align-items-center">
                            {/* Stock 86 Toggle */}
                            <button
                              className={`btn btn-sm ${isOut ? 'btn-success' : 'btn-outline-danger'} touch-btn py-1 px-2 text-xs`}
                              onClick={() => handleExplicit86(itemId, !isOut)}
                              title={isOut ? 'Restore Stock' : 'Mark 86 Out of Stock'}
                            >
                              {isOut ? <CheckCircle2 size={13} className="me-1" /> : <XCircle size={13} className="me-1" />}
                              {isOut ? 'In Stock' : '86 Stock'}
                            </button>

                            {/* Daily Special Star Toggle */}
                            <button
                              className={`btn btn-sm ${item.isSpecial ? 'btn-warning text-dark' : 'btn-outline-secondary'} touch-btn py-1 px-2 text-xs`}
                              onClick={() => openSpecialModal(item)}
                              title="Daily Special Toggle"
                            >
                              <Star size={13} className="me-1" fill={item.isSpecial ? 'currentColor' : 'none'} />
                              {item.isSpecial ? 'Special' : 'Mark Special'}
                            </button>
                          </div>

                          <div className="d-flex gap-1">
                            <button
                              className="btn btn-sm btn-outline-secondary flex-grow-1 touch-btn py-1 text-xs"
                              onClick={() => openModifiersModal(item)}
                            >
                              <Sliders size={13} className="me-1" /> Add-ons
                            </button>

                            {item.isCombo && (
                              <button
                                className="btn btn-sm btn-outline-secondary flex-grow-1 touch-btn py-1 text-xs"
                                onClick={() => openComboModal(item)}
                              >
                                <Layers size={13} className="me-1" /> Combo
                              </button>
                            )}

                            <button
                              className="btn btn-sm btn-secondary touch-btn py-1 px-3 text-xs fw-bold"
                              onClick={() => openEditDishModal(item)}
                            >
                              <Edit size={13} className="me-1" /> Edit
                            </button>

                            <button
                              className="btn btn-sm btn-outline-danger touch-btn py-1 px-2 text-xs"
                              onClick={() => handleDeleteDish(itemId, item.name)}
                              title={`Delete '${item.name}'`}
                            >
                              <Trash2 size={13} />
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* ========================================================= */}
      {/* MODAL 1: ADD / EDIT DISH FORM                              */}
      {/* ========================================================= */}
      {showDishModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered modal-lg">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">
                  {editingDishId ? 'Edit Menu Dish' : 'Create New Menu Dish'}
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowDishModal(false)}></button>
              </div>

              <form onSubmit={handleSaveDish}>
                <div className="modal-body max-vh-75 overflow-auto">
                  <div className="row g-3">
                    <div className="col-12 col-md-8">
                      <label className="form-label text-muted-custom small fw-semibold">Dish Name *</label>
                      <input
                        type="text"
                        className="form-control"
                        required
                        placeholder="e.g. Butter Chicken Special"
                        value={dishForm.name}
                        onChange={(e) => setDishForm({ ...dishForm, name: e.target.value })}
                      />
                    </div>

                    <div className="col-12 col-md-4">
                      <label className="form-label text-muted-custom small fw-semibold">Category *</label>
                      <select
                        className="form-select"
                        required
                        value={dishForm.categoryId}
                        onChange={(e) => setDishForm({ ...dishForm, categoryId: e.target.value })}
                      >
                        {categories.map((c) => (
                          <option key={c.categoryId || c.id} value={c.categoryId || c.id}>
                            {c.name}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="col-12">
                      <label className="form-label text-muted-custom small fw-semibold">Description</label>
                      <textarea
                        className="form-control"
                        rows="2"
                        placeholder="Detailed ingredients and culinary notes..."
                        value={dishForm.description}
                        onChange={(e) => setDishForm({ ...dishForm, description: e.target.value })}
                      ></textarea>
                    </div>

                    {/* Pricing Row */}
                    <div className="col-12 col-md-4">
                      <label className="form-label text-muted-custom small fw-semibold">Dine-in Price (₹) *</label>
                      <input
                        type="number"
                        step="0.01"
                        className="form-control"
                        required
                        placeholder="14.99"
                        value={dishForm.price}
                        onChange={(e) => setDishForm({ ...dishForm, price: e.target.value })}
                      />
                    </div>

                    <div className="col-12 col-md-4">
                      <label className="form-label text-muted-custom small fw-semibold">Takeaway Price (₹)</label>
                      <input
                        type="number"
                        step="0.01"
                        className="form-control"
                        placeholder="Optional"
                        value={dishForm.priceTakeaway}
                        onChange={(e) => setDishForm({ ...dishForm, priceTakeaway: e.target.value })}
                      />
                    </div>

                    <div className="col-12 col-md-4">
                      <label className="form-label text-muted-custom small fw-semibold">Delivery Price (₹)</label>
                      <input
                        type="number"
                        step="0.01"
                        className="form-control"
                        placeholder="Optional"
                        value={dishForm.priceDelivery}
                        onChange={(e) => setDishForm({ ...dishForm, priceDelivery: e.target.value })}
                      />
                    </div>

                    {/* Tax & Food Classification */}
                    <div className="col-12 col-md-3">
                      <label className="form-label text-muted-custom small fw-semibold">Food Type</label>
                      <select
                        className="form-select"
                        value={dishForm.foodType}
                        onChange={(e) => setDishForm({ ...dishForm, foodType: e.target.value })}
                      >
                        <option value="MAIN_COURSE">Main Course</option>
                        <option value="STARTER">Starter</option>
                        <option value="BEVERAGE">Beverage</option>
                        <option value="DESSERT">Dessert</option>
                        <option value="ALCOHOL">Alcohol</option>
                      </select>
                    </div>

                    <div className="col-12 col-md-3">
                      <label className="form-label text-muted-custom small fw-semibold">GST Rate (%)</label>
                      <input
                        type="number"
                        step="0.01"
                        className="form-control"
                        value={dishForm.gstRate}
                        onChange={(e) => setDishForm({ ...dishForm, gstRate: e.target.value })}
                      />
                    </div>

                    <div className="col-12 col-md-3">
                      <label className="form-label text-muted-custom small fw-semibold">HSN Code</label>
                      <input
                        type="text"
                        className="form-control"
                        value={dishForm.hsnCode}
                        onChange={(e) => setDishForm({ ...dishForm, hsnCode: e.target.value })}
                      />
                    </div>

                    <div className="col-12 col-md-3">
                      <label className="form-label text-muted-custom small fw-semibold">Kitchen Station</label>
                      <select
                        className="form-select"
                        value={dishForm.stationId}
                        onChange={(e) => setDishForm({ ...dishForm, stationId: e.target.value })}
                      >
                        <option value="">Default Station</option>
                        {stations.map((s) => (
                          <option key={s.stationId || s.id} value={s.stationId || s.id}>
                            {s.name}
                          </option>
                        ))}
                      </select>
                    </div>

                    {/* Time Slot Availability */}
                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Available From (Time Slot)</label>
                      <input
                        type="time"
                        className="form-control"
                        value={dishForm.availableFrom}
                        onChange={(e) => setDishForm({ ...dishForm, availableFrom: e.target.value })}
                      />
                    </div>

                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Available To (Time Slot)</label>
                      <input
                        type="time"
                        className="form-control"
                        value={dishForm.availableTo}
                        onChange={(e) => setDishForm({ ...dishForm, availableTo: e.target.value })}
                      />
                    </div>

                    {/* Nutrition & Image */}
                    <div className="col-12 col-md-4">
                      <label className="form-label text-muted-custom small fw-semibold">Calories (kcal)</label>
                      <input
                        type="number"
                        className="form-control"
                        placeholder="e.g. 450"
                        value={dishForm.calories}
                        onChange={(e) => setDishForm({ ...dishForm, calories: e.target.value })}
                      />
                    </div>

                    <div className="col-12 col-md-8">
                      <label className="form-label text-muted-custom small fw-semibold">Allergens</label>
                      <input
                        type="text"
                        className="form-control"
                        placeholder="e.g. Dairy, Nuts, Gluten"
                        value={dishForm.allergens}
                        onChange={(e) => setDishForm({ ...dishForm, allergens: e.target.value })}
                      />
                    </div>

                    <div className="col-12">
                      <label className="form-label text-muted-custom small fw-semibold">Image URL</label>
                      <input
                        type="text"
                        className="form-control"
                        placeholder="https://..."
                        value={dishForm.imageUrl}
                        onChange={(e) => setDishForm({ ...dishForm, imageUrl: e.target.value })}
                      />
                    </div>

                    {/* Toggles */}
                    <div className="col-12">
                      <div className="p-3 bg-card-custom rounded-3 border border-custom d-flex flex-wrap gap-4">
                        <div className="form-check form-switch">
                          <input
                            className="form-check-input"
                            type="checkbox"
                            id="isVegSwitch"
                            checked={dishForm.isVeg}
                            onChange={(e) => setDishForm({ ...dishForm, isVeg: e.target.checked })}
                          />
                          <label className="form-check-label text-main small fw-bold" htmlFor="isVegSwitch">
                            Vegetarian Dish
                          </label>
                        </div>

                        <div className="form-check form-switch">
                          <input
                            className="form-check-input"
                            type="checkbox"
                            id="isAvailableSwitch"
                            checked={dishForm.isAvailable}
                            onChange={(e) => setDishForm({ ...dishForm, isAvailable: e.target.checked })}
                          />
                          <label className="form-check-label text-main small fw-bold" htmlFor="isAvailableSwitch">
                            Active Stock Available
                          </label>
                        </div>

                        <div className="form-check form-switch">
                          <input
                            className="form-check-input"
                            type="checkbox"
                            id="isSpecialSwitch"
                            checked={dishForm.isSpecial}
                            onChange={(e) => setDishForm({ ...dishForm, isSpecial: e.target.checked })}
                          />
                          <label className="form-check-label text-main small fw-bold" htmlFor="isSpecialSwitch">
                            Chef's Daily Special
                          </label>
                        </div>

                        <div className="form-check form-switch">
                          <input
                            className="form-check-input"
                            type="checkbox"
                            id="isComboSwitch"
                            checked={dishForm.isCombo}
                            onChange={(e) => setDishForm({ ...dishForm, isCombo: e.target.checked })}
                          />
                          <label className="form-check-label text-main small fw-bold" htmlFor="isComboSwitch">
                            Combo Item (Multi-item meal)
                          </label>
                        </div>
                      </div>
                    </div>

                    {dishForm.isSpecial && (
                      <div className="col-12 col-md-6">
                        <label className="form-label text-warning small fw-bold">Special Promo Price (₹)</label>
                        <input
                          type="number"
                          step="0.01"
                          className="form-control border-warning"
                          placeholder="Discounted special price"
                          value={dishForm.specialPrice}
                          onChange={(e) => setDishForm({ ...dishForm, specialPrice: e.target.value })}
                        />
                      </div>
                    )}
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowDishModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    {editingDishId ? 'Save Changes' : 'Create Dish'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 2: ADD CATEGORY FORM                                 */}
      {/* ========================================================= */}
      {showCategoryModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main">Add New Category</h5>
                <button type="button" className="btn-close" onClick={() => setShowCategoryModal(false)}></button>
              </div>

              <form onSubmit={handleSaveCategory}>
                <div className="modal-body">
                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Category Name *</label>
                    <input
                      type="text"
                      className="form-control"
                      required
                      placeholder="e.g. Chef Specials, Artisan Breads..."
                      value={categoryForm.name}
                      onChange={(e) => setCategoryForm({ ...categoryForm, name: e.target.value })}
                    />
                  </div>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Parent Category (Optional)</label>
                    <select
                      className="form-select"
                      value={categoryForm.parentId}
                      onChange={(e) => setCategoryForm({ ...categoryForm, parentId: e.target.value })}
                    >
                      <option value="">None (Top Level Category)</option>
                      {categories.map((c) => (
                        <option key={c.categoryId || c.id} value={c.categoryId || c.id}>
                          {c.name}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowCategoryModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-secondary fw-bold px-4">
                    Create Category
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 3: DIGITAL MENU QR CODES PREVIEW                     */}
      {/* ========================================================= */}
      {showQrModal && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered text-center">
            <div className="modal-content bg-surface border-custom shadow-lg p-4">
              <h5 className="fw-bold text-main mb-1 d-flex align-items-center justify-content-center gap-2">
                <QrCode size={22} className="text-secondary-custom" />
                Contactless Digital Menu QR Code
              </h5>
              <p className="text-muted-custom small mb-3">
                Scannable QR standee linking customers to live digital menu
              </p>

              {outlets.length > 0 && (
                <div className="mb-3 text-start">
                  <label className="form-label text-muted-custom small fw-semibold">Select Outlet:</label>
                  <select
                    className="form-select border-custom"
                    value={qrOutletId}
                    onChange={(e) => setQrOutletId(e.target.value)}
                  >
                    {outlets.map((o) => (
                      <option key={o.id || o.outletId} value={o.id || o.outletId}>
                        {o.name} ({o.city || 'Store'})
                      </option>
                    ))}
                  </select>
                </div>
              )}

              <div className="p-3 bg-white d-inline-block mx-auto rounded-3 shadow-sm mb-3 border border-custom position-relative">
                <img
                  src={`/api/v1/menu/outlets/${qrOutletId || '11111111-1111-1111-1111-111111111111'}/qr`}
                  alt="Digital Menu QR"
                  style={{ width: '220px', height: '220px' }}
                />
              </div>

              <div className="p-2 bg-card-custom rounded-2 border border-custom small text-muted-custom mb-3 font-monospace">
                https://menu.restaurantpos.com/outlet/{qrOutletId || 'default'}
              </div>

              <div className="d-flex justify-content-center gap-2">
                <button className="btn btn-outline-secondary" onClick={() => setShowQrModal(false)}>
                  Close
                </button>
                <button
                  className="btn btn-outline-secondary"
                  onClick={() => {
                    navigator.clipboard.writeText(`https://menu.restaurantpos.com/outlet/${qrOutletId}`);
                    if (showToast) showToast('Digital menu URL copied!', 'info');
                  }}
                >
                  <Copy size={15} className="me-1" /> Copy Link
                </button>
                <button className="btn btn-outline-secondary" onClick={handleDownloadQr}>
                  <Download size={15} className="me-1" /> Download PNG
                </button>
                <button className="btn btn-secondary fw-bold" onClick={() => window.print()}>
                  <Printer size={15} className="me-1" /> Print QR Standee
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 4: MODIFIERS & ADD-ONS MANAGER                       */}
      {/* ========================================================= */}
      {showModifiersModal && selectedItemForModifiers && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered modal-lg">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main d-flex align-items-center gap-2">
                  <Sliders size={20} className="text-secondary-custom" />
                  Manage Add-ons & Modifiers for '{selectedItemForModifiers.name}'
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowModifiersModal(false)}></button>
              </div>

              <div className="modal-body max-vh-75 overflow-auto">
                {/* Existing Groups */}
                <h6 className="fw-bold text-main mb-3">Existing Modifier Groups</h6>
                {modifierGroups.length === 0 ? (
                  <p className="text-muted-custom small italic">No modifier groups configured for this dish yet.</p>
                ) : (
                  <div className="d-flex flex-column gap-3 mb-4">
                    {modifierGroups.map((group) => {
                      const gId = group.modifierGroupId || group.id;
                      const opts = groupOptionsMap[gId] || [];
                      const optForm = newOptionForms[gId] || { name: '', price: '0', isAvailable: true };

                      return (
                        <div key={gId} className="card bg-card-custom border-custom p-3">
                          <div className="d-flex justify-content-between align-items-center mb-2">
                            <div>
                              <span className="fw-bold text-main">{group.name}</span>
                              <span className="badge bg-surface text-muted-custom border border-custom ms-2">
                                {group.isMandatory ? 'Required' : 'Optional'} • Min {group.minSelections} / Max {group.maxSelections}
                              </span>
                            </div>
                          </div>

                          {/* Options List */}
                          <div className="d-flex flex-wrap gap-2 mb-3">
                            {opts.map((o) => (
                              <span key={o.modifierOptionId || o.id} className="badge bg-surface text-main border border-custom p-2 d-flex align-items-center gap-2">
                                <span>{o.name}</span>
                                <span className="fw-bold text-danger">+₹{Number(o.price).toFixed(2)}</span>
                              </span>
                            ))}
                          </div>

                          {/* Add Option Form */}
                          <div className="d-flex gap-2 align-items-center pt-2 border-top border-custom">
                            <input
                              type="text"
                              className="form-control form-control-sm bg-surface"
                              placeholder="Option name (e.g. Extra Cheese)"
                              value={optForm.name || ''}
                              onChange={(e) => setNewOptionForms({ ...newOptionForms, [gId]: { ...optForm, name: e.target.value } })}
                            />
                            <input
                              type="number"
                              step="0.01"
                              className="form-control form-control-sm bg-surface"
                              style={{ width: '100px' }}
                              placeholder="Extra ₹"
                              value={optForm.price || '0'}
                              onChange={(e) => setNewOptionForms({ ...newOptionForms, [gId]: { ...optForm, price: e.target.value } })}
                            />
                            <button className="btn btn-sm btn-secondary text-nowrap fw-bold" onClick={() => handleCreateModifierOption(gId)}>
                              + Add Option
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}

                <hr className="my-4 border-custom" />

                {/* Create New Modifier Group Form */}
                <h6 className="fw-bold text-main mb-3">+ Create New Modifier Group</h6>
                <form onSubmit={handleCreateModifierGroup} className="card bg-surface border-custom p-3">
                  <div className="row g-3">
                    <div className="col-12 col-md-6">
                      <label className="form-label text-muted-custom small fw-semibold">Group Name *</label>
                      <input
                        type="text"
                        className="form-control"
                        required
                        placeholder="e.g. Choice of Crust, Portion Size"
                        value={newGroupForm.name}
                        onChange={(e) => setNewGroupForm({ ...newGroupForm, name: e.target.value })}
                      />
                    </div>

                    <div className="col-6 col-md-3">
                      <label className="form-label text-muted-custom small fw-semibold">Min Selections</label>
                      <input
                        type="number"
                        className="form-control"
                        value={newGroupForm.minSelections}
                        onChange={(e) => setNewGroupForm({ ...newGroupForm, minSelections: e.target.value })}
                      />
                    </div>

                    <div className="col-6 col-md-3">
                      <label className="form-label text-muted-custom small fw-semibold">Max Selections</label>
                      <input
                        type="number"
                        className="form-control"
                        value={newGroupForm.maxSelections}
                        onChange={(e) => setNewGroupForm({ ...newGroupForm, maxSelections: e.target.value })}
                      />
                    </div>

                    <div className="col-12">
                      <div className="form-check form-switch">
                        <input
                          className="form-check-input"
                          type="checkbox"
                          id="mandatorySwitch"
                          checked={newGroupForm.isMandatory}
                          onChange={(e) => setNewGroupForm({ ...newGroupForm, isMandatory: e.target.checked })}
                        />
                        <label className="form-check-label text-main small fw-bold" htmlFor="mandatorySwitch">
                          Mandatory Selection (Customer must pick)
                        </label>
                      </div>
                    </div>
                  </div>

                  <button type="submit" className="btn btn-secondary touch-btn mt-3 fw-bold align-self-start">
                    Create Modifier Group
                  </button>
                </form>
              </div>

              <div className="modal-footer border-custom">
                <button type="button" className="btn btn-outline-secondary" onClick={() => setShowModifiersModal(false)}>
                  Done
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 5: COMBO COMPONENTS MANAGER                          */}
      {/* ========================================================= */}
      {showComboModal && selectedItemForCombo && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main d-flex align-items-center gap-2">
                  <Layers size={20} className="text-secondary-custom" />
                  Combo Items for '{selectedItemForCombo.name}'
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowComboModal(false)}></button>
              </div>

              <div className="modal-body">
                <h6 className="fw-bold text-main mb-2">Included Component Items</h6>
                {comboComponents.length === 0 ? (
                  <p className="text-muted-custom small">No component items attached to this combo yet.</p>
                ) : (
                  <ul className="list-group mb-4 border-custom">
                    {comboComponents.map((comp) => {
                      const linkedItem = menuItems.find(i => (i.itemId || i.id) === comp.componentItemId);
                      return (
                        <li key={comp.componentId || comp.id} className="list-group-item bg-card-custom border-custom d-flex justify-content-between align-items-center text-main">
                          <span>{linkedItem ? linkedItem.name : 'Sub-item'}</span>
                          <span className="badge bg-secondary text-white">x{comp.quantity}</span>
                        </li>
                      );
                    })}
                  </ul>
                )}

                <h6 className="fw-bold text-main mb-2">+ Add Component Dish</h6>
                <form onSubmit={handleAddComboComponent} className="d-flex gap-2">
                  <select
                    className="form-select"
                    required
                    value={comboForm.componentItemId}
                    onChange={(e) => setComboForm({ ...comboForm, componentItemId: e.target.value })}
                  >
                    <option value="">Select Dish...</option>
                    {menuItems
                      .filter(i => (i.itemId || i.id) !== (selectedItemForCombo.itemId || selectedItemForCombo.id))
                      .map((i) => (
                        <option key={i.itemId || i.id} value={i.itemId || i.id}>
                          {i.name} (₹{i.price})
                        </option>
                      ))}
                  </select>
                  <input
                    type="number"
                    min="1"
                    className="form-control"
                    style={{ width: '80px' }}
                    value={comboForm.quantity}
                    onChange={(e) => setComboForm({ ...comboForm, quantity: e.target.value })}
                  />
                  <button type="submit" className="btn btn-secondary text-nowrap fw-bold">
                    Add
                  </button>
                </form>
              </div>

              <div className="modal-footer border-custom">
                <button type="button" className="btn btn-outline-secondary" onClick={() => setShowComboModal(false)}>
                  Done
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================= */}
      {/* MODAL 6: DAILY SPECIAL TOGGLE & PRICE SETTER              */}
      {/* ========================================================= */}
      {showSpecialModal && specialTargetItem && (
        <div className="modal show d-block" tabIndex="-1" style={{ backgroundColor: 'rgba(0,0,0,0.6)', zIndex: 1050 }}>
          <div className="modal-dialog modal-dialog-centered">
            <div className="modal-content bg-surface border-custom shadow-lg">
              <div className="modal-header border-custom">
                <h5 className="modal-title fw-bold text-main d-flex align-items-center gap-2">
                  <Star size={20} className="text-warning" fill="currentColor" />
                  Set Chef's Daily Special
                </h5>
                <button type="button" className="btn-close" onClick={() => setShowSpecialModal(false)}></button>
              </div>

              <form onSubmit={handleSaveSpecial}>
                <div className="modal-body">
                  <p className="text-main">
                    Target Dish: <strong>{specialTargetItem.name}</strong>
                  </p>
                  <p className="text-muted-custom small mb-3">
                    Standard Dine-in Price: ₹{specialTargetItem.price}
                  </p>

                  <div className="mb-3">
                    <label className="form-label text-muted-custom small fw-semibold">Special Promotional Price (₹)</label>
                    <input
                      type="number"
                      step="0.01"
                      className="form-control border-warning"
                      required
                      value={specialFormPrice}
                      onChange={(e) => setSpecialFormPrice(e.target.value)}
                    />
                  </div>
                </div>

                <div className="modal-footer border-custom">
                  <button type="button" className="btn btn-outline-secondary" onClick={() => setShowSpecialModal(false)}>
                    Cancel
                  </button>
                  <button type="submit" className="btn btn-warning text-dark fw-bold px-4">
                    {specialTargetItem.isSpecial ? 'Remove from Specials' : 'Mark as Daily Special'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
