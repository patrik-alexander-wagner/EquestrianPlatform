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
import type { Instructor } from "@shared/schema";

export default function InstructorsPage() {
  const canManage = useCan("shared_resources.instructors.manage");
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [editingInstructor, setEditingInstructor] = useState<Instructor | null>(null);
  const { toast } = useToast();

  const { data: instructors = [], isLoading } = useQuery<Instructor[]>({
    queryKey: ["/api/instructors"],
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/instructors", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/instructors"] });
      setShowCreateDialog(false);
      toast({ title: "Instructor created successfully" });
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: any) => apiRequest("PATCH", `/api/instructors/${data.id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/instructors"] });
      setShowEditDialog(false);
      toast({ title: "Instructor updated successfully" });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/instructors/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/instructors"] });
      toast({ title: "Instructor deleted successfully" });
    },
  });

  const columns = [
    { key: "name", label: "Instructor Name" },
    { key: "status", label: "Status" },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Instructors"
        description="Manage riding instructors"
        actions={canManage ? (
          <Button onClick={() => setShowCreateDialog(true)} data-testid="button-new-instructor">
            <Plus className="w-4 h-4 mr-2" />
            New Instructor
          </Button>
        ) : undefined}
      />

      <DataTable
        columns={columns}
        data={instructors}
        isLoading={isLoading}
        actions={canManage ? (item) => (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" data-testid={`button-actions-instructor-${item.id}`}>
                <MoreVertical className="w-4 h-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent>
              <DropdownMenuItem onClick={() => { setEditingInstructor(item); setShowEditDialog(true); }}>
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
            <DialogTitle>New Instructor</DialogTitle>
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
                <Label>Instructor Name</Label>
                <Input name="name" required data-testid="input-instructor-name" />
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-instructor">Create</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Instructor</DialogTitle>
          </DialogHeader>
          {editingInstructor && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                updateMutation.mutate({ id: editingInstructor.id, name: fd.get("name"), status: fd.get("status") });
              }}
            >
              <div className="space-y-4">
                <div>
                  <Label>Instructor Name</Label>
                  <Input name="name" defaultValue={editingInstructor.name} required data-testid="input-edit-instructor-name" />
                </div>
                <div>
                  <Label>Status</Label>
                  <Input name="status" defaultValue={editingInstructor.status} data-testid="input-edit-instructor-status" />
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={updateMutation.isPending} data-testid="button-submit-edit-instructor">Save</Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
