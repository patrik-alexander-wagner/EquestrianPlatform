import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { SearchBar } from "@/components/search-bar";
import { StatusBadge } from "@/components/status-badge";
import { ImportDialog } from "@/components/import-dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
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
    onError: (error: any) => {
      toast({ title: "Import failed", description: error.message, variant: "destructive" });
    },
  });

  const columns = [
    { key: "name", label: "Item Name" },
    { key: "category", label: "Category", render: (item: Item) => item.category || "-" },
    {
      key: "base",
      label: "Base (Qty Unit)",
      render: (item: Item) => item.base ? item.base : "-",
    },
    {
      key: "price",
      label: "Price",
      render: (item: Item) => item.price ? `$${item.price}` : "-",
    },
    {
      key: "unitPrice",
      label: "Unit Price",
      render: (item: Item) => {
        const base = item.base ? parseFloat(item.base) : 0;
        const price = item.price ? parseFloat(item.price) : 0;
        if (base > 0 && price > 0) {
          return `$${(price / base).toFixed(2)}`;
        }
        return "-";
      },
    },
    {
      key: "isLiveryPackage",
      label: "Type",
      render: (item: Item) => item.isLiveryPackage
        ? <Badge variant="default">Livery Package</Badge>
        : <Badge variant="outline">Service/Item</Badge>,
    },
    { key: "status", label: "Status", render: (item: Item) => <StatusBadge status={item.status} /> },
  ];

  const importFields = [
    { targetField: "name", label: "Item Name", required: true },
    { targetField: "category", label: "Category" },
    { targetField: "base", label: "Base (Qty Unit)" },
    { targetField: "price", label: "Price" },
    { targetField: "netsuiteId", label: "NetSuite ID" },
    { targetField: "status", label: "Status" },
  ];

  const handleImport = (data: Record<string, string>[]) => {
    const mapped = data.map(row => ({
      name: row.name || "Unknown",
      category: row.category || null,
      base: row.base || null,
      price: row.price || null,
      netsuiteId: row.netsuiteId || null,
      status: row.status || "active",
      isLiveryPackage: false,
    }));
    importMutation.mutate({ items: mapped });
  };

  return (
    <div className="p-6">
      <PageHeader
        title="Items"
        description="Items and service items. Base = quantity unit for pricing, Price = total price for that base quantity."
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

      <ImportDialog
        open={showImportDialog}
        onOpenChange={setShowImportDialog}
        title="Import Items"
        fields={importFields}
        onImport={handleImport}
        isPending={importMutation.isPending}
      />
    </div>
  );
}
