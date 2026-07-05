import { useState, useEffect } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { SearchBar } from "@/components/search-bar";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { DataTable } from "@/components/data-table";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { useToast } from "@/hooks/use-toast";
import { useCan } from "@/hooks/use-permissions";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Save, Package, Pencil, Plus, MoreVertical, Trash2, GraduationCap, Ticket, Clock, Power, PowerOff } from "lucide-react";
import type { Item, LessonTemplate, RsRidingPackage, RsCancellationPolicy, RiderLevel } from "@shared/schema";

const ANY_LEVEL = "__any__";

type LessonTemplateWithUsage = LessonTemplate & { hasInstances: boolean };

function LiveryPackagesSection() {
  const [search, setSearch] = useState("");
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const { toast } = useToast();

  const { data: items = [], isLoading } = useQuery<Item[]>({ queryKey: ["/api/items"] });

  useEffect(() => {
    if (items.length > 0) {
      const ids = new Set<string>();
      items.forEach((item) => { if (item.isLiveryPackage) ids.add(item.id); });
      setSelectedIds(ids);
    }
  }, [items]);

  const saveMutation = useMutation({
    mutationFn: () => apiRequest("POST", "/api/settings/livery-packages", { itemIds: Array.from(selectedIds) }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/items"] });
      toast({ title: "Livery package configuration saved" });
    },
  });

  // With no search text, only show what's already flagged as a livery
  // package — the full item catalog is too long to list in full here.
  // Typing a search shows matches across ALL items (selected or not) so you
  // can find something new to flag, or find an already-selected item to
  // unflag without it being buried in the full list.
  const filteredItems = search
    ? items.filter((item) => item.name.toLowerCase().includes(search.toLowerCase()))
    : items.filter((item) => selectedIds.has(item.id));

  const toggleItem = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Package className="w-5 h-5" />
            Livery Packages
          </CardTitle>
          <Button onClick={() => saveMutation.mutate()} disabled={saveMutation.isPending} data-testid="button-save-settings">
            <Save className="w-4 h-4 mr-2" />
            Save Configuration
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <div className="mb-4">
          <SearchBar placeholder="Search all items to flag/unflag..." value={search} onChange={setSearch} className="max-w-sm" />
        </div>

        {isLoading ? (
          <div className="text-muted-foreground">Loading items...</div>
        ) : filteredItems.length === 0 ? (
          <div className="text-center text-muted-foreground py-8">
            {search ? "No items found" : "No livery packages selected yet — search above to add one"}
          </div>
        ) : (
          <div className="space-y-2">
            {filteredItems.map((item) => (
              <div
                key={item.id}
                className={`flex items-center gap-3 p-3 rounded-md border cursor-pointer transition-colors ${
                  selectedIds.has(item.id) ? "bg-primary/5 border-primary/20" : "border-border"
                }`}
                onClick={() => toggleItem(item.id)}
                data-testid={`item-livery-toggle-${item.id}`}
              >
                <Checkbox checked={selectedIds.has(item.id)} onCheckedChange={() => toggleItem(item.id)} />
                <Package className="w-4 h-4 text-muted-foreground" />
                <div className="flex-1"><span className="font-medium">{item.name}</span></div>
                <span className="text-sm text-muted-foreground">{item.price ? `AED ${item.price}` : "-"}</span>
              </div>
            ))}
          </div>
        )}

        <div className="mt-4 text-sm text-muted-foreground">
          {selectedIds.size} item{selectedIds.size !== 1 ? "s" : ""} selected as livery packages
        </div>
      </CardContent>
    </Card>
  );
}

