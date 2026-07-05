import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { SearchableSelect } from "@/components/ui/searchable-select";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, Pencil } from "lucide-react";
import { StatusBadge } from "@/components/status-badge";
import type { Customer } from "@shared/schema";

interface RoleOption {
  key: string;
  name: string;
}

interface UserRow {
  id: string;
  username: string;
  roles: string[];
  customerId: string | null;
}

function RoleCheckboxList({
  roles,
  selected,
  onToggle,
  idPrefix,
}: {
  roles: RoleOption[];
  selected: string[];
  onToggle: (key: string) => void;
  idPrefix: string;
}) {
  return (
    <div className="space-y-2 max-h-56 overflow-y-auto border rounded-md p-3">
      {roles.map((role) => (
        <div key={role.key} className="flex items-center gap-2">
          <Checkbox
            id={`${idPrefix}-${role.key}`}
            checked={selected.includes(role.key)}
            onCheckedChange={() => onToggle(role.key)}
            data-testid={`checkbox-role-${role.key}`}
          />
          <Label htmlFor={`${idPrefix}-${role.key}`} className="font-normal cursor-pointer">
            {role.name}
          </Label>
        </div>
      ))}
    </div>
  );
}

export default function AdminUsersPage() {
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [editingUser, setEditingUser] = useState<UserRow | null>(null);
  const [newRoles, setNewRoles] = useState<string[]>([]);
  const [newCustomerId, setNewCustomerId] = useState<string>("");
  const [editRoles, setEditRoles] = useState<string[]>([]);
  const [editCustomerId, setEditCustomerId] = useState<string>("");
  const { toast } = useToast();

  const { data: users = [], isLoading } = useQuery<UserRow[]>({
    queryKey: ["/api/users"],
  });

  const { data: roles = [] } = useQuery<RoleOption[]>({
    queryKey: ["/api/roles"],
  });

  const { data: customers = [] } = useQuery<Customer[]>({
    queryKey: ["/api/customers"],
  });

  const roleLabels: Record<string, string> = Object.fromEntries(
    roles.map((r) => [r.key, r.name])
  );

  const resetCreateForm = () => {
    setNewRoles([]);
    setNewCustomerId("");
  };

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/users", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/users"] });
      setShowCreateDialog(false);
      resetCreateForm();
      toast({ title: "User created successfully" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to create user", description: error.message, variant: "destructive" });
    },
  });

  const updateUserMutation = useMutation({
    mutationFn: ({ id, roleKeys, customerId, password }: { id: string; roleKeys: string[]; customerId?: string; password?: string }) => {
      const body: any = { roleKeys };
      if (roleKeys.includes("CUSTOMER")) body.customerId = customerId;
      if (password) body.password = password;
      return apiRequest("PATCH", `/api/users/${id}`, body);
    },
    onSuccess: (_data, vars) => {
      queryClient.invalidateQueries({ queryKey: ["/api/users"] });
      setEditingUser(null);
      toast({ title: vars.password ? "User updated and password reset" : "User roles updated" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to update user", description: error.message, variant: "destructive" });
    },
  });

  const toggleNewRole = (key: string) => {
    setNewRoles((prev) => (prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key]));
  };

  const toggleEditRole = (key: string) => {
    setEditRoles((prev) => (prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key]));
  };

  const columns = [
    { key: "username", label: "Username" },
    {
      key: "roles",
      label: "Roles",
      render: (item: UserRow) => (
        <div className="flex flex-wrap gap-1">
          {item.roles.map((r) => (
            <StatusBadge key={r} status={roleLabels[r] || r} />
          ))}
        </div>
      ),
    },
    { key: "id", label: "User ID", render: (item: UserRow) => item.id.substring(0, 8) + "..." },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Users"
        description="Manage system users and roles"
        actions={
          <Button
            onClick={() => {
              resetCreateForm();
              setShowCreateDialog(true);
            }}
            data-testid="button-new-user"
          >
            <Plus className="w-4 h-4 mr-2" />
            New User
          </Button>
        }
      />

      <DataTable
        columns={columns}
        data={users}
        isLoading={isLoading}
        actions={(item) => (
          <Button
            size="sm"
            variant="outline"
            onClick={() => {
              setEditingUser(item);
              setEditRoles(item.roles);
              setEditCustomerId(item.customerId || "");
            }}
            data-testid={`button-edit-user-${item.id}`}
          >
            <Pencil className="w-4 h-4" />
          </Button>
        )}
      />

      <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>New User</DialogTitle>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({
                username: fd.get("username"),
                password: fd.get("password"),
                roleKeys: newRoles,
                customerId: newRoles.includes("CUSTOMER") ? newCustomerId : undefined,
              });
            }}
          >
            <div className="space-y-4">
              <div>
                <Label>Username</Label>
                <Input name="username" required data-testid="input-new-username" />
              </div>
              <div>
                <Label>Password</Label>
                <Input name="password" type="password" required data-testid="input-new-password" />
              </div>
              <div>
                <Label>Roles</Label>
                <p className="text-xs text-muted-foreground mb-2">
                  A user can hold multiple roles — e.g. an admin who also wants the Customer
                  Portal view.
                </p>
                <RoleCheckboxList roles={roles} selected={newRoles} onToggle={toggleNewRole} idPrefix="new" />
              </div>
              {newRoles.includes("CUSTOMER") && (
                <div>
                  <Label>Linked Customer</Label>
                  <SearchableSelect
                    value={newCustomerId}
                    onValueChange={setNewCustomerId}
                    options={customers.map((c) => ({ value: c.id, label: c.fullname }))}
                    placeholder="Select a customer..."
                    searchPlaceholder="Search customers..."
                    testId="select-new-customer"
                  />
                </div>
              )}
            </div>
            <DialogFooter className="mt-4">
              <Button
                type="submit"
                disabled={createMutation.isPending || newRoles.length === 0}
                data-testid="button-submit-user"
              >
                Create User
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={!!editingUser} onOpenChange={() => setEditingUser(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit User</DialogTitle>
          </DialogHeader>
          {editingUser && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                const password = (fd.get("password") as string)?.trim();
                updateUserMutation.mutate({
                  id: editingUser.id,
                  roleKeys: editRoles,
                  customerId: editRoles.includes("CUSTOMER") ? editCustomerId : undefined,
                  password: password || undefined,
                });
              }}
            >
              <div className="space-y-4">
                <div>
                  <Label>Username</Label>
                  <Input value={editingUser.username} disabled />
                </div>
                <div>
                  <Label>Roles</Label>
                  <RoleCheckboxList roles={roles} selected={editRoles} onToggle={toggleEditRole} idPrefix="edit" />
                </div>
                {editRoles.includes("CUSTOMER") && (
                  <div>
                    <Label>Linked Customer</Label>
                    <SearchableSelect
                      value={editCustomerId}
                      onValueChange={setEditCustomerId}
                      options={customers.map((c) => ({ value: c.id, label: c.fullname }))}
                      placeholder="Select a customer..."
                      searchPlaceholder="Search customers..."
                      testId="select-edit-customer"
                    />
                  </div>
                )}
                <div>
                  <Label>Reset Password</Label>
                  <Input
                    name="password"
                    type="password"
                    placeholder="Leave blank to keep current password"
                    autoComplete="new-password"
                    data-testid="input-edit-password"
                  />
                  <p className="text-xs text-muted-foreground mt-1">Min 6 characters. Leave blank to keep the current password.</p>
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button
                  type="submit"
                  disabled={updateUserMutation.isPending || editRoles.length === 0}
                  data-testid="button-save-role"
                >
                  Save
                </Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
