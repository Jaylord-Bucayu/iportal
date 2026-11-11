import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shop/constants.dart';
import 'package:shop/screens/leaves/components/LeaveDates.dart';
import 'package:shop/screens/leaves/views/leave_date_selector_screen.dart';
import 'package:shop/services/api_config.dart';

import '../components/LeaveDateSelector.dart';
// Only LeaveType is taken from the apply screen. DayPortion is also declared
// there, so importing it would clash with LeaveDateSelector.dart's version.
import 'apply_leave_screen.dart' show LeaveType;

/// Edit a leave request that is still on draft.
/// Pops with `true` when the update succeeded so the caller can refresh.
class EditLeaveScreen extends StatefulWidget {
  final int leaveId;
  final int staffId;
  final String leaveTypeId;
  final String initialReason;
  final List<LeaveDateItem> initialDates;
  final List<String> existingAttachmentNames;

  const EditLeaveScreen({
    super.key,
    required this.leaveId,
    required this.staffId,
    required this.leaveTypeId,
    required this.initialReason,
    required this.initialDates,
    this.existingAttachmentNames = const [],
  });

  @override
  State<EditLeaveScreen> createState() => _EditLeaveScreenState();
}

class _EditLeaveScreenState extends State<EditLeaveScreen> {
  static const Color _bgColor = Color(0xFFF0F2F5);
  static const Color _cardColor = Colors.white;
  static const Color _borderColor = Color(0xFFDDDFE2);
  static const int _maxFileSizeBytes = 15 * 1024 * 1024; // 15 MB
  final int _maxFiles = 3;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();

  LeaveType? _selectedLeaveType;
  late List<LeaveDateItem> _selectedDates;
  List<PlatformFile> _pickedFiles = [];
  bool _isSubmitting = false;

  final List<LeaveType> _leaveTypes = [
    LeaveType(
      id: '1',
      name: 'Vacation Leave',
      imageAsset: 'assets/images/tent.png',
      requirement: 'Submit request at least 5 days prior.',
      balanceDays: 5,
    ),
    LeaveType(
      id: '2',
      name: 'Sick Leave',
      imageAsset: 'assets/images/face-with-thermometer.png',
      requirement: 'Attach medical certificate if 5 days and more.',
      balanceDays: 8,
    ),
    LeaveType(
      id: '16',
      name: 'Emergency Leave',
      imageAsset: 'assets/images/emergency.png',
      requirement: 'Inform HR and supervisor immediately.',
      balanceDays: 4,
    ),
    LeaveType(
      id: '3',
      name: 'Special Privilege Leave',
      imageAsset: 'assets/images/spl.png',
      requirement: '',
      balanceDays: 4,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _reasonController.text = widget.initialReason;
    _selectedDates = List<LeaveDateItem>.from(widget.initialDates);
    for (final lt in _leaveTypes) {
      if (lt.id == widget.leaveTypeId) _selectedLeaveType = lt;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatBytes(int bytes) =>
      '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';

  // ── Date selector ─────────────────────────────────────────
  Future<void> _openLeaveDateScreen() async {
    final result = await Navigator.push<List<LeaveDateItem>>(
      context,
      MaterialPageRoute(
        builder: (_) => LeaveDateSelectorScreen(
          initialDates: _selectedDates,
          leaveTypeName: _selectedLeaveType?.name,
        ),
      ),
    );
    if (result != null) setState(() => _selectedDates = result);
  }

  // ── File picker (optional on edit; new files are appended) ─
  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        dialogTitle: 'Select Supporting Documents',
      );
      if (result == null || result.files.isEmpty) return;

      final oversized =
      result.files.where((f) => f.size > _maxFileSizeBytes).toList();
      final valid =
      result.files.where((f) => f.size <= _maxFileSizeBytes).toList();

      if (oversized.isNotEmpty && mounted) {
        final names = oversized
            .map((f) => '${f.name} (${_formatBytes(f.size)})')
            .join(', ');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('File(s) exceed the 15MB limit: $names'),
          backgroundColor: Colors.red,
        ));
      }
      if (valid.isEmpty) return;

