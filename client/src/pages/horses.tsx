import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { SearchBar } from "@/components/search-bar";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from "@/components/ui/command";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { useToast } from "@/hooks/use-toast";
import { useCan } from "@/hooks/use-permissions";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, MoreVertical, ChevronsUpDown, Check } from "lucide-react";
import { cn } from "@/lib/utils";
import type { HorseWellbeingStatus } from "@shared/schema";

function HorseWellbeingSection({ horseId }: { horseId: string }) {
  const canManage = useCan("shared_resources.horse_wellbeing.manage");
  const { toast } = useToast();

  const { data: history = [] } = useQuery<HorseWellbeingStatus[]>({
    queryKey: [`/api/horses/${horseId}/wellbeing-status`],
  });

  const addMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", `/api/horses/${horseId}/wellbeing-status`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: [`/api/horses/${horseId}/wellbeing-status`] });
      toast({ title: "Wellbeing status recorded" });
    },
  });

  return (
    <div className="pt-2 border-t">
      <Label className="text-sm font-medium">Wellbeing Status</Label>
      {history.length === 0 ? (
        <p className="text-sm text-muted-foreground mt-1">No status recorded yet.</p>
      ) : (
        <ul className="mt-1 space-y-1 max-h-32 overflow-auto text-sm">
          {history.map((entry) => (
            <li key={entry.id} className="flex justify-between gap-2 text-muted-foreground">
              <span>
                <span className="font-medium text-foreground">{entry.statusTag}</span>
                {entry.note ? ` — ${entry.note}` : ""}
              </span>
              <span className="shrink-0">{entry.createdAt ? new Date(entry.createdAt).toLocaleDateString() : ""}</span>
            </li>
          ))}
        </ul>
      )}
      {canManage && (
        <form
          className="flex gap-2 mt-2"
          onSubmit={(e) => {
            e.preventDefault();
            const fd = new FormData(e.currentTarget);
            const statusTag = fd.get("statusTag") as string;
            if (!statusTag) return;
            addMutation.mutate({ statusTag, note: fd.get("note") || null });
            e.currentTarget.reset();
          }}
        >
          <Input name="statusTag" placeholder="e.g. Fit, Light Work, Rest" required data-testid="input-wellbeing-status-tag" className="flex-1" />
          <Input name="note" placeholder="Note (optional)" data-testid="input-wellbeing-note" className="flex-1" />
          <Button type="submit" size="sm" disabled={addMutation.isPending} data-testid="button-submit-wellbeing">Add</Button>
        </form>
      )}
    </div>
  );
}

