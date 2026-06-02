import jsPDF from "jspdf";
import autoTable from "jspdf-autotable";
import adecLogoUrl from "@assets/image_1776675363121.png";

interface InvoiceLineItem {
  description?: string;
  horseName?: string;
  billDate?: string;
  isLivery?: boolean;
  quantity?: number;
  unit?: string;
  unitPrice?: number;
  amount?: number;
}

interface InvoiceDetails {
  id: string;
  invoiceDate: string;
  billingMonth: string | null;
  totalAmount: string;
  customerName?: string;
  customerNumber?: string;
  lineItems?: InvoiceLineItem[];
}

const VAT_PERCENT = 5;
const RED: [number, number, number] = [200, 30, 30];
const GREY_BAND: [number, number, number] = [230, 230, 230];

function formatBillingMonthShort(billingMonth: string | null): string {
  if (!billingMonth) return "";
  const [y, m] = billingMonth.split("-");
  const date = new Date(parseInt(y), parseInt(m) - 1);
  return `${date.toLocaleString("en-US", { month: "long" })}/${y}`;
}

let cachedLogo: string | null = null;
async function loadLogoDataUrl(): Promise<string | null> {
  if (cachedLogo) return cachedLogo;
  try {
    const res = await fetch(adecLogoUrl);
    const blob = await res.blob();
    return await new Promise((resolve) => {
      const reader = new FileReader();
      reader.onloadend = () => {
        cachedLogo = reader.result as string;
        resolve(cachedLogo);
      };
      reader.onerror = () => resolve(null);
      reader.readAsDataURL(blob);
    });
  } catch {
    return null;
  }
}

