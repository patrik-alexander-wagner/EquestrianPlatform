import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { useToast } from "@/hooks/use-toast";
import { useCan } from "@/hooks/use-permissions";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, MoreVertical, Trash2 } from "lucide-react";
import type { Arena } from "@shared/schema";

export default function ArenasPage() {
  const canManage = useCan("shared_resources.arenas.manage");
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [editingArena, setEditingArena] = useState<Arena | null>(null);
  const { toast } = useToast();

  const { data: arenas = [], isLoading } = useQuery<Arena[]>({
    queryKey: ["/api/arenas"],
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/arenas", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/arenas"] });
      setShowCreateDialog(false);
      toast({ title: "Arena created successfully" });
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: any) => apiRequest("PATCH", `/api/arenas/${data.id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/arenas"] });
      setShowEditDialog(false);
      toast({ title: "Arena updated successfully" });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/arenas/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/arenas"] });
      toast({ title: "Arena deleted successfully" });
    },
  });

  const columns = [
    { key: "name", label: "Arena Name" },
    { key: "status", label: "Status" },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Arenas"
        description="Manage riding arenas"
        actions={canManage ? (
          <Button onClick={() => setShowCreateDialog(true)} data-testid="button-new-arena">
            <Plus className="w-4 h-4 mr-2" />
            New Arena
          </Button>
        ) : undefined}
      />

      <DataTable
        columns={columns}
        data={arenas}
        isLoading={isLoading}
        actions={canManage ? (item) => (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" data-testid={`button-actions-arena-${item.id}`}>
                <MoreVertical className="w-4 h-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent>
              <DropdownMenuItem onClick={() => { setEditingArena(item); setShowEditDialog(true); }}>
                Edit
              </DropdownMenuItem>
              <DropdownMenuItem
                className="text-destructive"
                onClick={() => deleteMutation.mutate(item.id)}
              >
                <Trash2 className="w-4 h-4 mr-2" />
                Delete
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        ) : undefined}
      />

      <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>New Arena</DialogTitle>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({ name: fd.get("name"), status: "active" });
            }}
          >
            <div className="space-y-4">
              <div>
                <Label>Arena Name</Label>
                <Input name="name" required data-testid="input-arena-name" />
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-arena">Create</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Arena</DialogTitle>
          </DialogHeader>
          {editingArena && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                updateMutation.mutate({ id: editingArena.id, name: fd.get("name"), status: fd.get("status") });
              }}
            >
              <div className="space-y-4">
                <div>
                  <Label>Arena Name</Label>
                  <Input name="name" defaultValue={editingArena.name} required data-testid="input-edit-arena-name" />
                </div>
                <div>
                  <Label>Status</Label>
                  <Input name="status" defaultValue={editingArena.status} data-testid="input-edit-arena-status" />
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={updateMutation.isPending} data-testid="button-submit-edit-arena">Save</Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
