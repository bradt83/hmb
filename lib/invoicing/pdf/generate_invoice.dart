import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../dao/dao_invoice_line.dart';
import '../../dao/dao_system.dart';
import '../../entity/invoice.dart';
import '../../util/format.dart';

Future<File> generateInvoicePdf(Invoice invoice) async {
  final pdf = pw.Document();
  final system = await DaoSystem().get();

  final lines = await DaoInvoiceLine().getByInvoiceId(invoice.id);

  pdf.addPage(
    pw.Page(
      build: (context) => pw.Column(
        children: [
          pw.Text(
              'Invoice: ${invoice.externalInvoiceId ?? invoice.invoiceNum}'),
          pw.Text('Date: ${invoice.createdDate.toIso8601String()}'),
          pw.Text('Total Amount: ${invoice.totalAmount}'),
          pw.Text(
              '''Due Date: ${formatDate(invoice.createdDate.add(const Duration(days: 3)))}'''),
          pw.Divider(),
          pw.Text('Business Details:'),
          pw.Text('Business Name: ${system!.businessName}'),
          pw.Text('''
Address: ${system.addressLine1}, ${system.addressLine2}, ${system.suburb}, ${system.state}, ${system.postcode}'''),
          pw.Text('Email: ${system.emailAddress}'),
          pw.Text('Phone: ${system.mobileNumber}'),
          pw.Text('${system.businessNumberLabel}: ${system.businessNumber}'),
          pw.Divider(),
          ...lines.map((line) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(line.description),
                  pw.Text(line.lineTotal.toString()),
                ],
              )),
          pw.Divider(),
          pw.Text('Payment Details:'),
          pw.Text('BSB: ${system.bsb}'),
          pw.Text('Account Number: ${system.accountNo}'),
          pw.UrlLink(
              child: pw.Text('Pay Now',
                  style: const pw.TextStyle(color: PdfColor(0, 0, 1))),
              destination:
                  'https://in.xero.com/${invoice.externalInvoiceId ?? invoice.invoiceNum}')
        ],
      ),
    ),
  );

  final output = await getTemporaryDirectory();
  final file = File('${output.path}/invoice_${invoice.invoiceNum}.pdf');
  await file.writeAsBytes(await pdf.save());
  return file;
}
