import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/components/modal/success_modal.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shop/screens/leaves/components/LeaveDates.dart';
import 'package:shop/screens/leaves/views/leave_date_selector_screen.dart';
import 'package:shop/services/api_config.dart';

import '../components/LeaveDateSelector.dart';



enum DayPortion { whole, am, pm }

class LeaveType {
  final String id;
  final String name;
  final String imageAsset;
  final String requirement;
  final int balanceDays;

  LeaveType({
    required this.id,
    required this.name,
    required this.imageAsset,
    required this.requirement,
    required this.balanceDays,
  });
}

class ApplyLeaveScreen extends StatefulWidget {
  final int staffId;

  const ApplyLeaveScreen({
    super.key,
    required this.staffId,
  });

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bgColor = Color(0xFFF0F2F5);
  static const Color _cardColor = Colors.white;
  static const Color _borderColor = Color(0xFFDDDFE2);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();

  LeaveType? _selectedLeaveType;
  List<LeaveDateItem> _selectedDates = [];

  List<PlatformFile> _pickedFiles = [];
  final int _maxFiles = 3;
  // ── Max allowed size per uploaded file ──────────────────────
  static const int _maxFileSizeBytes = 15 * 1024 * 1024; // 15 MB

  double _totalDays = 0;
  bool _showAttachment = false;
  PlatformFile? _pickedFile;

  // ── Submission loading state ──────────────────────────────
  bool _isSubmitting = false;

  final Set<String> _flippedCards = {};

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

  // Supporting documents are now REQUIRED for every leave type/application,
  // not just Sick Leave with 5+ days. Kept as a getter so the requirement
  // logic stays in one place and the UI/validation both read from it.
  //bool get _attachmentRequired => _selectedLeaveType != null;
  bool get _attachmentRequired => false;
  void _recomputeAttachmentRule() {
    // Show the "Supporting Documents" uploader for any selected leave type,
    // not just Sick Leave. It's also now mandatory (see _attachmentRequired).
    _showAttachment = _selectedLeaveType != null;
  }

  // ── Open Leave Date Selector Screen ───────────────────────
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

