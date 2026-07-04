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
import type { RiderLevel } from "@shared/schema";

export default function RiderLevelsPage() {
  const canManage = useCan("riding_school.settings.manage");
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [editingLevel, setEditingLevel] = useState<RiderLevel | null>(null);
  const { toast } = useToast();

  const { data: riderLevels = [], isLoading } = useQuery<RiderLevel[]>({
    queryKey: ["/api/rider-levels"],
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/rider-levels", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/rider-levels"] });
      setShowCreateDialog(false);
      toast({ title: "Rider level created successfully" });
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: any) => apiRequest("PATCH", `/api/rider-levels/${data.id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/rider-levels"] });
      setShowEditDialog(false);
      toast({ title: "Rider level updated successfully" });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/rider-levels/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/rider-levels"] });
      toast({ title: "Rider level deleted successfully" });
    },
  });

  const columns = [
    { key: "name", label: "Level Name" },
    { key: "sortOrder", label: "Order" },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Rider Levels"
        description="Manage riding skill levels used to gate class visibility"
        actions={canManage ? (
          <Button onClick={() => setShowCreateDialog(true)} data-testid="button-new-rider-level">
            <Plus className="w-4 h-4 mr-2" />
            New Level
          </Button>
        ) : undefined}
      />

      <DataTable
        columns={columns}
        data={riderLevels}
        isLoading={isLoading}
        actions={canManage ? (item) => (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" data-testid={`button-actions-rider-level-${item.id}`}>
                <MoreVertical className="w-4 h-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent>
              <DropdownMenuItem onClick={() => { setEditingLevel(item); setShowEditDialog(true); }}>
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
            <DialogTitle>New Rider Level</DialogTitle>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({ name: fd.get("name"), sortOrder: Number(fd.get("sortOrder")) || 0 });
            }}
          >
            <div className="space-y-4">
              <div>
                <Label>Level Name</Label>
                <Input name="name" required data-testid="input-rider-level-name" />
              </div>
              <div>
                <Label>Sort Order</Label>
                <Input name="sortOrder" type="number" defaultValue={0} data-testid="input-rider-level-sort-order" />
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-rider-level">Create</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Rider Level</DialogTitle>
          </DialogHeader>
          {editingLevel && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                updateMutation.mutate({
                  id: editingLevel.id,
                  name: fd.get("name"),
                  sortOrder: Number(fd.get("sortOrder")) || 0,
                });
              }}
            >
              <div className="space-y-4">
                <div>
                  <Label>Level Name</Label>
                  <Input name="name" defaultValue={editingLevel.name} required data-testid="input-edit-rider-level-name" />
                </div>
                <div>
                  <Label>Sort Order</Label>
                  <Input name="sortOrder" type="number" defaultValue={editingLevel.sortOrder} data-testid="input-edit-rider-level-sort-order" />
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={updateMutation.isPending} data-testid="button-submit-edit-rider-level">Save</Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
