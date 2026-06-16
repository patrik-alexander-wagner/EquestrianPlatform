import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, Pencil } from "lucide-react";
import { StatusBadge } from "@/components/status-badge";
import type { User } from "@shared/schema";

interface RoleOption {
  key: string;
  name: string;
}

export default function AdminUsersPage() {
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [editingUser, setEditingUser] = useState<any | null>(null);
  const { toast } = useToast();

  const { data: users = [], isLoading } = useQuery<User[]>({
    queryKey: ["/api/users"],
  });

  const { data: roles = [] } = useQuery<RoleOption[]>({
    queryKey: ["/api/roles"],
  });

  const roleLabels: Record<string, string> = Object.fromEntries(
    roles.map((r) => [r.key, r.name])
  );

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/users", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/users"] });
      setShowCreateDialog(false);
      toast({ title: "User created successfully" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to create user", description: error.message, variant: "destructive" });
    },
  });

  const updateUserMutation = useMutation({
    mutationFn: ({ id, role, password }: { id: string; role: string; password?: string }) => {
      const body: any = { role };
      if (password) body.password = password;
      return apiRequest("PATCH", `/api/users/${id}`, body);
    },
    onSuccess: (_data, vars) => {
      queryClient.invalidateQueries({ queryKey: ["/api/users"] });
      setEditingUser(null);
      toast({ title: vars.password ? "User updated and password reset" : "User role updated" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to update user", description: error.message, variant: "destructive" });
    },
  });

  const columns = [
    { key: "username", label: "Username" },
    {
      key: "role",
      label: "Role",
      render: (item: any) => (
        <StatusBadge status={roleLabels[item.role] || item.role} />
      ),
    },
    { key: "id", label: "User ID", render: (item: User) => item.id.substring(0, 8) + "..." },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Users"
        description="Manage system users and roles"
        actions={
          <Button onClick={() => setShowCreateDialog(true)} data-testid="button-new-user">
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
            onClick={() => setEditingUser(item)}
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
                role: fd.get("role"),
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
                <Label>Role</Label>
                <select name="role" defaultValue="LIVERY_ADMIN" className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" data-testid="select-new-role">
                  {roles.map(role => (
                    <option key={role.key} value={role.key}>{role.name}</option>
                  ))}
                </select>
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-user">
                Create User
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={!!editingUser} onOpenChange={() => setEditingUser(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit User Role</DialogTitle>
          </DialogHeader>
          {editingUser && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                const password = (fd.get("password") as string)?.trim();
                updateUserMutation.mutate({
                  id: editingUser.id,
                  role: fd.get("role") as string,
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
                  <Label>Role</Label>
                  <select name="role" defaultValue={editingUser.role} className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" data-testid="select-edit-role">
                    {roles.map(role => (
                      <option key={role.key} value={role.key}>{role.name}</option>
                    ))}
                  </select>
                </div>
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
                <Button type="submit" disabled={updateUserMutation.isPending} data-testid="button-save-role">
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
