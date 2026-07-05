// Central catalog of permission "actions" used by the dynamic RBAC system.
// Each route in the backend maps to one (or more) of these action keys, and the
// frontend uses the same keys to show/hide navigation and action buttons.

export type ActionType = "view" | "action";

export interface ActionDef {
  key: string;
  label: string;
  group: string;
  type: ActionType;
}

export const ACTION_GROUPS = [
  "Billing Element",
  "Livery Agreements",
  "Master Data",
  "Stable Management",
  "Billing",
  "ERP",
  "Reports",
  "Administration",
  "Riding School",
  "Shared Resources",
] as const;

export const ACTIONS: ActionDef[] = [
  // Billing Element
  { key: "billing_elements.view", label: "View Billing Elements page", group: "Billing Element", type: "view" },
  { key: "billing_elements.manage", label: "Add / edit / delete billing elements", group: "Billing Element", type: "action" },

  // Livery Agreements
  { key: "agreements.view", label: "View Agreements pages", group: "Livery Agreements", type: "view" },
  { key: "agreements.create", label: "Create agreement", group: "Livery Agreements", type: "action" },
  { key: "agreements.edit", label: "Edit agreement", group: "Livery Agreements", type: "action" },
  { key: "agreements.cancel_checkout", label: "Cancel checkout", group: "Livery Agreements", type: "action" },
  { key: "agreements.documents", label: "Upload / delete agreement documents", group: "Livery Agreements", type: "action" },

  // Master Data
  { key: "customers.view", label: "View Customers page", group: "Master Data", type: "view" },
  { key: "customers.sync", label: "Sync customers from NetSuite", group: "Master Data", type: "action" },
  { key: "horses.view", label: "View Horses page", group: "Master Data", type: "view" },
  { key: "horses.create", label: "Create horse", group: "Master Data", type: "action" },
  { key: "horses.edit", label: "Edit horse", group: "Master Data", type: "action" },
  { key: "stables.view", label: "View Stables page", group: "Master Data", type: "view" },
  { key: "stables.manage", label: "Add / edit / delete stables", group: "Master Data", type: "action" },
  { key: "boxes.view", label: "View Boxes page", group: "Master Data", type: "view" },
  { key: "boxes.manage", label: "Add / edit / delete / import boxes", group: "Master Data", type: "action" },
  { key: "items.view", label: "View Items page", group: "Master Data", type: "view" },
  { key: "items.edit", label: "Edit item / change price", group: "Master Data", type: "action" },
  { key: "items.sync", label: "Sync items from NetSuite", group: "Master Data", type: "action" },

  // Stable Management
  { key: "movements.view", label: "View Horse Movements page", group: "Stable Management", type: "view" },
  { key: "movements.manage", label: "Move / swap / record horse movements", group: "Stable Management", type: "action" },
  { key: "ownership.manage", label: "Assign horse ownership", group: "Stable Management", type: "action" },

  // Billing
  { key: "to_invoice.view", label: "View To Invoice page", group: "Billing", type: "view" },
  { key: "approvals.vet", label: "Vet sign-off", group: "Billing", type: "action" },
  { key: "approvals.stores", label: "Stores sign-off", group: "Billing", type: "action" },
  { key: "invoices.view", label: "View Invoices page", group: "Billing", type: "view" },
  { key: "invoices.generate", label: "Generate invoice", group: "Billing", type: "action" },
  { key: "invoices.rollback", label: "Rollback invoice", group: "Billing", type: "action" },
  { key: "invoices.delete", label: "Delete invoice", group: "Billing", type: "action" },

  // ERP
  { key: "erp.generate_so", label: "Generate Sales Order", group: "ERP", type: "action" },
  { key: "erp.send_to_netsuite", label: "Send invoice to NetSuite", group: "ERP", type: "action" },

  // Reports
  { key: "reports.view", label: "View Reports page", group: "Reports", type: "view" },

  // Administration (each key gates both the page view and its management actions)
  { key: "admin.users", label: "Manage users", group: "Administration", type: "view" },
  { key: "admin.settings", label: "Manage settings", group: "Administration", type: "view" },
  { key: "admin.audit_logs", label: "View audit logs", group: "Administration", type: "view" },
  { key: "admin.roles", label: "Manage roles & permissions", group: "Administration", type: "view" },

  // Riding School
  { key: "riding_school.view", label: "View Riding School mode", group: "Riding School", type: "view" },
  { key: "riding_school.calendar.manage", label: "Schedule / edit / cancel lessons", group: "Riding School", type: "action" },
  { key: "riding_school.templates.manage", label: "Manage lesson templates", group: "Riding School", type: "action" },
  { key: "riding_school.packages.manage", label: "Manage riding packages", group: "Riding School", type: "action" },
  { key: "riding_school.settings.manage", label: "Manage riding school settings", group: "Riding School", type: "action" },
  { key: "riding_school.bookings.manage", label: "Manage bookings on behalf of customers", group: "Riding School", type: "action" },
  { key: "riding_school.horses.manage", label: "Assign riding school horses & record status", group: "Riding School", type: "action" },

  // Shared Resources
  { key: "shared_resources.view", label: "View Arenas / Instructors pages", group: "Shared Resources", type: "view" },
  { key: "shared_resources.instructors.manage", label: "Add / edit instructors", group: "Shared Resources", type: "action" },
  { key: "shared_resources.arenas.manage", label: "Add / edit arenas", group: "Shared Resources", type: "action" },
];

