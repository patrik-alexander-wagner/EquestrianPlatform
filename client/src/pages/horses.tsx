import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { SearchBar } from "@/components/search-bar";

import { ImportDialog } from "@/components/import-dialog";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { useToast } from "@/hooks/use-toast";
import { useUserRole } from "@/hooks/use-user-role";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, Upload, MoreVertical } from "lucide-react";

export default function HorsesPage() {
  const userRole = useUserRole();
  const isAdmin = userRole === "ADMIN";
  const [search, setSearch] = useState("");
  const [customerSearch, setCustomerSearch] = useState("");
  const [stableBoxSearch, setStableBoxSearch] = useState("");
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [showImportDialog, setShowImportDialog] = useState(false);
  const [editingHorse, setEditingHorse] = useState<any>(null);
  const { toast } = useToast();

  const queryParams = new URLSearchParams();
  if (search) queryParams.set("search", search);
  if (customerSearch) queryParams.set("customerSearch", customerSearch);
  if (stableBoxSearch) queryParams.set("stableBoxSearch", stableBoxSearch);
  const qs = queryParams.toString();

  const { data: horses = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/horses", qs ? `?${qs}` : ""],
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/horses", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/horses"] });
      setShowCreateDialog(false);
      toast({ title: "Horse created successfully" });
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: any) => apiRequest("PATCH", `/api/horses/${data.id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/horses"] });
      setShowEditDialog(false);
      toast({ title: "Horse updated successfully" });
    },
  });

  const importMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/horses/import", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/horses"] });
      setShowImportDialog(false);
      toast({ title: "Horses imported successfully" });
    },
  });

  const columns = [
    { key: "horseName", label: "Horse Name" },
    { key: "breed", label: "Breed", render: (item: any) => item.breed || "-" },
    { key: "dateOfBirth", label: "Date of Birth", render: (item: any) => item.dateOfBirth || "-" },
    {
      key: "stableBox",
      label: "Stable / Box",
      render: (item: any) => item.stable && item.box ? `${item.stable} / ${item.box}` : "-",
    },
    {
      key: "customer",
      label: "Customer",
      render: (item: any) => item.customer || "-",
    },
  ];

  const importFields = [
    { targetField: "netsuiteId", label: "NetSuite ID" },
    { targetField: "horseName", label: "Horse Name", required: true },
    { targetField: "breed", label: "Breed" },
    { targetField: "dateOfBirth", label: "Date of Birth" },
    { targetField: "sex", label: "Sex" },
    { targetField: "color", label: "Color" },
    { targetField: "size", label: "Size" },
    { targetField: "passportName", label: "Passport Name" },
    { targetField: "passportNumber", label: "Passport Number" },
  ];

  const handleImport = (data: Record<string, string>[]) => {
    const mapped = data.map(row => ({
      netsuiteId: row.netsuiteId || null,
      horseName: row.horseName || "Unknown",
      breed: row.breed || null,
      dateOfBirth: row.dateOfBirth || null,
      sex: row.sex || null,
      color: row.color || null,
      size: row.size || null,
      passportName: row.passportName || null,
      passportNumber: row.passportNumber || null,
      status: "active",
    }));
    importMutation.mutate({ horses: mapped });
  };

  return (
    <div className="p-6">
      <PageHeader
        title="Horses"
        description="Manage horses used in livery agreements"
        actions={isAdmin ? (
          <>
            <Button variant="outline" onClick={() => setShowImportDialog(true)} data-testid="button-import-horses">
              <Upload className="w-4 h-4 mr-2" />
              Import
            </Button>
            <Button onClick={() => setShowCreateDialog(true)} data-testid="button-new-horse">
              <Plus className="w-4 h-4 mr-2" />
              New Horse
            </Button>
          </>
        ) : undefined}
      />

      <div className="flex gap-3 mb-4 flex-wrap">
        <SearchBar placeholder="Horse name..." value={search} onChange={setSearch} className="w-52" />
        <SearchBar placeholder="Customer..." value={customerSearch} onChange={setCustomerSearch} className="w-52" />
        <SearchBar placeholder="Stable / Box..." value={stableBoxSearch} onChange={setStableBoxSearch} className="w-52" />
      </div>

      <DataTable
        columns={columns}
        data={horses}
        isLoading={isLoading}
        actions={(item) => (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" data-testid={`button-actions-${item.id}`}>
                <MoreVertical className="w-4 h-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent>
              <DropdownMenuItem
                onClick={() => { setEditingHorse(item); setShowEditDialog(true); }}
                data-testid={`button-edit-${item.id}`}
              >
                Edit
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        )}
      />

      <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>New Horse</DialogTitle>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({
                horseName: fd.get("horseName"),
                breed: fd.get("breed") || null,
                dateOfBirth: fd.get("dateOfBirth") || null,
                sex: fd.get("sex") || null,
                color: fd.get("color") || null,
                size: fd.get("size") || null,
                status: "active",
              });
            }}
          >
            <div className="space-y-4">
              <div>
                <Label>Horse Name</Label>
                <Input name="horseName" required data-testid="input-horse-name" />
              </div>
              <div>
                <Label>Breed</Label>
                <Input name="breed" data-testid="input-breed" />
              </div>
              <div>
                <Label>Date of Birth</Label>
                <Input name="dateOfBirth" type="date" data-testid="input-dob" />
              </div>
              <div>
                <Label>Sex</Label>
                <Input name="sex" data-testid="input-sex" />
              </div>
              <div>
                <Label>Color</Label>
                <Input name="color" data-testid="input-color" />
              </div>
              <div>
                <Label>Size</Label>
                <Input name="size" data-testid="input-size" />
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-horse">Create</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Horse</DialogTitle>
          </DialogHeader>
          {editingHorse && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                updateMutation.mutate({
                  id: editingHorse.id,
                  horseName: fd.get("horseName"),
                  breed: fd.get("breed") || null,
                  dateOfBirth: fd.get("dateOfBirth") || null,
                  sex: fd.get("sex") || null,
                  color: fd.get("color") || null,
                  size: fd.get("size") || null,
                  status: fd.get("status") || "active",
                });
              }}
            >
              <div className="space-y-4">
                <div>
                  <Label>Horse Name</Label>
                  <Input name="horseName" defaultValue={editingHorse.horseName} required data-testid="input-edit-horse-name" />
                </div>
                <div>
                  <Label>Breed</Label>
                  <Input name="breed" defaultValue={editingHorse.breed || ""} data-testid="input-edit-breed" />
                </div>
                <div>
                  <Label>Date of Birth</Label>
                  <Input name="dateOfBirth" type="date" defaultValue={editingHorse.dateOfBirth || ""} data-testid="input-edit-dob" />
                </div>
                <div>
                  <Label>Sex</Label>
                  <Input name="sex" defaultValue={editingHorse.sex || ""} data-testid="input-edit-sex" />
                </div>
                <div>
                  <Label>Color</Label>
                  <Input name="color" defaultValue={editingHorse.color || ""} data-testid="input-edit-color" />
                </div>
                <div>
                  <Label>Size</Label>
                  <Input name="size" defaultValue={editingHorse.size || ""} data-testid="input-edit-size" />
                </div>
                <div>
                  <Label>Status</Label>
                  <Input name="status" defaultValue={editingHorse.status} data-testid="input-edit-status" />
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={updateMutation.isPending} data-testid="button-submit-edit-horse">Save</Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>

      <ImportDialog
        open={showImportDialog}
        onOpenChange={setShowImportDialog}
        title="Import Horses"
        fields={importFields}
        onImport={handleImport}
        isPending={importMutation.isPending}
      />
    </div>
  );
}
