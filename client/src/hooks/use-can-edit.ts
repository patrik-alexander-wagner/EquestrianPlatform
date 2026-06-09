import { useQuery } from "@tanstack/react-query";

export function useUserRole(): string {
  const { data } = useQuery<{ id: string; username: string; role: string }>({
    queryKey: ["/api/me"],
  });
  return data?.role ?? "";
}

export function useIsViewer(): boolean {
  return useUserRole() === "VIEWER";
}

export function useCanEdit(): boolean {
  const role = useUserRole();
  return role !== "" && role !== "VIEWER";
}
