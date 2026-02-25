import { useState } from "react";
import { useQuery, useMutation } from "@tanstack/react-query";
import { PageHeader } from "@/components/page-header";
import { DataTable } from "@/components/data-table";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { apiRequest, queryClient } from "@/lib/queryClient";
import { Plus } from "lucide-react";
import type { User } from "@shared/schema";

export default function AdminUsersPage() {
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const { toast } = useToast();

  const { data: users = [], isLoading } = useQuery<User[]>({
    queryKey: ["/api/users"],
  });

  const createMutation = useMutation({
    mutationFn: (data: any) => apiRequest("POST", "/api/users", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["/api/users"] });
      setShowCreateDialog(false);
      toast({ title: "User created successfully" });
    },
    onError: (error: any) => {
      toast({ title: "Failed to create user", description: error.message, variant: "destructive" });
    },
  });

  const columns = [
    { key: "username", label: "Username" },
    { key: "id", label: "User ID", render: (item: User) => item.id.substring(0, 8) + "..." },
  ];

  return (
    <div className="p-6">
      <PageHeader
        title="Users"
        description="Manage system users (no roles/permissions at this stage)"
        actions={
          <Button onClick={() => setShowCreateDialog(true)} data-testid="button-new-user">
            <Plus className="w-4 h-4 mr-2" />
            New User
          </Button>
        }
      />

      <DataTable columns={columns} data={users} isLoading={isLoading} />

      <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>New User</DialogTitle>
          </DialogHeader>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const fd = new FormData(e.currentTarget);
              createMutation.mutate({
                username: fd.get("username"),
                password: fd.get("password"),
              });
            }}
          >
            <div className="space-y-4">
              <div>
                <Label>Username</Label>
                <Input name="username" required data-testid="input-new-username" />
              </div>
              <div>
                <Label>Password</Label>
                <Input name="password" type="password" required data-testid="input-new-password" />
              </div>
            </div>
            <DialogFooter className="mt-4">
              <Button type="submit" disabled={createMutation.isPending} data-testid="button-submit-user">
                Create User
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
