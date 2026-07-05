import { useState, useEffect } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { SearchBar } from "@/components/search-bar";
import { DataTable } from "@/components/data-table";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { useToast } from "@/hooks/use-toast";
import { useCan } from "@/hooks/use-permissions";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { UserCog, MoreVertical, History } from "lucide-react";
import type { RsHorseStatus } from "@shared/schema";

interface HorseWithOwner {
  horseId: string;
  horseName: string;
  ownerId: string | null;
  ownerName: string;
  boxId: string | null;
  boxName: string | null;
  stableName: string | null;
  isRidingSchoolHorse: boolean;
}

interface RsHorse extends HorseWithOwner {
  status: RsHorseStatus | null;
}

const MOOD_LABELS: Record<string, string> = {
  fit: "Fit",
  lame: "Lame",
  needs_training: "Needs Training",
  injured: "Injured",
};

const MOOD_COLORS: Record<string, string> = {
  fit: "text-green-600",
  lame: "text-red-600",
  needs_training: "text-amber-600",
  injured: "text-red-600",
};

function AssignHorsesDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  const { toast } = useToast();
  const [search, setSearch] = useState("");
  const [ownerFilter, setOwnerFilter] = useState("");
  const [selected, setSelected] = useState<Set<string>>(new Set());

  const { data: allHorses = [], isLoading } = useQuery<HorseWithOwner[]>({
    queryKey: ["/api/horses-with-owners"],
    enabled: open,
  });

  // Re-seed the selection from current membership every time the dialog opens.
  useEffect(() => {
    if (open && allHorses.length > 0) {
      setSelected(new Set(allHorses.filter((h) => h.isRidingSchoolHorse).map((h) => h.horseId)));
    }
    if (!open) {
      setSearch("");
      setOwnerFilter("");
    }
  }, [open, allHorses]);

  const toggle = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  const saveMutation = useMutation({
    mutationFn: () => apiRequest("POST", "/api/riding-school/horses/assignments", { horseIds: Array.from(selected) }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/horses"] });
      queryClient.invalidateQueries({ queryKey: ["/api/horses-with-owners"] });
      toast({ title: "Riding School roster updated" });
      onOpenChange(false);
    },
    onError: (e: any) => toast({ title: "Failed to update roster", description: e.message, variant: "destructive" as any }),
  });

  const filtered = allHorses.filter((h) => {
    const matchesName = !search || h.horseName.toLowerCase().includes(search.toLowerCase());
    const matchesOwner = !ownerFilter || h.ownerName.toLowerCase().includes(ownerFilter.toLowerCase());
    return matchesName && matchesOwner;
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader><DialogTitle>Assign Riding School Horses</DialogTitle></DialogHeader>
        <div className="grid grid-cols-2 gap-2">
          <SearchBar placeholder="Search horse name..." value={search} onChange={setSearch} data-testid="input-assign-search-horse" />
          <SearchBar placeholder="Search owner..." value={ownerFilter} onChange={setOwnerFilter} data-testid="input-assign-search-owner" />
        </div>
        <div className="text-sm text-muted-foreground">
          {selected.size} horse{selected.size !== 1 ? "s" : ""} selected
        </div>
        <div className="space-y-1 max-h-96 overflow-y-auto border rounded-md p-2">
          {isLoading ? (
            <div className="text-muted-foreground p-4">Loading horses...</div>
          ) : filtered.length === 0 ? (
            <div className="text-muted-foreground p-4 text-center">No horses found</div>
          ) : (
            filtered.map((h) => (
              <div
                key={h.horseId}
                className={`flex items-center gap-3 p-2 rounded-md cursor-pointer transition-colors ${
                  selected.has(h.horseId) ? "bg-primary/5" : ""
                }`}
                onClick={() => toggle(h.horseId)}
                data-testid={`item-horse-toggle-${h.horseId}`}
              >
                <Checkbox checked={selected.has(h.horseId)} onCheckedChange={() => toggle(h.horseId)} />
                <div className="flex-1">
                  <div className="font-medium">{h.horseName}</div>
                  <div className="text-xs text-muted-foreground">Owner: {h.ownerName}</div>
                </div>
              </div>
            ))
          )}
        </div>
        <DialogFooter className="mt-4">
          <Button onClick={() => saveMutation.mutate()} disabled={saveMutation.isPending} data-testid="button-save-roster">
            Save
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

function StatusDialog({ horse, onOpenChange }: { horse: RsHorse | null; onOpenChange: (open: boolean) => void }) {
  const { toast } = useToast();
  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", `/api/riding-school/horses/${horse!.horseId}/status`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/horses"] });
      toast({ title: "Status recorded" });
      onOpenChange(false);
    },
    onError: (e: any) => toast({ title: "Failed to record status", description: e.message, variant: "destructive" as any }),
  });

  return (
    <Dialog open={!!horse} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader><DialogTitle>Update Status — {horse?.horseName}</DialogTitle></DialogHeader>
        {horse && (
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({
                mood: fd.get("mood"),
                maxLessonsPerDay: fd.get("maxLessonsPerDay") ? Number(fd.get("maxLessonsPerDay")) : undefined,
                maxLessonsPerWeek: fd.get("maxLessonsPerWeek") ? Number(fd.get("maxLessonsPerWeek")) : undefined,
                note: fd.get("note") || undefined,
              });
            }}
          >
            <div className="space-y-4">
              <div>
                <Label>Mood</Label>
                <Select name="mood" defaultValue={horse.status?.mood || "fit"}>
                  <SelectTrigger data-testid="select-horse-mood"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {Object.entries(MOOD_LABELS).map(([value, label]) => (
                      <SelectItem key={value} value={value}>{label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <Label>Max Lessons / Day</Label>
                  <Input name="maxLessonsPerDay" type="number" min={0} defaultValue={horse.status?.maxLessonsPerDay ?? ""} data-testid="input-max-lessons-day" />
                </div>
                <div>
                  <Label>Max Lessons / Week</Label>
                  <Input name="maxLessonsPerWeek" type="number" min={0} defaultValue={horse.status?.maxLessonsPerWeek ?? ""} data-testid="input-max-lessons-week" />
                </div>
              </div>
              <div>
                <Label>Note</Label>
                <Input name="note" placeholder="Optional note" data-testid="input-status-note" />
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-status">Save</Button>
            </DialogFooter>
          </form>
        )}
      </DialogContent>
    </Dialog>
  );
}

function HistoryDialog({ horse, onOpenChange }: { horse: RsHorse | null; onOpenChange: (open: boolean) => void }) {
  const { data: history = [], isLoading } = useQuery<RsHorseStatus[]>({
    queryKey: [`/api/riding-school/horses/${horse?.horseId}/status-history`],
    enabled: !!horse,
  });

  return (
    <Dialog open={!!horse} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader><DialogTitle>Status History — {horse?.horseName}</DialogTitle></DialogHeader>
        <div className="space-y-2 max-h-96 overflow-y-auto">
          {isLoading ? (
            <div className="text-muted-foreground">Loading...</div>
          ) : history.length === 0 ? (
            <div className="text-muted-foreground text-center py-4">No status recorded yet</div>
          ) : (
            history.map((entry) => (
              <div key={entry.id} className="border rounded-md p-3 text-sm">
                <div className="flex items-center justify-between">
                  <span className={`font-medium ${MOOD_COLORS[entry.mood] || ""}`}>{MOOD_LABELS[entry.mood] || entry.mood}</span>
                  <span className="text-xs text-muted-foreground">
                    {entry.createdAt ? new Date(entry.createdAt).toLocaleString() : ""}
                  </span>
                </div>
                <div className="text-xs text-muted-foreground mt-1">
                  Max/day: {entry.maxLessonsPerDay ?? "—"} · Max/week: {entry.maxLessonsPerWeek ?? "—"}
                </div>
                {entry.note && <div className="text-xs mt-1">{entry.note}</div>}
              </div>
            ))
          )}
        </div>
      </DialogContent>
    </Dialog>
  );
}

export default function HorseManagementPage() {
  const [search, setSearch] = useState("");
  const [showAssign, setShowAssign] = useState(false);
  const [statusHorse, setStatusHorse] = useState<RsHorse | null>(null);
  const [historyHorse, setHistoryHorse] = useState<RsHorse | null>(null);
  const canManage = useCan("riding_school.horses.manage");

  const { data: horses = [], isLoading } = useQuery<RsHorse[]>({ queryKey: ["/api/riding-school/horses"] });

  const filteredHorses = horses.filter((h) => !search || h.horseName.toLowerCase().includes(search.toLowerCase()));

  const columns = [
    { key: "horseName", label: "Horse" },
    { key: "ownerName", label: "Owner" },
    {
      key: "mood", label: "Mood",
      render: (row: RsHorse) => row.status
        ? <span className={MOOD_COLORS[row.status.mood] || ""}>{MOOD_LABELS[row.status.mood] || row.status.mood}</span>
        : <span className="text-muted-foreground">Not set</span>,
    },
    { key: "maxPerDay", label: "Max / Day", render: (row: RsHorse) => row.status?.maxLessonsPerDay ?? "—" },
    { key: "maxPerWeek", label: "Max / Week", render: (row: RsHorse) => row.status?.maxLessonsPerWeek ?? "—" },
    {
      key: "updatedAt", label: "Last Updated",
      render: (row: RsHorse) => row.status?.createdAt ? new Date(row.status.createdAt).toLocaleDateString() : "—",
    },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Horse Management"
        description="Horses assigned to the Riding School — wellbeing, mood, and lesson limits"
        actions={canManage ? (
          <Button onClick={() => setShowAssign(true)} data-testid="button-assign-horses">
            <UserCog className="w-4 h-4 mr-2" />Assign Riding School Horses
          </Button>
        ) : undefined}
      />
      <SearchBar value={search} onChange={setSearch} placeholder="Search horses..." />
      <div className="mt-4">
        <DataTable
          columns={columns}
          data={filteredHorses}
          isLoading={isLoading}
          emptyMessage={'No horses assigned to the Riding School yet — use "Assign Riding School Horses" to add some.'}
          actions={canManage ? (item: RsHorse) => (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" data-testid={`button-actions-horse-${item.horseId}`}><MoreVertical className="w-4 h-4" /></Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent>
                <DropdownMenuItem onClick={() => setStatusHorse(item)} data-testid={`button-update-status-${item.horseId}`}>
                  <UserCog className="w-4 h-4 mr-2" />Update Status
                </DropdownMenuItem>
                <DropdownMenuItem onClick={() => setHistoryHorse(item)} data-testid={`button-view-history-${item.horseId}`}>
                  <History className="w-4 h-4 mr-2" />View History
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          ) : undefined}
        />
      </div>

      <AssignHorsesDialog open={showAssign} onOpenChange={setShowAssign} />
      <StatusDialog horse={statusHorse} onOpenChange={(open) => !open && setStatusHorse(null)} />
      <HistoryDialog horse={historyHorse} onOpenChange={(open) => !open && setHistoryHorse(null)} />
    </div>
  );
}
