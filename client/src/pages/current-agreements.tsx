import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { LogOut } from "lucide-react";

export default function CurrentAgreementsPage() {
  const [showCheckoutDialog, setShowCheckoutDialog] = useState(false);
  const [checkoutAgreement, setCheckoutAgreement] = useState<any>(null);
  const { toast } = useToast();

  const { data: agreements = [], isLoading } = useQuery<any[]>({
    queryKey: ["/api/livery-agreements", "?status=active"],
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
      />

      <Dialog open={showCheckoutDialog} onOpenChange={setShowCheckoutDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Checkout Agreement</DialogTitle>
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
    </div>
  );
}