export async function generateInvoicePDF(invoice: InvoiceDetails): Promise<jsPDF> {
  const doc = new jsPDF("p", "mm", "a4");
  const pageWidth = doc.internal.pageSize.getWidth();
  const pageHeight = doc.internal.pageSize.getHeight();
  const margin = 15;
  const rightCol = pageWidth - margin;

  const lineItems = Array.isArray(invoice.lineItems) ? invoice.lineItems : [];
  const customerName = invoice.customerName || "Unknown Customer";
  const customerNumber = invoice.customerNumber || "-";
  const monthLabel = formatBillingMonthShort(invoice.billingMonth);

  const logo = await loadLogoDataUrl();
  if (logo) {
    try {
      const props = doc.getImageProperties(logo);
      const targetW = 50;
      const targetH = (props.height / props.width) * targetW;
      doc.addImage(logo, "PNG", margin, 14, targetW, targetH);
    } catch {
      // ignore — render without logo
    }
  }

  doc.setFontSize(22);
  doc.setFont("helvetica", "bold");
  doc.text("Invoice Batch", rightCol, 22, { align: "right" });
  if (monthLabel) {
    doc.setFontSize(11);
    doc.setFont("helvetica", "normal");
    doc.text(`[${monthLabel}]`, rightCol, 30, { align: "right" });
  }

  doc.setFontSize(8.5);
  doc.setFont("helvetica", "normal");
  const addrY = 44;
  doc.text("United Arab Emirates", margin, addrY);
  doc.text("Al Mushrif West, Abu Dhabi", margin, addrY + 4);
  doc.text("PO Box 590, Abu Dhabi UAE", margin, addrY + 8);
  doc.text("TRN: 100259446100003", margin, addrY + 12);

  const toNum = (v: any) => {
    const n = Number(v);
    return Number.isFinite(n) ? n : 0;
  };
  const safeItems = lineItems.map(li => ({
    description: li.description || "-",
    horseName: li.horseName || "-",
    billDate: li.isLivery ? "" : (li.billDate || ""),
    quantity: toNum(li.quantity),
    amount: toNum(li.amount),
  }));

  const subtotal = safeItems.reduce((s, li) => s + li.amount, 0);
  const vatAmount = subtotal * (VAT_PERCENT / 100);
  const grandTotal = subtotal + vatAmount;

  doc.setFillColor(...GREY_BAND);
  doc.rect(pageWidth - margin - 70, 42, 70, 16, "F");
  doc.setTextColor(60, 60, 60);
  doc.setFontSize(9);
  doc.setFont("helvetica", "normal");
  doc.text("Total Amount", pageWidth - margin - 67, 48);
  doc.setTextColor(0, 0, 0);
  doc.setFontSize(15);
  doc.setFont("helvetica", "bold");
  doc.text(`AED ${grandTotal.toFixed(2)}`, pageWidth - margin - 67, 55);

  let y = 66;
  const halfW = (pageWidth - margin * 2 - 6) / 2;
  doc.setFillColor(...GREY_BAND);
  doc.rect(margin, y, halfW, 7, "F");
  doc.rect(margin + halfW + 6, y, halfW, 7, "F");
  doc.setFontSize(10);
  doc.setFont("helvetica", "bold");
  doc.setTextColor(60, 60, 60);
  doc.text("Customer Information", margin + 2, y + 5);
  doc.text("Issuer Information", margin + halfW + 8, y + 5);
  doc.setTextColor(0, 0, 0);

  y += 12;
  doc.setFont("helvetica", "normal");
  doc.setFontSize(9);
  doc.text("Customer Number:", margin, y);
  doc.setFont("helvetica", "bold");
  doc.text(customerNumber, margin + 38, y);

  doc.setFont("helvetica", "normal");
  doc.text("Company:", margin + halfW + 6, y);
  doc.setFont("helvetica", "bold");
  doc.text("Abu Dhabi Equestrian Club", margin + halfW + 26, y);

  y += 6;
  doc.setFont("helvetica", "normal");
  doc.text("Customer Name:", margin, y);
  doc.setFont("helvetica", "bold");
  doc.text(customerName, margin + 38, y);

  y += 6;
  doc.setFont("helvetica", "normal");
  doc.text("VAT Reg. Number:", margin, y);

  y += 10;

  const tableBody = safeItems.length === 0
    ? [["", "No items linked to this invoice", "", "", "", "", "", ""]]
    : safeItems.map((li, idx) => {
        const lineVat = li.amount * (VAT_PERCENT / 100);
        return [
          (idx + 1).toString(),
          li.description,
          li.horseName,
          li.billDate,
          li.quantity.toFixed(2),
          li.amount.toFixed(2),
          lineVat.toFixed(2),
          (li.amount + lineVat).toFixed(2),
        ];
      });

  const FOOTER_HEIGHT = 35;
  const TOTALS_BLOCK_HEIGHT = 40;

  const drawFooter = () => {
    const footerY = pageHeight - 30;
    doc.setDrawColor(...RED);
    doc.setLineWidth(0.5);
    doc.line(margin, footerY - 5, rightCol, footerY - 5);

    doc.setFontSize(7);
    doc.setTextColor(0, 0, 0);
    doc.setFont("helvetica", "bold");
    doc.text("Abu Dhabi Equestrian Club", margin, footerY);
    doc.setFont("helvetica", "normal");
    doc.text("Al Mushrif - Abu Dhabi", margin, footerY + 4);
    doc.text("United Arab Emirates", margin, footerY + 8);

    const contactX = margin + 60;
    doc.text("Tel: +971 2 445 5500", contactX, footerY);
    doc.text("Fax: 02 445 5500", contactX, footerY + 4);
    doc.setTextColor(0, 0, 200);
    doc.text("www.adec.ae/", contactX, footerY + 8);
    doc.setTextColor(0, 0, 0);

    const bankX = margin + 115;
    doc.text("BankName: Abu Dhabi Commercial Bank", bankX, footerY);
    doc.text("IBAN: AE630030000131122020002", bankX, footerY + 4);
    doc.text("Account Number : 131122020002", bankX, footerY + 8);
    doc.text("BIC / SWIFT : ADCBAEAAXXX", bankX, footerY + 12);
    doc.text("Branch Name : 105 / AL SALAM STREET", bankX, footerY + 16);

    if (monthLabel) {
      doc.setFontSize(7);
      doc.text(`[${monthLabel}]`, margin, pageHeight - 6);
    }
  };

  autoTable(doc, {
    startY: y,
    head: [["#", "Ln. Description", "Horse", "Transaction Date", "Qty", "Amount", "Vat Amount", "Net Amount"]],
    body: tableBody,
    theme: "grid",
    headStyles: {
      fillColor: GREY_BAND,
      textColor: [40, 40, 40],
      fontSize: 8,
      fontStyle: "bold",
      lineColor: [180, 180, 180],
    },
    bodyStyles: { fontSize: 8, lineColor: [220, 220, 220] },
    alternateRowStyles: { fillColor: [248, 248, 248] },
    columnStyles: {
      0: { cellWidth: 8, halign: "center" },
      1: { cellWidth: 50 },
      2: { cellWidth: 30 },
      3: { cellWidth: 22 },
      4: { cellWidth: 12, halign: "right" },
      5: { cellWidth: 22, halign: "right" },
      6: { cellWidth: 22, halign: "right" },
      7: { cellWidth: 24, halign: "right" },
    },
    margin: { left: margin, right: margin, bottom: FOOTER_HEIGHT },
    didDrawPage: () => {
      drawFooter();
    },
  });

  const finalY = (doc as any).lastAutoTable?.finalY || y + 30;
  const availableSpace = pageHeight - FOOTER_HEIGHT - finalY;
  if (availableSpace < TOTALS_BLOCK_HEIGHT) {
    doc.addPage();
    drawFooter();
  }

  let totalsY = (availableSpace < TOTALS_BLOCK_HEIGHT ? 20 : finalY + 12);

  doc.setFontSize(10);
  const labelX = pageWidth / 2 + 10;
  const valueX = rightCol;

  doc.setFillColor(...GREY_BAND);
  doc.rect(labelX - 4, totalsY - 5, rightCol - labelX + 6, 7, "F");
  doc.setFont("helvetica", "bold");
  doc.setTextColor(0, 0, 0);
  doc.text("Total (exc. VAT)", labelX, totalsY);
  doc.text(`AED ${subtotal.toFixed(2)}`, valueX, totalsY, { align: "right" });

  totalsY += 8;
  doc.setFont("helvetica", "normal");
  doc.text("Vat Percent", labelX, totalsY);
  doc.text(`${VAT_PERCENT}%`, valueX, totalsY, { align: "right" });

  totalsY += 8;
  doc.setFillColor(...GREY_BAND);
  doc.rect(labelX - 4, totalsY - 5, rightCol - labelX + 6, 7, "F");
  doc.setFont("helvetica", "bold");
  doc.text("Vat Total", labelX, totalsY);
  doc.text(`AED ${vatAmount.toFixed(2)}`, valueX, totalsY, { align: "right" });

  totalsY += 9;
  doc.setFillColor(...GREY_BAND);
  doc.rect(labelX - 4, totalsY - 5, rightCol - labelX + 6, 8, "F");
  doc.setTextColor(40, 40, 40);
  doc.setFont("helvetica", "bold");
  doc.text("Total Amount", labelX, totalsY);
  doc.text(`AED ${grandTotal.toFixed(2)}`, valueX, totalsY, { align: "right" });
  doc.setTextColor(0, 0, 0);

  const totalPages = doc.getNumberOfPages();
  for (let p = 1; p <= totalPages; p++) {
    doc.setPage(p);
    doc.setFontSize(7);
    doc.setFont("helvetica", "normal");
    doc.setTextColor(0, 0, 0);
    doc.text(`${p}/${totalPages}`, rightCol, pageHeight - 6, { align: "right" });
  }

  return doc;
}

export async function viewInvoicePDF(invoice: InvoiceDetails) {
  const doc = await generateInvoicePDF(invoice);
  const blob = doc.output("blob");
  const url = URL.createObjectURL(blob);
  window.open(url, "_blank");
}

export async function downloadInvoicePDF(invoice: InvoiceDetails) {
  const doc = await generateInvoicePDF(invoice);
  const monthLabel = formatBillingMonthShort(invoice.billingMonth);
  const safeName = (invoice.customerName || "invoice").replace(/\s+/g, "_");
  const fileName = `Invoice_${safeName}_${monthLabel || invoice.invoiceDate}.pdf`;
  doc.save(fileName);
}