function LessonTemplatesSection({ canManage }: { canManage: boolean }) {
  const { toast } = useToast();
  const [showCreate, setShowCreate] = useState(false);
  const [editing, setEditing] = useState<LessonTemplateWithUsage | null>(null);
  const [statusFilter, setStatusFilter] = useState<"active" | "inactive" | "all">("active");

  const { data: templates = [], isLoading } = useQuery<LessonTemplateWithUsage[]>({ queryKey: ["/api/riding-school/lesson-templates"] });
  const visibleTemplates = templates.filter((t) => statusFilter === "all" || (statusFilter === "active") === t.isActive);
  const { data: riderLevels = [] } = useQuery<RiderLevel[]>({ queryKey: ["/api/rider-levels"] });
  const sortedLevels = [...riderLevels].sort((a, b) => a.sortOrder - b.sortOrder);
  const levelById = Object.fromEntries(riderLevels.map((l) => [l.id, l.name]));

  const levelRangeLabel = (t: LessonTemplate) => {
    if (!t.minRiderLevelId && !t.maxRiderLevelId) return "Any";
    const min = t.minRiderLevelId ? levelById[t.minRiderLevelId] : "Any";
    const max = t.maxRiderLevelId ? levelById[t.maxRiderLevelId] : "Any";
    return min === max ? min : `${min} - ${max}`;
  };

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ["/api/riding-school/lesson-templates"] });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/riding-school/lesson-templates", data),
    onSuccess: () => { invalidate(); setShowCreate(false); toast({ title: "Lesson template created" }); },
    onError: (e: any) => toast({ title: "Failed to create lesson template", description: e.message, variant: "destructive" as any }),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, ...data }: any) => apiRequest("PATCH", `/api/riding-school/lesson-templates/${id}`, data),
    onSuccess: () => { invalidate(); setEditing(null); toast({ title: "Lesson template updated" }); },
    onError: (e: any) => toast({ title: "Failed to update lesson template", description: e.message, variant: "destructive" as any }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/riding-school/lesson-templates/${id}`),
    onSuccess: () => { invalidate(); toast({ title: "Lesson template deleted" }); },
    onError: (e: any) => toast({ title: "Failed to delete lesson template", description: e.message, variant: "destructive" as any }),
  });

  const columns = [
    { key: "name", label: "Name" },
    { key: "level", label: "Level", render: levelRangeLabel },
    { key: "age", label: "Age", render: (row: LessonTemplate) => (row.minAge || row.maxAge) ? `${row.minAge ?? "0"}-${row.maxAge ?? "∞"}` : "Any" },
    { key: "riders", label: "Riders", render: (row: LessonTemplate) => `${row.minRiders}-${row.maxRiders}` },
    { key: "durationMinutes", label: "Duration", render: (row: LessonTemplate) => `${row.durationMinutes} min` },
    { key: "price", label: "Price (AED)" },
    {
      key: "status", label: "Status",
      render: (row: LessonTemplateWithUsage) => (
        <span className={row.isActive ? "text-foreground" : "text-muted-foreground"}>
          {row.isActive ? "Active" : "Inactive"}{row.hasInstances ? " · in use" : ""}
        </span>
      ),
    },
  ];

  function LevelFields({ defaultMin, defaultMax }: { defaultMin?: string | null; defaultMax?: string | null }) {
    return (
      <div className="grid grid-cols-2 gap-2">
        <div>
          <Label>Min Rider Level</Label>
          <Select name="minRiderLevelId" defaultValue={defaultMin || ANY_LEVEL}>
            <SelectTrigger data-testid="select-template-min-level"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value={ANY_LEVEL}>Any</SelectItem>
              {sortedLevels.map((l) => <SelectItem key={l.id} value={l.id}>{l.name}</SelectItem>)}
            </SelectContent>
          </Select>
        </div>
        <div>
          <Label>Max Rider Level</Label>
          <Select name="maxRiderLevelId" defaultValue={defaultMax || ANY_LEVEL}>
            <SelectTrigger data-testid="select-template-max-level"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value={ANY_LEVEL}>Any</SelectItem>
              {sortedLevels.map((l) => <SelectItem key={l.id} value={l.id}>{l.name}</SelectItem>)}
            </SelectContent>
          </Select>
        </div>
      </div>
    );
  }

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <GraduationCap className="w-5 h-5" />
            Lesson Templates
          </CardTitle>
          {canManage && (
            <Button size="sm" onClick={() => setShowCreate(true)} data-testid="button-new-lesson-template">
              <Plus className="w-4 h-4 mr-2" />New Template
            </Button>
          )}
        </div>
      </CardHeader>
      <CardContent>
        <div className="mb-4 max-w-[180px]">
          <Select value={statusFilter} onValueChange={(v) => setStatusFilter(v as typeof statusFilter)}>
            <SelectTrigger data-testid="select-template-status-filter"><SelectValue /></SelectTrigger>
            <SelectContent>
              <SelectItem value="active">Active</SelectItem>
              <SelectItem value="inactive">Inactive</SelectItem>
              <SelectItem value="all">All</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <DataTable
          columns={columns}
          data={visibleTemplates}
          isLoading={isLoading}
          actions={canManage ? (item: LessonTemplateWithUsage) => (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" data-testid={`button-actions-template-${item.id}`}><MoreVertical className="w-4 h-4" /></Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent>
                <DropdownMenuItem
                  disabled={item.hasInstances}
                  onClick={() => setEditing(item)}
                  data-testid={`button-edit-template-${item.id}`}
                >
                  <Pencil className="w-4 h-4 mr-2" />Edit
                </DropdownMenuItem>
                <DropdownMenuItem
                  onClick={() => updateMutation.mutate({ id: item.id, isActive: !item.isActive })}
                  data-testid={`button-toggle-active-template-${item.id}`}
                >
                  {item.isActive
                    ? <><PowerOff className="w-4 h-4 mr-2" />Deactivate</>
                    : <><Power className="w-4 h-4 mr-2" />Activate</>}
                </DropdownMenuItem>
                <DropdownMenuItem
                  className="text-destructive"
                  disabled={item.hasInstances}
                  onClick={() => deleteMutation.mutate(item.id)}
                  data-testid={`button-delete-template-${item.id}`}
                >
                  <Trash2 className="w-4 h-4 mr-2" />Delete
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          ) : undefined}
        />
      </CardContent>

      <Dialog open={showCreate} onOpenChange={setShowCreate}>
        <DialogContent>
          <DialogHeader><DialogTitle>New Lesson Template</DialogTitle></DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              const minRiderLevelId = fd.get("minRiderLevelId");
              const maxRiderLevelId = fd.get("maxRiderLevelId");
              createMutation.mutate({
                name: fd.get("name"),
                minAge: fd.get("minAge") ? Number(fd.get("minAge")) : undefined,
                maxAge: fd.get("maxAge") ? Number(fd.get("maxAge")) : undefined,
                minRiderLevelId: minRiderLevelId === ANY_LEVEL ? undefined : minRiderLevelId,
                maxRiderLevelId: maxRiderLevelId === ANY_LEVEL ? undefined : maxRiderLevelId,
                minRiders: Number(fd.get("minRiders")) || 1,
                maxRiders: Number(fd.get("maxRiders")) || 1,
                durationMinutes: Number(fd.get("durationMinutes")),
                price: fd.get("price"),
                isActive: true,
              });
            }}
          >
            <div className="space-y-4">
              <div><Label>Name</Label><Input name="name" required data-testid="input-template-name" /></div>
              <div className="grid grid-cols-2 gap-2">
                <div><Label>Min Age</Label><Input name="minAge" type="number" data-testid="input-template-min-age" /></div>
                <div><Label>Max Age</Label><Input name="maxAge" type="number" data-testid="input-template-max-age" /></div>
              </div>
              <LevelFields />
              <div className="grid grid-cols-2 gap-2">
                <div><Label>Min Riders</Label><Input name="minRiders" type="number" min={1} defaultValue={1} data-testid="input-template-min-riders" /></div>
                <div><Label>Max Riders (1-6)</Label><Input name="maxRiders" type="number" min={1} max={6} defaultValue={1} required data-testid="input-template-max-riders" /></div>
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div><Label>Duration (minutes)</Label><Input name="durationMinutes" type="number" required data-testid="input-template-duration" /></div>
                <div><Label>Price (AED)</Label><Input name="price" type="number" step="0.01" required data-testid="input-template-price" /></div>
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-template">Create</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={!!editing} onOpenChange={(open) => !open && setEditing(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Edit Lesson Template</DialogTitle></DialogHeader>
          {editing && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                const minRiderLevelId = fd.get("minRiderLevelId");
                const maxRiderLevelId = fd.get("maxRiderLevelId");
                updateMutation.mutate({
                  id: editing.id,
                  name: fd.get("name"),
                  minAge: fd.get("minAge") ? Number(fd.get("minAge")) : undefined,
                  maxAge: fd.get("maxAge") ? Number(fd.get("maxAge")) : undefined,
                  minRiderLevelId: minRiderLevelId === ANY_LEVEL ? null : minRiderLevelId,
                  maxRiderLevelId: maxRiderLevelId === ANY_LEVEL ? null : maxRiderLevelId,
                  minRiders: Number(fd.get("minRiders")) || 1,
                  maxRiders: Number(fd.get("maxRiders")) || 1,
                  durationMinutes: Number(fd.get("durationMinutes")),
                  price: fd.get("price"),
                  isActive: fd.get("isActive") === "on",
                });
              }}
            >
              <div className="space-y-4">
                <div><Label>Name</Label><Input name="name" defaultValue={editing.name} required data-testid="input-edit-template-name" /></div>
                <div className="grid grid-cols-2 gap-2">
                  <div><Label>Min Age</Label><Input name="minAge" type="number" defaultValue={editing.minAge ?? ""} data-testid="input-edit-template-min-age" /></div>
                  <div><Label>Max Age</Label><Input name="maxAge" type="number" defaultValue={editing.maxAge ?? ""} data-testid="input-edit-template-max-age" /></div>
                </div>
                <LevelFields defaultMin={editing.minRiderLevelId} defaultMax={editing.maxRiderLevelId} />
                <div className="grid grid-cols-2 gap-2">
                  <div><Label>Min Riders</Label><Input name="minRiders" type="number" min={1} defaultValue={editing.minRiders} data-testid="input-edit-template-min-riders" /></div>
                  <div><Label>Max Riders (1-6)</Label><Input name="maxRiders" type="number" min={1} max={6} defaultValue={editing.maxRiders} required data-testid="input-edit-template-max-riders" /></div>
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div><Label>Duration (minutes)</Label><Input name="durationMinutes" type="number" defaultValue={editing.durationMinutes} required data-testid="input-edit-template-duration" /></div>
                  <div><Label>Price (AED)</Label><Input name="price" type="number" step="0.01" defaultValue={editing.price} required data-testid="input-edit-template-price" /></div>
                </div>
                <div className="flex items-center gap-2">
                  <Checkbox name="isActive" defaultChecked={editing.isActive} data-testid="checkbox-edit-template-active" />
                  <Label className="font-normal">Active (shown when scheduling new lessons)</Label>
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={updateMutation.isPending} data-testid="button-submit-edit-template">Save</Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </Card>
  );
}

function TemplateCheckboxList({
  templates, selected, onToggle, idPrefix,
}: {
  templates: LessonTemplate[]; selected: string[]; onToggle: (id: string) => void; idPrefix: string;
}) {
  return (
    <div className="space-y-2 max-h-56 overflow-y-auto border rounded-md p-3">
      {templates.map((t) => (
        <div key={t.id} className="flex items-center gap-2">
          <Checkbox
            id={`${idPrefix}-${t.id}`}
            checked={selected.includes(t.id)}
            onCheckedChange={() => onToggle(t.id)}
            data-testid={`checkbox-package-template-${t.id}`}
          />
          <Label htmlFor={`${idPrefix}-${t.id}`} className="font-normal cursor-pointer">{t.name}</Label>
        </div>
      ))}
      {templates.length === 0 && <p className="text-sm text-muted-foreground">No lesson templates yet — create one first.</p>}
    </div>
  );
}

function TermsPackagesSection({ canManage }: { canManage: boolean }) {
  const { toast } = useToast();
  const [showCreate, setShowCreate] = useState(false);
  const [editing, setEditing] = useState<(RsRidingPackage & { templateIds: string[] }) | null>(null);
  const [newTemplateIds, setNewTemplateIds] = useState<string[]>([]);
  const [editTemplateIds, setEditTemplateIds] = useState<string[]>([]);

  const { data: packages = [], isLoading } = useQuery<(RsRidingPackage & { templateIds: string[] })[]>({ queryKey: ["/api/riding-school/packages"] });
  const { data: templates = [] } = useQuery<LessonTemplate[]>({ queryKey: ["/api/riding-school/lesson-templates"] });
  const templateById = Object.fromEntries(templates.map((t) => [t.id, t.name]));

  const invalidate = () => queryClient.invalidateQueries({ queryKey: ["/api/riding-school/packages"] });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/riding-school/packages", data),
    onSuccess: () => { invalidate(); setShowCreate(false); setNewTemplateIds([]); toast({ title: "Term / Riding Package created" }); },
    onError: (e: any) => toast({ title: "Failed to create term / riding package", description: e.message, variant: "destructive" as any }),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, ...data }: any) => apiRequest("PATCH", `/api/riding-school/packages/${id}`, data),
    onSuccess: () => { invalidate(); setEditing(null); toast({ title: "Term / Riding Package updated" }); },
    onError: (e: any) => toast({ title: "Failed to update term / riding package", description: e.message, variant: "destructive" as any }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/riding-school/packages/${id}`),
    onSuccess: () => { invalidate(); toast({ title: "Term / Riding Package deleted" }); },
    onError: (e: any) => toast({ title: "Failed to delete term / riding package", description: e.message, variant: "destructive" as any }),
  });

  const toggleNewTemplate = (id: string) => setNewTemplateIds((prev) => prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]);
  const toggleEditTemplate = (id: string) => setEditTemplateIds((prev) => prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]);

  const columns = [
    { key: "name", label: "Name" },
    {
      key: "templateIds", label: "Usable For",
      render: (row: RsRidingPackage & { templateIds: string[] }) => row.templateIds.map((id) => templateById[id] || "?").join(", ") || "—",
    },
    { key: "numberOfLessons", label: "Lessons" },
    { key: "validityDays", label: "Validity (days)" },
    { key: "price", label: "Price (AED)" },
  ];

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Ticket className="w-5 h-5" />
            Terms / Riding Package
          </CardTitle>
          {canManage && (
            <Button size="sm" onClick={() => { setNewTemplateIds([]); setShowCreate(true); }} data-testid="button-new-package">
              <Plus className="w-4 h-4 mr-2" />New Term / Package
            </Button>
          )}
        </div>
        <p className="text-sm text-muted-foreground mt-1">
          A discount on a bundle of lessons, valid for a period. Choose which lesson templates a customer
          may use this balance against — e.g. a package limited to "Beginner Group Lesson" only pays for
          that class, even though the rider may be entitled to book others.
        </p>
      </CardHeader>
      <CardContent>
        <DataTable
          columns={columns}
          data={packages}
          isLoading={isLoading}
          actions={canManage ? (item) => (
            <DropdownMenu>
              <DropdownMenuTrigger asChild>
                <Button variant="ghost" size="icon" data-testid={`button-actions-package-${item.id}`}><MoreVertical className="w-4 h-4" /></Button>
              </DropdownMenuTrigger>
              <DropdownMenuContent>
                <DropdownMenuItem onClick={() => { setEditing(item); setEditTemplateIds(item.templateIds); }} data-testid={`button-edit-package-${item.id}`}>
                  <Pencil className="w-4 h-4 mr-2" />Edit
                </DropdownMenuItem>
                <DropdownMenuItem className="text-destructive" onClick={() => deleteMutation.mutate(item.id)}>
                  <Trash2 className="w-4 h-4 mr-2" />Delete
                </DropdownMenuItem>
              </DropdownMenuContent>
            </DropdownMenu>
          ) : undefined}
        />
      </CardContent>

      <Dialog open={showCreate} onOpenChange={setShowCreate}>
        <DialogContent>
          <DialogHeader><DialogTitle>New Term / Riding Package</DialogTitle></DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({
                name: fd.get("name"),
                numberOfLessons: Number(fd.get("numberOfLessons")),
                validityDays: Number(fd.get("validityDays")),
                price: fd.get("price"),
                isActive: true,
                templateIds: newTemplateIds,
              });
            }}
          >
            <div className="space-y-4">
              <div><Label>Name</Label><Input name="name" required data-testid="input-package-name" /></div>
              <div>
                <Label>Usable For (lesson templates)</Label>
                <TemplateCheckboxList templates={templates} selected={newTemplateIds} onToggle={toggleNewTemplate} idPrefix="new-pkg" />
              </div>
              <div className="grid grid-cols-2 gap-2">
                <div><Label>Number of Lessons</Label><Input name="numberOfLessons" type="number" required data-testid="input-package-lessons" /></div>
                <div><Label>Validity (days)</Label><Input name="validityDays" type="number" required data-testid="input-package-validity" /></div>
              </div>
              <div><Label>Price (AED)</Label><Input name="price" type="number" step="0.01" required data-testid="input-package-price" /></div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending || newTemplateIds.length === 0} data-testid="button-submit-package">Create</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={!!editing} onOpenChange={(open) => !open && setEditing(null)}>
        <DialogContent>
          <DialogHeader><DialogTitle>Edit Term / Riding Package</DialogTitle></DialogHeader>
          {editing && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                updateMutation.mutate({
                  id: editing.id,
                  name: fd.get("name"),
                  numberOfLessons: Number(fd.get("numberOfLessons")),
                  validityDays: Number(fd.get("validityDays")),
                  price: fd.get("price"),
                  templateIds: editTemplateIds,
                  isActive: fd.get("isActive") === "on",
                });
              }}
            >
              <div className="space-y-4">
                <div><Label>Name</Label><Input name="name" defaultValue={editing.name} required data-testid="input-edit-package-name" /></div>
                <div>
                  <Label>Usable For (lesson templates)</Label>
                  <TemplateCheckboxList templates={templates} selected={editTemplateIds} onToggle={toggleEditTemplate} idPrefix="edit-pkg" />
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div><Label>Number of Lessons</Label><Input name="numberOfLessons" type="number" defaultValue={editing.numberOfLessons} required data-testid="input-edit-package-lessons" /></div>
                  <div><Label>Validity (days)</Label><Input name="validityDays" type="number" defaultValue={editing.validityDays} required data-testid="input-edit-package-validity" /></div>
                </div>
                <div><Label>Price (AED)</Label><Input name="price" type="number" step="0.01" defaultValue={editing.price} required data-testid="input-edit-package-price" /></div>
                <div className="flex items-center gap-2">
                  <Checkbox name="isActive" defaultChecked={editing.isActive} data-testid="checkbox-edit-package-active" />
                  <Label className="font-normal">Active (shown for new purchases)</Label>
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={updateMutation.isPending || editTemplateIds.length === 0} data-testid="button-submit-edit-package">Save</Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>
    </Card>
  );
}