    if (result != null) {
      setState(() {
        _selectedDates = result;
        _recomputeAttachmentRule();
      });
    }
  }

  String _formatBytes(int bytes) {
    final mb = bytes / 1024 / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        dialogTitle: 'Select Supporting Documents (Hold to select multiple)',
      );

      if (result != null && result.files.isNotEmpty) {
        // ── Validate file size (max 15MB per file) ──────────────
        final oversizedFiles =
        result.files.where((f) => f.size > _maxFileSizeBytes).toList();
        final validFiles =
        result.files.where((f) => f.size <= _maxFileSizeBytes).toList();

        if (oversizedFiles.isNotEmpty) {
          final names = oversizedFiles
              .map((f) => '${f.name} (${_formatBytes(f.size)})')
              .join(', ');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'File(s) exceed the 15MB limit and were not added: $names'),
              backgroundColor: Colors.red,
            ),
          );
        }

        if (validFiles.isEmpty) {
          return;
        }

        setState(() {
          if (validFiles.length > _maxFiles) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Maximum $_maxFiles files allowed. Selected ${validFiles.length}'),
                backgroundColor: Colors.red,
              ),
            );
            _pickedFiles = validFiles.sublist(0, _maxFiles);
          } else {
            _pickedFiles = validFiles;
          }
        });
        debugPrint(
            'Files selected: ${_pickedFiles.map((f) => f.name).toList()}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // ── Reason modal ───────────────────────────────────────────
  void _showReasonModal() {
    final tempController = TextEditingController(text: _reasonController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            bool isLoadingSuggestion = false;
            String? aiSuggestion;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: StatefulBuilder(
                      builder: (context, setInnerState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Reason for Leave",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: tempController,
                                    maxLines: 4,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: "Enter your reason here...",
                                      filled: true,
                                      fillColor: _bgColor,
                                      border: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: _borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        borderSide: const BorderSide(
                                            color: _borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                        BorderRadius.circular(10),
                                        borderSide: BorderSide(
                                            color: Colors.primaries[4]),
                                      ),
                                      contentPadding:
                                      const EdgeInsets.all(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (aiSuggestion != null) ...[
                              const SizedBox(height: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.primaries[4].withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.auto_awesome,
                                            size: 13,
                                            color: Colors.primaries[4]),
                                        const SizedBox(width: 4),
                                        Text(
                                          'AI Suggestion',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.primaries[4],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      aiSuggestion!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setInnerState(() {
                                                tempController.text =
                                                aiSuggestion!;
                                                aiSuggestion = null;
                                              });
                                            },
                                            child: Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 9),
                                              decoration: BoxDecoration(
                                                color: Colors.primaries[4],
                                                borderRadius:
                                                BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.check,
                                                      size: 15,
                                                      color: Colors.white),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Accept',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.white,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              setInnerState(
                                                      () => aiSuggestion = null);
                                            },
                                            child: Container(
                                              padding:
                                              const EdgeInsets.symmetric(
                                                  vertical: 9),
                                              decoration: BoxDecoration(
                                                color: _bgColor,
                                                borderRadius:
                                                BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: _borderColor),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.close,
                                                      size: 15,
                                                      color: Colors.black54),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Reject',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.black54,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _reasonController.text = tempController.text;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.primaries[4],
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Confirm",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Cancel",
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Blocking loading modal (no back button / no tap-outside dismiss) ──
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF0866FF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Submitting your leave request…',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _submitApplication(int staffId) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLeaveType == null || _selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    // ── Supporting documents are now required for every leave type ──
    if (_attachmentRequired && _pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please attach at least one supporting document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ── Safety-net re-check in case files were picked before the
    // limit was enforced (e.g. state restored from another source). ──
    if (_pickedFiles.any((f) => f.size > _maxFileSizeBytes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('One or more files exceed the 15MB limit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _showLoadingDialog();

    try {
      final uri = Uri.parse('${ApiConfig.leaveBase}/leave-requests');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({'Accept': 'application/json'});
      request.fields['staff_id'] = staffId.toString();
      request.fields['leave_type_id'] = _selectedLeaveType!.id;
      request.fields['reason'] = _reasonController.text;
      request.fields['leave_dates'] = jsonEncode(
        _selectedDates.map((d) {
          String type = switch (d.portion.name.toUpperCase()) {
            'WHOLE' => 'FULL',
            'AM' => 'AM_HALF',
            'PM' => 'PM_HALF',
            _ => 'FULL',
          };
          String formattedDate =
              "${d.date.year}-${_two(d.date.month)}-${_two(d.date.day)}";
          return {"date": formattedDate, "type": type};
        }).toList(),
      );

      if (_pickedFiles.isNotEmpty) {
        for (var file in _pickedFiles) {
          if (file.bytes != null) {
            // ✅ Web AND mobile/desktop (if withData: true) — bytes are always platform-safe
            request.files.add(
              http.MultipartFile.fromBytes(
                'file[]',
                file.bytes!,
                filename: file.name,
              ),
            );
          } else if (file.path != null) {
            // ✅ Fallback for mobile/desktop when bytes weren't loaded
            request.files.add(
              await http.MultipartFile.fromPath('file[]', file.path!),
            );
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // ── Close the loading modal before showing any result UI ──
      _hideLoadingDialog();

      if (response.statusCode == 200 || response.statusCode == 201) {
        await SuccessModal.show(
          context,
          message: 'Leave submitted successfully',
          description:
          'Your leave request has been sent to your supervisor for approval.',
          assetImage: 'assets/images/success.png',
          onDone: () {
            Navigator.pushNamed(context, leavesScreenRoute);
          },
        );
        _formKey.currentState!.reset();
        setState(() {
          _selectedDates.clear();
          _pickedFiles.clear();
          _selectedLeaveType = null;
        });
      } else if (response.statusCode == 422) {
        try {
          final json = jsonDecode(response.body);
          String errorMessage = 'Validation failed';

          if (json['message'] != null && json['message'] is String) {
            errorMessage = json['message'];
          }

          if (json['errors'] != null && json['errors'] is Map) {
            final errors = json['errors'] as Map;
            if (errors.isNotEmpty) {
              final firstKey = errors.keys.first;
              final firstError = errors[firstKey];
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError.first.toString();
              } else if (firstError is String) {
                errorMessage = firstError;
              }
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Validation error: ${response.body}')),
          );
        }
      } else if (response.statusCode == 207) {
        final json = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${json['successful_count']} file(s) uploaded successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unauthorized request')),
        );
      } else {
        final json = jsonDecode(response.body);
        print('ERROR RESPONSE: $json');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(json['message'] ?? 'Something went wrong')),
        );
      }
    } catch (e) {
      // ── Make sure the modal is closed even if the request throws ──
      _hideLoadingDialog();
      debugPrint('EXCEPTION: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Apply a Leave',
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20.0),
          onPressed: _isSubmitting
              ? null
              : () => Navigator.pushNamed(context, leavesScreenRoute),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section label ──────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Select Leave Type',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              // ── Leave type cards ───────────────────────────
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
                        : () {
                      setState(() {
                        _selectedLeaveType = lt;
                        _recomputeAttachmentRule();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF0866FF) : _cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? const Color.fromARGB(255, 213, 214, 214)
                              : _borderColor,
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 48,
                              height: 48,
                              color: selected ? Colors.white12 : _bgColor,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 1.6,
                                  end: selected ? 1.0 : 1.6,
                                ),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutBack,
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: child,
                                  );
                                },
                                child: Image.asset(
                                  lt.imageAsset,
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        lt.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: selected ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 26,
                                      width: 26,
                                      child: ElevatedButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : () {
                                          Navigator.pushNamed(
                                            context,
                                            leaveTypeDetailscreenRoute,
                                            arguments: {
                                              'title': lt.name,
                                              'imagePath': lt.imageAsset,
                                            },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          selected ? Colors.white24 : _bgColor,
                                          foregroundColor:
                                          selected ? Colors.white : Colors.black54,
                                          padding: EdgeInsets.zero,
                                          shape: const CircleBorder(),
                                          elevation: 0,
                                        ),
                                        child: const Icon(Icons.info_outline, size: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lt.requirement,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selected ? Colors.white70 : Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },),

              const SizedBox(height: 16),

              // ── Date badges ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: LeaveDateBadges(dates: _selectedDates),
              ),

              const SizedBox(height: 16),

              // ── Section label ──────────────────────────────
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Reason',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              // ── Reason tappable field ──────────────────────
              GestureDetector(
                onTap: _isSubmitting ? null : _showReasonModal,
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      const Icon(Icons.chevron_right, color: Color(0xFFBCC0C4)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Supporting documents (now shown AND required for every leave type) ──
              if (_selectedLeaveType != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    _attachmentRequired
                        ? 'Supporting Documents (Required)'
                        : 'Supporting Documents',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Max file size: 15MB per file',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
                  ),
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
                      border: Border.all(
                        color: (_attachmentRequired && _pickedFiles.isEmpty)
                            ? Colors.red.withOpacity(0.6)
                            : _borderColor,
                      ),
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
                      children: _pickedFiles.map((file) {
                        final isLast =
                            _pickedFiles.indexOf(file) == _pickedFiles.length - 1;
                        return Column(
                          children: [
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
                                        Text(
                                          file.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87),
                                        ),
                                        Text(
                                          '${(file.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black45),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _isSubmitting
                                        ? null
                                        : () {
                                      setState(() {
                                        _pickedFiles.removeAt(
                                            _pickedFiles.indexOf(file));
                                      });
                                    },
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: _bgColor,
                                        shape: BoxShape.circle,
                                        border:
                                        Border.all(color: _borderColor),
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Divider(height: 1, color: _borderColor),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ] else if (_attachmentRequired) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      'At least one supporting document is required to submit this leave.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),

      // ── Bottom bar ─────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _borderColor)),
        ),
        child: _selectedDates.isEmpty
            ? SizedBox(
          height: 58,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_selectedLeaveType == null || _isSubmitting)
                ? null
                : _openLeaveDateScreen,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedLeaveType == null
                  ? const Color(0xFFDDDFE2)
                  : Colors.black,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: Text(
              _selectedLeaveType == null
                  ? 'Select Leave Type'
                  : 'Choose Dates to Apply',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        )
            : SizedBox(
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
                      'See Dates',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.primaries[4],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    'You selected ${_selectedDates.length} days',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 150,
                height: 75,
                child: ElevatedButton(
                  onPressed: (_isSubmitting ||
                      (_attachmentRequired && _pickedFiles.isEmpty))
                      ? null
                      : () => _submitApplication(widget.staffId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0866FF),
                    disabledBackgroundColor:
                    const Color(0xFF0866FF).withOpacity(0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Submit',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}