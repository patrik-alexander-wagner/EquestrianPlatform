import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { SearchBar } from "@/components/search-bar";
import { StatusBadge } from "@/components/status-badge";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { RefreshCw, CheckCircle2, XCircle } from "lucide-react";
import type { Customer } from "@shared/schema";
import { useCanEdit } from "@/hooks/use-can-edit";

export default function CustomersPage() {
  const canEdit = useCanEdit();
  const [search, setSearch] = useState("");
  const { toast } = useToast();

  const { data: customers = [], isLoading } = useQuery<Customer[]>({
    queryKey: ["/api/customers", search ? `?search=${search}` : ""],
  });

  const [showSyncDialog, setShowSyncDialog] = useState(false);
  const [syncResult, setSyncResult] = useState<{ created: number; unchanged: number; processed: number; skipped: number; durationMs: number } | null>(null);
  const [syncError, setSyncError] = useState<string | null>(null);

  const syncNetsuiteMutation = useMutation({
    mutationFn: async () => {
      const res = await apiRequest("POST", "/api/customers/sync-netsuite", {});
      return await res.json();
    },
    onSuccess: (data: any) => {
      setSyncResult({
        created: data.created || 0,
        unchanged: data.unchanged || 0,
        processed: data.processed || 0,
        skipped: data.skipped || 0,
        durationMs: data.durationMs || 0,
      });
      setSyncError(null);
      queryClient.invalidateQueries({ queryKey: ["/api/customers"] });
      toast({ title: "Sync complete", description: `Created ${data.created}, unchanged ${data.unchanged}` });
    },
    onError: (err: any) => {
      setSyncResult(null);
      setSyncError(err?.message || "Sync failed");
    },
  });

  const startSync = () => {
    setSyncResult(null);
    setSyncError(null);
    setShowSyncDialog(true);
    syncNetsuiteMutation.mutate();
  };

  const closeSyncDialog = () => {
    if (syncNetsuiteMutation.isPending) return;
    setShowSyncDialog(false);
    setSyncResult(null);
    setSyncError(null);
  };

  const columns = [
    { key: "fullname", label: "Full Name" },
    {
      key: "isInactive",
      label: "Status",
      render: (c: Customer) => (
        <StatusBadge status={c.isInactive ? "inactive" : "active"} />
      ),
    },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Customers"
        description="View customers synced from NetSuite"
        actions={
          canEdit ? (
            <Button
              variant="outline"
              onClick={startSync}
              disabled={syncNetsuiteMutation.isPending}
              data-testid="button-sync-netsuite"
            >
              <RefreshCw className={`w-4 h-4 mr-2 ${syncNetsuiteMutation.isPending ? "animate-spin" : ""}`} />
              {syncNetsuiteMutation.isPending ? "Syncing..." : "Sync with NetSuite"}
            </Button>
          ) : undefined
        }
      />

      <Dialog open={showSyncDialog} onOpenChange={(open) => { if (!open) closeSyncDialog(); }}>
        <DialogContent data-testid="dialog-sync-netsuite">
          <DialogHeader>
            <DialogTitle>NetSuite Customer Sync</DialogTitle>
            <DialogDescription>
              {syncNetsuiteMutation.isPending
                ? "Fetching customers from NetSuite. New customers will be added; existing ones are left untouched. Please don't close this window."
                : syncError
                ? "Sync failed."
                : "Sync complete."}
            </DialogDescription>
          </DialogHeader>

          {syncNetsuiteMutation.isPending && (
            <div className="flex flex-col items-center justify-center py-8 gap-3">
              <RefreshCw className="w-10 h-10 animate-spin text-primary" />
              <p className="text-sm text-muted-foreground">Syncing customers from NetSuite...</p>
            </div>
          )}

          {!syncNetsuiteMutation.isPending && syncResult && (
            <div className="py-4 space-y-3" data-testid="sync-result">
              <div className="flex items-center gap-2 text-green-700 dark:text-green-400">
                <CheckCircle2 className="w-5 h-5" />
                <span className="font-medium">Sync complete</span>
              </div>
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div className="rounded border p-3">
                  <div className="text-muted-foreground">Created</div>
                  <div className="text-2xl font-semibold" data-testid="sync-created">{syncResult.created.toLocaleString()}</div>
                </div>
                <div className="rounded border p-3">
                  <div className="text-muted-foreground">Already existed</div>
                  <div className="text-2xl font-semibold" data-testid="sync-unchanged">{syncResult.unchanged.toLocaleString()}</div>
                </div>
                <div className="rounded border p-3">
                  <div className="text-muted-foreground">Total processed</div>
                  <div className="text-2xl font-semibold" data-testid="sync-processed">{syncResult.processed.toLocaleString()}</div>
                </div>
                <div className="rounded border p-3">
                  <div className="text-muted-foreground">Duration</div>
                  <div className="text-2xl font-semibold">{(syncResult.durationMs / 1000).toFixed(1)}s</div>
                </div>
              </div>
              {syncResult.skipped > 0 && (
                <p className="text-sm text-amber-700 dark:text-amber-400">
                  {syncResult.skipped} customer{syncResult.skipped === 1 ? " was" : "s were"} skipped (missing internalId).
                </p>
              )}
            </div>
          )}

          {!syncNetsuiteMutation.isPending && syncError && (
            <div className="py-4 space-y-3" data-testid="sync-error">
              <div className="flex items-center gap-2 text-destructive">
                <XCircle className="w-5 h-5" />
                <span className="font-medium">Sync failed</span>
              </div>
              <p className="text-sm text-muted-foreground break-words">{syncError}</p>
            </div>
          )}

          <DialogFooter>
            {!syncNetsuiteMutation.isPending && syncError && (
              <Button onClick={startSync} data-testid="button-sync-retry">Retry</Button>
            )}
            <Button
              variant="outline"
              onClick={closeSyncDialog}
              disabled={syncNetsuiteMutation.isPending}
              data-testid="button-sync-close"
            >
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <div className="mb-4">
        <SearchBar
          placeholder="Search by name..."
          value={search}
          onChange={setSearch}
          className="max-w-sm"
        />
      </div>

      <DataTable columns={columns} data={customers} isLoading={isLoading} />
    </div>
  );
}