      setState(() {
        if (valid.length > _maxFiles) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Maximum $_maxFiles files allowed. Selected ${valid.length}'),
            backgroundColor: Colors.red,
          ));
          _pickedFiles = valid.sublist(0, _maxFiles);
        } else {
          _pickedFiles = valid;
        }
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // ── Reason modal ──────────────────────────────────────────
  void _showReasonModal() {
    final temp = TextEditingController(text: _reasonController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reason for Leave',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: temp,
                    maxLines: 4,
                    maxLength: 1000,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Enter your reason here...',
                      filled: true,
                      fillColor: _bgColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.primaries[4]),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() => _reasonController.text = temp.text);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.primaries[4],
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Confirm',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Submit update ─────────────────────────────────────────
  Future<void> _submitUpdate() async {
    if (_selectedLeaveType == null ||
        _selectedDates.isEmpty ||
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    if (_pickedFiles.any((f) => f.size > _maxFileSizeBytes)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('One or more files exceed the 15MB limit'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final uri = Uri.parse(
          '${ApiConfig.leaveBase}/leave-requests/${widget.leaveId}');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({'Accept': 'application/json'});

      // Laravel can't parse multipart on a real PUT, so POST + method spoof.
      request.fields['_method'] = 'PUT';
      request.fields['staff_id'] = widget.staffId.toString();
      request.fields['leave_type_id'] = _selectedLeaveType!.id;
      request.fields['reason'] = _reasonController.text.trim();
      request.fields['leave_dates'] = jsonEncode(
        _selectedDates.map((d) {
          final type = switch (d.portion) {
            DayPortion.whole => 'FULL',
            DayPortion.am => 'AM_HALF',
            DayPortion.pm => 'PM_HALF',
          };
          final formattedDate =
              '${d.date.year}-${_two(d.date.month)}-${_two(d.date.day)}';
          return {'date': formattedDate, 'type': type};
        }).toList(),
      );

      for (final file in _pickedFiles) {
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file[]',
            file.bytes!,
            filename: file.name,
          ));
        } else if (file.path != null) {
          request.files
              .add(await http.MultipartFile.fromPath('file[]', file.path!));
        }
      }

      // ── DEBUG: what is actually being sent ──────────────────
      debugPrint('──────── EDIT LEAVE PAYLOAD ────────');
      debugPrint('${request.method} ${request.url}');
      debugPrint('headers: ${request.headers}');
      debugPrint('fields: ${const JsonEncoder.withIndent('  ').convert(request.fields)}');
      debugPrint('files: ${request.files.map((f) => '${f.field}: ${f.filename} (${f.length} bytes)').toList()}');
      debugPrint('widget.staffId=${widget.staffId} '
          'widget.leaveTypeId=${widget.leaveTypeId} '
          'selectedType=${_selectedLeaveType?.id}');
      debugPrint('────────────────────────────────────');

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      // ── DEBUG: what came back ───────────────────────────────
      debugPrint('──────── EDIT LEAVE RESPONSE ────────');
      debugPrint('status: ${response.statusCode}');
      debugPrint('body: ${response.body}');
      debugPrint('─────────────────────────────────────');

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request updated successfully')),
        );
        Navigator.pop(context, true); // tell caller to refresh
        return;
      }

      String msg = 'Something went wrong';
      try {
        final json = jsonDecode(response.body);
        if (json['message'] is String) msg = json['message'];
        if (json['errors'] is Map && (json['errors'] as Map).isNotEmpty) {
          final first = (json['errors'] as Map).values.first;
          if (first is List && first.isNotEmpty) {
            msg = first.first.toString();
          } else if (first is String) {
            msg = first;
          }
        }
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      debugPrint('EXCEPTION: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Network error')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── UI ────────────────────────────────────────────────────
  Widget _label(String text, {FontWeight weight = FontWeight.w800}) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: weight,
        color: Colors.black,
        letterSpacing: 0.3,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Edit Leave Request',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: C.textHi,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _borderColor, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.black, size: 20.0),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Leave Type', weight: FontWeight.w700),

              // ── Leave type cards ───────────────────────
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _leaveTypes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final lt = _leaveTypes[i];
                  final selected = _selectedLeaveType?.id == lt.id;

                  return GestureDetector(
                    onTap: _isSubmitting
                        ? null
                        : () => setState(() => _selectedLeaveType = lt),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                        selected ? const Color(0xFF0866FF) : _cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color.fromARGB(255, 213, 214, 214)
                              : _borderColor,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 48,
                              height: 48,
                              color: selected ? Colors.white12 : _bgColor,
                              child: Image.asset(lt.imageAsset,
                                  fit: BoxFit.cover, width: 48, height: 48),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lt.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                if (lt.requirement.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    lt.requirement,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: selected
                                          ? Colors.white70
                                          : Colors.black45,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ── Date badges ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: LeaveDateBadges(dates: _selectedDates),
              ),

              const SizedBox(height: 16),

              // ── Reason ─────────────────────────────────
              _label('Reason'),
              GestureDetector(
                onTap: _isSubmitting ? null : _showReasonModal,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _reasonController.text.isEmpty
                              ? 'What is the reason for your leave? 😊'
                              : _reasonController.text,
                          style: TextStyle(
                            fontSize: 14,
                            color: _reasonController.text.isEmpty
                                ? const Color(0xFFBCC0C4)
                                : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          color: Color(0xFFBCC0C4)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Existing attachments (read-only) ───────
              if (widget.existingAttachmentNames.isNotEmpty) ...[
                _label('Current Attachments'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final name in widget.existingAttachmentNames)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file_outlined,
                                  size: 16, color: Colors.black54),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      const Text(
                        'Files you add below will be attached in addition to these.',
                        style: TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Add more supporting documents ──────────
              _label('Add Supporting Documents (Optional)'),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text('Max file size: 15MB per file',
                    style: TextStyle(fontSize: 11, color: Colors.black45)),
              ),
              GestureDetector(
                onTap: _isSubmitting ? null : _pickFiles,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _borderColor),
                        ),
                        child: const Icon(Icons.upload_file_outlined,
                            size: 18, color: Colors.black54),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickedFiles.isEmpty
                              ? 'Upload files (jpg, png, pdf)'
                              : '${_pickedFiles.length} of $_maxFiles file(s) selected',
                          style: TextStyle(
                            fontSize: 14,
                            color: _pickedFiles.isEmpty
                                ? const Color(0xFFBCC0C4)
                                : Colors.black87,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Color(0xFFBCC0C4)),
                    ],
                  ),
                ),
              ),

              if (_pickedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < _pickedFiles.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: _bgColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _borderColor),
                                ),
                                child: const Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 16,
                                    color: Colors.black54),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(_pickedFiles[i].name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87)),
                                    Text(_formatBytes(_pickedFiles[i].size),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black45)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: _isSubmitting
                                    ? null
                                    : () => setState(
                                        () => _pickedFiles.removeAt(i)),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: _bgColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _borderColor),
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i != _pickedFiles.length - 1)
                          const Divider(height: 1, color: _borderColor),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // ── Bottom bar ───────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _borderColor)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 50,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _isSubmitting ? null : _openLeaveDateScreen,
                      child: Text(
                        'Change Dates',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.primaries[4],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${_selectedDates.length} day(s) selected',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 150,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || _selectedDates.isEmpty)
                        ? null
                        : _submitUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0866FF),
                      disabledBackgroundColor:
                      const Color(0xFF0866FF).withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('Save Changes',
                        style:
                        TextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}