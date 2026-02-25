import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { SearchBar } from "@/components/search-bar";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Upload } from "lucide-react";
import type { Item } from "@shared/schema";

export default function ItemsPage() {
  const [search, setSearch] = useState("");
  const [showImportDialog, setShowImportDialog] = useState(false);
  const { toast } = useToast();

  const { data: items = [], isLoading } = useQuery<Item[]>({
    queryKey: ["/api/items", search ? `?search=${search}` : ""],
  });

  const importMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/items/import", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/items"] });
      setShowImportDialog(false);
      toast({ title: "Items imported successfully" });
    },
  });

  const columns = [
    { key: "name", label: "Item Name" },
    { key: "category", label: "Category", render: (item: Item) => item.category || "-" },
    { key: "base", label: "Base", render: (item: Item) => item.base ? `$${item.base}` : "-" },
    { key: "price", label: "Price", render: (item: Item) => item.price ? `$${item.price}` : "-" },
    {
      key: "isLiveryPackage",
      label: "Type",
      render: (item: Item) => item.isLiveryPackage
        ? <Badge variant="default">Livery Package</Badge>
        : <Badge variant="outline">Service/Item</Badge>,
    },
    { key: "status", label: "Status", render: (item: Item) => <StatusBadge status={item.status} /> },
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
          const obj: any = { status: "active", isLiveryPackage: false };
          headers.forEach((h, i) => {
            if (h.includes("name") || h.includes("item")) obj.name = values[i];
            else if (h.includes("category")) obj.category = values[i];
            else if (h.includes("base")) obj.base = values[i];
            else if (h.includes("price")) obj.price = values[i];
          });
          if (!obj.name) obj.name = values[0] || "Unknown";
          return obj;
        });
        importMutation.mutate({ items: data });
      } catch {
        toast({ title: "Failed to parse file", variant: "destructive" });
      }
    };
    reader.readAsText(file);
  };

  return (
    <div className="p-6">
      <PageHeader
        title="Items"
        description="Items and service items (read-only, synced from NetSuite)"
        actions={
          <Button variant="outline" onClick={() => setShowImportDialog(true)} data-testid="button-import-items">
            <Upload className="w-4 h-4 mr-2" />
            Import (Temp)
          </Button>
        }
      />

      <div className="mb-4">
        <SearchBar placeholder="Search item name..." value={search} onChange={setSearch} className="max-w-sm" />
      </div>

      <DataTable columns={columns} data={items} isLoading={isLoading} />

      <Dialog open={showImportDialog} onOpenChange={setShowImportDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Import Items from CSV</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <p className="text-sm text-muted-foreground">
              Upload a CSV file with columns: Item Name, Category, Base, Price
            </p>
            <Input type="file" accept=".csv,.txt" onChange={handleImport} data-testid="input-import-items-file" />
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
