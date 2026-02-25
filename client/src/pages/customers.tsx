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
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Upload, Plus } from "lucide-react";
import type { Customer } from "@shared/schema";

export default function CustomersPage() {
  const [search, setSearch] = useState("");
  const [showNewDialog, setShowNewDialog] = useState(false);
  const [showImportDialog, setShowImportDialog] = useState(false);
  const { toast } = useToast();

  const { data: customers = [], isLoading } = useQuery<Customer[]>({
    queryKey: ["/api/customers", search ? `?search=${search}` : ""],
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/customers", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/customers"] });
      setShowNewDialog(false);
      toast({ title: "Customer created successfully" });
    },
  });

  const importMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/customers/import", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/customers"] });
      setShowImportDialog(false);
      toast({ title: "Customers imported successfully" });
    },
  });

  const columns = [
    { key: "firstname", label: "First Name" },
    { key: "lastname", label: "Last Name" },
    { key: "phone", label: "Phone" },
    { key: "email", label: "Email" },
    {
      key: "status",
      label: "Status",
      render: (item: Customer) => <StatusBadge status={item.status} />,
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
        if (lines.length < 2) {
          toast({ title: "File must have a header row and data", variant: "destructive" });
          return;
        }
        const headers = lines[0].split(",").map(h => h.trim().toLowerCase());
        const data = lines.slice(1).map(line => {
          const values = line.split(",").map(v => v.trim());
          const obj: any = {};
          headers.forEach((h, i) => {
            if (h.includes("first")) obj.firstname = values[i];
            else if (h.includes("last")) obj.lastname = values[i];
            else if (h.includes("phone")) obj.phone = values[i];
            else if (h.includes("email")) obj.email = values[i];
            else if (h.includes("status")) obj.status = values[i] || "active";
          });
          if (!obj.firstname) obj.firstname = values[0] || "Unknown";
          if (!obj.lastname) obj.lastname = values[1] || "Unknown";
          if (!obj.status) obj.status = "active";
          return obj;
        });
        importMutation.mutate({ customers: data });
      } catch {
        toast({ title: "Failed to parse file", variant: "destructive" });
      }
    };
    reader.readAsText(file);
  };

  return (
    <div className="p-6">
      <PageHeader
        title="Customers"
        description="View customers synced from NetSuite"
        actions={
          <>
            <Button variant="outline" onClick={() => setShowImportDialog(true)} data-testid="button-import-customers">
              <Upload className="w-4 h-4 mr-2" />
              Import (Temp)
            </Button>
            <Button variant="outline" onClick={() => setShowNewDialog(true)} data-testid="button-new-customer">
              <Plus className="w-4 h-4 mr-2" />
              New Customer (Temp)
            </Button>
          </>
        }
      />

      <div className="mb-4">
        <SearchBar
          placeholder="Search by first or last name..."
          value={search}
          onChange={setSearch}
          className="max-w-sm"
        />
      </div>

      <DataTable columns={columns} data={customers} isLoading={isLoading} />

      <Dialog open={showNewDialog} onOpenChange={setShowNewDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>New Customer (Temporary)</DialogTitle>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({
                firstname: fd.get("firstname"),
                lastname: fd.get("lastname"),
                phone: fd.get("phone"),
                email: fd.get("email"),
                status: "active",
              });
            }}
          >
            <div className="space-y-4">
              <div>
                <Label>First Name</Label>
                <Input name="firstname" required data-testid="input-firstname" />
              </div>
              <div>
                <Label>Last Name</Label>
                <Input name="lastname" required data-testid="input-lastname" />
              </div>
              <div>
                <Label>Phone</Label>
                <Input name="phone" data-testid="input-phone" />
              </div>
              <div>
                <Label>Email</Label>
                <Input name="email" type="email" data-testid="input-email" />
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-customer">
                Create
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={showImportDialog} onOpenChange={setShowImportDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Import Customers from CSV</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Upload a CSV file with columns: First Name, Last Name, Phone, Email
            </p>
            <Input type="file" accept=".csv,.txt" onChange={handleImport} data-testid="input-import-file" />
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
