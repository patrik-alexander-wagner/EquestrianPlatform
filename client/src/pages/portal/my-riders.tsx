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
import type { Rider, RiderLevel } from "@shared/schema";

export default function MyRidersPage() {
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [editing, setEditing] = useState<Rider | null>(null);
  const { toast } = useToast();

  const { data: riders = [], isLoading } = useQuery<Rider[]>({ queryKey: ["/api/portal/riders"] });
  const { data: riderLevels = [] } = useQuery<RiderLevel[]>({ queryKey: ["/api/rider-levels"] });
  const levelById = Object.fromEntries(riderLevels.map((l) => [l.id, l.name]));

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/portal/riders", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/portal/riders"] });
      setShowCreateDialog(false);
      toast({ title: "Rider added" });
    },
    onError: (e: any) => toast({ title: "Failed to add rider", description: e.message, variant: "destructive" as any }),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, ...data }: any) => apiRequest("PATCH", `/api/portal/riders/${id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/portal/riders"] });
      setEditing(null);
      toast({ title: "Rider updated" });
    },
    onError: (e: any) => toast({ title: "Failed to update rider", description: e.message, variant: "destructive" as any }),
  });

  const columns = [
    { key: "fullName", label: "Name" },
    { key: "dateOfBirth", label: "Date of Birth", render: (r: Rider) => r.dateOfBirth || "—" },
    { key: "riderLevelId", label: "Level", render: (r: Rider) => r.riderLevelId ? levelById[r.riderLevelId] || "—" : "—" },
    { key: "isAccountHolder", label: "Role", render: (r: Rider) => r.isAccountHolder ? "Account Holder" : "Family Member" },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="My Riders"
        description="Manage riders on your account — including family members you book and cancel for"
        actions={
          <Button onClick={() => setShowCreateDialog(true)} data-testid="button-new-rider">
            <Plus className="w-4 h-4 mr-2" />
            Add Rider
          </Button>
        }
      />

      <DataTable
        columns={columns}
        data={riders}
        isLoading={isLoading}
        actions={(item: Rider) => (
          <Button variant="ghost" size="icon" onClick={() => setEditing(item)} data-testid={`button-edit-rider-${item.id}`}>
            <Pencil className="w-4 h-4" />
          </Button>
        )}
      />

      <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Rider</DialogTitle>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({
                fullName: fd.get("fullName"),
                dateOfBirth: fd.get("dateOfBirth") || undefined,
                riderLevelId: fd.get("riderLevelId") || undefined,
                isAccountHolder: false,
              });
            }}
          >
            <div className="space-y-4">
              <div>
                <Label>Full Name</Label>
                <Input name="fullName" required data-testid="input-rider-name" />
              </div>
              <div>
                <Label>Date of Birth</Label>
                <Input name="dateOfBirth" type="date" data-testid="input-rider-dob" />
              </div>
              <div>
                <Label>Riding Level</Label>
                <Select name="riderLevelId">
                  <SelectTrigger data-testid="select-rider-level"><SelectValue placeholder="Select a level" /></SelectTrigger>
                  <SelectContent>
                    {riderLevels.map((l) => <SelectItem key={l.id} value={l.id}>{l.name}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-rider">Add</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={!!editing} onOpenChange={(open) => !open && setEditing(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Rider</DialogTitle>
          </DialogHeader>
          {editing && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                updateMutation.mutate({
                  id: editing.id,
                  fullName: fd.get("fullName"),
                  dateOfBirth: fd.get("dateOfBirth") || undefined,
                  riderLevelId: fd.get("riderLevelId") || undefined,
                });
              }}
            >
              <div className="space-y-4">
                <div>
                  <Label>Full Name</Label>
                  <Input name="fullName" defaultValue={editing.fullName} required data-testid="input-edit-rider-name" />
                </div>
                <div>
                  <Label>Date of Birth</Label>
                  <Input name="dateOfBirth" type="date" defaultValue={editing.dateOfBirth ?? ""} data-testid="input-edit-rider-dob" />
                </div>
                <div>
                  <Label>Riding Level</Label>
                  <Select name="riderLevelId" defaultValue={editing.riderLevelId ?? undefined}>
                    <SelectTrigger data-testid="select-edit-rider-level"><SelectValue placeholder="Select a level" /></SelectTrigger>
                    <SelectContent>
                      {riderLevels.map((l) => <SelectItem key={l.id} value={l.id}>{l.name}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={updateMutation.isPending} data-testid="button-submit-edit-rider">Save</Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