function CancellationNoticeSection({ canManage }: { canManage: boolean }) {
  const { toast } = useToast();
  const { data: policy } = useQuery<RsCancellationPolicy>({ queryKey: ["/api/riding-school/cancellation-policy"] });
  const [hours, setHours] = useState("");

  useEffect(() => {
    if (policy) setHours(String(policy.thresholdHours));
  }, [policy]);

  const saveMutation = useMutation({
    mutationFn: () => apiRequest("PATCH", "/api/riding-school/cancellation-policy", { thresholdHours: Number(hours) }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/cancellation-policy"] });
      toast({ title: "Cancellation notice updated" });
    },
    onError: (e: any) => toast({ title: "Failed to update cancellation notice", description: e.message, variant: "destructive" as any }),
  });

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Clock className="w-5 h-5" />
          Cancellation Notice
        </CardTitle>
        <p className="text-sm text-muted-foreground mt-1">
          A customer who cancels at least this many hours before a lesson gets a full refund (credit back to
          their package, or a voucher). Cancelling later than that refunds nothing.
        </p>
      </CardHeader>
      <CardContent>
        <div className="flex items-end gap-3 max-w-sm">
          <div className="flex-1">
            <Label htmlFor="notice-hours">Notice (hours)</Label>
            <Input
              id="notice-hours"
              type="number"
              min={0}
              value={hours}
              onChange={(e) => setHours(e.target.value)}
              disabled={!canManage}
              data-testid="input-notice-hours"
            />
          </div>
          {canManage && (
            <Button onClick={() => saveMutation.mutate()} disabled={saveMutation.isPending || hours === ""} data-testid="button-save-notice-hours">
              <Save className="w-4 h-4 mr-2" />Save
            </Button>
          )}
        </div>
      </CardContent>
    </Card>
  );
}

export default function AdminSettingsPage() {
  const canManageLivery = useCan("admin.settings");
  const canManageTemplates = useCan("riding_school.templates.manage");
  const canManagePackages = useCan("riding_school.packages.manage");
  const canManageCancellation = useCan("riding_school.settings.manage");

  return (
    <div className="p-6">
      <PageHeader title="Settings" description="Configure application settings" />

      <div className="space-y-6">
        {canManageLivery && <LiveryPackagesSection />}
        {canManageTemplates && <LessonTemplatesSection canManage={canManageTemplates} />}
        {canManagePackages && <TermsPackagesSection canManage={canManagePackages} />}
        {canManageCancellation && <CancellationNoticeSection canManage={canManageCancellation} />}
      </div>
    </div>
  );
}