export const ACTION_KEYS = ACTIONS.map((a) => a.key);

export function isValidActionKey(key: string): boolean {
  return ACTION_KEYS.includes(key);
}

export interface SystemRoleDef {
  key: string;
  name: string;
  isAdmin: boolean;
}

export const SYSTEM_ROLES: SystemRoleDef[] = [
  { key: "ADMIN", name: "Administrator", isAdmin: true },
  { key: "LIVERY_ADMIN", name: "Livery Admin", isAdmin: false },
  { key: "VETERINARY", name: "Veterinary", isAdmin: false },
  { key: "STORES", name: "Stores", isAdmin: false },
  { key: "FINANCE", name: "Finance", isAdmin: false },
  { key: "VIEWER", name: "Viewer (read-only)", isAdmin: false },
  { key: "RIDING_SCHOOL_ADMIN", name: "Riding School Admin", isAdmin: false },
  // Deliberately zero default permissions: this role only grants Customer
  // Portal access (via requireCustomer), never any staff action/view. A user
  // can hold this alongside any staff role (see DEFAULT_ROLE_PERMISSIONS note).
  { key: "CUSTOMER", name: "Customer", isAdmin: false },
  // Deliberately zero default permissions too — holding this role is what
  // instantiates/retires the user's row in the `instructors` table (see
  // DatabaseStorage.syncInstructorForUser), it doesn't grant any staff
  // action on its own. Combine with a staff role (e.g. RIDING_SCHOOL_ADMIN)
  // if the instructor also needs to manage the schedule themselves.
  { key: "INSTRUCTOR", name: "Instructor", isAdmin: false },
];

// View actions that every non-admin operational role gets by default.
const ALL_OPERATIONAL_VIEWS = [
  "billing_elements.view",
  "agreements.view",
  "customers.view",
  "horses.view",
  "stables.view",
  "boxes.view",
  "items.view",
  "movements.view",
  "to_invoice.view",
  "invoices.view",
  "reports.view",
];

// Default permissions per system role, replicating the previous hardcoded RBAC.
// ADMIN is omitted because isAdmin grants everything.
export const DEFAULT_ROLE_PERMISSIONS: Record<string, string[]> = {
  LIVERY_ADMIN: [
    ...ALL_OPERATIONAL_VIEWS,
    "billing_elements.manage",
    "agreements.create",
    "agreements.edit",
    "agreements.cancel_checkout",
    "agreements.documents",
    "customers.sync",
    "horses.create",
    "horses.edit",
    "items.edit",
    "items.sync",
    "movements.manage",
    "ownership.manage",
    "invoices.generate",
    "invoices.rollback",
  ],
  VETERINARY: [
    ...ALL_OPERATIONAL_VIEWS,
    "horses.create",
    "approvals.vet",
    "billing_elements.manage",
    "customers.sync",
    "items.sync",
  ],
  STORES: [
    ...ALL_OPERATIONAL_VIEWS,
    "approvals.stores",
    "billing_elements.manage",
    "customers.sync",
    "items.sync",
  ],
  FINANCE: [
    ...ALL_OPERATIONAL_VIEWS,
    "erp.generate_so",
    "erp.send_to_netsuite",
    "billing_elements.manage",
    "customers.sync",
    "items.sync",
  ],
  VIEWER: [
    ...ALL_OPERATIONAL_VIEWS,
  ],
  RIDING_SCHOOL_ADMIN: [
    // The riding-school nav already links to Customers (customers.view) and
    // Horse Management (fetches /api/horses, horses.view) — grant both so
    // those pages actually load for a Riding School Admin who isn't also
    // ADMIN/LIVERY_ADMIN. Also needed for the calendar's Horses/Customers
    // resource-axis tabs.
    "customers.view",
    "horses.view",
    "riding_school.view",
    "riding_school.calendar.manage",
    "riding_school.templates.manage",
    "riding_school.packages.manage",
    "riding_school.settings.manage",
    "riding_school.bookings.manage",
    "riding_school.horses.manage",
    "shared_resources.view",
    "shared_resources.instructors.manage",
    "shared_resources.arenas.manage",
  ],
};
