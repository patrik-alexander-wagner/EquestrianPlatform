import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { LogOut, FileText, Upload, Download, Trash2 } from "lucide-react";

export default function CurrentAgreementsPage() {
  const [showCheckoutDialog, setShowCheckoutDialog] = useState(false);
  const [checkoutAgreement, setCheckoutAgreement] = useState<any>(null);
  const [showDocumentsDialog, setShowDocumentsDialog] = useState(false);
  const [documentsAgreement, setDocumentsAgreement] = useState<any>(null);
  const [uploading, setUploading] = useState(false);
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

  const checkoutMutation = useMutation({
    mutationFn: (data: any) => apiRequest("PATCH", `/api/livery-agreements/${data.id}`, {
      status: "closed",
      endDate: data.endDate,
      checkoutReason: data.reason,
    }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/livery-agreements"] });
      setShowCheckoutDialog(false);
      toast({ title: "Agreement checked out successfully" });
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
        data={agreements}
        isLoading={isLoading}
        actions={(item) => (
          <div className="flex gap-1">
            <Button
              variant="outline"
              size="sm"
              onClick={() => { setDocumentsAgreement(item); setShowDocumentsDialog(true); }}
              data-testid={`button-documents-${item.id}`}
            >
              <FileText className="w-4 h-4 mr-1" />
              Docs
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => { setCheckoutAgreement(item); setShowCheckoutDialog(true); }}
              data-testid={`button-checkout-${item.id}`}
            >
              <LogOut className="w-4 h-4 mr-1" />
              Checkout
            </Button>
          </div>
        )}
      />

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
