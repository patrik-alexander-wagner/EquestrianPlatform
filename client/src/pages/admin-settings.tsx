import { useState, useEffect } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { SearchBar } from "@/components/search-bar";
import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Save, Package } from "lucide-react";
import type { Item } from "@shared/schema";

export default function AdminSettingsPage() {
  const [search, setSearch] = useState("");
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const { toast } = useToast();

  const { data: items = [], isLoading } = useQuery<Item[]>({
    queryKey: ["/api/items"],
  });

  useEffect(() => {
    if (items.length > 0) {
      const ids = new Set<string>();
      items.forEach(item => {
        if (item.isLiveryPackage) ids.add(item.id);
      });
      setSelectedIds(ids);
    }
  }, [items]);

  const saveMutation = useMutation({
    mutationFn: () =>
      apiRequest("POST", "/api/settings/livery-packages", { itemIds: Array.from(selectedIds) }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/items"] });
      toast({ title: "Livery package configuration saved" });
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

  return (
    <div className="p-6">
      <PageHeader
        title="Settings"
        description="Configure livery packages"
        actions={
          <Button onClick={() => saveMutation.mutate()} disabled={saveMutation.isPending} data-testid="button-save-settings">
            <Save className="w-4 h-4 mr-2" />
            Save Configuration
          </Button>
        }
      />

      <Card>
        <CardContent className="pt-6">
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
                    {item.category && (
                      <span className="text-sm text-muted-foreground ml-2">({item.category})</span>
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
  );
}
