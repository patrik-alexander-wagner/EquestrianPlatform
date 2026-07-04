import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { useToast } from "@/hooks/use-toast";
import { useCan } from "@/hooks/use-permissions";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus, MoreVertical, Trash2 } from "lucide-react";
import type { LessonTemplate, RsRidingPackage, RsCancellationPolicy, RiderLevel } from "@shared/schema";

function LessonTemplatesSection({ canManage }: { canManage: boolean }) {
  const { toast } = useToast();
  const [showCreate, setShowCreate] = useState(false);

  const { data: templates = [], isLoading } = useQuery<LessonTemplate[]>({ queryKey: ["/api/riding-school/lesson-templates"] });
  const { data: riderLevels = [] } = useQuery<RiderLevel[]>({ queryKey: ["/api/rider-levels"] });
  const levelById = Object.fromEntries(riderLevels.map((l) => [l.id, l.name]));

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/riding-school/lesson-templates", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/lesson-templates"] });
      setShowCreate(false);
      toast({ title: "Lesson template created" });
    },
    onError: (e: any) => toast({ title: "Failed to create lesson template", description: e.message, variant: "destructive" as any }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/riding-school/lesson-templates/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/lesson-templates"] });
      toast({ title: "Lesson template deleted" });
    },
    onError: (e: any) => toast({ title: "Failed to delete lesson template", description: e.message, variant: "destructive" as any }),
  });

  const columns = [
    { key: "name", label: "Name" },
    { key: "riderLevelId", label: "Level", render: (row: LessonTemplate) => row.riderLevelId ? levelById[row.riderLevelId] || "—" : "Any" },
    { key: "riders", label: "Riders", render: (row: LessonTemplate) => `${row.minRiders}-${row.maxRiders}` },
    { key: "durationMinutes", label: "Duration", render: (row: LessonTemplate) => `${row.durationMinutes} min` },
    { key: "price", label: "Price (AED)" },
  ];

  return (
    <div>
      <div className="flex items-center justify-between mb-2">
        <h2 className="text-lg font-semibold">Lesson Templates</h2>
        {canManage && (
          <Button size="sm" onClick={() => setShowCreate(true)} data-testid="button-new-lesson-template">
            <Plus className="w-4 h-4 mr-2" />New Template
          </Button>
        )}
      </div>
      <DataTable
        columns={columns}
        data={templates}
        isLoading={isLoading}
        actions={canManage ? (item) => (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" data-testid={`button-actions-template-${item.id}`}><MoreVertical className="w-4 h-4" /></Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent>
              <DropdownMenuItem className="text-destructive" onClick={() => deleteMutation.mutate(item.id)}>
                <Trash2 className="w-4 h-4 mr-2" />Delete
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        ) : undefined}
      />

      <Dialog open={showCreate} onOpenChange={setShowCreate}>
        <DialogContent>
          <DialogHeader><DialogTitle>New Lesson Template</DialogTitle></DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({
                name: fd.get("name"),
                minAge: fd.get("minAge") ? Number(fd.get("minAge")) : undefined,
                maxAge: fd.get("maxAge") ? Number(fd.get("maxAge")) : undefined,
                riderLevelId: fd.get("riderLevelId") || undefined,
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
              <div>
                <Label>Rider Level</Label>
                <Select name="riderLevelId">
                  <SelectTrigger data-testid="select-template-level"><SelectValue placeholder="Any level" /></SelectTrigger>
                  <SelectContent>
                    {riderLevels.map((l) => <SelectItem key={l.id} value={l.id}>{l.name}</SelectItem>)}
                  </SelectContent>
                </Select>
              </div>
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
    </div>
  );
}

function RidingPackagesSection({ canManage }: { canManage: boolean }) {
  const { toast } = useToast();
  const [showCreate, setShowCreate] = useState(false);

  const { data: packages = [], isLoading } = useQuery<RsRidingPackage[]>({ queryKey: ["/api/riding-school/packages"] });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/riding-school/packages", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/packages"] });
      setShowCreate(false);
      toast({ title: "Riding package created" });
    },
    onError: (e: any) => toast({ title: "Failed to create riding package", description: e.message, variant: "destructive" as any }),
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => apiRequest("DELETE", `/api/riding-school/packages/${id}`),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/riding-school/packages"] });
      toast({ title: "Riding package deleted" });
    },
    onError: (e: any) => toast({ title: "Failed to delete riding package", description: e.message, variant: "destructive" as any }),
  });

  const columns = [
    { key: "name", label: "Name" },
    { key: "lessonTemplateCategory", label: "Category" },
    { key: "numberOfLessons", label: "Lessons" },
    { key: "validityDays", label: "Validity (days)" },
    { key: "price", label: "Price (AED)" },
  ];

  return (
    <div className="mt-8">
      <div className="flex items-center justify-between mb-2">
        <h2 className="text-lg font-semibold">Riding Packages</h2>
        {canManage && (
          <Button size="sm" onClick={() => setShowCreate(true)} data-testid="button-new-package">
            <Plus className="w-4 h-4 mr-2" />New Package
          </Button>
        )}
      </div>
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
              <DropdownMenuItem className="text-destructive" onClick={() => deleteMutation.mutate(item.id)}>
                <Trash2 className="w-4 h-4 mr-2" />Delete
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        ) : undefined}
      />

      <Dialog open={showCreate} onOpenChange={setShowCreate}>
        <DialogContent>
          <DialogHeader><DialogTitle>New Riding Package</DialogTitle></DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({
                name: fd.get("name"),
                lessonTemplateCategory: fd.get("lessonTemplateCategory"),
                numberOfLessons: Number(fd.get("numberOfLessons")),
                validityDays: Number(fd.get("validityDays")),
                price: fd.get("price"),
                isActive: true,
              });
            }}
          >
            <div className="space-y-4">
              <div><Label>Name</Label><Input name="name" required data-testid="input-package-name" /></div>
              <div><Label>Lesson Category (matches a template name)</Label><Input name="lessonTemplateCategory" required data-testid="input-package-category" /></div>
              <div className="grid grid-cols-2 gap-2">
                <div><Label>Number of Lessons</Label><Input name="numberOfLessons" type="number" required data-testid="input-package-lessons" /></div>
                <div><Label>Validity (days)</Label><Input name="validityDays" type="number" required data-testid="input-package-validity" /></div>
              </div>
              <div><Label>Price (AED)</Label><Input name="price" type="number" step="0.01" required data-testid="input-package-price" /></div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-package">Create</Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}

function CancellationPolicySection() {
  const { data: policies = [] } = useQuery<RsCancellationPolicy[]>({ queryKey: ["/api/riding-school/cancellation-policy"] });
  return (
    <div className="mt-8">
      <h2 className="text-lg font-semibold mb-2">Cancellation & Credit Policy</h2>
      <p className="text-sm text-muted-foreground mb-2">
        Notice given before a lesson determines the credit issued on cancellation (refunded to a package if package-redeemed, otherwise a voucher for a class of the same type).
      </p>
      <DataTable
        columns={[
          { key: "thresholdHours", label: "Notice (hours)" },
          { key: "creditPercent", label: "Credit", render: (row: RsCancellationPolicy) => `${row.creditPercent}%` },
        ]}
        data={policies}
        isLoading={false}
      />
    </div>
  );
}

export default function RidingSchoolSettingsPage() {
  const canManage = useCan("riding_school.settings.manage");
  return (
    <div className="p-6">
      <PageHeader title="Riding School Settings" description="Lesson templates, packages, and cancellation policy" />
      <LessonTemplatesSection canManage={canManage} />
      <RidingPackagesSection canManage={canManage} />
      <CancellationPolicySection />
    </div>
  );
}
