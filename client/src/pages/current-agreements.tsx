import { useState, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { LogOut, FileText, Upload, Download, Trash2, Pencil } from "lucide-react";
import type { Customer, Item } from "@shared/schema";

export default function CurrentAgreementsPage() {
  const [showCheckoutDialog, setShowCheckoutDialog] = useState(false);
  const [checkoutAgreement, setCheckoutAgreement] = useState<any>(null);
  const [showDocumentsDialog, setShowDocumentsDialog] = useState(false);
  const [documentsAgreement, setDocumentsAgreement] = useState<any>(null);
  const [uploading, setUploading] = useState(false);

  const [showEditDialog, setShowEditDialog] = useState(false);
  const [editAgreement, setEditAgreement] = useState<any>(null);
  const [editAgreementType, setEditAgreementType] = useState("permanent");
  const [editSelectedCustomerId, setEditSelectedCustomerId] = useState("");
  const [editCustomerSearch, setEditCustomerSearch] = useState("");
  const [editCustomerDropdownOpen, setEditCustomerDropdownOpen] = useState(false);
  const [editSelectedHorseId, setEditSelectedHorseId] = useState("");
  const [editHorseSearch, setEditHorseSearch] = useState("");
  const [editHorseDropdownOpen, setEditHorseDropdownOpen] = useState(false);
  const [editSelectedItemId, setEditSelectedItemId] = useState("");
  const [editMonthlyAmount, setEditMonthlyAmount] = useState("");

  const { toast } = useToast();

  const { data: agreements = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/livery-agreements", "?status=active"],
  });

  const { data: documents = [], refetch: refetchDocs } = useQuery<any[]>({
    queryKey: ["/api/livery-agreements", documentsAgreement?.id, "documents"],
    queryFn: async () => {
      if (!documentsAgreement?.id) return [];
      const res = await fetch(`/api/livery-agreements/${documentsAgreement.id}/documents`);
      return res.json();
    },
    enabled: !!documentsAgreement?.id,
  });

  const { data: customers = [] } = useQuery<Customer[]>({
    queryKey: ["/api/customers"],
  });

  const { data: allHorses = [] } = useQuery<any[]>({
    queryKey: ["/api/horses"],
  });

  const { data: liveryItems = [] } = useQuery<Item[]>({
    queryKey: ["/api/items/livery-packages"],
  });

  const { data: boxesWithStatus = [] } = useQuery<any[]>({
    queryKey: ["/api/boxes-with-status"],
  });

  const checkoutMutation = useMutation({
    mutationFn: (data: any) => apiRequest("PATCH", `/api/livery-agreements/${data.id}`, {
      endDate: data.endDate,
      checkoutReason: data.reason,
    }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/livery-agreements"] });
      setShowCheckoutDialog(false);
      toast({ title: "Agreement checkout date set successfully" });
    },
  });

  const editMutation = useMutation({
    mutationFn: (data: any) => apiRequest("PATCH", `/api/livery-agreements/${data.id}`, data.updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/livery-agreements"] });
      queryClient.invalidateQueries({ queryKey: ["/api/boxes-with-status"] });
      queryClient.invalidateQueries({ queryKey: ["/api/horses"] });
      setShowEditDialog(false);
      toast({ title: "Agreement updated successfully" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to update agreement", description: error.message, variant: "destructive" });
    },
  });

  const deleteDocMutation = useMutation({
    mutationFn: (docId: string) => apiRequest("DELETE", `/api/agreement-documents/${docId}`),
    onSuccess: () => {
      refetchDocs();
      toast({ title: "Document deleted" });
    },
  });

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !documentsAgreement) return;

    if (file.type !== "application/pdf") {
      toast({ title: "Only PDF files are allowed", variant: "destructive" });
      return;
    }

    if (file.size > 10 * 1024 * 1024) {
      toast({ title: "File too large (max 10MB)", variant: "destructive" });
      return;
    }

    setUploading(true);
    try {
      const reader = new FileReader();
      reader.onload = async () => {
        const base64 = (reader.result as string).split(",")[1];
        await apiRequest("POST", `/api/livery-agreements/${documentsAgreement.id}/documents`, {
          filename: file.name,
          fileData: base64,
        });
        refetchDocs();
        toast({ title: "Document uploaded successfully" });
        setUploading(false);
      };
      reader.readAsDataURL(file);
    } catch {
      toast({ title: "Failed to upload document", variant: "destructive" });
      setUploading(false);
    }

    e.target.value = "";
  };

  const todayStr = useMemo(() => {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
  }, []);

  const visibleAgreements = useMemo(() => {
    return agreements.filter((a: any) => {
      if (!a.endDate) return true;
      return a.endDate >= todayStr;
    });
  }, [agreements, todayStr]);

  const editActiveCustomers = useMemo(() => {
    const active = customers.filter(c => c.status === "active");
    if (!editCustomerSearch.trim()) return active;
    const s = editCustomerSearch.toLowerCase();
    return active.filter(c =>
      `${c.firstname} ${c.lastname}`.toLowerCase().includes(s) ||
      (c.email && c.email.toLowerCase().includes(s))
    );
  }, [customers, editCustomerSearch]);

  const editActiveHorses = useMemo(() => {
    const currentHorseId = editAgreement?.horseId;
    const active = allHorses.filter((h: any) => h.status === "active");
    const availableOrCurrent = active.filter((h: any) => {
      if (h.id === currentHorseId) return true;
      const hasActiveAgreement = visibleAgreements.some((a: any) => a.horseId === h.id && a.id !== editAgreement?.id);
      return !hasActiveAgreement;
    });
    if (!editHorseSearch.trim()) return availableOrCurrent;
    const s = editHorseSearch.toLowerCase();
    return availableOrCurrent.filter((h: any) =>
      h.horseName.toLowerCase().includes(s) ||
      (h.breed && h.breed.toLowerCase().includes(s))
    );
  }, [allHorses, editHorseSearch, editAgreement, visibleAgreements]);

  const editSelectedCustomer = customers.find(c => c.id === editSelectedCustomerId);
  const editSelectedHorse = allHorses.find((h: any) => h.id === editSelectedHorseId);
  const editSelectedItem = liveryItems.find(i => i.id === editSelectedItemId);

  const handleEditItemChange = (itemId: string) => {
    setEditSelectedItemId(itemId);
    const item = liveryItems.find(i => i.id === itemId);
    setEditMonthlyAmount(item?.price || "0");
  };

  const openEditDialog = (agreement: any) => {
    setEditAgreement(agreement);
    setEditSelectedCustomerId(agreement.customerId);
    setEditCustomerSearch("");
    setEditSelectedHorseId(agreement.horseId);
    setEditHorseSearch("");
    setEditSelectedItemId(agreement.itemId);
    setEditMonthlyAmount(agreement.monthlyAmount || "");
    setEditAgreementType(agreement.type || "permanent");
    setEditSelectedBoxId(agreement.boxId);
    setShowEditDialog(true);
  };

  const editAvailableBoxes = useMemo(() => {
    if (!editAgreement) return [];
    return boxesWithStatus.filter((b: any) => b.isAvailable || b.id === editAgreement.boxId);
  }, [boxesWithStatus, editAgreement]);

  const [editSelectedBoxId, setEditSelectedBoxId] = useState("");

  const columns = [
    { key: "referenceNumber", label: "Reference #" },
    {
      key: "type",
      label: "Type",
      render: (item: any) => (
        <Badge variant={item.type === "permanent" ? "default" : "outline"}>
          {item.type === "permanent" ? "Permanent" : "Temporary"}
        </Badge>
      ),
    },
    { key: "horseName", label: "Horse" },
    { key: "customerName", label: "Customer" },
    { key: "stableName", label: "Stable" },
    { key: "boxName", label: "Box" },
    { key: "itemName", label: "Livery Package" },
    { key: "startDate", label: "Start Date" },
    { key: "endDate", label: "End Date", render: (item: any) => item.endDate || "-" },
    {
      key: "monthlyAmount",
      label: "Monthly Amount",
      render: (item: any) => item.monthlyAmount ? `AED ${parseFloat(item.monthlyAmount).toFixed(2)}` : "-",
    },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Current Agreements"
        description="Active livery agreements"
      />

      <DataTable
        columns={columns}
        data={visibleAgreements}
        isLoading={isLoading}
        actions={(item) => (
          <div className="flex gap-1">
            <Button
              variant="outline"
              size="sm"
              onClick={() => openEditDialog(item)}
              data-testid={`button-edit-${item.id}`}
            >
              <Pencil className="w-4 h-4 mr-1" />
              Edit
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => { setDocumentsAgreement(item); setShowDocumentsDialog(true); }}
              data-testid={`button-documents-${item.id}`}
            >
              <FileText className="w-4 h-4 mr-1" />
              Docs
            </Button>
            {!item.endDate && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => { setCheckoutAgreement(item); setShowCheckoutDialog(true); }}
                data-testid={`button-checkout-${item.id}`}
              >
                <LogOut className="w-4 h-4 mr-1" />
                Checkout
              </Button>
            )}
            {item.endDate && (
              <Badge variant="secondary" className="text-xs">
                Ends {item.endDate}
              </Badge>
            )}
          </div>
        )}
      />

      <Dialog open={showEditDialog} onOpenChange={setShowEditDialog}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Edit Livery Agreement</DialogTitle>
            <DialogDescription>Update the details for agreement {editAgreement?.referenceNumber}</DialogDescription>
          </DialogHeader>
          {editAgreement && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                const boxId = editSelectedBoxId || editAgreement.boxId;
                editMutation.mutate({
                  id: editAgreement.id,
                  updates: {
                    horseId: editSelectedHorseId,
                    customerId: editSelectedCustomerId,
                    boxId,
                    itemId: editSelectedItemId,
                    startDate: fd.get("startDate") as string,
                    endDate: editAgreementType === "temporary" ? (fd.get("endDate") as string) : null,
                    type: editAgreementType,
                    notes: (fd.get("notes") as string) || null,
                    monthlyAmount: editMonthlyAmount || editSelectedItem?.price || "0",
                  },
                });
              }}
              onKeyDown={(e) => { if (e.key === "Enter") e.preventDefault(); }}
            >
              <div className="space-y-4 max-h-[60vh] overflow-y-auto pr-1">
                <div>
                  <Label>Box</Label>
                  <Select value={editSelectedBoxId || editAgreement.boxId} onValueChange={setEditSelectedBoxId}>
                    <SelectTrigger data-testid="select-edit-box">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {editAvailableBoxes.map((b: any) => (
                        <SelectItem key={b.id} value={b.id}>{b.name} ({b.stableName})</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="relative">
                  <Label>Customer</Label>
                  <div className="relative">
                    <Input
                      data-testid="input-edit-customer-search"
                      placeholder="Search customer..."
                      value={editSelectedCustomer && !editCustomerDropdownOpen ? `${editSelectedCustomer.firstname} ${editSelectedCustomer.lastname}` : editCustomerSearch}
                      onChange={(e) => {
                        setEditCustomerSearch(e.target.value);
                        setEditCustomerDropdownOpen(true);
                        if (editSelectedCustomerId) setEditSelectedCustomerId("");
                      }}
                      onFocus={() => setEditCustomerDropdownOpen(true)}
                      onBlur={() => setTimeout(() => setEditCustomerDropdownOpen(false), 200)}
                    />
                    {editSelectedCustomerId && (
                      <button
                        type="button"
                        className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground text-sm"
                        onClick={() => { setEditSelectedCustomerId(""); setEditCustomerSearch(""); setEditCustomerDropdownOpen(true); }}
                      >✕</button>
                    )}
                  </div>
                  {editCustomerDropdownOpen && !editSelectedCustomerId && (
                    <div className="absolute z-50 w-full mt-1 bg-popover border rounded-md shadow-md max-h-48 overflow-y-auto">
                      {editActiveCustomers.length === 0 ? (
                        <div className="p-3 text-sm text-muted-foreground">No customers found</div>
                      ) : (
                        editActiveCustomers.map(c => (
                          <button
                            type="button"
                            key={c.id}
                            data-testid={`edit-customer-option-${c.id}`}
                            className="w-full text-left px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground cursor-pointer"
                            onClick={() => { setEditSelectedCustomerId(c.id); setEditCustomerSearch(""); setEditCustomerDropdownOpen(false); }}
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
                      data-testid="input-edit-horse-search"
                      placeholder="Search horse..."
                      value={editSelectedHorse && !editHorseDropdownOpen ? editSelectedHorse.horseName : editHorseSearch}
                      onChange={(e) => {
                        setEditHorseSearch(e.target.value);
                        setEditHorseDropdownOpen(true);
                        if (editSelectedHorseId) setEditSelectedHorseId("");
                      }}
                      onFocus={() => setEditHorseDropdownOpen(true)}
                      onBlur={() => setTimeout(() => setEditHorseDropdownOpen(false), 200)}
                    />
                    {editSelectedHorseId && (
                      <button
                        type="button"
                        className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground text-sm"
                        onClick={() => { setEditSelectedHorseId(""); setEditHorseSearch(""); setEditHorseDropdownOpen(true); }}
                      >✕</button>
                    )}
                  </div>
                  {editHorseDropdownOpen && !editSelectedHorseId && (
                    <div className="absolute z-50 w-full mt-1 bg-popover border rounded-md shadow-md max-h-48 overflow-y-auto">
                      {editActiveHorses.length === 0 ? (
                        <div className="p-3 text-sm text-muted-foreground">No horses found</div>
                      ) : (
                        editActiveHorses.map((h: any) => (
                          <button
                            type="button"
                            key={h.id}
                            data-testid={`edit-horse-option-${h.id}`}
                            className="w-full text-left px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground cursor-pointer"
                            onClick={() => { setEditSelectedHorseId(h.id); setEditHorseSearch(""); setEditHorseDropdownOpen(false); }}
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
                  <Select value={editSelectedItemId} onValueChange={handleEditItemChange}>
                    <SelectTrigger data-testid="select-edit-item">
                      <SelectValue placeholder="Select livery package..." />
                    </SelectTrigger>
                    <SelectContent>
                      {liveryItems.map(i => (
                        <SelectItem key={i.id} value={i.id}>{i.name} (AED {i.price}/mo)</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                {editSelectedItem && (
                  <div>
                    <Label>Monthly Amount (AED)</Label>
                    <div className="flex items-center gap-2">
                      <Input
                        type="number"
                        step="0.01"
                        value={editMonthlyAmount}
                        onChange={(e) => setEditMonthlyAmount(e.target.value)}
                        data-testid="input-edit-monthly-amount"
                      />
                      {editMonthlyAmount !== editSelectedItem.price && (
                        <Button
                          type="button"
                          variant="ghost"
                          size="sm"
                          onClick={() => setEditMonthlyAmount(editSelectedItem.price || "0")}
                          data-testid="button-edit-reset-price"
                          className="text-xs whitespace-nowrap"
                        >
                          Reset to {editSelectedItem.price}
                        </Button>
                      )}
                    </div>
                    {editMonthlyAmount !== editSelectedItem.price && (
                      <p className="text-xs text-muted-foreground mt-1">
                        Default package price: AED {editSelectedItem.price}
                      </p>
                    )}
                  </div>
                )}

                <div>
                  <Label>Start Date</Label>
                  <Input name="startDate" type="date" required defaultValue={editAgreement.startDate} data-testid="input-edit-start" />
                </div>

                <div>
                  <Label>Type</Label>
                  <Select value={editAgreementType} onValueChange={setEditAgreementType}>
                    <SelectTrigger data-testid="select-edit-type">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="permanent">Permanent</SelectItem>
                      <SelectItem value="temporary">Temporary</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                {editAgreementType === "temporary" && (
                  <div>
                    <Label>End Date</Label>
                    <Input name="endDate" type="date" required defaultValue={editAgreement.endDate || ""} data-testid="input-edit-end" />
                  </div>
                )}

                <div>
                  <Label>Notes (optional)</Label>
                  <Textarea name="notes" placeholder="Additional notes..." defaultValue={editAgreement.notes || ""} data-testid="input-edit-notes" />
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={editMutation.isPending || !editSelectedCustomerId || !editSelectedHorseId || !editSelectedItemId} data-testid="button-submit-edit">
                  Save Changes
                </Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>

      <Dialog open={showCheckoutDialog} onOpenChange={setShowCheckoutDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Checkout Agreement</DialogTitle>
            <DialogDescription>End the livery agreement for this horse</DialogDescription>
          </DialogHeader>
          {checkoutAgreement && (
            <form
              onSubmit={(e) => {
                e.preventDefault();
                const fd = new FormData(e.currentTarget);
                checkoutMutation.mutate({
                  id: checkoutAgreement.id,
                  endDate: fd.get("endDate"),
                  reason: fd.get("reason"),
                });
              }}
            >
              <div className="space-y-4">
                <p className="text-sm text-muted-foreground">
                  Checking out: <strong>{checkoutAgreement.horseName}</strong> ({checkoutAgreement.customerName})
                </p>
                <div>
                  <Label>End Date</Label>
                  <Input name="endDate" type="date" required data-testid="input-checkout-date" />
                </div>
                <div>
                  <Label>Reason</Label>
                  <Textarea name="reason" placeholder="Reason for checkout..." data-testid="input-checkout-reason" />
                </div>
              </div>
              <DialogFooter className="mt-4">
                <Button type="submit" disabled={checkoutMutation.isPending} data-testid="button-submit-checkout">
                  Confirm Checkout
                </Button>
              </DialogFooter>
            </form>
          )}
        </DialogContent>
      </Dialog>

      <Dialog open={showDocumentsDialog} onOpenChange={setShowDocumentsDialog}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Agreement Documents</DialogTitle>
            <DialogDescription>
              {documentsAgreement ? `${documentsAgreement.horseName} - ${documentsAgreement.customerName} (${documentsAgreement.referenceNumber})` : ""}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <Label htmlFor="pdf-upload" className="cursor-pointer">
                <div className="flex items-center gap-2 px-4 py-2 border rounded-md hover:bg-accent text-sm">
                  <Upload className="w-4 h-4" />
                  {uploading ? "Uploading..." : "Upload PDF"}
                </div>
              </Label>
              <input
                id="pdf-upload"
                type="file"
                accept=".pdf"
                className="hidden"
                onChange={handleFileUpload}
                disabled={uploading}
                data-testid="input-upload-document"
              />
            </div>

            {documents.length === 0 ? (
              <p className="text-sm text-muted-foreground py-4 text-center">No documents uploaded yet</p>
            ) : (
              <div className="space-y-2">
                {documents.map((doc: any) => (
                  <div key={doc.id} className="flex items-center justify-between p-3 border rounded-md" data-testid={`document-row-${doc.id}`}>
                    <div className="flex items-center gap-2 min-w-0">
                      <FileText className="w-4 h-4 text-muted-foreground shrink-0" />
                      <div className="min-w-0">
                        <p className="text-sm font-medium truncate">{doc.filename}</p>
                        <p className="text-xs text-muted-foreground">
                          {doc.uploadedAt ? new Date(doc.uploadedAt).toLocaleDateString() : ""}
                        </p>
                      </div>
                    </div>
                    <div className="flex gap-1 shrink-0">
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8"
                        onClick={() => window.open(`/api/agreement-documents/${doc.id}/download`, "_blank")}
                        data-testid={`button-download-doc-${doc.id}`}
                      >
                        <Download className="w-4 h-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="h-8 w-8 text-destructive hover:text-destructive"
                        onClick={() => deleteDocMutation.mutate(doc.id)}
                        disabled={deleteDocMutation.isPending}
                        data-testid={`button-delete-doc-${doc.id}`}
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
