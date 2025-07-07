import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EmployeeQRScannerScreen extends StatefulWidget {
  final String userId;
  final String name;
  final String email;

  const EmployeeQRScannerScreen({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
  });

  @override
  State<EmployeeQRScannerScreen> createState() => _EmployeeQRScannerScreenState();
}

class _EmployeeQRScannerScreenState extends State<EmployeeQRScannerScreen> {
  bool _isProcessing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _handleQRCode(String qrData) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final data = json.decode(qrData);
      final String scannedType = data['type'];
      final String scannedOfficeId = data['officeId'];
      final String scannedDate = data['date'];
      final String scannedSecurityKey = data['securityKey'];

      // Check if QR is valid in Firestore
      final qrDocId = '${scannedOfficeId}_$scannedType';
      final qrDoc = await _firestore.collection('qrCodes').doc(qrDocId).get();

      if (!qrDoc.exists) {
        _showMessage('QR code not found.');
        return;
      }

      final qrDataInDb = qrDoc.data()!;
      if (!qrDataInDb['active'] || qrDataInDb['securityKey'] != scannedSecurityKey || qrDataInDb['date'] != scannedDate) {
        _showMessage('Invalid or expired QR code.');
        return;
      }

      // Proceed to mark attendance
      final today = DateFormat('ddMMyyyy').format(DateTime.now());
      final docId = '${widget.userId}_$today';
      final attendanceRef = _firestore.collection('attendance').doc(docId);
      final now = Timestamp.now();

      final attendanceDoc = await attendanceRef.get();
      final updateData = {
        'userId': widget.userId,
        'date': scannedDate,
        'updatedOn': now,
        'updatedBy': widget.email,
        'markedBy': 'qr',
      };

      if (scannedType == 'checkin') {
        await attendanceRef.set({
          ...updateData,
          'checkInTime': now,
          'status': 'Present',
        }, SetOptions(merge: true));
        _showMessage('Check-in successful.');
      } else if (scannedType == 'checkout') {
        if (!attendanceDoc.exists) {
          _showMessage('Check-in not found. Please check in first.');
        } else {
          await attendanceRef.update({
            ...updateData,
            'checkOutTime': now,
          });
          _showMessage('Check-out successful.');
        }
      } else {
        _showMessage('Unknown QR type.');
      }

      Navigator.pop(context);
    } catch (e) {
      _showMessage('Invalid QR format.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Check-In/Out')),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? raw = barcode.rawValue;
                if (raw != null) {
                  _handleQRCode(raw);
                  break;
                }
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 32.0),
              child: Text(
                'Point your camera at the QR code',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),

    );
  }
}
