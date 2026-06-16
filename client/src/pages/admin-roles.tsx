import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Badge } from "@/components/ui/badge";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, Pencil, Trash2, ShieldCheck } from "lucide-react";
import { ACTION_GROUPS, type ActionDef } from "@shared/permissions";

interface RoleWithPerms {
  id: string;
  key: string;
  name: string;
  isSystem: boolean;
  isAdmin: boolean;
  permissions: string[];
  userCount: number;
}

export default function AdminRolesPage() {
  const { toast } = useToast();
  const [showCreate, setShowCreate] = useState(false);
  const [createName, setCreateName] = useState("");
  const [createPerms, setCreatePerms] = useState<Set<string>>(new Set());
  const [renaming, setRenaming] = useState<RoleWithPerms | null>(null);
  const [renameValue, setRenameValue] = useState("");
  const [deleting, setDeleting] = useState<RoleWithPerms | null>(null);

  const { data: roles = [], isLoading: rolesLoading } = useQuery<RoleWithPerms[]>({
    queryKey: ["/api/roles"],
  });
  const { data: actions = [], isLoading: actionsLoading } = useQuery<ActionDef[]>({
    queryKey: ["/api/permissions/actions"],
  });

  const setPermsMutation = useMutation({
    mutationFn: ({ key, permissions }: { key: string; permissions: string[] }) =>
      apiRequest("PATCH", `/api/roles/${key}`, { permissions }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/roles"] });
      queryClient.invalidateQueries({ queryKey: ["/api/me"] });
    },
    onError: (error: any) => {
      queryClient.invalidateQueries({ queryKey: ["/api/roles"] });
      toast({ title: "Failed to update permission", description: error.message, variant: "destructive" });
    },
  });

  const createMutation = useMutation({
    mutationFn: (data: { name: string; permissions: string[] }) => apiRequest("POST", "/api/roles", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/roles"] });
      setShowCreate(false);
      setCreateName("");
      setCreatePerms(new Set());
      toast({ title: "Role created" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to create role", description: error.message, variant: "destructive" });
    },
  });

  const renameMutation = useMutation({
    mutationFn: ({ key, name }: { key: string; name: string }) => apiRequest("PATCH", `/api/roles/${key}`, { name }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/roles"] });
      setRenaming(null);
      toast({ title: "Role renamed" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to rename role", description: error.message, variant: "destructive" });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (key: string) => apiRequest("DELETE", `/api/roles/${key}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/roles"] });
      setDeleting(null);
      toast({ title: "Role deleted" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to delete role", description: error.message, variant: "destructive" });
    },
  });

  const togglePerm = (role: RoleWithPerms, actionKey: string, checked: boolean) => {
    const next = new Set(role.permissions);
    if (checked) next.add(actionKey);
    else next.delete(actionKey);
    setPermsMutation.mutate({ key: role.key, permissions: Array.from(next) });
  };

  const toggleCreatePerm = (actionKey: string, checked: boolean) => {
    setCreatePerms((prev) => {
      const next = new Set(prev);
      if (checked) next.add(actionKey);
      else next.delete(actionKey);
      return next;
    });
  };

  const isLoading = rolesLoading || actionsLoading;

  return (
    <div className="p-6">
      <PageHeader
        title="Roles & Permissions"
        description="Create roles and control exactly what each role can see and do."
        actions={
          <Button onClick={() => setShowCreate(true)} data-testid="button-new-role">
            <Plus className="w-4 h-4 mr-2" />
            New Role
          </Button>
        }
      />

      {isLoading ? (
        <p className="text-muted-foreground">Loading...</p>
      ) : (
        <div className="overflow-auto border rounded-md">
          <table className="w-full text-sm border-collapse">
            <thead className="sticky top-0 bg-background z-10">
              <tr className="border-b">
                <th className="text-left p-3 font-medium min-w-[280px] sticky left-0 bg-background">Permission</th>
                {roles.map((role) => (
                  <th key={role.key} className="p-3 font-medium text-center min-w-[120px] align-bottom">
                    <div className="flex flex-col items-center gap-1">
                      <span className="flex items-center gap-1" data-testid={`text-role-${role.key}`}>
                        {role.isAdmin && <ShieldCheck className="w-3.5 h-3.5 text-primary" />}
                        {role.name}
                      </span>
                      <span className="text-xs text-muted-foreground font-normal">
                        {role.userCount} user{role.userCount === 1 ? "" : "s"}
                      </span>
                      <div className="flex gap-1">
                        <Badge variant="outline" className="text-[10px] px-1 py-0">
                          {role.isSystem ? "Built-in" : "Custom"}
                        </Badge>
                      </div>
                      <div className="flex gap-1 mt-1">
                        <Button
                          size="icon"
                          variant="ghost"
                          className="h-6 w-6"
                          title="Rename role"
                          onClick={() => { setRenaming(role); setRenameValue(role.name); }}
                          data-testid={`button-rename-${role.key}`}
                        >
                          <Pencil className="w-3 h-3" />
                        </Button>
                        {!role.isSystem && (
                          <Button
                            size="icon"
                            variant="ghost"
                            className="h-6 w-6 text-destructive"
                            title="Delete role"
                            onClick={() => setDeleting(role)}
                            data-testid={`button-delete-${role.key}`}
                          >
                            <Trash2 className="w-3 h-3" />
                          </Button>
                        )}
                      </div>
                    </div>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {ACTION_GROUPS.map((group) => {
                const groupActions = actions.filter((a) => a.group === group);
                if (groupActions.length === 0) return [];
                return [
                  <tr key={`group-${group}`} className="bg-muted/50 border-b">
                    <td className="p-2 px-3 font-semibold text-xs uppercase tracking-wide text-muted-foreground sticky left-0 bg-muted/50" colSpan={roles.length + 1}>
                      {group}
                    </td>
                  </tr>,
                  ...groupActions.map((action) => (
                    <tr key={action.key} className="border-b hover-elevate">
                      <td className="p-2 px-3 sticky left-0 bg-background">
                        <span className="flex items-center gap-2">
                          {action.label}
                          <Badge variant="outline" className="text-[10px] px-1 py-0">
                            {action.type === "view" ? "see" : "do"}
                          </Badge>
                        </span>
                      </td>
                      {roles.map((role) => {
                        const granted = role.isAdmin || role.permissions.includes(action.key);
                        return (
                          <td key={role.key} className="p-2 text-center">
                            <Checkbox
                              checked={granted}
                              disabled={role.isAdmin || setPermsMutation.isPending}
                              onCheckedChange={(v) => togglePerm(role, action.key, v === true)}
                              data-testid={`toggle-${role.key}-${action.key}`}
                            />
                          </td>
                        );
                      })}
                    </tr>
                  )),
                ];
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Create role dialog */}
      <Dialog open={showCreate} onOpenChange={setShowCreate}>
        <DialogContent className="max-w-2xl max-h-[85vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>New Role</DialogTitle>
            <DialogDescription>Name the role and choose its permissions. You can change these anytime.</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label>Role name</Label>
              <Input
                value={createName}
                onChange={(e) => setCreateName(e.target.value)}
                placeholder="e.g. Yard Manager"
                data-testid="input-role-name"
              />
            </div>
            <div className="space-y-3">
              {ACTION_GROUPS.map((group) => {
                const groupActions = actions.filter((a) => a.group === group);
                if (groupActions.length === 0) return null;
                return (
                  <div key={group}>
                    <p className="font-semibold text-xs uppercase tracking-wide text-muted-foreground mb-1">{group}</p>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-1">
                      {groupActions.map((action) => (
                        <label key={action.key} className="flex items-center gap-2 text-sm cursor-pointer">
                          <Checkbox
                            checked={createPerms.has(action.key)}
                            onCheckedChange={(v) => toggleCreatePerm(action.key, v === true)}
                            data-testid={`create-toggle-${action.key}`}
                          />
                          <span>{action.label}</span>
                          <Badge variant="outline" className="text-[10px] px-1 py-0">
                            {action.type === "view" ? "see" : "do"}
                          </Badge>
                        </label>
                      ))}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
          <DialogFooter className="mt-4">
            <Button variant="outline" onClick={() => setShowCreate(false)}>Cancel</Button>
            <Button
              onClick={() => createMutation.mutate({ name: createName.trim(), permissions: Array.from(createPerms) })}
              disabled={!createName.trim() || createMutation.isPending}
              data-testid="button-submit-role"
            >
              Create Role
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Rename dialog */}
      <Dialog open={!!renaming} onOpenChange={(o) => !o && setRenaming(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Rename Role</DialogTitle>
          </DialogHeader>
          <div>
            <Label>Role name</Label>
            <Input value={renameValue} onChange={(e) => setRenameValue(e.target.value)} data-testid="input-rename-role" />
          </div>
          <DialogFooter className="mt-4">
            <Button variant="outline" onClick={() => setRenaming(null)}>Cancel</Button>
            <Button
              onClick={() => renaming && renameMutation.mutate({ key: renaming.key, name: renameValue.trim() })}
              disabled={!renameValue.trim() || renameMutation.isPending}
              data-testid="button-save-rename"
            >
              Save
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Delete confirm */}
      <Dialog open={!!deleting} onOpenChange={(o) => !o && setDeleting(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Delete Role</DialogTitle>
            <DialogDescription>
              {deleting && deleting.userCount > 0
                ? `This role is assigned to ${deleting.userCount} user(s). Reassign them before deleting.`
                : `Are you sure you want to delete the "${deleting?.name}" role? This cannot be undone.`}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="mt-4">
            <Button variant="outline" onClick={() => setDeleting(null)}>Cancel</Button>
            <Button
              variant="destructive"
              onClick={() => deleting && deleteMutation.mutate(deleting.key)}
              disabled={deleteMutation.isPending || (deleting?.userCount ?? 0) > 0}
              data-testid="button-confirm-delete"
            >
              Delete
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