export default function HorsesPage() {
  const canEdit = useCan("horses.edit");
  const canCreate = useCan("horses.create");
  const [search, setSearch] = useState("");
  const [customerSearch, setCustomerSearch] = useState("");
  const [stableBoxSearch, setStableBoxSearch] = useState("");
  const [displayInactives, setDisplayInactives] = useState(false);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [selectedOwnerId, setSelectedOwnerId] = useState<string>("");
  const [ownerComboOpen, setOwnerComboOpen] = useState(false);
  const [ownerSearchTerm, setOwnerSearchTerm] = useState("");
  const [showEditDialog, setShowEditDialog] = useState(false);
  const [editingHorse, setEditingHorse] = useState<any>(null);
  const [editOwnerId, setEditOwnerId] = useState<string>("");
  const [editOwnerComboOpen, setEditOwnerComboOpen] = useState(false);
  const [editOwnerSearchTerm, setEditOwnerSearchTerm] = useState("");
  const { toast } = useToast();

  const { data: allCustomers = [] } = useQuery<any[]>({
    queryKey: ["/api/customers"],
  });

  const filteredCustomers = useMemo(() => {
    if (!ownerSearchTerm) return allCustomers;
    return allCustomers.filter((c: any) =>
      c.fullname.toLowerCase().includes(ownerSearchTerm.toLowerCase())
    );
  }, [allCustomers, ownerSearchTerm]);

  const filteredEditCustomers = useMemo(() => {
    if (!editOwnerSearchTerm) return allCustomers;
    return allCustomers.filter((c: any) =>
      c.fullname.toLowerCase().includes(editOwnerSearchTerm.toLowerCase())
    );
  }, [allCustomers, editOwnerSearchTerm]);

  const queryParams = new URLSearchParams();
  if (search) queryParams.set("search", search);
  if (customerSearch) queryParams.set("customerSearch", customerSearch);
  if (stableBoxSearch) queryParams.set("stableBoxSearch", stableBoxSearch);
  const qs = queryParams.toString();

  const { data: horses = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/horses", qs ? `?${qs}` : ""],
  });

  const visibleHorses = useMemo(
    () => (displayInactives ? horses : horses.filter((h: any) => (h.status || "active") !== "inactive")),
    [horses, displayInactives],
  );

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/horses", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/horses"] });
      setShowCreateDialog(false);
      setSelectedOwnerId("");
      setOwnerSearchTerm("");
      toast({ title: "Horse created successfully" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to create horse", description: error.message, variant: "destructive" });
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: any) => apiRequest("PATCH", `/api/horses/${data.id}`, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/horses"] });
      setShowEditDialog(false);
      toast({ title: "Horse updated successfully" });
    },
  });

  const columns = [
    { key: "horseName", label: "Horse Name" },
    {
      key: "ownerName",
      label: "Owner",
      render: (item: any) => item.ownerName || "-",
    },
    { key: "breed", label: "Breed", render: (item: any) => item.breed || "-" },
    { key: "dateOfBirth", label: "Date of Birth", render: (item: any) => item.dateOfBirth || "-" },
    {
      key: "stableBox",
      label: "Stable / Box",
      render: (item: any) => item.stable && item.box ? `${item.stable} / ${item.box}` : "-",
    },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Horses"
        description="Manage horses used in livery agreements"
        actions={canCreate ? (
          <Button onClick={() => setShowCreateDialog(true)} data-testid="button-new-horse">
            <Plus className="w-4 h-4 mr-2" />
            New Horse
          </Button>
        ) : undefined}
      />

      <div className="flex gap-3 mb-4 flex-wrap items-center">
        <SearchBar placeholder="Horse name..." value={search} onChange={setSearch} className="w-52" />
        <SearchBar placeholder="Customer..." value={customerSearch} onChange={setCustomerSearch} className="w-52" />
        <SearchBar placeholder="Stable / Box..." value={stableBoxSearch} onChange={setStableBoxSearch} className="w-52" />
        <div className="flex items-center gap-2 ml-2">
          <Switch
            id="display-inactives"
            checked={displayInactives}
            onCheckedChange={setDisplayInactives}
            data-testid="switch-display-inactives"
          />
          <Label htmlFor="display-inactives" className="cursor-pointer">Display inactives</Label>
        </div>
      </div>

      <DataTable
        columns={columns}
        data={visibleHorses}
        isLoading={isLoading}
        actions={canEdit ? ((item) => (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" data-testid={`button-actions-${item.id}`}>
                <MoreVertical className="w-4 h-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent>
              <DropdownMenuItem
                onClick={() => { setEditingHorse(item); setEditOwnerId(item.ownerId || ""); setShowEditDialog(true); }}
                data-testid={`button-edit-${item.id}`}
              >
                Edit
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        )) : undefined}
      />

      <Dialog open={showCreateDialog} onOpenChange={(open) => {
        setShowCreateDialog(open);
        if (!open) { setSelectedOwnerId(""); setOwnerSearchTerm(""); }
      }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>New Horse</DialogTitle>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              if (!selectedOwnerId) {
                toast({ title: "Owner is required", variant: "destructive" });
                return;
              }
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({
                horseName: fd.get("horseName"),
                passportName: fd.get("passportName") || null,
                breed: fd.get("breed") || null,
                dateOfBirth: fd.get("dateOfBirth") || null,
                sex: fd.get("sex") || null,
                color: fd.get("color") || null,
                passportNumber: fd.get("passportNumber") || null,
                status: "active",
                ownerId: selectedOwnerId,
              });
            }}
          >
            <div className="space-y-4">
              <div>
                <Label>Owner <span className="text-destructive">*</span></Label>
                <Popover open={ownerComboOpen} onOpenChange={setOwnerComboOpen}>
                  <PopoverTrigger asChild>
                    <Button
                      variant="outline"
                      role="combobox"
                      aria-expanded={ownerComboOpen}
                      className="w-full justify-between font-normal"
                      data-testid="select-owner"
                    >
                      {selectedOwnerId
                        ? allCustomers.find((c: any) => c.id === selectedOwnerId)?.fullname || "Select owner..."
                        : "Select owner..."}
                      <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-full p-0" align="start">
                    <Command shouldFilter={false}>
                      <CommandInput
                        placeholder="Search customers..."
                        value={ownerSearchTerm}
                        onValueChange={setOwnerSearchTerm}
                        data-testid="input-owner-search"
                      />
                      <CommandList>
                        <CommandEmpty>No customer found.</CommandEmpty>
                        <CommandGroup>
                          {filteredCustomers.map((c: any) => (
                            <CommandItem
                              key={c.id}
                              value={c.id}
                              onSelect={() => {
                                setSelectedOwnerId(c.id);
                                setOwnerComboOpen(false);
                                setOwnerSearchTerm("");
                              }}
                              data-testid={`option-owner-${c.id}`}
                            >
                              <Check className={cn("mr-2 h-4 w-4", selectedOwnerId === c.id ? "opacity-100" : "opacity-0")} />
                              {c.fullname}
                            </CommandItem>
                          ))}
                        </CommandGroup>
                      </CommandList>
                    </Command>
                  </PopoverContent>
                </Popover>
              </div>
              <div>
                <Label>Stable Name</Label>
                <Input name="horseName" required data-testid="input-horse-name" />
              </div>
              <div>
                <Label>Passport Name</Label>
                <Input name="passportName" data-testid="input-passport-name" />
              </div>
              <div>
                <Label>Breed</Label>
                <Input name="breed" data-testid="input-breed" />
              </div>
              <div>
                <Label>Date of Birth</Label>
                <Input name="dateOfBirth" type="date" data-testid="input-dob" />
              </div>
              <div>
                <Label>Sex</Label>
                <Input name="sex" data-testid="input-sex" />
              </div>
              <div>
                <Label>Color</Label>
                <Input name="color" data-testid="input-color" />
              </div>
              <div>
                <Label>Passport Number</Label>
                <Input name="passportNumber" maxLength={40} data-testid="input-passport-number" />
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-horse">Create Horse</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      <Dialog open={showEditDialog} onOpenChange={(open) => {
        setShowEditDialog(open);
        if (!open) { setEditOwnerId(""); setEditOwnerSearchTerm(""); }
      }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit Horse</DialogTitle>
          </DialogHeader>
          {editingHorse && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                updateMutation.mutate({
                  id: editingHorse.id,
                  horseName: fd.get("horseName"),
                  passportName: fd.get("passportName") || null,
                  breed: fd.get("breed") || null,
                  dateOfBirth: fd.get("dateOfBirth") || null,
                  sex: fd.get("sex") || null,
                  color: fd.get("color") || null,
                  passportNumber: fd.get("passportNumber") || null,
                  status: fd.get("status") || "active",
                  ownerId: editOwnerId || undefined,
                });
              }}
            >
              <div className="space-y-4">
                <div>
                  <Label>Owner</Label>
                  <Popover open={editOwnerComboOpen} onOpenChange={setEditOwnerComboOpen}>
                    <PopoverTrigger asChild>
                      <Button
                        variant="outline"
                        role="combobox"
                        aria-expanded={editOwnerComboOpen}
                        className="w-full justify-between font-normal"
                        data-testid="select-edit-owner"
                      >
                        {editOwnerId
                          ? allCustomers.find((c: any) => c.id === editOwnerId)?.fullname || "Select owner..."
                          : "Select owner..."}
                        <ChevronsUpDown className="ml-2 h-4 w-4 shrink-0 opacity-50" />
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-full p-0" align="start">
                      <Command shouldFilter={false}>
                        <CommandInput
                          placeholder="Search customers..."
                          value={editOwnerSearchTerm}
                          onValueChange={setEditOwnerSearchTerm}
                          data-testid="input-edit-owner-search"
                        />
                        <CommandList>
                          <CommandEmpty>No customer found.</CommandEmpty>
                          <CommandGroup>
                            {filteredEditCustomers.map((c: any) => (
                              <CommandItem
                                key={c.id}
                                value={c.id}
                                onSelect={() => {
                                  setEditOwnerId(c.id);
                                  setEditOwnerComboOpen(false);
                                  setEditOwnerSearchTerm("");
                                }}
                                data-testid={`option-edit-owner-${c.id}`}
                              >
                                <Check className={cn("mr-2 h-4 w-4", editOwnerId === c.id ? "opacity-100" : "opacity-0")} />
                                {c.fullname}
                              </CommandItem>
                            ))}
                          </CommandGroup>
                        </CommandList>
                      </Command>
                    </PopoverContent>
                  </Popover>
                </div>
                <div>
                  <Label>Stable Name</Label>
                  <Input name="horseName" defaultValue={editingHorse.rawHorseName || editingHorse.horseName} required data-testid="input-edit-horse-name" />
                </div>
                <div>
                  <Label>Passport Name</Label>
                  <Input name="passportName" defaultValue={editingHorse.passportName || ""} data-testid="input-edit-passport-name" />
                </div>
                <div>
                  <Label>Breed</Label>
                  <Input name="breed" defaultValue={editingHorse.breed || ""} data-testid="input-edit-breed" />
                </div>
                <div>
                  <Label>Date of Birth</Label>
                  <Input name="dateOfBirth" type="date" defaultValue={editingHorse.dateOfBirth || ""} data-testid="input-edit-dob" />
                </div>
                <div>
                  <Label>Sex</Label>
                  <Input name="sex" defaultValue={editingHorse.sex || ""} data-testid="input-edit-sex" />
                </div>
                <div>
                  <Label>Color</Label>
                  <Input name="color" defaultValue={editingHorse.color || ""} data-testid="input-edit-color" />
                </div>
                <div>
                  <Label>Passport Number</Label>
                  <Input name="passportNumber" maxLength={40} defaultValue={editingHorse.passportNumber || ""} data-testid="input-edit-passport-number" />
                </div>
                <div>
                  <Label>Status</Label>
                  <Select name="status" defaultValue={editingHorse.status === "inactive" ? "inactive" : "active"}>
                    <SelectTrigger data-testid="select-edit-status">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="active">Active</SelectItem>
                      <SelectItem value="inactive">Inactive</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={updateMutation.isPending} data-testid="button-submit-edit-horse">Save</Button>
              </DialogFooter>
            </form>
          )}
          {editingHorse && <HorseWellbeingSection horseId={editingHorse.id} />}
        </DialogContent>
      </Dialog>
    </div>
  );
}
