import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { useCan } from "@/hooks/use-permissions";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Pencil } from "lucide-react";
import { StatusBadge } from "@/components/status-badge";
import type { Instructor } from "@shared/schema";

type InstructorRow = Instructor & { username: string | null };

export default function InstructorsPage() {
  const canManage = useCan("shared_resources.instructors.manage");
  const [editingInstructor, setEditingInstructor] = useState<InstructorRow | null>(null);
  const { toast } = useToast();

  const { data: instructors = [], isLoading } = useQuery<InstructorRow[]>({
    queryKey: ["/api/instructors"],
  });

  const updateMutation = useMutation({
    mutationFn: (data: any) => apiRequest("PATCH", `/api/instructors/${data.id}`, { name: data.name }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/instructors"] });
      setEditingInstructor(null);
      toast({ title: "Instructor updated successfully" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to update instructor", description: error.message, variant: "destructive" });
    },
  });

  const columns = [
    { key: "name", label: "Instructor Name" },
    { key: "username", label: "Linked User", render: (i: InstructorRow) => i.username || "—" },
    {
      key: "status",
      label: "Status",
      render: (i: InstructorRow) => <StatusBadge status={i.status} />,
    },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Instructors"
        description="Instructors are created by giving a user the Instructor role on the Users page — this list is a read-only roster you can rename."
      />

      <DataTable
        columns={columns}
        data={instructors}
        isLoading={isLoading}
        actions={canManage ? (item) => (
          <Button
            size="sm"
            variant="outline"
            onClick={() => setEditingInstructor(item)}
            data-testid={`button-edit-instructor-${item.id}`}
          >
            <Pencil className="w-4 h-4" />
          </Button>
        ) : undefined}
      />

      <Dialog open={!!editingInstructor} onOpenChange={() => setEditingInstructor(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Instructor</DialogTitle>
          </DialogHeader>
          {editingInstructor && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                updateMutation.mutate({ id: editingInstructor.id, name: fd.get("name") });
              }}
            >
              <div className="space-y-4">
                <div>
                  <Label>Instructor Name</Label>
                  <Input name="name" defaultValue={editingInstructor.name} required data-testid="input-edit-instructor-name" />
                  <p className="text-xs text-muted-foreground mt-1">
                    Display name shown on the calendar and booking pages — the linked login is {editingInstructor.username || "unlinked"}.
                  </p>
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
