import { useState, useEffect, useMemo } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { SearchBar } from "@/components/search-bar";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Save, Package, Webhook, Settings2 } from "lucide-react";
import type { Item, Horse, Box, Stable } from "@shared/schema";

export default function AdminSettingsPage() {
  const [search, setSearch] = useState("");
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const [webhookUrl, setWebhookUrl] = useState("");
  const [defaultBoxId, setDefaultBoxId] = useState("");
  const [defaultHorseId, setDefaultHorseId] = useState("");
  const [boxSearch, setBoxSearch] = useState("");
  const [horseSearch, setHorseSearch] = useState("");
  const [boxDropdownOpen, setBoxDropdownOpen] = useState(false);
  const [horseDropdownOpen, setHorseDropdownOpen] = useState(false);
  const { toast } = useToast();

  const { data: items = [], isLoading } = useQuery<Item[]>({
    queryKey: ["/api/items"],
  });

  const { data: webhookData } = useQuery<{ url: string }>({
    queryKey: ["/api/settings/n8n-webhook"],
  });

  const { data: erpDefaults } = useQuery<{ defaultBoxId: string; defaultHorseId: string }>({
    queryKey: ["/api/settings/erp-defaults"],
  });

  const { data: allBoxes = [] } = useQuery<Box[]>({
    queryKey: ["/api/boxes"],
  });

  const { data: allHorses = [] } = useQuery<Horse[]>({
    queryKey: ["/api/horses"],
  });

  const { data: allStables = [] } = useQuery<Stable[]>({
    queryKey: ["/api/stables"],
  });

  useEffect(() => {
    if (webhookData?.url !== undefined) {
      setWebhookUrl(webhookData.url);
    }
  }, [webhookData]);

  useEffect(() => {
    if (erpDefaults) {
      setDefaultBoxId(erpDefaults.defaultBoxId || "");
      setDefaultHorseId(erpDefaults.defaultHorseId || "");
    }
  }, [erpDefaults]);

  useEffect(() => {
    if (items.length > 0) {
      const ids = new Set<string>();
      items.forEach(item => {
        if (item.isLiveryPackage) ids.add(item.id);
      });
      setSelectedIds(ids);
    }
  }, [items]);

  const selectedBox = useMemo(() => allBoxes.find(b => b.id === defaultBoxId), [allBoxes, defaultBoxId]);
  const selectedHorse = useMemo(() => allHorses.find(h => h.id === defaultHorseId), [allHorses, defaultHorseId]);

  const filteredBoxes = useMemo(() => {
    if (!boxSearch.trim()) return allBoxes;
    const s = boxSearch.toLowerCase();
    return allBoxes.filter(b => {
      const stable = allStables.find(st => st.id === b.stableId);
      const stableName = stable ? stable.name : "";
      return b.boxNumber.toLowerCase().includes(s) || stableName.toLowerCase().includes(s);
    });
  }, [allBoxes, allStables, boxSearch]);

  const filteredHorses = useMemo(() => {
    if (!horseSearch.trim()) return allHorses;
    const s = horseSearch.toLowerCase();
    return allHorses.filter(h => h.horseName.toLowerCase().includes(s));
  }, [allHorses, horseSearch]);

  const saveMutation = useMutation({
    mutationFn: () =>
      apiRequest("POST", "/api/settings/livery-packages", { itemIds: Array.from(selectedIds) }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/items"] });
      toast({ title: "Livery package configuration saved" });
    },
  });

  const saveWebhookMutation = useMutation({
    mutationFn: () =>
      apiRequest("POST", "/api/settings/n8n-webhook", { url: webhookUrl }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/settings/n8n-webhook"] });
      toast({ title: "N8N Webhook URL saved" });
    },
    onError: () => {
      toast({ title: "Failed to save webhook URL", variant: "destructive" });
    },
  });

  const saveErpDefaultsMutation = useMutation({
    mutationFn: () =>
      apiRequest("POST", "/api/settings/erp-defaults", { defaultBoxId, defaultHorseId }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/settings/erp-defaults"] });
      toast({ title: "ERP defaults saved" });
    },
    onError: () => {
      toast({ title: "Failed to save ERP defaults", variant: "destructive" });
    },
  });

  const filteredItems = items.filter(item =>
    !search || item.name.toLowerCase().includes(search.toLowerCase())
  );

  const toggleItem = (id: string) => {
    setSelectedIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const getStableName = (stableId: string | null) => {
    if (!stableId) return "";
    const stable = allStables.find(s => s.id === stableId);
    return stable ? stable.name : "";
  };

  return (
    <div className="p-6">
      <PageHeader
        title="Settings"
        description="Configure application settings"
      />

      <div className="space-y-6">
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle className="flex items-center gap-2">
                <Settings2 className="w-5 h-5" />
                ERP Defaults
              </CardTitle>
              <Button
                onClick={() => saveErpDefaultsMutation.mutate()}
                disabled={saveErpDefaultsMutation.isPending}
                data-testid="button-save-erp-defaults"
              >
                <Save className="w-4 h-4 mr-2" />
                Save Defaults
              </Button>
            </div>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground mb-4">
              These defaults are used when creating billing elements for non-livery customers (default box) and agreements without a horse (default horse). All records must have these IDs for ERP integration.
            </p>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="relative">
                <Label>Default Box</Label>
                <div className="relative mt-1">
                  <Input
                    data-testid="input-default-box-search"
                    placeholder="Search box..."
                    value={selectedBox && !boxDropdownOpen ? `${selectedBox.boxNumber} (${getStableName(selectedBox.stableId)})` : boxSearch}
                    onChange={(e) => {
                      setBoxSearch(e.target.value);
                      setBoxDropdownOpen(true);
                      if (defaultBoxId) setDefaultBoxId("");
                    }}
                    onFocus={() => setBoxDropdownOpen(true)}
                    onBlur={() => setTimeout(() => setBoxDropdownOpen(false), 200)}
                  />
                  {defaultBoxId && (
                    <button
                      type="button"
                      className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground text-sm"
                      onClick={() => { setDefaultBoxId(""); setBoxSearch(""); setBoxDropdownOpen(true); }}
                    >&times;</button>
                  )}
                </div>
                {boxDropdownOpen && !defaultBoxId && (
                  <div className="absolute z-50 w-full mt-1 bg-popover border rounded-md shadow-md max-h-48 overflow-y-auto">
                    {filteredBoxes.length === 0 ? (
                      <div className="p-3 text-sm text-muted-foreground">No boxes found</div>
                    ) : (
                      filteredBoxes.map(b => (
                        <button
                          type="button"
                          key={b.id}
                          data-testid={`erp-default-box-option-${b.id}`}
                          className="w-full text-left px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground cursor-pointer"
                          onClick={() => { setDefaultBoxId(b.id); setBoxSearch(""); setBoxDropdownOpen(false); }}
                        >
                          <div className="font-medium">{b.boxNumber}</div>
                          <div className="text-xs text-muted-foreground">{getStableName(b.stableId)}</div>
                        </button>
                      ))
                    )}
                  </div>
                )}
                {selectedBox && (
                  <p className="text-xs text-muted-foreground mt-1">
                    NetSuite ID: {selectedBox.netsuiteId || "Not set"}
                  </p>
                )}
              </div>

              <div className="relative">
                <Label>Default Horse</Label>
                <div className="relative mt-1">
                  <Input
                    data-testid="input-default-horse-search"
                    placeholder="Search horse..."
                    value={selectedHorse && !horseDropdownOpen ? selectedHorse.horseName : horseSearch}
                    onChange={(e) => {
                      setHorseSearch(e.target.value);
                      setHorseDropdownOpen(true);
                      if (defaultHorseId) setDefaultHorseId("");
                    }}
                    onFocus={() => setHorseDropdownOpen(true)}
                    onBlur={() => setTimeout(() => setHorseDropdownOpen(false), 200)}
                  />
                  {defaultHorseId && (
                    <button
                      type="button"
                      className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground text-sm"
                      onClick={() => { setDefaultHorseId(""); setHorseSearch(""); setHorseDropdownOpen(true); }}
                    >&times;</button>
                  )}
                </div>
                {horseDropdownOpen && !defaultHorseId && (
                  <div className="absolute z-50 w-full mt-1 bg-popover border rounded-md shadow-md max-h-48 overflow-y-auto">
                    {filteredHorses.length === 0 ? (
                      <div className="p-3 text-sm text-muted-foreground">No horses found</div>
                    ) : (
                      filteredHorses.map(h => (
                        <button
                          type="button"
                          key={h.id}
                          data-testid={`erp-default-horse-option-${h.id}`}
                          className="w-full text-left px-3 py-2 text-sm hover:bg-accent hover:text-accent-foreground cursor-pointer"
                          onClick={() => { setDefaultHorseId(h.id); setHorseSearch(""); setHorseDropdownOpen(false); }}
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
                {selectedHorse && (
                  <p className="text-xs text-muted-foreground mt-1">
                    NetSuite ID: {selectedHorse.netsuiteId || "Not set"}
                  </p>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Webhook className="w-5 h-5" />
              N8N Integration
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-end gap-3">
              <div className="flex-1">
                <Label htmlFor="webhook-url">N8N Webhook URL</Label>
                <Input
                  id="webhook-url"
                  placeholder="https://your-n8n-instance.com/webhook/..."
                  value={webhookUrl}
                  onChange={(e) => setWebhookUrl(e.target.value)}
                  className="mt-1"
                  data-testid="input-webhook-url"
                />
                <p className="text-xs text-muted-foreground mt-1">
                  The webhook URL where NetSuite SO JSON will be sent for processing
                </p>
              </div>
              <Button
                onClick={() => saveWebhookMutation.mutate()}
                disabled={saveWebhookMutation.isPending}
                data-testid="button-save-webhook"
              >
                <Save className="w-4 h-4 mr-2" />
                Save
              </Button>
            </div>
          </CardContent>
        </Card>

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
              <SearchBar
                placeholder="Search items..."
                value={search}
                onChange={setSearch}
                className="max-w-sm"
              />
            </div>

            {isLoading ? (
              <div className="text-muted-foreground">Loading items...</div>
            ) : filteredItems.length === 0 ? (
              <div className="text-center text-muted-foreground py-8">No items found</div>
            ) : (
              <div className="space-y-2">
                {filteredItems.map(item => (
                  <div
                    key={item.id}
                    className={`flex items-center gap-3 p-3 rounded-md border cursor-pointer transition-colors ${
                      selectedIds.has(item.id)
                        ? "bg-primary/5 border-primary/20"
                        : "border-border"
                    }`}
                    onClick={() => toggleItem(item.id)}
                    data-testid={`item-livery-toggle-${item.id}`}
                  >
                    <Checkbox
                      checked={selectedIds.has(item.id)}
                      onCheckedChange={() => toggleItem(item.id)}
                    />
                    <Package className="w-4 h-4 text-muted-foreground" />
                    <div className="flex-1">
                      <span className="font-medium">{item.name}</span>
                      {item.department && (
                        <span className="text-sm text-muted-foreground ml-2">({item.department})</span>
                      )}
                    </div>
                    <span className="text-sm text-muted-foreground">
                      {item.price ? `AED ${item.price}` : "-"}
                    </span>
                  </div>
                ))}
              </div>
            )}

            <div className="mt-4 text-sm text-muted-foreground">
              {selectedIds.size} item{selectedIds.size !== 1 ? "s" : ""} selected as livery packages
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
