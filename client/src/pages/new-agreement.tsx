import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { SearchBar } from "@/components/search-bar";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus } from "lucide-react";
import type { Customer, Item } from "@shared/schema";

export default function NewAgreementPage() {
  const [stableSearch, setStableSearch] = useState("");
  const [boxSearch, setBoxSearch] = useState("");
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [selectedBox, setSelectedBox] = useState<any>(null);
  const [agreementType, setAgreementType] = useState("permanent");
  const [selectedCustomerId, setSelectedCustomerId] = useState("");
  const [customerSearch, setCustomerSearch] = useState("");
  const [customerDropdownOpen, setCustomerDropdownOpen] = useState(false);
  const [selectedHorseId, setSelectedHorseId] = useState("");
  const [horseSearch, setHorseSearch] = useState("");
  const [horseDropdownOpen, setHorseDropdownOpen] = useState(false);
  const [selectedItemId, setSelectedItemId] = useState("");
  const [monthlyAmount, setMonthlyAmount] = useState("");
  const { toast } = useToast();

  const { data: boxesWithStatus = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/boxes-with-status"],
  });

  const { data: customers = [] } = useQuery<Customer[]>({
    queryKey: ["/api/customers"],
  });

  const { data: horses = [] } = useQuery<any[]>({
    queryKey: ["/api/horses/available"],
  });

  const { data: liveryItems = [] } = useQuery<Item[]>({
    queryKey: ["/api/items/livery-packages"],
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/livery-agreements", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/boxes-with-status"] });
      queryClient.invalidateQueries({ queryKey: ["/api/livery-agreements"] });
      queryClient.invalidateQueries({ queryKey: ["/api/horses/available"] });
      setShowCreateDialog(false);
      toast({ title: "Livery agreement created successfully" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to create agreement", description: error.message, variant: "destructive" });
    },
  });

  const filteredBoxes = useMemo(() => {
    let result = boxesWithStatus;
    if (stableSearch) {
      result = result.filter(b => b.stableName.toLowerCase().includes(stableSearch.toLowerCase()));
    }
    if (boxSearch) {
      result = result.filter(b => b.name.toLowerCase().includes(boxSearch.toLowerCase()));
    }
    return result;
  }, [boxesWithStatus, stableSearch, boxSearch]);

  const groupedByStable = useMemo(() => {
    const groups: Record<string, any[]> = {};
    for (const box of filteredBoxes) {
      if (!groups[box.stableName]) groups[box.stableName] = [];
      groups[box.stableName].push(box);
    }
    return groups;
  }, [filteredBoxes]);

  const activeCustomers = useMemo(() => {
    const active = customers.filter(c => c.status === "active");
    if (!customerSearch.trim()) return active;
    const s = customerSearch.toLowerCase();
    return active.filter(c =>
      `${c.firstname} ${c.lastname}`.toLowerCase().includes(s) ||
      (c.email && c.email.toLowerCase().includes(s))
    );
  }, [customers, customerSearch]);

  const activeHorses = useMemo(() => {
    const active = horses.filter((h: any) => h.status === "active");
    if (!horseSearch.trim()) return active;
    const s = horseSearch.toLowerCase();
    return active.filter((h: any) =>
      h.horseName.toLowerCase().includes(s) ||
      (h.breed && h.breed.toLowerCase().includes(s))
    );
  }, [horses, horseSearch]);

  const selectedCustomer = customers.find(c => c.id === selectedCustomerId);
  const selectedHorse = horses.find((h: any) => h.id === selectedHorseId);
  const selectedItem = liveryItems.find(i => i.id === selectedItemId);

  const handleItemChange = (itemId: string) => {
    setSelectedItemId(itemId);
    const item = liveryItems.find(i => i.id === itemId);
    setMonthlyAmount(item?.price || "0");
  };

  const openCreateDialog = (box: any) => {
    setSelectedBox(box);
    setSelectedCustomerId("");
    setCustomerSearch("");
    setSelectedHorseId("");
    setHorseSearch("");
    setSelectedItemId("");
    setMonthlyAmount("");
    setAgreementType("permanent");
    setShowCreateDialog(true);
  };

  return (
    <div className="p-6">
      <PageHeader
        title="New Agreement"
        description="Create livery agreements by selecting available boxes"
      />

      <div className="flex items-center gap-4 mb-6 flex-wrap">
        <SearchBar placeholder="Search stable..." value={stableSearch} onChange={setStableSearch} className="w-52" />
        <SearchBar placeholder="Search box..." value={boxSearch} onChange={setBoxSearch} className="w-52" />
      </div>

      {isLoading ? (
        <div className="text-muted-foreground">Loading boxes...</div>
      ) : Object.keys(groupedByStable).length === 0 ? (
        <div className="text-center text-muted-foreground py-12">No boxes found matching your criteria</div>
      ) : (
        <div className="space-y-6">
          {Object.entries(groupedByStable).map(([stableName, stableBoxes]) => (
            <div key={stableName}>
              <h3 className="text-lg font-semibold mb-3">{stableName}</h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-3">
                {stableBoxes.map((box) => (
                  <Card key={box.id} className={`${box.isAvailable ? "" : "opacity-60"}`}>
                    <CardContent className="p-4">
                      <div className="flex items-center justify-between gap-2 mb-2">
                        <span className="font-medium">{box.name}</span>
                        {!box.isAvailable && (
                          <Badge variant="secondary">Occupied</Badge>
                        )}
                      </div>
                      {box.isAvailable && (
                        <Button
                          size="sm"
                          className="w-full mt-2"
                          onClick={() => openCreateDialog(box)}
                          data-testid={`button-new-agreement-${box.id}`}
                        >
                          <Plus className="w-4 h-4 mr-1" />
                          New Agreement
                        </Button>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}

      <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>New Livery Agreement</DialogTitle>
            <DialogDescription>Create a new livery agreement for the selected box</DialogDescription>
          </DialogHeader>
          {selectedBox && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                const refNum = `LA-${new Date().getFullYear()}-${String(Date.now()).slice(-4)}`;
                createMutation.mutate({
                  referenceNumber: refNum,
                  horseId: selectedHorseId,
                  customerId: selectedCustomerId,
                  boxId: selectedBox.id,
                  itemId: selectedItemId,
                  startDate: fd.get("startDate"),
                  endDate: agreementType === "temporary" ? fd.get("endDate") : null,
                  type: agreementType,
                  status: "active",
                  notes: fd.get("notes") || null,
                  monthlyAmount: monthlyAmount || selectedItem?.price || "0",
                });
              }}
              onKeyDown={(e) => { if (e.key === "Enter") e.preventDefault(); }}
            >
              <div className="space-y-4">
                <div className="p-3 rounded-md bg-muted text-sm">
                  Box: <strong>{selectedBox.name}</strong> ({selectedBox.stableName})
                </div>

                <div className="relative">
                  <Label>Customer</Label>
                  <div className="relative">
                    <Input
                      data-testid="input-agreement-customer-search"
                      placeholder="Search customer..."
                      value={selectedCustomer && !customerDropdownOpen ? `${selectedCustomer.firstname} ${selectedCustomer.lastname}` : customerSearch}
                      onChange={(e) => {
                        setCustomerSearch(e.target.value);
                        setCustomerDropdownOpen(true);
                        if (selectedCustomerId) setSelectedCustomerId("");
                      }}
                      onFocus={() => setCustomerDropdownOpen(true)}
                      onBlur={() => setTimeout(() => setCustomerDropdownOpen(false), 200)}
                    />
                    {selectedCustomerId && (
                      <button
                        type="button"
                        className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground text-sm"
                        onClick={() => { setSelectedCustomerId(""); setCustomerSearch(""); setCustomerDropdownOpen(true); }}
                      >✕</button>
                    )}
                  </div>
                  {customerDropdownOpen && !selectedCustomerId && (
                    <div className="absolute z-50 w-full mt-1 bg-popover border rounded-md shadow-md max-h-48 overflow-y-auto">
                      {activeCustomers.length === 0 ? (
                        <div className="p-3 text-sm text-muted-foreground">No customers found</div>
                      ) : (
                        activeCustomers.map(c => (
                          <button
                            type="button"
                            key={c.id}
                            data-testid={`agreement-customer-option-${c.id}`}
                            className="w-full text-left px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground cursor-pointer"
                            onClick={() => { setSelectedCustomerId(c.id); setCustomerSearch(""); setCustomerDropdownOpen(false); }}
                          >
                            <div className="font-medium">{c.firstname} {c.lastname}</div>
                            {c.email && <div className="text-xs text-muted-foreground">{c.email}</div>}
                          </button>
                        ))
                      )}
                    </div>
                  )}
                </div>

                <div className="relative">
                  <Label>Horse</Label>
                  <div className="relative">
                    <Input
                      data-testid="input-agreement-horse-search"
                      placeholder="Search horse..."
                      value={selectedHorse && !horseDropdownOpen ? selectedHorse.horseName : horseSearch}
                      onChange={(e) => {
                        setHorseSearch(e.target.value);
                        setHorseDropdownOpen(true);
                        if (selectedHorseId) setSelectedHorseId("");
                      }}
                      onFocus={() => setHorseDropdownOpen(true)}
                      onBlur={() => setTimeout(() => setHorseDropdownOpen(false), 200)}
                    />
                    {selectedHorseId && (
                      <button
                        type="button"
                        className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground text-sm"
                        onClick={() => { setSelectedHorseId(""); setHorseSearch(""); setHorseDropdownOpen(true); }}
                      >✕</button>
                    )}
                  </div>
                  {horseDropdownOpen && !selectedHorseId && (
                    <div className="absolute z-50 w-full mt-1 bg-popover border rounded-md shadow-md max-h-48 overflow-y-auto">
                      {activeHorses.length === 0 ? (
                        <div className="p-3 text-sm text-muted-foreground">No horses found</div>
                      ) : (
                        activeHorses.map((h: any) => (
                          <button
                            type="button"
                            key={h.id}
                            data-testid={`agreement-horse-option-${h.id}`}
                            className="w-full text-left px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground cursor-pointer"
                            onClick={() => { setSelectedHorseId(h.id); setHorseSearch(""); setHorseDropdownOpen(false); }}
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

                <div>
                  <Label>Livery Package</Label>
                  <Select value={selectedItemId} onValueChange={handleItemChange}>
                    <SelectTrigger data-testid="select-agreement-item">
                      <SelectValue placeholder="Select livery package..." />
                    </SelectTrigger>
                    <SelectContent>
                      {liveryItems.map(i => (
                        <SelectItem key={i.id} value={i.id}>{i.name} (AED {i.price}/mo)</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {selectedItem && (
                  <div>
                    <Label>Monthly Amount (AED)</Label>
                    <div className="flex items-center gap-2">
                      <Input
                        type="number"
                        step="0.01"
                        value={monthlyAmount}
                        onChange={(e) => setMonthlyAmount(e.target.value)}
                        data-testid="input-monthly-amount"
                      />
                      {monthlyAmount !== selectedItem.price && (
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => setMonthlyAmount(selectedItem.price || "0")}
                          data-testid="button-reset-price"
                          className="text-xs whitespace-nowrap"
                        >
                          Reset to {selectedItem.price}
                        </Button>
                      )}
                    </div>
                    {monthlyAmount !== selectedItem.price && (
                      <p className="text-xs text-muted-foreground mt-1">
                        Default package price: AED {selectedItem.price}
                      </p>
                    )}
                  </div>
                )}

                <div>
                  <Label>Start Date</Label>
                  <Input name="startDate" type="date" required data-testid="input-agreement-start" />
                </div>

                <div>
                  <Label>Type</Label>
                  <Select value={agreementType} onValueChange={setAgreementType}>
                    <SelectTrigger data-testid="select-agreement-type">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="permanent">Permanent</SelectItem>
                      <SelectItem value="temporary">Temporary</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {agreementType === "temporary" && (
                  <div>
                    <Label>End Date</Label>
                    <Input name="endDate" type="date" required data-testid="input-agreement-end" />
                  </div>
                )}

                <div>
                  <Label>Notes (optional)</Label>
                  <Textarea name="notes" placeholder="Additional notes..." data-testid="input-agreement-notes" />
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={createMutation.isPending || !selectedCustomerId || !selectedHorseId || !selectedItemId} data-testid="button-submit-agreement">
                  Create Agreement
                </Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
