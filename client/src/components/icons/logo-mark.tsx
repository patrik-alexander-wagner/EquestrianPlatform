import logoMark from "@assets/logo-mark.png";

interface LogoMarkProps {
  className?: string;
}

export function LogoMark({ className = "" }: LogoMarkProps) {
  return <img src={logoMark} alt="Saddle Hub" className={className} style={{ objectFit: "contain" }} />;
}
