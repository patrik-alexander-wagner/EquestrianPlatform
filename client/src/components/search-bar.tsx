import { Input } from "@/components/ui/input";
import { Search } from "lucide-react";

interface SearchBarProps {
  placeholder?: string;
  value: string;
  onChange: (value: string) => void;
  className?: string;
  "data-testid"?: string;
}

export function SearchBar({ placeholder = "Search...", value, onChange, className, "data-testid": testId }: SearchBarProps) {
  return (
    <div className={`relative ${className || ""}`}>
      <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
      <Input
        type="search"
        placeholder={placeholder}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="pl-9"
        data-testid={testId || "input-search"}
      />
    </div>
  );
}
