import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { SearchBar } from "@/components/search-bar";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, Check, X } from "lucide-react";
import type { Customer, Item } from "@shared/schema";

export default function NewAgreementPage() {
  const [stableSearch, setStableSearch] = useState("");
  const [boxSearch, setBoxSearch] = useState("");
  const [availableOnly, setAvailableOnly] = useState(true);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [selectedBox, setSelectedBox] = useState<any>(null);
  const [agreementType, setAgreementType] = useState("permanent");
  const [selectedCustomerId, setSelectedCustomerId] = useState("");
  const [selectedHorseId, setSelectedHorseId] = useState("");
  const [selectedItemId, setSelectedItemId] = useState("");
  const { toast } = useToast();

  const { data: boxesWithStatus = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/boxes-with-status"],
  });

  const { data: customers = [] } = useQuery<Customer[]>({
    queryKey: ["/api/customers"],
  });

  const { data: horses = [] } = useQuery<any[]>({
    queryKey: ["/api/horses"],
  });

  const { data: liveryItems = [] } = useQuery<Item[]>({
    queryKey: ["/api/items/livery-packages"],
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/livery-agreements", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/boxes-with-status"] });
      queryClient.invalidateQueries({ queryKey: ["/api/livery-agreements"] });
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
    if (availableOnly) {
      result = result.filter(b => b.isAvailable);
    }
    return result;
  }, [boxesWithStatus, stableSearch, boxSearch, availableOnly]);

  const groupedByStable = useMemo(() => {
    const groups: Record<string, any[]> = {};
    for (const box of filteredBoxes) {
      if (!groups[box.stableName]) groups[box.stableName] = [];
      groups[box.stableName].push(box);
    }
    return groups;
  }, [filteredBoxes]);

  const selectedItem = liveryItems.find(i => i.id === selectedItemId);

  return (
    <div className="p-6">
      <PageHeader
        title="New Agreement"
        description="Create livery agreements by selecting available boxes"
      />

      <div className="flex items-center gap-4 mb-6 flex-wrap">
        <SearchBar placeholder="Search stable..." value={stableSearch} onChange={setStableSearch} className="w-52" />
        <SearchBar placeholder="Search box..." value={boxSearch} onChange={setBoxSearch} className="w-52" />
        <div className="flex items-center gap-2">
          <Switch
            checked={availableOnly}
            onCheckedChange={setAvailableOnly}
            data-testid="switch-available-only"
          />
          <Label className="text-sm">Available only</Label>
        </div>
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
                        <Badge variant={box.isAvailable ? "default" : "secondary"}>
                          {box.isAvailable ? "Available" : "Occupied"}
                        </Badge>
                      </div>
                      {box.isAvailable && (
                        <Button
                          size="sm"
                          className="w-full mt-2"
                          onClick={() => { setSelectedBox(box); setShowCreateDialog(true); }}
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
                  monthlyAmount: selectedItem?.price || "0",
                });
              }}
            >
              <div className="space-y-4">
                <div className="p-3 rounded-md bg-muted text-sm">
                  Box: <strong>{selectedBox.name}</strong> ({selectedBox.stableName})
                </div>

                <div>
                  <Label>Customer</Label>
                  <Select value={selectedCustomerId} onValueChange={setSelectedCustomerId}>
                    <SelectTrigger data-testid="select-agreement-customer">
                      <SelectValue placeholder="Select customer..." />
                    </SelectTrigger>
                    <SelectContent>
                      {customers.filter(c => c.status === "active").map(c => (
                        <SelectItem key={c.id} value={c.id}>{c.firstname} {c.lastname}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label>Horse</Label>
                  <Select value={selectedHorseId} onValueChange={setSelectedHorseId}>
                    <SelectTrigger data-testid="select-agreement-horse">
                      <SelectValue placeholder="Select horse..." />
                    </SelectTrigger>
                    <SelectContent>
                      {horses.filter((h: any) => h.status === "active").map((h: any) => (
                        <SelectItem key={h.id} value={h.id}>{h.horseName}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label>Livery Package</Label>
                  <Select value={selectedItemId} onValueChange={setSelectedItemId}>
                    <SelectTrigger data-testid="select-agreement-item">
                      <SelectValue placeholder="Select livery package..." />
                    </SelectTrigger>
                    <SelectContent>
                      {liveryItems.map(i => (
                        <SelectItem key={i.id} value={i.id}>{i.name} (${i.price}/mo)</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

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
