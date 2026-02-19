package com.example.backend.service;

import com.example.backend.models.Institution;
import com.example.backend.models.Payment;
import com.example.backend.models.StudentFee;
import com.example.backend.models.User;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.pdf.PdfPCell;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.text.SimpleDateFormat;

@Service
public class PdfService {

    public byte[] generateFeeReceipt(Institution institution, User student, StudentFee studentFee, Payment payment) throws DocumentException {
        Document document = new Document();
        ByteArrayOutputStream out = new ByteArrayOutputStream();

        PdfWriter.getInstance(document, out);
        document.open();

        // Title and Institution Details
        Font headerFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
        Paragraph title = new Paragraph(institution.getName(), headerFont);
        title.setAlignment(Element.ALIGN_CENTER);
        document.add(title);

        Paragraph subtitle = new Paragraph("FEE RECEIPT", FontFactory.getFont(FontFactory.HELVETICA_BOLD, 14));
        subtitle.setAlignment(Element.ALIGN_CENTER);
        subtitle.setSpacingBefore(10);
        document.add(subtitle);

        document.add(new Paragraph(" ")); // Spacer

        // Info Table
        PdfPTable infoTable = new PdfPTable(2);
        infoTable.setWidthPercentage(100);
        infoTable.setSpacingBefore(10);

        SimpleDateFormat sdf = new SimpleDateFormat("dd-MMM-yyyy HH:mm");

        addTableCell(infoTable, "Receipt No:", payment.getReceiptNumber());
        addTableCell(infoTable, "Date:", sdf.format(payment.getPaymentDate()));
        addTableCell(infoTable, "Student Name:", student.getDisplayName());
        addTableCell(infoTable, "USN:", student.getUsn());
        addTableCell(infoTable, "Fee Structure:", studentFee.getFeeStructureTitle());
        addTableCell(infoTable, "Payment Method:", payment.getPaymentMethod());

        document.add(infoTable);

        document.add(new Paragraph(" ")); // Spacer

        // Payment Details Table
        PdfPTable paymentTable = new PdfPTable(2);
        paymentTable.setWidthPercentage(100);
        paymentTable.setSpacingBefore(10);

        PdfPCell cell1 = new PdfPCell(new Phrase("Description", FontFactory.getFont(FontFactory.HELVETICA_BOLD)));
        PdfPCell cell2 = new PdfPCell(new Phrase("Amount (INR)", FontFactory.getFont(FontFactory.HELVETICA_BOLD)));
        
        cell1.setPadding(8);
        cell2.setPadding(8);
        paymentTable.addCell(cell1);
        paymentTable.addCell(cell2);

        PdfPCell descCell = new PdfPCell(new Phrase("Fee Payment toward " + studentFee.getFeeStructureTitle()));
        descCell.setPadding(8);
        paymentTable.addCell(descCell);

        PdfPCell amountCell = new PdfPCell(new Phrase(String.format("%.2f", payment.getAmountPaid())));
        amountCell.setPadding(8);
        paymentTable.addCell(amountCell);

        document.add(paymentTable);

        // Summary
        document.add(new Paragraph(" "));
        Paragraph summary = new Paragraph();
        summary.add(new Paragraph("Total Paid: INR " + String.format("%.2f", payment.getAmountPaid()), FontFactory.getFont(FontFactory.HELVETICA_BOLD)));
        summary.add(new Paragraph("Outstanding Balance: INR " + String.format("%.2f", studentFee.getBalanceAmount())));
        document.add(summary);

        document.add(new Paragraph(" "));
        Paragraph footer = new Paragraph("This is a computer-generated receipt and does not require a signature.", FontFactory.getFont(FontFactory.HELVETICA, 10, Font.ITALIC));
        footer.setAlignment(Element.ALIGN_CENTER);
        document.add(footer);

        document.close();
        return out.toByteArray();
    }

    private void addTableCell(PdfPTable table, String label, String value) {
        PdfPCell labelCell = new PdfPCell(new Phrase(label, FontFactory.getFont(FontFactory.HELVETICA_BOLD)));
        labelCell.setBorder(PdfPCell.NO_BORDER);
        labelCell.setPadding(5);
        table.addCell(labelCell);

        PdfPCell valueCell = new PdfPCell(new Phrase(value != null ? value : "N/A"));
        valueCell.setBorder(PdfPCell.NO_BORDER);
        valueCell.setPadding(5);
        table.addCell(valueCell);
    }
}
