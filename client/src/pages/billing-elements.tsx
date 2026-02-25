import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { SearchBar } from "@/components/search-bar";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus } from "lucide-react";
import type { Item } from "@shared/schema";

export default function BillingElementsPage() {
  const [horseSearch, setHorseSearch] = useState("");
  const [customerSearch, setCustomerSearch] = useState("");
  const [stableSearch, setStableSearch] = useState("");
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [selectedAgreementHorse, setSelectedAgreementHorse] = useState<any>(null);
  const [selectedItemId, setSelectedItemId] = useState("");
  const [quantity, setQuantity] = useState(1);
  const { toast } = useToast();

  const { data: horsesWithAgreements = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/horses-with-agreements"],
  });

  const { data: nonLiveryItems = [] } = useQuery<Item[]>({
    queryKey: ["/api/items/non-livery-packages"],
  });

  const { data: billingElements = [] } = useQuery<any[]>({
    queryKey: ["/api/billing-elements"],
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/billing-elements", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/billing-elements"] });
      queryClient.invalidateQueries({ queryKey: ["/api/horses-with-agreements"] });
      setShowAddDialog(false);
      toast({ title: "Billing element added successfully" });
    },
  });

  const filteredHorses = useMemo(() => {
    let result = horsesWithAgreements;
    if (horseSearch) {
      result = result.filter((h: any) => h.horseName.toLowerCase().includes(horseSearch.toLowerCase()));
    }
    if (customerSearch) {
      result = result.filter((h: any) => h.customerName.toLowerCase().includes(customerSearch.toLowerCase()));
    }
    if (stableSearch) {
      result = result.filter((h: any) =>
        h.stableName.toLowerCase().includes(stableSearch.toLowerCase()) ||
        h.boxName.toLowerCase().includes(stableSearch.toLowerCase())
      );
    }
    return result;
  }, [horsesWithAgreements, horseSearch, customerSearch, stableSearch]);

  const columns = [
    { key: "horseName", label: "Horse" },
    { key: "customerName", label: "Customer" },
    { key: "stableName", label: "Stable" },
    { key: "boxName", label: "Box" },
  ];

  const selectedItem = nonLiveryItems.find(i => i.id === selectedItemId);
  const unitPrice = selectedItem?.price ? parseFloat(selectedItem.price) : 0;
  const totalPrice = unitPrice * quantity;

  return (
    <div className="p-6">
      <PageHeader
        title="Billing Elements"
        description="Add extra billable items per horse with active livery agreements"
      />

      <div className="flex gap-3 mb-4 flex-wrap">
        <SearchBar placeholder="Horse..." value={horseSearch} onChange={setHorseSearch} className="w-52" />
        <SearchBar placeholder="Customer..." value={customerSearch} onChange={setCustomerSearch} className="w-52" />
        <SearchBar placeholder="Stable / Box..." value={stableSearch} onChange={setStableSearch} className="w-52" />
      </div>

      <DataTable
        columns={columns}
        data={filteredHorses}
        isLoading={isLoading}
        emptyMessage="No horses with active livery agreements"
        actions={(item) => (
          <Button
            size="sm"
            onClick={() => { setSelectedAgreementHorse(item); setSelectedItemId(""); setQuantity(1); setShowAddDialog(true); }}
            data-testid={`button-add-billing-${item.horseId}`}
          >
            <Plus className="w-4 h-4 mr-1" />
            Add
          </Button>
        )}
      />

      {billingElements.length > 0 && (
        <div className="mt-8">
          <h3 className="text-lg font-semibold mb-4">Recent Billing Elements</h3>
          <DataTable
            columns={[
              { key: "horseName", label: "Horse" },
              { key: "customerName", label: "Customer" },
              { key: "itemName", label: "Item" },
              { key: "quantity", label: "Qty" },
              {
                key: "unitPrice",
                label: "Unit Price",
                render: (item: any) => `AED ${parseFloat(item.price).toFixed(2)}`,
              },
              {
                key: "total",
                label: "Total",
                render: (item: any) => `AED ${(parseFloat(item.price) * (item.quantity || 1)).toFixed(2)}`,
              },
              { key: "transactionDate", label: "Date" },
              {
                key: "billed",
                label: "Billed",
                render: (item: any) => item.billed ? "Yes" : "No",
              },
            ]}
            data={billingElements}
          />
        </div>
      )}

      <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Billing Element</DialogTitle>
          </DialogHeader>
          {selectedAgreementHorse && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                createMutation.mutate({
                  horseId: selectedAgreementHorse.horseId,
                  customerId: selectedAgreementHorse.customerId,
                  boxId: selectedAgreementHorse.boxId,
                  itemId: selectedItemId,
                  quantity: quantity,
                  price: fd.get("price"),
                  transactionDate: fd.get("transactionDate"),
                  billed: false,
                });
              }}
            >
              <div className="space-y-4">
                <div className="p-3 rounded-md bg-muted text-sm space-y-1">
                  <div>Horse: <strong>{selectedAgreementHorse.horseName}</strong></div>
                  <div>Customer: <strong>{selectedAgreementHorse.customerName}</strong></div>
                  <div>Location: <strong>{selectedAgreementHorse.stableName} / {selectedAgreementHorse.boxName}</strong></div>
                </div>

                <div>
                  <Label>Item</Label>
                  <Select value={selectedItemId} onValueChange={(val) => {
                    setSelectedItemId(val);
                  }}>
                    <SelectTrigger data-testid="select-billing-item">
                      <SelectValue placeholder="Select item..." />
                    </SelectTrigger>
                    <SelectContent>
                      {nonLiveryItems.map(i => (
                        <SelectItem key={i.id} value={i.id}>
                          {i.name} {i.base ? `(base: ${i.base})` : ""} {i.price ? `- AED ${i.price}` : ""}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label>Quantity</Label>
                  <Input
                    name="quantity"
                    type="number"
                    min="1"
                    value={quantity}
                    onChange={(e) => setQuantity(parseInt(e.target.value) || 1)}
                    data-testid="input-billing-quantity"
                  />
                </div>

                <div>
                  <Label>Unit Price (AED)</Label>
                  <Input
                    name="price"
                    type="number"
                    step="0.01"
                    defaultValue={selectedItem?.price || ""}
                    key={selectedItemId}
                    data-testid="input-billing-price"
                  />
                </div>

                {selectedItem && (
                  <div className="p-3 rounded-md bg-primary/5 border text-sm space-y-1">
                    <div className="flex justify-between">
                      <span>Unit Price:</span>
                      <span>AED {unitPrice.toFixed(2)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Quantity:</span>
                      <span>{quantity}</span>
                    </div>
                    <div className="flex justify-between font-semibold border-t pt-1 mt-1">
                      <span>Total Price:</span>
                      <span>AED {totalPrice.toFixed(2)}</span>
                    </div>
                  </div>
                )}

                <div>
                  <Label>Transaction Date</Label>
                  <Input name="transactionDate" type="date" required data-testid="input-billing-date" />
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={createMutation.isPending || !selectedItemId} data-testid="button-submit-billing">
                  Save
                </Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
