import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { SearchBar } from "@/components/search-bar";

import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";

import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { RefreshCw, CheckCircle2, XCircle } from "lucide-react";
import type { Item } from "@shared/schema";
import { useCan } from "@/hooks/use-permissions";

export default function ItemsPage() {
  const canEdit = useCan("items.sync");
  const [search, setSearch] = useState("");
  const { toast } = useToast();

  const { data: items = [], isLoading } = useQuery<Item[]>({
    queryKey: ["/api/items", search ? `?search=${search}` : ""],
  });

  const [showSyncDialog, setShowSyncDialog] = useState(false);
  const [syncResult, setSyncResult] = useState<{ created: number; updated: number; unchanged: number; processed: number; skipped: number; durationMs: number } | null>(null);
  const [syncError, setSyncError] = useState<string | null>(null);

  const syncNetsuiteMutation = useMutation({
    mutationFn: async () => {
      const res = await apiRequest("POST", "/api/items/sync-netsuite", {});
      return await res.json();
    },
    onSuccess: (data: any) => {
      setSyncResult({
        created: data.created || 0,
        updated: data.updated || 0,
        unchanged: data.unchanged || 0,
        processed: data.processed || 0,
        skipped: data.skipped || 0,
        durationMs: data.durationMs || 0,
      });
      setSyncError(null);
      queryClient.invalidateQueries({ queryKey: ["/api/items"] });
      queryClient.invalidateQueries({ queryKey: ["/api/items/non-livery-packages"] });
      queryClient.invalidateQueries({ queryKey: ["/api/items/livery-packages"] });
      toast({ title: "Sync complete", description: `Created ${data.created}, updated ${data.updated}` });
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
    { key: "name", label: "Item Name" },
    {
      key: "unitFactor",
      label: "Unit Factor",
      render: (item: Item) => item.unitFactor ? item.unitFactor : "-",
    },
    {
      key: "price",
      label: "Price",
      render: (item: Item) => item.price ? `AED ${item.price}` : "-",
    },
    {
      key: "lastPurchasePrice",
      label: "Last Purchase Price",
      render: (item: Item) => item.lastPurchasePrice ? `AED ${item.lastPurchasePrice}` : "-",
    },
    {
      key: "isInactive",
      label: "Status",
      render: (item: Item) => (
        <span
          className={
            item.isInactive
              ? "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-muted text-muted-foreground"
              : "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
          }
          data-testid={`status-item-${item.id}`}
        >
          {item.isInactive ? "Inactive" : "Active"}
        </span>
      ),
    },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Items"
        description="Items and service items. Unit Factor = quantity unit for pricing, Price = price for that unit factor."
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
            <DialogTitle>NetSuite Item Sync</DialogTitle>
            <DialogDescription>
              {syncNetsuiteMutation.isPending
                ? "Fetching items from NetSuite and updating the local catalogue. This usually takes 20-60 seconds for ~2,000 items. Please don't close this window."
                : syncError
                ? "Sync failed."
                : "Sync complete."}
            </DialogDescription>
          </DialogHeader>

          {syncNetsuiteMutation.isPending && (
            <div className="flex flex-col items-center justify-center py-8 gap-3">
              <RefreshCw className="w-10 h-10 animate-spin text-primary" />
              <p className="text-sm text-muted-foreground">Syncing items from NetSuite...</p>
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
                  <div className="text-muted-foreground">Updated (changed)</div>
                  <div className="text-2xl font-semibold" data-testid="sync-updated">{syncResult.updated.toLocaleString()}</div>
                </div>
                <div className="rounded border p-3">
                  <div className="text-muted-foreground">Unchanged</div>
                  <div className="text-2xl font-semibold" data-testid="sync-unchanged">{syncResult.unchanged.toLocaleString()}</div>
                </div>
                <div className="rounded border p-3">
                  <div className="text-muted-foreground">Total processed</div>
                  <div className="text-2xl font-semibold" data-testid="sync-processed">{syncResult.processed.toLocaleString()}</div>
                </div>
                <div className="rounded border p-3 col-span-2">
                  <div className="text-muted-foreground">Duration</div>
                  <div className="text-2xl font-semibold">{(syncResult.durationMs / 1000).toFixed(1)}s</div>
                </div>
              </div>
              {syncResult.skipped > 0 && (
                <p className="text-sm text-amber-700 dark:text-amber-400">
                  {syncResult.skipped} item{syncResult.skipped === 1 ? " was" : "s were"} skipped (missing internalId).
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
        <SearchBar placeholder="Search item name..." value={search} onChange={setSearch} className="max-w-sm" />
      </div>

      <DataTable columns={columns} data={items} isLoading={isLoading} />
    </div>
  );
}
