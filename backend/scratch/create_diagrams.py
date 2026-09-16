import os
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from PIL import Image, ImageDraw, ImageFont

os.makedirs('scratch/assets', exist_ok=True)

# -------------------------------------------------------------
# 1. FIG 4.1: USE CASE DIAGRAM
# -------------------------------------------------------------
def create_use_case_diagram():
    fig, ax = plt.subplots(figsize=(7, 10), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis('off')

    # System boundary
    rect = patches.FancyBboxPatch((28, 4), 44, 91, boxstyle="round,pad=1.5",
                                  facecolor='#F8FAFC', edgecolor='#1E3A8A', linewidth=2)
    ax.add_patch(rect)
    ax.text(50, 92, "Restaurant POS & Order Management System", fontsize=11, fontweight='bold',
            color='#1E3A8A', ha='center', va='center')

    # Use cases
    use_cases = [
        (50, 84, "User Auth & PIN Login"),
        (50, 74, "Manage Floor & Tables"),
        (50, 64, "Take Table Order & KOT"),
        (50, 54, "Kitchen Display (KDS)"),
        (50, 44, "Process Split Billing"),
        (50, 34, "Inventory & Recipes"),
        (50, 24, "Dispatch Delivery & Route"),
        (50, 14, "Reports & Sales Analytics")
    ]

    uc_patches = []
    for x, y, text in use_cases:
        ellipse = patches.Ellipse((x, y), 38, 6.5, facecolor='#EFF6FF', edgecolor='#2563EB', linewidth=1.5)
        ax.add_patch(ellipse)
        ax.text(x, y, text, fontsize=9.5, fontweight='bold', color='#1E293B', ha='center', va='center')
        uc_patches.append((x, y))

    # Actors Left
    actors_left = [
        (12, 75, "Waiter / Floor Staff"),
        (12, 54, "Kitchen Staff / Chef"),
        (12, 35, "Cashier")
    ]

    # Actors Right
    actors_right = [
        (88, 75, "Restaurant Admin"),
        (88, 54, "Restaurant Manager"),
        (88, 30, "Delivery Partner")
    ]

    def draw_actor(x, y, name):
        # Head
        head = patches.Circle((x, y+3.5), 1.8, facecolor='#E2E8F0', edgecolor='#0F172A', linewidth=1.5)
        ax.add_patch(head)
        # Body
        ax.plot([x, x], [y+1.7, y-1.5], color='#0F172A', linewidth=1.8)
        # Arms
        ax.plot([x-2.2, x+2.2], [y+0.5, y+0.5], color='#0F172A', linewidth=1.8)
        # Legs
        ax.plot([x, x-1.8], [y-1.5, y-4.5], color='#0F172A', linewidth=1.8)
        ax.plot([x, x+1.8], [y-1.5, y-4.5], color='#0F172A', linewidth=1.8)
        # Label
        ax.text(x, y-6.5, name, fontsize=8, fontweight='bold', color='#0F172A', ha='center', va='top')

    for x, y, name in actors_left:
        draw_actor(x, y, name)

    for x, y, name in actors_right:
        draw_actor(x, y, name)

    # Connections Left
    # Waiter -> Login (0), Floor (1), Order (2)
    for idx in [0, 1, 2]:
        ax.plot([14, 31], [75, use_cases[idx][1]], color='#64748B', linewidth=1, linestyle='-')
    # Kitchen -> Login (0), KDS (3)
    for idx in [0, 3]:
        ax.plot([14, 31], [54, use_cases[idx][1]], color='#64748B', linewidth=1, linestyle='-')
    # Cashier -> Login (0), Billing (4)
    for idx in [0, 4]:
        ax.plot([14, 31], [35, use_cases[idx][1]], color='#64748B', linewidth=1, linestyle='-')

    # Connections Right
    # Admin -> Login (0), Floor (1), Inventory (5), Reports (7)
    for idx in [0, 1, 5, 7]:
        ax.plot([86, 69], [75, use_cases[idx][1]], color='#64748B', linewidth=1, linestyle='-')
    # Manager -> Login (0), Order (2), Inventory (5), Reports (7)
    for idx in [0, 2, 5, 7]:
        ax.plot([86, 69], [54, use_cases[idx][1]], color='#64748B', linewidth=1, linestyle='-')
    # Delivery -> Login (0), Delivery (6)
    for idx in [0, 6]:
        ax.plot([86, 69], [30, use_cases[idx][1]], color='#64748B', linewidth=1, linestyle='-')

    plt.tight_layout()
    plt.savefig('scratch/assets/fig4_1_use_case.png', bbox_inches='tight', dpi=300)
    plt.close()
    print("Created fig4_1_use_case.png")

# -------------------------------------------------------------
# 2. FIG 4.2: SEQUENCE DIAGRAM
# -------------------------------------------------------------
def create_sequence_diagram():
    fig, ax = plt.subplots(figsize=(10, 7), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis('off')

    lifelines = [
        (10, "Waiter / Customer"),
        (26, "POS Web Client"),
        (44, "Backend API / OrderCtrl"),
        (62, "WebSocket Broker"),
        (80, "Kitchen Display (KDS)"),
        (94, "PostgreSQL DB")
    ]

    # Draw headers & lifelines
    for x, label in lifelines:
        box = patches.FancyBboxPatch((x-6.5, 90), 13, 6, boxstyle="round,pad=0.5",
                                     facecolor='#1E3A8A', edgecolor='#0F172A', linewidth=1)
        ax.add_patch(box)
        ax.text(x, 93, label, fontsize=8, fontweight='bold', color='white', ha='center', va='center')
        ax.plot([x, x], [89, 8], color='#94A3B8', linestyle='--', linewidth=1.2)

        # bottom box
        box_bot = patches.FancyBboxPatch((x-6.5, 2), 13, 5, boxstyle="round,pad=0.5",
                                         facecolor='#E2E8F0', edgecolor='#64748B', linewidth=1)
        ax.add_patch(box_bot)
        ax.text(x, 4.5, label, fontsize=7.5, fontweight='bold', color='#1E293B', ha='center', va='center')

    # Sequence messages (y, from_x, to_x, label, is_response)
    steps = [
        (83, 10, 26, "1. Select Menu Items & Submit Order", False),
        (76, 26, 44, "2. POST /api/orders (JWT Auth)", False),
        (69, 44, 94, "3. validateStockAndSaveOrder()", False),
        (62, 94, 44, "4. Order Saved (Status: PENDING)", True),
        (55, 44, 62, "5. publishEvent('/topic/kitchen')", False),
        (48, 62, 80, "6. WS push: New KOT Ticket (Chime)", False),
        (41, 80, 44, "7. PATCH /api/orders/{id}/status (PREPARING)", False),
        (34, 80, 44, "8. PATCH /api/orders/{id}/status (READY)", False),
        (27, 44, 62, "9. broadcastStatusUpdate('/topic/orders')", False),
        (20, 62, 26, "10. WS push: Order Ready Notification", False),
        (14, 26, 10, "11. Serve Order & Display Table Bill", True)
    ]

    for y, x1, x2, text, is_resp in steps:
        style = '--' if is_resp else '-'
        color = '#0D9488' if is_resp else '#2563EB'
        ax.annotate('', xy=(x2, y), xytext=(x1, y),
                    arrowprops=dict(arrowstyle="->", color=color, lw=1.3, linestyle=style))
        mid_x = (x1 + x2) / 2
        ax.text(mid_x, y + 1.6, text, fontsize=7.5, fontweight='bold', color='#1E293B',
                ha='center', va='bottom', bbox=dict(boxstyle='round,pad=0.2', facecolor='white', alpha=0.9, edgecolor='none'))

    plt.tight_layout()
    plt.savefig('scratch/assets/fig4_2_sequence.png', bbox_inches='tight', dpi=300)
    plt.close()
    print("Created fig4_2_sequence.png")

# -------------------------------------------------------------
# 3. FIG 4.3: DATA FLOW DIAGRAM (DFD LEVEL 1)
# -------------------------------------------------------------
def create_dfd_diagram():
    fig, ax = plt.subplots(figsize=(7, 10), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis('off')

    # Entities
    entities = [
        (15, 90, "Waiter / Floor Staff"),
        (85, 90, "Kitchen Chef"),
        (15, 45, "Cashier"),
        (85, 45, "Admin / Manager")
    ]

    for x, y, text in entities:
        box = patches.FancyBboxPatch((x-12, y-3.5), 24, 7, boxstyle="square,pad=0",
                                     facecolor='#FEF3C7', edgecolor='#D97706', linewidth=1.5)
        ax.add_patch(box)
        ax.text(x, y, text, fontsize=8.5, fontweight='bold', color='#92400E', ha='center', va='center')

    # Processes (Circles)
    processes = [
        (50, 85, "1.0\nOrder Entry\n& KOT", 7.5),
        (50, 65, "2.0\nKitchen Queue\n& Prep", 7.5),
        (50, 45, "3.0\nBill & Split\nPayment", 7.5),
        (50, 25, "4.0\nInventory &\nStock Sync", 7.5),
        (50, 8, "5.0\nSales Analytics\n& Reports", 7.5)
    ]

    for x, y, text, r in processes:
        circle = patches.Circle((x, y), r, facecolor='#EFF6FF', edgecolor='#2563EB', linewidth=1.8)
        ax.add_patch(circle)
        ax.text(x, y, text, fontsize=8, fontweight='bold', color='#1E3A8A', ha='center', va='center')

    # Data Stores (Open rects)
    stores = [
        (15, 65, "D1: Orders & Items"),
        (85, 65, "D2: KDS Queue"),
        (15, 18, "D3: Bills & Payments"),
        (85, 18, "D4: Inventory Master")
    ]

    for x, y, text in stores:
        # draw two parallel lines for data store
        ax.plot([x-13, x+13], [y+3, y+3], color='#047857', linewidth=1.5)
        ax.plot([x-13, x+13], [y-3, y-3], color='#047857', linewidth=1.5)
        rect = patches.Rectangle((x-13, y-3), 26, 6, facecolor='#ECFDF5', alpha=0.5)
        ax.add_patch(rect)
        ax.text(x, y, text, fontsize=7.5, fontweight='bold', color='#065F46', ha='center', va='center')

    # Flow arrows
    flows = [
        ((25, 87), (42, 85), "Order Details"),
        ((50, 77), (50, 73), "Dispatch KOT"),
        ((42, 85), (25, 68), "Record Order"),
        ((58, 65), (72, 65), "Update State"),
        ((75, 87), (58, 68), "Ready Signal"),
        ((25, 45), (42, 45), "Payment Request"),
        ((42, 45), (25, 21), "Save Payment"),
        ((50, 37), (50, 33), "Deduct Stock"),
        ((58, 25), (72, 21), "Stock Levels"),
        ((50, 17), (50, 15.5), "Daily Aggregates"),
        ((85, 41), (58, 11), "Generate Reports")
    ]

    for start, end, label in flows:
        ax.annotate('', xy=end, xytext=start,
                    arrowprops=dict(arrowstyle="->", color='#475569', lw=1.2))

    plt.tight_layout()
    plt.savefig('scratch/assets/fig4_3_dfd.png', bbox_inches='tight', dpi=300)
    plt.close()
    print("Created fig4_3_dfd.png")

# -------------------------------------------------------------
# 4. FIG 5.1 & 5.2: CODE SNIPPETS
# -------------------------------------------------------------
def create_code_image(title, code_lines, filename, width=1000, height=520):
    img = Image.new('RGB', (width, height), color='#1E1E2E')
    draw = ImageDraw.Draw(img)

    # Window title bar
    draw.rectangle([(0, 0), (width, 42)], fill='#181825')
    # Dots
    draw.ellipse([(14, 15), (26, 27)], fill='#F38BA8')
    draw.ellipse([(34, 15), (46, 27)], fill='#F9E2AF')
    draw.ellipse([(54, 15), (66, 27)], fill='#A6E3A1')

    # Title
    try:
        font_title = ImageFont.truetype("arial.ttf", 15)
        font_code = ImageFont.truetype("consola.ttf", 15)
    except:
        font_title = font_code = ImageFont.load_default()

    draw.text((80, 13), title, fill='#CDD6F4', font=font_title)

    # Code lines
    y = 60
    for idx, (line, color) in enumerate(code_lines, 1):
        num_str = f"{idx:2d}  "
        draw.text((20, y), num_str, fill='#585B70', font=font_code)
        draw.text((65, y), line, fill=color, font=font_code)
        y += 24

    img.save(filename)
    print(f"Created {filename}")

code_token_storage = [
    ("// authService.js - Restaurant POS Session Management", "#6C7086"),
    ("import { apiRequest } from './apiClient';", "#F38BA8"),
    ("", "#CDD6F4"),
    ("export async function loginWithEmail(email, password) {", "#89B4FA"),
    ("  const data = await apiRequest('/api/auth/login', 'POST', {", "#CDD6F4"),
    ("    username: email, email, password", "#FAB387"),
    ("  });", "#CDD6F4"),
    ("  if (data && data.token) {", "#F9E2AF"),
    ("    saveSession(data.token, data.role, data.username);", "#A6E3A1"),
    ("  }", "#CDD6F4"),
    ("  return data;", "#F38BA8"),
    ("}", "#89B4FA"),
    ("", "#CDD6F4"),
    ("export function saveSession(token, role, username) {", "#89B4FA"),
    ("  localStorage.setItem('pos_jwt_token', token);", "#A6E3A1"),
    ("  localStorage.setItem('pos_user_role', role);", "#A6E3A1"),
    ("  localStorage.setItem('pos_username', username);", "#A6E3A1"),
    ("}", "#89B4FA")
]

code_bearer_auth = [
    ("// apiClient.js - Centralized HTTP Client with JWT Interceptor", "#6C7086"),
    ("export async function apiRequest(url, method = 'GET', body = null) {", "#89B4FA"),
    ("  const headers = { 'Content-Type': 'application/json' };", "#CDD6F4"),
    ("  const token = localStorage.getItem('pos_jwt_token');", "#FAB387"),
    ("", "#CDD6F4"),
    ("  if (token) {", "#F9E2AF"),
    ("    headers['Authorization'] = `Bearer ${token}`;", "#A6E3A1"),
    ("  }", "#CDD6F4"),
    ("", "#CDD6F4"),
    ("  const res = await fetch(url, {", "#CDD6F4"),
    ("    method,", "#FAB387"),
    ("    headers,", "#FAB387"),
    ("    body: body ? JSON.stringify(body) : null", "#FAB387"),
    ("  });", "#CDD6F4"),
    ("  if (res.status === 401) {", "#F9E2AF"),
    ("    localStorage.removeItem('pos_jwt_token');", "#F38BA8"),
    ("    window.location.href = '/login';", "#F38BA8"),
    ("  }", "#CDD6F4"),
    ("  return await res.json();", "#F38BA8"),
    ("}", "#89B4FA")
]

# -------------------------------------------------------------
# 5. FIG 5.3 & 5.4: TEST CASE UI CARDS
# -------------------------------------------------------------
def create_test_case_1_card():
    img = Image.new('RGB', (1000, 480), color='#0F172A')
    draw = ImageDraw.Draw(img)

    # Card
    draw.rounded_rectangle([(250, 40), (750, 440)], radius=16, fill='#1E293B', outline='#334155', width=2)

    try:
        font_h1 = ImageFont.truetype("arial.ttf", 22)
        font_p = ImageFont.truetype("arial.ttf", 14)
        font_btn = ImageFont.truetype("arial.ttf", 16)
    except:
        font_h1 = font_p = font_btn = ImageFont.load_default()

    draw.text((500, 80), "Staff Quick PIN Login", fill='#F8FAFC', font=font_h1, anchor="mm")
    draw.text((500, 115), "Enter your 4-digit staff terminal access code", fill='#94A3B8', font=font_p, anchor="mm")

    # Error alert box
    draw.rounded_rectangle([(280, 145), (720, 195)], radius=8, fill='#450A0A', outline='#EF4444', width=1)
    draw.text((500, 170), "(!) Error: Invalid Staff PIN. Please re-enter credentials.", fill='#FCA5A5', font=font_p, anchor="mm")

    # PIN circles
    cx = 380
    for _ in range(4):
        draw.ellipse([(cx, 225), (cx+25, 250)], fill='#38BDF8', outline='#0284C7', width=2)
        cx += 65

    # Button
    draw.rounded_rectangle([(320, 290), (680, 345)], radius=10, fill='#DC2626')
    draw.text((500, 317), "Login to POS Terminal", fill='white', font=font_btn, anchor="mm")

    draw.text((500, 385), "Role Assigned: Floor Waiter / Cashier", fill='#64748B', font=font_p, anchor="mm")

    img.save('scratch/assets/fig5_3_test_case1.png')
    print("Created fig5_3_test_case1.png")

def create_test_case_2_card():
    img = Image.new('RGB', (1000, 480), color='#0F172A')
    draw = ImageDraw.Draw(img)

    # Card
    draw.rounded_rectangle([(250, 40), (750, 440)], radius=16, fill='#1E293B', outline='#10B981', width=2)

    try:
        font_h1 = ImageFont.truetype("arial.ttf", 22)
        font_p = ImageFont.truetype("arial.ttf", 14)
        font_bold = ImageFont.truetype("arial.ttf", 15)
        font_btn = ImageFont.truetype("arial.ttf", 16)
    except:
        font_h1 = font_p = font_bold = font_btn = ImageFont.load_default()

    # Success checkmark circle
    draw.ellipse([(470, 70), (530, 130)], fill='#065F46', outline='#10B981', width=2)
    draw.text((500, 100), "OK", fill='#34D399', font=font_h1, anchor="mm")

    draw.text((500, 155), "Order Dispatched to Kitchen!", fill='#F8FAFC', font=font_h1, anchor="mm")
    draw.text((500, 185), "Order #ORD-2025-0842 dispatched via WebSocket", fill='#94A3B8', font=font_p, anchor="mm")

    # Details
    details = [
        ("Table / Section:", "Table T-04 (Main Dining Hall)"),
        ("Server / Waiter:", "Alex Morgan (Staff ID: ST-102)"),
        ("Ordered Items:", "2x Grilled Salmon, 1x Truffle Pasta"),
        ("Total Bill Amount:", "$68.50 (Taxes & Service Included)"),
        ("Live KOT Status:", "SENT TO KDS (Station 1: Hot Line)")
    ]

    y = 220
    for label, val in details:
        draw.text((300, y), label, fill='#94A3B8', font=font_p)
        draw.text((450, y), val, fill='#38BDF8' if 'KDS' in val else '#F1F5F9', font=font_bold)
        y += 24

    # Button
    draw.rounded_rectangle([(320, 365), (680, 415)], radius=10, fill='#059669')
    draw.text((500, 390), "View Table & Kitchen Status", fill='white', font=font_btn, anchor="mm")

    img.save('scratch/assets/fig5_4_test_case2.png')
    print("Created fig5_4_test_case2.png")

create_use_case_diagram()
create_sequence_diagram()
create_dfd_diagram()
create_code_image("Storing Token in Local Storage - authService.js", code_token_storage, 'scratch/assets/fig5_1_token_storage.png')
create_code_image("Authenticating User using Bearer Token - apiClient.js", code_bearer_auth, 'scratch/assets/fig5_2_bearer_auth.png')
create_test_case_1_card()
create_test_case_2_card()
print("All diagram assets generated successfully!")
