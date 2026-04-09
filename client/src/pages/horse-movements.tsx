import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { useLocation } from "wouter";
import { queryClient, apiRequest } from "@/lib/queryClient";
import { useToast } from "@/hooks/use-toast";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { ArrowRightLeft, MoveRight, X, Search, Filter, Plus } from "lucide-react";
import { Horseshoe } from "@/components/icons/horseshoe";

interface BoxGridItem {
  id: string;
  name: string;
  type: string;
  stableId: string;
  stableName: string;
  status: string;
  isOccupied: boolean;
  movementId: string | null;
  horseId: string | null;
  horseName: string | null;
  customerId: string | null;
  customerName: string | null;
  agreementId: string | null;
  itemName: string | null;
  checkIn: string | null;
}

interface EnrichedMovement {
  id: string;
  agreementId: string | null;
  horseId: string;
  stableboxId: string;
  checkIn: string;
  checkOut: string | null;
  createdAt: string;
  horseName: string;
  customerName: string;
  boxName: string;
  stableName: string;
}

interface HorseOwnershipEntry {
  id: string;
  horseId: string;
  customerId: string;
}

interface HorseEntry {
  id: string;
  horseName: string;
  status: string;
}

export default function HorseMovementsPage() {
  const { toast } = useToast();
  const [, navigate] = useLocation();
  const [selectedBox, setSelectedBox] = useState<BoxGridItem | null>(null);
  const [moveDialogOpen, setMoveDialogOpen] = useState(false);
  const [swapDialogOpen, setSwapDialogOpen] = useState(false);
  const [targetBoxId, setTargetBoxId] = useState("");
  const [swapHorseId, setSwapHorseId] = useState("");
  const [stableFilter, setStableFilter] = useState("all");
  const [logCustomerFilter, setLogCustomerFilter] = useState("");
  const [logBoxFilter, setLogBoxFilter] = useState("");

  const { data: boxGrid = [], isLoading: gridLoading } = useQuery<BoxGridItem[]>({
    queryKey: ["/api/box-grid"],
  });

  const { data: movementLog = [], isLoading: logLoading } = useQuery<EnrichedMovement[]>({
    queryKey: ["/api/horse-movements/enriched"],
  });

  const { data: customerHorses = [] } = useQuery<HorseOwnershipEntry[]>({
    queryKey: ["/api/horse-ownership/customer", selectedBox?.customerId],
    enabled: !!selectedBox?.customerId && swapDialogOpen,
  });

  const { data: allHorses = [] } = useQuery<HorseEntry[]>({
    queryKey: ["/api/horses"],
    enabled: swapDialogOpen,
  });

  const activeHorseIds = useMemo(() => {
    return new Set(boxGrid.filter(b => b.isOccupied && b.horseId).map(b => b.horseId!));
  }, [boxGrid]);

  const eligibleSwapHorses = useMemo(() => {
    const customerHorseIds = new Set(customerHorses.map(ch => ch.horseId));
    return allHorses.filter(h =>
      customerHorseIds.has(h.id) &&
      h.id !== selectedBox?.horseId &&
      !activeHorseIds.has(h.id) &&
      h.status === "active"
    );
  }, [customerHorses, allHorses, selectedBox, activeHorseIds]);

  const stables = useMemo(() => {
    const set = new Set(boxGrid.map(b => b.stableName));
    return Array.from(set).sort();
  }, [boxGrid]);

  const filteredGrid = useMemo(() => {
    if (stableFilter === "all") return boxGrid;
    return boxGrid.filter(b => b.stableName === stableFilter);
  }, [boxGrid, stableFilter]);

  const groupedByStable = useMemo(() => {
    const groups: Record<string, BoxGridItem[]> = {};
    filteredGrid.forEach(b => {
      if (!groups[b.stableName]) groups[b.stableName] = [];
      groups[b.stableName].push(b);
    });
    Object.values(groups).forEach(g => g.sort((a, b) => a.name.localeCompare(b.name)));
    return groups;
  }, [filteredGrid]);

  const emptyBoxes = useMemo(() => {
    return boxGrid.filter(b => !b.isOccupied);
  }, [boxGrid]);

  const filteredLog = useMemo(() => {
    let result = movementLog;
    if (logCustomerFilter) {
      result = result.filter(m => m.customerName.toLowerCase().includes(logCustomerFilter.toLowerCase()));
    }
    if (logBoxFilter) {
      result = result.filter(m => m.boxName.toLowerCase().includes(logBoxFilter.toLowerCase()) || m.stableName.toLowerCase().includes(logBoxFilter.toLowerCase()));
    }
    return result;
  }, [movementLog, logCustomerFilter, logBoxFilter]);

  const moveMutation = useMutation({
    mutationFn: async (data: { movementId: string; newBoxId: string }) => {
      const res = await apiRequest("POST", "/api/horse-movements/move", data);
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/box-grid"] });
      queryClient.invalidateQueries({ queryKey: ["/api/horse-movements/enriched"] });
      setMoveDialogOpen(false);
      setSelectedBox(null);
      setTargetBoxId("");
      toast({ title: "Horse moved successfully" });
    },
    onError: (err: Error) => {
      toast({ title: "Move failed", description: err.message, variant: "destructive" });
    },
  });

  const swapMutation = useMutation({
    mutationFn: async (data: { movementId: string; newHorseId: string }) => {
      const res = await apiRequest("POST", "/api/horse-movements/swap", data);
      return res.json();
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/box-grid"] });
      queryClient.invalidateQueries({ queryKey: ["/api/horse-movements/enriched"] });
      setSwapDialogOpen(false);
      setSelectedBox(null);
      setSwapHorseId("");
      toast({ title: "Horse swapped successfully" });
    },
    onError: (err: Error) => {
      toast({ title: "Swap failed", description: err.message, variant: "destructive" });
    },
  });

  const handleBoxClick = (box: BoxGridItem) => {
    if (box.isOccupied) {
      setSelectedBox(box);
    } else {
      navigate("/agreements/new");
    }
  };

  const handleMove = () => {
    if (!selectedBox?.movementId || !targetBoxId) return;
    moveMutation.mutate({ movementId: selectedBox.movementId, newBoxId: targetBoxId });
  };

  const handleSwap = () => {
    if (!selectedBox?.movementId || !swapHorseId) return;
    swapMutation.mutate({ movementId: selectedBox.movementId, newHorseId: swapHorseId });
  };

  const occupiedCount = boxGrid.filter(b => b.isOccupied).length;
  const totalCount = boxGrid.length;

  const formatDate = (dateStr: string | null) => {
    if (!dateStr) return "—";
    return dateStr;
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold" data-testid="text-page-title">Horse Movements</h1>
          <p className="text-muted-foreground" data-testid="text-occupancy-summary">
            {occupiedCount} occupied / {totalCount} total boxes
          </p>
        </div>
      </div>

      <div className="space-y-4">
          <div className="flex items-center gap-3">
            <Filter className="w-4 h-4 text-muted-foreground" />
            <Select value={stableFilter} onValueChange={setStableFilter}>
              <SelectTrigger className="w-[200px]" data-testid="select-stable-filter">
                <SelectValue placeholder="All Stables" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">All Stables</SelectItem>
                {stables.map(s => (
                  <SelectItem key={s} value={s}>{s}</SelectItem>
                ))}
              </SelectContent>
            </Select>
            <div className="flex gap-3 ml-auto text-sm text-muted-foreground">
              <div className="flex items-center gap-1.5">
                <div className="w-3 h-3 rounded bg-emerald-500/20 border border-emerald-500" />
                <span>Occupied</span>
              </div>
              <div className="flex items-center gap-1.5">
                <div className="w-3 h-3 rounded bg-muted border border-border" />
                <span>Empty</span>
              </div>
            </div>
          </div>

          {gridLoading ? (
            <div className="flex justify-center py-12">
              <p className="text-muted-foreground">Loading boxes...</p>
            </div>
          ) : (
            Object.entries(groupedByStable).map(([stableName, stableBoxes]) => (
              <div key={stableName} className="space-y-2">
                <h3 className="text-sm font-medium text-muted-foreground uppercase tracking-wider">{stableName}</h3>
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8 gap-2">
                  {stableBoxes.map(box => (
                    <button
                      key={box.id}
                      onClick={() => handleBoxClick(box)}
                      className={`relative p-3 rounded-lg border text-left transition-all cursor-pointer ${
                        selectedBox?.id === box.id
                          ? "ring-2 ring-primary border-primary"
                          : box.isOccupied
                            ? "bg-emerald-500/10 border-emerald-500/30 hover:border-emerald-500/60"
                            : "bg-muted/30 border-border hover:border-primary/40 hover:bg-muted/50"
                      }`}
                      data-testid={`box-cell-${box.id}`}
                    >
                      <div className="text-xs font-semibold truncate" data-testid={`text-box-name-${box.id}`}>{box.name}</div>
                      {box.isOccupied ? (
                        <div className="mt-1">
                          <div className="flex items-center gap-1">
                            <Horseshoe className="w-3 h-3 shrink-0" />
                            <span className="text-xs truncate" data-testid={`text-horse-name-${box.id}`}>{box.horseName}</span>
                          </div>
                          <div className="text-[10px] text-muted-foreground truncate" data-testid={`text-customer-name-${box.id}`}>{box.customerName}</div>
                        </div>
                      ) : (
                        <div className="mt-1 flex items-center gap-1">
                          <Plus className="w-3 h-3 text-muted-foreground" />
                          <span className="text-[10px] text-muted-foreground">Empty</span>
                        </div>
                      )}
                    </button>
                  ))}
                </div>
              </div>
            ))
          )}

          {selectedBox && (
            <Card className="border-primary" data-testid="card-box-detail">
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-base">
                    {selectedBox.name} — {selectedBox.stableName}
                  </CardTitle>
                  <Button variant="ghost" size="icon" onClick={() => setSelectedBox(null)} data-testid="button-close-detail">
                    <X className="w-4 h-4" />
                  </Button>
                </div>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <span className="text-muted-foreground">Horse:</span>
                    <span className="ml-2 font-medium" data-testid="text-detail-horse">{selectedBox.horseName}</span>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Customer:</span>
                    <span className="ml-2 font-medium" data-testid="text-detail-customer">{selectedBox.customerName}</span>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Package:</span>
                    <span className="ml-2" data-testid="text-detail-package">{selectedBox.itemName || "—"}</span>
                  </div>
                  <div>
                    <span className="text-muted-foreground">Checked In:</span>
                    <span className="ml-2" data-testid="text-detail-checkin">{selectedBox.checkIn || "—"}</span>
                  </div>
                </div>
                <div className="flex gap-2 pt-2">
                  <Button
                    size="sm"
                    onClick={() => setMoveDialogOpen(true)}
                    disabled={emptyBoxes.length === 0}
                    data-testid="button-move-horse"
                  >
                    <MoveRight className="w-4 h-4 mr-1" />
                    Move to Empty Box
                  </Button>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => setSwapDialogOpen(true)}
                    data-testid="button-swap-horse"
                  >
                    <ArrowRightLeft className="w-4 h-4 mr-1" />
                    Swap Horse
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}
      </div>

      <div className="space-y-4">
          <h2 className="text-lg font-semibold" data-testid="text-movement-log-title">Movement Log</h2>
          <div className="flex items-center gap-3">
            <div className="relative">
              <Search className="absolute left-2.5 top-2.5 w-4 h-4 text-muted-foreground" />
              <Input
                placeholder="Filter by customer..."
                className="pl-8 w-[200px]"
                value={logCustomerFilter}
                onChange={e => setLogCustomerFilter(e.target.value)}
                data-testid="input-filter-customer"
              />
            </div>
            <div className="relative">
              <Search className="absolute left-2.5 top-2.5 w-4 h-4 text-muted-foreground" />
              <Input
                placeholder="Filter by box/stable..."
                className="pl-8 w-[200px]"
                value={logBoxFilter}
                onChange={e => setLogBoxFilter(e.target.value)}
                data-testid="input-filter-box"
              />
            </div>
          </div>

          {logLoading ? (
            <div className="flex justify-center py-12">
              <p className="text-muted-foreground">Loading movements...</p>
            </div>
          ) : filteredLog.length === 0 ? (
            <div className="text-center py-12 text-muted-foreground" data-testid="text-no-movements">
              No movement records found
            </div>
          ) : (
            <div className="rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Date</TableHead>
                    <TableHead>Horse</TableHead>
                    <TableHead>Customer</TableHead>
                    <TableHead>Box</TableHead>
                    <TableHead>Check In</TableHead>
                    <TableHead>Check Out</TableHead>
                    <TableHead>Status</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {filteredLog.map(m => (
                    <TableRow key={m.id} data-testid={`row-movement-${m.id}`}>
                      <TableCell className="text-muted-foreground" data-testid={`text-log-date-${m.id}`}>
                        {m.createdAt ? new Date(m.createdAt).toLocaleDateString() : "—"}
                      </TableCell>
                      <TableCell className="font-medium" data-testid={`text-log-horse-${m.id}`}>{m.horseName}</TableCell>
                      <TableCell data-testid={`text-log-customer-${m.id}`}>{m.customerName}</TableCell>
                      <TableCell data-testid={`text-log-box-${m.id}`}>{m.boxName} ({m.stableName})</TableCell>
                      <TableCell>{formatDate(m.checkIn)}</TableCell>
                      <TableCell>{formatDate(m.checkOut)}</TableCell>
                      <TableCell>
                        {m.checkOut ? (
                          <Badge variant="secondary" data-testid={`badge-status-${m.id}`}>Closed</Badge>
                        ) : (
                          <Badge className="bg-emerald-500/10 text-emerald-700 border-emerald-500/30" data-testid={`badge-status-${m.id}`}>Active</Badge>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
      </div>

      <Dialog open={moveDialogOpen} onOpenChange={setMoveDialogOpen}>
        <DialogContent data-testid="dialog-move-horse">
          <DialogHeader>
            <DialogTitle>Move {selectedBox?.horseName} to Empty Box</DialogTitle>
          </DialogHeader>
          <div className="space-y-3">
            <p className="text-sm text-muted-foreground">
              Currently in: <strong>{selectedBox?.name}</strong> ({selectedBox?.stableName})
            </p>
            <Select value={targetBoxId} onValueChange={setTargetBoxId}>
              <SelectTrigger data-testid="select-target-box">
                <SelectValue placeholder="Select target box..." />
              </SelectTrigger>
              <SelectContent>
                {emptyBoxes.map(b => (
                  <SelectItem key={b.id} value={b.id}>{b.name} — {b.stableName}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setMoveDialogOpen(false)} data-testid="button-cancel-move">Cancel</Button>
            <Button onClick={handleMove} disabled={!targetBoxId || moveMutation.isPending} data-testid="button-confirm-move">
              {moveMutation.isPending ? "Moving..." : "Confirm Move"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={swapDialogOpen} onOpenChange={setSwapDialogOpen}>
        <DialogContent data-testid="dialog-swap-horse">
          <DialogHeader>
            <DialogTitle>Swap Horse in {selectedBox?.name}</DialogTitle>
          </DialogHeader>
          <div className="space-y-3">
            <p className="text-sm text-muted-foreground">
              Replace <strong>{selectedBox?.horseName}</strong> with another horse from {selectedBox?.customerName}
            </p>
            {eligibleSwapHorses.length === 0 ? (
              <p className="text-sm text-muted-foreground italic" data-testid="text-no-eligible-horses">
                No other eligible horses available for this customer.
              </p>
            ) : (
              <Select value={swapHorseId} onValueChange={setSwapHorseId}>
                <SelectTrigger data-testid="select-swap-horse">
                  <SelectValue placeholder="Select horse..." />
                </SelectTrigger>
                <SelectContent>
                  {eligibleSwapHorses.map(h => (
                    <SelectItem key={h.id} value={h.id}>{h.horseName}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setSwapDialogOpen(false)} data-testid="button-cancel-swap">Cancel</Button>
            <Button onClick={handleSwap} disabled={!swapHorseId || swapMutation.isPending || eligibleSwapHorses.length === 0} data-testid="button-confirm-swap">
              {swapMutation.isPending ? "Swapping..." : "Confirm Swap"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
