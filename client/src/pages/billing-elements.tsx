import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { SearchBar } from "@/components/search-bar";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, UserPlus, DollarSign } from "lucide-react";
import { AlertTriangle } from "lucide-react";
import type { Item, Customer, Horse } from "@shared/schema";

function getTodayString() {
  const now = new Date();
  return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
}

function deriveBillingMonth(dateStr: string) {
  return dateStr ? dateStr.substring(0, 7) : "";
}

export default function BillingElementsPage() {
  const [horseSearch, setHorseSearch] = useState("");
  const [customerSearch, setCustomerSearch] = useState("");
  const [stableSearch, setStableSearch] = useState("");
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [showNonLiveryDialog, setShowNonLiveryDialog] = useState(false);
  const [selectedAgreementHorse, setSelectedAgreementHorse] = useState<any>(null);
  const [selectedItemId, setSelectedItemId] = useState("");
  const [itemSearch, setItemSearch] = useState("");
  const [itemDropdownOpen, setItemDropdownOpen] = useState(false);
  const [quantity, setQuantity] = useState(1);
  const [finalSellingPrice, setFinalSellingPrice] = useState("");
  const [transactionDate, setTransactionDate] = useState(getTodayString());

  const [nlCustomerId, setNlCustomerId] = useState("");
  const [nlCustomerSearch, setNlCustomerSearch] = useState("");
  const [nlCustomerDropdownOpen, setNlCustomerDropdownOpen] = useState(false);
  const [nlHorseId, setNlHorseId] = useState("");
  const [nlHorseSearch, setNlHorseSearch] = useState("");
  const [nlHorseDropdownOpen, setNlHorseDropdownOpen] = useState(false);

  const [showChangePriceDialog, setShowChangePriceDialog] = useState(false);
  const [changePriceItem, setChangePriceItem] = useState<Item | null>(null);
  const [newPrice, setNewPrice] = useState("");

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

  const { data: allCustomers = [] } = useQuery<Customer[]>({
    queryKey: ["/api/customers"],
  });

  const { data: allHorses = [] } = useQuery<any[]>({
    queryKey: ["/api/horses"],
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/billing-elements", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/billing-elements"] });
      queryClient.invalidateQueries({ queryKey: ["/api/horses-with-agreements"] });
      setShowAddDialog(false);
      setShowNonLiveryDialog(false);
      toast({ title: "Billing element added successfully" });
    },
  });

  const changePriceMutation = useMutation({
    mutationFn: (data: { itemId: string; price: string }) =>
      apiRequest("POST", `/api/items/${data.itemId}/change-price`, { price: data.price }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/items"] });
      queryClient.invalidateQueries({ queryKey: ["/api/items/non-livery-packages"] });
      queryClient.invalidateQueries({ queryKey: ["/api/items/livery-packages"] });
      setShowChangePriceDialog(false);
      setChangePriceItem(null);
      setNewPrice("");
      toast({ title: "Price updated successfully" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to update price", description: error.message, variant: "destructive" });
    },
  });

  const openChangePriceDialog = (item: Item) => {
    setChangePriceItem(item);
    setNewPrice("");
    setShowChangePriceDialog(true);
  };

  const filteredItems = useMemo(() => {
    if (!itemSearch.trim()) return nonLiveryItems;
    const search = itemSearch.toLowerCase();
    return nonLiveryItems.filter((i: Item) =>
      i.name.toLowerCase().includes(search) ||
      (i.department && i.department.toLowerCase().includes(search)) ||
      (i.location && i.location.toLowerCase().includes(search))
    );
  }, [nonLiveryItems, itemSearch]);

  const filteredHorses = useMemo(() => {
    let result = horsesWithAgreements;
    if (horseSearch) {
      result = result.filter((h: any) => (h.horseName || "").toLowerCase().includes(horseSearch.toLowerCase()));
    }
    if (customerSearch) {
      result = result.filter((h: any) => (h.customerName || "").toLowerCase().includes(customerSearch.toLowerCase()));
    }
    if (stableSearch) {
      result = result.filter((h: any) =>
        h.stableName.toLowerCase().includes(stableSearch.toLowerCase()) ||
        h.boxName.toLowerCase().includes(stableSearch.toLowerCase())
      );
    }
    return result;
  }, [horsesWithAgreements, horseSearch, customerSearch, stableSearch]);

  const filteredBillingElements = useMemo(() => {
    let result = billingElements;
    if (horseSearch) {
      result = result.filter((el: any) => el.horseName?.toLowerCase().includes(horseSearch.toLowerCase()));
    }
    if (customerSearch) {
      result = result.filter((el: any) => el.customerName?.toLowerCase().includes(customerSearch.toLowerCase()));
    }
    if (stableSearch) {
      const s = stableSearch.toLowerCase();
      result = result.filter((el: any) =>
        (el.stableName && el.stableName.toLowerCase().includes(s)) ||
        (el.boxName && el.boxName.toLowerCase().includes(s))
      );
    }
    return result;
  }, [billingElements, horseSearch, customerSearch, stableSearch]);

  const filteredNlCustomers = useMemo(() => {
    const active = allCustomers.filter(c => c.status === "active");
    if (!nlCustomerSearch.trim()) return active;
    const s = nlCustomerSearch.toLowerCase();
    return active.filter(c =>
      (c.fullname || '').toLowerCase().includes(s) ||
      (c.email && c.email.toLowerCase().includes(s))
    );
  }, [allCustomers, nlCustomerSearch]);

  const filteredNlHorses = useMemo(() => {
    const active = allHorses.filter((h: any) => h.status === "active");
    if (!nlHorseSearch.trim()) return active;
    const s = nlHorseSearch.toLowerCase();
    return active.filter((h: any) => h.horseName.toLowerCase().includes(s));
  }, [allHorses, nlHorseSearch]);

  const columns = [
    { key: "horseName", label: "Horse" },
    { key: "customerName", label: "Customer" },
    { key: "stableName", label: "Stable" },
    { key: "boxName", label: "Box" },
  ];

  const selectedItem = nonLiveryItems.find(i => i.id === selectedItemId);
  const itemPrice = selectedItem?.price ? parseFloat(selectedItem.price) : 0;
  const itemUnitFactor = selectedItem?.unitFactor ? parseFloat(selectedItem.unitFactor) : 1;
  const computedSellingPrice = itemUnitFactor > 0 ? (itemPrice / itemUnitFactor) * quantity : 0;

  const handleItemChange = (val: string) => {
    setSelectedItemId(val);
    const item = nonLiveryItems.find(i => i.id === val);
    const price = item?.price ? parseFloat(item.price) : 0;
    const uf = item?.unitFactor ? parseFloat(item.unitFactor) : 1;
    const computed = uf > 0 ? (price / uf) * quantity : 0;
    setFinalSellingPrice(computed.toFixed(2));
  };

  const handleQuantityChange = (newQty: number) => {
    setQuantity(newQty);
    if (selectedItem) {
      const computed = itemUnitFactor > 0 ? (itemPrice / itemUnitFactor) * newQty : 0;
      setFinalSellingPrice(computed.toFixed(2));
    }
  };

  const resetDialogState = () => {
    setSelectedItemId("");
    setItemSearch("");
    setItemDropdownOpen(false);
    setQuantity(1);
    setFinalSellingPrice("");
    setTransactionDate(getTodayString());
  };

  const openDialog = (horse: any) => {
    setSelectedAgreementHorse(horse);
    resetDialogState();
    setShowAddDialog(true);
  };

  const openNonLiveryDialog = () => {
    resetDialogState();
    setNlCustomerId("");
    setNlCustomerSearch("");
    setNlCustomerDropdownOpen(false);
    setNlHorseId("");
    setNlHorseSearch("");
    setNlHorseDropdownOpen(false);
    setShowNonLiveryDialog(true);
  };

  const selectedNlCustomer = allCustomers.find(c => c.id === nlCustomerId);
  const selectedNlHorse = allHorses.find((h: any) => h.id === nlHorseId);

  const itemSearchDropdown = (
    <div className="relative">
      <Label>Item</Label>
      <div className="relative">
        <Input
          data-testid="input-item-search"
          placeholder="Search items by name, department, or location..."
          value={selectedItem && !itemDropdownOpen ? `${selectedItem.name}${selectedItem.price ? ` - AED ${selectedItem.price}` : ""}` : itemSearch}
          onChange={(e) => {
            setItemSearch(e.target.value);
            setItemDropdownOpen(true);
            if (selectedItemId) {
              setSelectedItemId("");
              setFinalSellingPrice("");
            }
          }}
          onFocus={() => setItemDropdownOpen(true)}
          onBlur={() => setTimeout(() => setItemDropdownOpen(false), 200)}
        />
        {selectedItemId && (
          <button
            type="button"
            className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground text-sm"
            onClick={() => {
              setSelectedItemId("");
              setItemSearch("");
              setFinalSellingPrice("");
              setItemDropdownOpen(true);
            }}
            data-testid="button-clear-item"
          >
            ✕
          </button>
        )}
      </div>
      {itemDropdownOpen && !selectedItemId && (
        <div className="absolute z-50 w-full mt-1 bg-popover border rounded-md shadow-md max-h-48 overflow-y-auto">
          {filteredItems.length === 0 ? (
            <div className="p-3 text-sm text-muted-foreground">No items found</div>
          ) : (
            filteredItems.map(i => (
              <button
                type="button"
                key={i.id}
                data-testid={`item-option-${i.id}`}
                className="w-full text-left px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground cursor-pointer"
                onClick={() => {
                  handleItemChange(i.id);
                  setItemSearch("");
                  setItemDropdownOpen(false);
                }}
              >
                <div className="font-medium">{i.name}</div>
                <div className="text-xs text-muted-foreground">
                  {i.price ? `AED ${i.price}` : "No price"}{i.department ? ` · ${i.department}` : ""}{i.location ? ` · ${i.location}` : ""}
                </div>
              </button>
            ))
          )}
        </div>
      )}
    </div>
  );

  const pricingFields = (
    <>
      {selectedItem && (
        <div className="p-3 rounded-md bg-muted text-sm space-y-1">
          <div className="flex justify-between">
            <span>Unit Factor:</span>
            <span>{itemUnitFactor}</span>
          </div>
          <div className="flex justify-between items-center">
            <span>Base Price (per unit factor):</span>
            <span className="flex items-center gap-2">
              AED {itemPrice.toFixed(2)}
              <Button
                type="button"
                variant="outline"
                size="sm"
                className="h-6 px-2 text-xs"
                onClick={() => openChangePriceDialog(selectedItem)}
                data-testid="button-change-price"
              >
                <DollarSign className="w-3 h-3 mr-1" />
                Change Price
              </Button>
            </span>
          </div>
        </div>
      )}

      <div>
        <Label>Quantity</Label>
        <Input
          type="number"
          min="1"
          value={quantity}
          onChange={(e) => handleQuantityChange(parseInt(e.target.value) || 1)}
          data-testid="input-billing-quantity"
        />
      </div>

      {selectedItem && (
        <div className="flex gap-4 items-end">
          <div className="flex-1">
            <Label className="text-muted-foreground">Computed Price</Label>
            <Input
              type="text"
              value={`AED ${computedSellingPrice.toFixed(2)}`}
              readOnly
              className="bg-muted"
              data-testid="text-computed-price"
            />
          </div>
          <div className="flex-1">
            <Label>Final Selling Price</Label>
            <Input
              type="number"
              step="0.01"
              value={finalSellingPrice}
              onChange={(e) => setFinalSellingPrice(e.target.value)}
              data-testid="input-final-selling-price"
            />
          </div>
        </div>
      )}

      <div>
        <Label>Transaction Date</Label>
        <Input
          type="date"
          value={transactionDate}
          onChange={(e) => setTransactionDate(e.target.value)}
          required
          data-testid="input-billing-date"
        />
      </div>
    </>
  );

  return (
    <div className="p-6">
      <PageHeader
        title="Billing Elements"
        description="Add extra billable items per horse with active livery agreements"
      />

      <div className="flex gap-3 mb-4 flex-wrap items-center">
        <SearchBar placeholder="Horse..." value={horseSearch} onChange={setHorseSearch} className="w-52" />
        <SearchBar placeholder="Customer..." value={customerSearch} onChange={setCustomerSearch} className="w-52" />
        <SearchBar placeholder="Stable / Box..." value={stableSearch} onChange={setStableSearch} className="w-52" />
        <Button
          variant="outline"
          onClick={openNonLiveryDialog}
          data-testid="button-bill-non-livery"
        >
          <UserPlus className="w-4 h-4 mr-1" />
          Bill Non-Livery Customer
        </Button>
      </div>

      <DataTable
        columns={columns}
        data={filteredHorses}
        isLoading={isLoading}
        emptyMessage="No horses with active livery agreements"
        actions={(item) => (
          <Button
            size="sm"
            onClick={() => openDialog(item)}
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
                key: "price",
                label: "Selling Price",
                render: (item: any) => `AED ${parseFloat(item.price).toFixed(2)}`,
              },
              { key: "transactionDate", label: "Date" },
              { key: "billingMonth", label: "Billing Month" },
              {
                key: "billed",
                label: "Billed",
                render: (item: any) => item.billed ? "Yes" : "No",
              },
            ]}
            data={filteredBillingElements}
          />
        </div>
      )}

      <Dialog open={showAddDialog} onOpenChange={setShowAddDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Add Billing Element</DialogTitle>
            <DialogDescription>Add a billable item for the selected horse</DialogDescription>
          </DialogHeader>
          {selectedAgreementHorse && (
            <form
              onSubmit={(e) => { e.preventDefault(); }}
              onKeyDown={(e) => { if (e.key === "Enter") e.preventDefault(); }}
            >
              <div className="space-y-4">
                <div className="p-3 rounded-md bg-muted text-sm space-y-1">
                  <div>Horse: <strong>{selectedAgreementHorse.horseName}</strong></div>
                  <div>Customer: <strong>{selectedAgreementHorse.customerName}</strong></div>
                  <div>Location: <strong>{selectedAgreementHorse.stableName} / {selectedAgreementHorse.boxName}</strong></div>
                </div>

                {itemSearchDropdown}
                {pricingFields}
              </div>
              <DialogFooter className="mt-4">
                <Button
                  type="button"
                  disabled={createMutation.isPending || !selectedItemId || !finalSellingPrice}
                  data-testid="button-submit-billing"
                  onClick={() => {
                    createMutation.mutate({
                      horseId: selectedAgreementHorse.horseId,
                      customerId: selectedAgreementHorse.customerId,
                      boxId: selectedAgreementHorse.boxId,
                      itemId: selectedItemId,
                      quantity,
                      price: finalSellingPrice,
                      transactionDate,
                      billingMonth: deriveBillingMonth(transactionDate),
                      billed: false,
                    });
                  }}
                >
                  Save
                </Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>

      <Dialog open={showNonLiveryDialog} onOpenChange={setShowNonLiveryDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Bill Non-Livery Customer</DialogTitle>
            <DialogDescription>Create a billing element for a customer without a livery agreement</DialogDescription>
          </DialogHeader>
          <form
            onSubmit={(e) => { e.preventDefault(); }}
            onKeyDown={(e) => { if (e.key === "Enter") e.preventDefault(); }}
          >
            <div className="space-y-4">
              <div className="relative">
                <Label>Customer *</Label>
                <div className="relative">
                  <Input
                    data-testid="input-nl-customer-search"
                    placeholder="Search customer..."
                    value={selectedNlCustomer && !nlCustomerDropdownOpen ? selectedNlCustomer.fullname : nlCustomerSearch}
                    onChange={(e) => {
                      setNlCustomerSearch(e.target.value);
                      setNlCustomerDropdownOpen(true);
                      if (nlCustomerId) setNlCustomerId("");
                    }}
                    onFocus={() => setNlCustomerDropdownOpen(true)}
                    onBlur={() => setTimeout(() => setNlCustomerDropdownOpen(false), 200)}
                  />
                  {nlCustomerId && (
                    <button
                      type="button"
                      className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground text-sm"
                      onClick={() => { setNlCustomerId(""); setNlCustomerSearch(""); setNlCustomerDropdownOpen(true); }}
                    >✕</button>
                  )}
                </div>
                {nlCustomerDropdownOpen && !nlCustomerId && (
                  <div className="absolute z-50 w-full mt-1 bg-popover border rounded-md shadow-md max-h-48 overflow-y-auto">
                    {filteredNlCustomers.length === 0 ? (
                      <div className="p-3 text-sm text-muted-foreground">No customers found</div>
                    ) : (
                      filteredNlCustomers.map(c => (
                        <button
                          type="button"
                          key={c.id}
                          data-testid={`nl-customer-option-${c.id}`}
                          className="w-full text-left px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground cursor-pointer"
                          onClick={() => { setNlCustomerId(c.id); setNlCustomerSearch(""); setNlCustomerDropdownOpen(false); }}
                        >
                          <div className="font-medium">{c.fullname}</div>
                          {c.email && <div className="text-xs text-muted-foreground">{c.email}</div>}
                        </button>
                      ))
                    )}
                  </div>
                )}
              </div>

              <div className="relative">
                <Label>Horse *</Label>
                <div className="relative">
                  <Input
                    data-testid="input-nl-horse-search"
                    placeholder="Search horse..."
                    value={selectedNlHorse && !nlHorseDropdownOpen ? selectedNlHorse.horseName : nlHorseSearch}
                    onChange={(e) => {
                      setNlHorseSearch(e.target.value);
                      setNlHorseDropdownOpen(true);
                      if (nlHorseId) setNlHorseId("");
                    }}
                    onFocus={() => setNlHorseDropdownOpen(true)}
                    onBlur={() => setTimeout(() => setNlHorseDropdownOpen(false), 200)}
                  />
                  {nlHorseId && (
                    <button
                      type="button"
                      className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground text-sm"
                      onClick={() => { setNlHorseId(""); setNlHorseSearch(""); setNlHorseDropdownOpen(true); }}
                    >✕</button>
                  )}
                </div>
                {nlHorseDropdownOpen && !nlHorseId && (
                  <div className="absolute z-50 w-full mt-1 bg-popover border rounded-md shadow-md max-h-48 overflow-y-auto">
                    {filteredNlHorses.length === 0 ? (
                      <div className="p-3 text-sm text-muted-foreground">No horses found</div>
                    ) : (
                      filteredNlHorses.map((h: any) => (
                        <button
                          type="button"
                          key={h.id}
                          data-testid={`nl-horse-option-${h.id}`}
                          className="w-full text-left px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground cursor-pointer"
                          onClick={() => { setNlHorseId(h.id); setNlHorseSearch(""); setNlHorseDropdownOpen(false); }}
                        >
                          <div className="font-medium">{h.horseName}</div>
                          <div className="text-xs text-muted-foreground">
                            {h.breed || ""}{h.color ? ` · ${h.color}` : ""}
                          </div>
                        </button>
                      ))
                    )}
                  </div>
                )}
              </div>

              {itemSearchDropdown}
              {pricingFields}
            </div>
            <DialogFooter className="mt-4">
              <Button
                type="button"
                disabled={createMutation.isPending || !nlCustomerId || !nlHorseId || !selectedItemId || !finalSellingPrice}
                data-testid="button-submit-non-livery-billing"
                onClick={() => {
                  createMutation.mutate({
                    horseId: nlHorseId,
                    customerId: nlCustomerId,
                    boxId: null,
                    itemId: selectedItemId,
                    agreementId: null,
                    quantity,
                    price: finalSellingPrice,
                    transactionDate,
                    billingMonth: deriveBillingMonth(transactionDate),
                    billed: false,
                  });
                }}
              >
                Save
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={showChangePriceDialog} onOpenChange={setShowChangePriceDialog}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Change Item Price</DialogTitle>
            <DialogDescription>Update the price for this item</DialogDescription>
          </DialogHeader>
          {changePriceItem && (
            <div className="space-y-4">
              <div className="p-3 rounded-md bg-muted text-sm space-y-1">
                <div className="flex justify-between">
                  <span>Item:</span>
                  <span className="font-medium">{changePriceItem.name}</span>
                </div>
                <div className="flex justify-between">
                  <span>Current Price:</span>
                  <span className="font-medium">AED {changePriceItem.price ? parseFloat(changePriceItem.price).toFixed(2) : "0.00"}</span>
                </div>
                {changePriceItem.unitFactor && (
                  <div className="flex justify-between">
                    <span>Unit Factor:</span>
                    <span>{changePriceItem.unitFactor}</span>
                  </div>
                )}
              </div>

              <div>
                <Label>New Price (AED)</Label>
                <Input
                  type="number"
                  step="0.01"
                  min="0"
                  value={newPrice}
                  onChange={(e) => setNewPrice(e.target.value)}
                  placeholder="Enter new price..."
                  data-testid="input-new-price"
                />
              </div>

              <div className="flex items-start gap-2 p-3 rounded-md bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800">
                <AlertTriangle className="w-4 h-4 text-amber-600 dark:text-amber-400 mt-0.5 shrink-0" />
                <p className="text-xs text-amber-700 dark:text-amber-300">
                  This price will be used for all future billing. Existing records will not be affected.
                </p>
              </div>

              <DialogFooter>
                <Button
                  type="button"
                  disabled={changePriceMutation.isPending || !newPrice || parseFloat(newPrice) <= 0}
                  onClick={() => {
                    if (changePriceItem) {
                      changePriceMutation.mutate({ itemId: changePriceItem.id, price: newPrice });
                    }
                  }}
                  data-testid="button-submit-change-price"
                >
                  Update Price
                </Button>
              </DialogFooter>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
