
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  runApp(const SmartInvoiceGeneratorApp());
}

class SmartInvoiceGeneratorApp extends StatelessWidget {
  const SmartInvoiceGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Invoice Generator',
      theme: ThemeData.dark().copyWith(
    scaffoldBackgroundColor: Colors.black, // All screen backgrounds
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black, // App bar color
      foregroundColor: Colors.white, // App bar text/icon color
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.blueAccent, // Buttons, active elements
      secondary: Colors.blueAccent,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white),
    ),
  ),
      home: const SplashScreen(),
    );
  }
}

class InvoiceItem {
  String name;
  String description;
  int quantity;
  double unitPrice;
  double get total => quantity * unitPrice;

  InvoiceItem({
    required this.name,
    this.description = '',
    this.quantity = 1,
    required this.unitPrice,
  });
}

class Invoice {
  int id;
  String companyName;
  String companyEmail;
  String companyPhone;
  String? companyLogoPath;
  String clientName;
  String clientEmail;
  String clientPhone;
  int invoiceNumber;
  DateTime invoiceDate;
  DateTime dueDate;
  List<InvoiceItem> items;
  double taxRate;
  double discountRate;

  Invoice({
    required this.id,
    required this.companyName,
    required this.companyEmail,
    required this.companyPhone,
    this.companyLogoPath,
    required this.clientName,
    required this.clientEmail,
    required this.clientPhone,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.items,
    this.taxRate = 0.0,
    this.discountRate = 0.0,
  });

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.total);
  double get taxAmount => subtotal * (taxRate / 100);
  double get discountAmount => subtotal * (discountRate / 100);
  double get grandTotal => subtotal + taxAmount - discountAmount;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Invoice> _invoices = [];
  int _nextInvoiceNumber = 1;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  void _loadInvoices() {
    // In a real app, this would load from persistent storage.
    // For this example, we'll just use an empty list.
    setState(() {
      _invoices = [];
      _nextInvoiceNumber = 1;
    });
  }

  void _addInvoice(Invoice invoice) {
    setState(() {
      _invoices.add(invoice);
      _nextInvoiceNumber++;
    });
  }

  void _navigateToCreateInvoice() async {
    final newInvoice = await Navigator.push<Invoice>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateInvoiceScreen(
          nextInvoiceNumber: _nextInvoiceNumber,
          onSave: (invoice) {
            _addInvoice(invoice);
          },
        ),
      ),
    );
    if (newInvoice != null) {
      // Invoice already added via onSave callback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Invoice Generator'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _invoices.isEmpty
          ? const Center(
              child: Text('No invoices created yet. Tap + to create one.',),
            )
          : ListView.builder(
              itemCount: _invoices.length,
              itemBuilder: (context, index) {
                final invoice = _invoices[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Invoice #${invoice.invoiceNumber}'),
                    subtitle: Text('Client: ${invoice.clientName} - Total: ${NumberFormat.currency(symbol: '\$').format(invoice.grandTotal)}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PreviewInvoiceScreen(invoice: invoice),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _navigateToCreateInvoice,
        child: const Icon(Icons.add, color: Colors.black,),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup fade animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Navigate to next screen after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo or icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Image.asset("assets/icon.png")
              ),
              const SizedBox(height: 25),
              const Text(
                "Smart Invoice Generator",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Create, Save & Share Invoices Easily",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class CreateInvoiceScreen extends StatefulWidget {
  final int nextInvoiceNumber;
  final Function(Invoice) onSave;

  const CreateInvoiceScreen({
    super.key,
    required this.nextInvoiceNumber,
    required this.onSave,
  });

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Company Details
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  String? _companyLogoPath;

  // Client Details
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _clientEmailController = TextEditingController();
  final TextEditingController _clientPhoneController = TextEditingController();

  // Invoice Details
  late int _invoiceNumber;
  DateTime _invoiceDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));

  // Items
  final List<InvoiceItem> _items = [
    InvoiceItem(name: 'Service A', unitPrice: 100.0, quantity: 1),
  ];

  // Tax & Discount
  final TextEditingController _taxRateController = TextEditingController(text: '10.0');
  final TextEditingController _discountRateController = TextEditingController(text: '0.0');

  @override
  void initState() {
    super.initState();
    _invoiceNumber = widget.nextInvoiceNumber;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _clientNameController.dispose();
    _clientEmailController.dispose();
    _clientPhoneController.dispose();
    _taxRateController.dispose();
    _discountRateController.dispose();
    super.dispose();
  }

  Future<void> _pickCompanyLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _companyLogoPath = pickedFile.path;
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem(name: '', unitPrice: 0.0, quantity: 1));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _previewInvoice() {
    if (_formKey.currentState!.validate()) {
      final invoice = Invoice(
        id: DateTime.now().millisecondsSinceEpoch,
        companyName: _companyNameController.text,
        companyEmail: _companyEmailController.text,
        companyPhone: _companyPhoneController.text,
        companyLogoPath: _companyLogoPath,
        clientName: _clientNameController.text,
        clientEmail: _clientEmailController.text,
        clientPhone: _clientPhoneController.text,
        invoiceNumber: _invoiceNumber,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        items: List.from(_items),
        taxRate: double.tryParse(_taxRateController.text) ?? 0.0,
        discountRate: double.tryParse(_discountRateController.text) ?? 0.0,
      );
      widget.onSave(invoice);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewInvoiceScreen(invoice: invoice),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Invoice'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('Company Details'),
            TextFormField(
              
              controller: _companyNameController,
              decoration: const InputDecoration(labelText: 'Company Name'),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _companyEmailController,
              decoration: const InputDecoration(labelText: 'Company Email'),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _companyPhoneController,
              decoration: const InputDecoration(labelText: 'Company Phone'),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _pickCompanyLogo,
              icon: const Icon(Icons.image),
              label: Text(_companyLogoPath == null ? 'Add Company Logo' : 'Change Company Logo'),
            ),
            if (_companyLogoPath != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Image.file(File(_companyLogoPath!), height: 100),
              ),
            const SizedBox(height: 20),

            _buildSectionTitle('Client Details'),
            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(labelText: 'Client Name'),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _clientEmailController,
              decoration: const InputDecoration(labelText: 'Client Email'),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _clientPhoneController,
              decoration: const InputDecoration(labelText: 'Client Phone'),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Invoice Details'),
            TextFormField(
              initialValue: _invoiceNumber.toString(),
              decoration: const InputDecoration(labelText: 'Invoice Number'),
              readOnly: true,
            ),
            ListTile(
              title: Text('Invoice Date: ${DateFormat('yyyy-MM-dd').format(_invoiceDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _invoiceDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    _invoiceDate = pickedDate;
                  });
                }
              },
            ),
            ListTile(
              title: Text('Due Date: ${DateFormat('yyyy-MM-dd').format(_dueDate)}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    _dueDate = pickedDate;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Items'),
            ..._items.asMap().entries.map((entry) {
              int idx = entry.key;
              InvoiceItem item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: item.name,
                          decoration: InputDecoration(labelText: 'Item Name ${idx + 1}'),
                          onChanged: (value) => item.name = value,
                          validator: (value) => value!.isEmpty ? 'Required' : null,
                        ),
                        TextFormField(
                          initialValue: item.description,
                          decoration: const InputDecoration(labelText: 'Description (Optional)'),
                          onChanged: (value) => item.description = value,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: item.quantity.toString(),
                                decoration: const InputDecoration(labelText: 'Quantity'),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    item.quantity = int.tryParse(value) ?? 0;
                                  });
                                },
                                validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0 ? 'Invalid' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                initialValue: item.unitPrice.toStringAsFixed(2),
                                decoration: const InputDecoration(labelText: 'Unit Price'),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    item.unitPrice = double.tryParse(value) ?? 0.0;
                                  });
                                },
                                validator: (value) => (double.tryParse(value ?? '') ?? 0.0) <= 0 ? 'Invalid' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Total'),
                                child: Text(NumberFormat.currency(symbol: '\$').format(item.total)),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeItem(idx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Summary'),
            TextFormField(
              controller: _taxRateController,
              decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}), // Rebuild to update totals
              validator: (value) => (double.tryParse(value ?? '') ?? -1) < 0 ? 'Invalid' : null,
            ),
            TextFormField(
              controller: _discountRateController,
              decoration: const InputDecoration(labelText: 'Discount Rate (%)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() {}), // Rebuild to update totals
              validator: (value) => (double.tryParse(value ?? '') ?? -1) < 0 ? 'Invalid' : null,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _previewInvoice,
              child: const Text('Preview Invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

class PreviewInvoiceScreen extends StatefulWidget {
  final Invoice invoice;

  const PreviewInvoiceScreen({super.key, required this.invoice});

  @override
  State<PreviewInvoiceScreen> createState() => _PreviewInvoiceScreenState();
}

class _PreviewInvoiceScreenState extends State<PreviewInvoiceScreen> {
  late Future<Uint8List> _pdfDataFuture;

  @override
  void initState() {
    super.initState();
    _pdfDataFuture = _generatePdf(widget.invoice);
  }

  Future<Uint8List> _generatePdf(Invoice invoice) async {
    final pdf = pw.Document();

    pw.MemoryImage? companyLogo;
    if (invoice.companyLogoPath != null) {
      final file = File(invoice.companyLogoPath!);
      if (await file.exists()) {
        final imageBytes = await file.readAsBytes();
        companyLogo = pw.MemoryImage(imageBytes);
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (companyLogo != null)
                        pw.Image(companyLogo, height: 50),
                      pw.Text(invoice.companyName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                      pw.Text(invoice.companyEmail),
                      pw.Text(invoice.companyPhone),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE', style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Invoice #${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 16)),
                      pw.Text('Date: ${DateFormat('yyyy-MM-dd').format(invoice.invoiceDate)}'),
                      pw.Text('Due Date: ${DateFormat('yyyy-MM-dd').format(invoice.dueDate)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text('BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.clientName),
              pw.Text(invoice.clientEmail),
              pw.Text(invoice.clientPhone),
              pw.SizedBox(height: 30),

              pw.Table.fromTextArray(
                headers: ['Item', 'Description', 'Qty', 'Unit Price', 'Total'],
                data: invoice.items.map((item) => [
                  item.name,
                  item.description,
                  item.quantity.toString(),
                  NumberFormat.currency(symbol: '\$').format(item.unitPrice),
                  NumberFormat.currency(symbol: '\$').format(item.total),
                ]).toList(),
                border: pw.TableBorder.all(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
              ),
              pw.SizedBox(height: 20),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Subtotal: ${NumberFormat.currency(symbol: '\$').format(invoice.subtotal)}'),
                    pw.Text('Tax (${invoice.taxRate.toStringAsFixed(0)}%): ${NumberFormat.currency(symbol: '\$').format(invoice.taxAmount)}'),
                    pw.Text('Discount (${invoice.discountRate.toStringAsFixed(0)}%): -${NumberFormat.currency(symbol: '\$').format(invoice.discountAmount)}'),
                    pw.Divider(),
                    pw.Text('GRAND TOTAL: ${NumberFormat.currency(symbol: '\$').format(invoice.grandTotal)}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 50),
              pw.Center(
                child: pw.Text('Thank you for your business!', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  Future<void> _savePdf(Uint8List pdfBytes) async {
   try {
    if (Platform.isAndroid) {
      const downloadsPath = '/storage/emulated/0/Download';
      final fileName = 'invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
      // Use MediaStore API through a platform channel
      const platform = MethodChannel('com.maaz.smartinvoice/save_pdf');

      final bool result = await platform.invokeMethod('saveFile', {
        'bytes': pdfBytes,
        'name': fileName,
      });

      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Saved to Downloads/$fileName')),
        );
        await OpenFilex.open('$downloadsPath/$fileName');
      } else {
        throw 'Failed to save file';
      }
    } else {
      // For iOS or others
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/invoice.pdf');
      await file.writeAsBytes(pdfBytes);
      await OpenFilex.open(file.path);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error saving PDF: $e')),
    );
  }
}

  Future<void> _sharePdf(Uint8List pdfBytes) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/invoice_${widget.invoice.invoiceNumber}.pdf');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Here is your invoice!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Column(
              children: [
                Expanded(
                  child: PdfPreview(
                    build: (format) => snapshot.data!,
                    allowPrinting: false,
                    allowSharing: false,
                    canChangePageFormat: false,
                    canDebug: false,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _savePdf(snapshot.data!),
                        icon: const Icon(Icons.download),
                        label: const Text('Download PDF'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _sharePdf(snapshot.data!),
                        icon: const Icon(Icons.share),
                        label: const Text('Share PDF'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error generating PDF: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

