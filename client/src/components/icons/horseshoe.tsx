import horseshoeIcon from "@assets/horseshoe-icon.png";

interface HorseshoeProps {
  className?: string;
}

export function Horseshoe({ className = "" }: HorseshoeProps) {
  return (
    <img
      src={horseshoeIcon}
      alt=""
      className={className}
      style={{ objectFit: "contain", filter: "brightness(0) invert(1)" }}
    />
  );
}
