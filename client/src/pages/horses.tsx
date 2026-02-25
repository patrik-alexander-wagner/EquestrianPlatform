import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { SearchBar } from "@/components/search-bar";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, Upload, MoreVertical } from "lucide-react";

export default function HorsesPage() {
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
    { key: "status", label: "Status", render: (item: any) => <StatusBadge status={item.status} /> },
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

  const handleImport = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const text = event.target?.result as string;
        const lines = text.split("\n").filter(l => l.trim());
        if (lines.length < 2) return;
        const headers = lines[0].split(",").map(h => h.trim().toLowerCase());
        const data = lines.slice(1).map(line => {
          const values = line.split(",").map(v => v.trim());
          const obj: any = { status: "active" };
          headers.forEach((h, i) => {
            if (h.includes("name") || h.includes("horse")) obj.horseName = values[i];
            else if (h.includes("breed")) obj.breed = values[i];
            else if (h.includes("birth") || h.includes("dob")) obj.dateOfBirth = values[i];
            else if (h.includes("sex")) obj.sex = values[i];
            else if (h.includes("color")) obj.color = values[i];
            else if (h.includes("size")) obj.size = values[i];
          });
          if (!obj.horseName) obj.horseName = values[0] || "Unknown";
          return obj;
        });
        importMutation.mutate({ horses: data });
      } catch {
        toast({ title: "Failed to parse file", variant: "destructive" });
      }
    };
    reader.readAsText(file);
  };

  return (
    <div className="p-6">
      <PageHeader
        title="Horses"
        description="Manage horses used in livery agreements"
        actions={
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
        }
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

      <Dialog open={showImportDialog} onOpenChange={setShowImportDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Import Horses from CSV</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Upload a CSV file with columns: Horse Name, Breed, Date of Birth, Sex, Color, Size
            </p>
            <Input type="file" accept=".csv,.txt" onChange={handleImport} data-testid="input-import-horses-file" />
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
