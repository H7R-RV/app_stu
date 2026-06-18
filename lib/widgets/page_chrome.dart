import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/document.dart';

/// The exam header band — rendered on the FIRST page only, inside the margins.
class HeaderBand extends StatelessWidget {
  const HeaderBand({super.key, required this.doc, required this.scale});
  final TestDocument doc;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final h = doc.header;
    final logo = h.logoB64 == null ? null : base64Decode(h.logoB64!);
    return Positioned(
      top: doc.marginTop * scale,
      left: doc.marginLeft * scale,
      right: doc.marginRight * scale,
      child: IgnorePointer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (logo != null)
                  Padding(
                    padding: EdgeInsets.only(right: 8 * scale),
                    child: Image.memory(logo,
                        width: 34 * scale, height: 34 * scale, fit: BoxFit.cover),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Text(h.school,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.bold,
                              color: Colors.black)),
                      Text(h.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                              color: Colors.black)),
                    ],
                  ),
                ),
                if (logo != null) SizedBox(width: 42 * scale),
              ],
            ),
            SizedBox(height: 3 * scale),
            Text(h.subject,
                style: TextStyle(fontSize: 9.5 * scale, color: Colors.black)),
            Text(h.meta,
                style: TextStyle(fontSize: 9.5 * scale, color: Colors.black)),
            Divider(thickness: 1 * scale, color: Colors.black54),
            if (h.studentGrid)
              Text('Name: ____________   Roll No: ______   Section: ____',
                  style: TextStyle(fontSize: 9.5 * scale, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}

/// The footer band — replicated on ALL pages, inside the margins.
class FooterBand extends StatelessWidget {
  const FooterBand({
    super.key,
    required this.doc,
    required this.scale,
    required this.pageHeight,
    required this.pageNumber,
    required this.pageCount,
  });

  final TestDocument doc;
  final double scale;
  final double pageHeight;
  final int pageNumber;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final f = doc.footer;
    return Positioned(
      bottom: (doc.marginBottom - 18).clamp(2, doc.marginBottom) * scale,
      left: doc.marginLeft * scale,
      right: doc.marginRight * scale,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(thickness: 0.8 * scale, color: Colors.black38),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(f.text,
                    style: TextStyle(fontSize: 9 * scale, color: Colors.black54)),
                if (f.pageNumber)
                  Text('Page $pageNumber of $pageCount',
                      style:
                          TextStyle(fontSize: 9 * scale, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
