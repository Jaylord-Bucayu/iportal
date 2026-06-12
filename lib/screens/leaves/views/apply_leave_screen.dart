import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shop/components/modal/success_modal.dart';
import 'package:shop/constants.dart';
import 'package:shop/route/route_constants.dart';
import 'package:shop/screens/leaves/components/LeaveDateSelector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shop/screens/leaves/components/LeaveDates.dart';

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
  
  final int staffId; // 👈 ADD THIS

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

  double _totalDays = 0;
  bool _showAttachment = false;
  PlatformFile? _pickedFile;

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
      requirement: 'Attach medical certificate if more than 4 days.',
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
      requirement: 'Inform HR and supervisor immediately.',
      balanceDays: 4,
    )
  ];

  void _recomputeAttachmentRule() {
    _showAttachment = _selectedLeaveType?.name.toLowerCase() == 'sick leave' &&
        _selectedDates.length >= 5;
  }

  // ── Groq API call ──────────────────────────────────────────
  // Future<String?> _fetchGroqSuggestion(String reason) async {
  //   const endpoint = 'https://api.groq.com/openai/v1/chat/completions';
  //   final response = await http.post(
  //     Uri.parse(endpoint),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $_groqApiKey',
  //     },
  //     body: jsonEncode({
  //       'model': 'llama-3.3-70b-versatile',
  //       'messages': [
  //         {
  //           'role': 'user',
  //           'content':
  //               'You are an HR assistant. Rewrite the following leave reason into a formal, polite, and concise single sentence. Return only the rewritten sentence, no explanation:\n\n$reason',
  //         }
  //       ],
  //       'max_tokens': 100,
  //       'temperature': 0.7,
  //     }),
  //   );

  //   if (response.statusCode == 200) {
  //     final json = jsonDecode(response.body);
  //     return json['choices'][0]['message']['content']?.toString().trim();
  //   }
  //   return null;
  // }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        dialogTitle: 'Select Medical Certificates (Hold to select multiple)',
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          if (result.files.length > _maxFiles) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Maximum $_maxFiles files allowed. Selected ${result.files.length}'),
                backgroundColor: Colors.red,
              ),
            );
            _pickedFiles = result.files.sublist(0, _maxFiles);
          } else {
            _pickedFiles = result.files;
          }
        });
        debugPrint(
            'Files selected: ${_pickedFiles.map((f) => f.name).toList()}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void openLeaveDateBottomSheet(
      BuildContext context, Function(List<LeaveDateItem>) onChanged) {
    final double initialSize = _selectedDates.isNotEmpty ? 0.95 : 0.6;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialSize,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const Text(
                      'Select Leave Dates',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Please select the dates you wish to take leave for. You can select multiple dates if needed.',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    LeaveDateSelector(
                      selectedDates: _selectedDates,
                      leaveTypeName: _selectedLeaveType?.name,
                      onChanged: (dates) {
                        setState(() {
                          _selectedDates = dates;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Done'),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Reason modal with Groq AI suggest ─────────────────────
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
                  // Drag handle
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

                            // ── Text field + AI button row ──
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
                                const SizedBox(width: 8),

                          
                              ],
                            ),

                            // ── AI Suggestion bubble ──
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
                                    // Label
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

                                    // Suggested text
                                    Text(
                                      aiSuggestion!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // ── Accept / Reject ──
                                    Row(
                                      children: [
                                        // Accept
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

                                        // Reject
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

                  // ── Confirm / Cancel ──
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

  Future<void> _submitApplication(int staffId) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLeaveType == null || _selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    if (_selectedLeaveType?.name.toLowerCase() == 'sick leave' &&
        _selectedDates.length >= 5 &&
        _pickedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical certificate is required')),
      );
      return;
    }

    try {
      final uri = Uri.parse('http://172.31.16.69/api/v1/leave-requests');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({'Accept': 'application/json'});
      request.fields['staff_id'] = staffId.toString();
      request.fields['leave_type_id'] = _selectedLeaveType!.id;
      request.fields['reason'] = _reasonController.text;
      request.fields['leave_dates'] = jsonEncode(
        _selectedDates.map((d) {
          String type = switch (d.portion.name) {
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
          if (file.path != null) {
            request.files.add(
              await http.MultipartFile.fromPath('file[]', file.path!),
            );
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
      }else if (response.statusCode == 422) {
  try {
    final json = jsonDecode(response.body);

    String errorMessage = 'Validation failed';

    // 1. Try Laravel "message" first
    if (json['message'] != null && json['message'] is String) {
      errorMessage = json['message'];
    }

    // 2. Then try "errors" map (Laravel standard)
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
          SnackBar(
              content: Text(json['message'] ?? 'Something went wrong')),
        );
      }
    } catch (e) {
      debugPrint('EXCEPTION: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error')),
      );
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
          onPressed: () => Navigator.pushNamed(context, leavesScreenRoute),
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
                    onTap: () {
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
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: selected ? Colors.white12 : _bgColor,
                              image: DecorationImage(
                                image: AssetImage(lt.imageAsset),
                                fit: BoxFit.cover,
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
                                          color: selected
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 26,
                                      width: 26,
                                      child: ElevatedButton(
                                        onPressed: () {
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
                                          backgroundColor: selected
                                              ? Colors.white24
                                              : _bgColor,
                                          foregroundColor: selected
                                              ? Colors.white
                                              : Colors.black54,
                                          padding: EdgeInsets.zero,
                                          shape: const CircleBorder(),
                                          elevation: 0,
                                        ),
                                        child: const Icon(Icons.info_outline,
                                            size: 15),
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
                                    color: selected
                                        ? Colors.white70
                                        : Colors.black45,
                                  ),
                                ),
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
                onTap: _showReasonModal,
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

              // ── Unfilled leave notice ──────────────────────
              // Card(
              //   elevation: 0,
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(8),
              //     side: BorderSide(color: Colors.grey.shade300, width: 1),
              //   ),
              //   color: Colors.transparent,
              //   child: Padding(
              //     padding: const EdgeInsets.all(12),
              //     child: Row(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         const Text('❗', style: TextStyle(fontSize: 20)),
              //         const SizedBox(width: 8),
              //         Expanded(
              //           child: Column(
              //             crossAxisAlignment: CrossAxisAlignment.start,
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             children: [
              //               Text(
              //                 "You have unfilled leave",
              //                 style: TextStyle(
              //                   fontSize: 13,
              //                   fontWeight: FontWeight.w600,
              //                   color: Colors.primaries[4],
              //                   height: 1.3,
              //                 ),
              //               ),
              //               const SizedBox(height: 2),
              //               const Text(
              //                 "File it to ensure your leave records are complete.",
              //                 style: TextStyle(
              //                   fontSize: 12,
              //                   color: Colors.black54,
              //                   height: 1.4,
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

              const SizedBox(height: 10),

              // ── Medical certificate (conditional) ──────────
              if (_selectedLeaveType?.name.toLowerCase() == 'sick leave' &&
                  _selectedDates.length >= 5) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Medical Certificate (Required)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: _pickFiles,
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
                                    onTap: () {
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
                  onPressed: _selectedLeaveType == null
                      ? null
                      : () {
                          openLeaveDateBottomSheet(context, (dates) {
                            setState(() => _selectedDates = dates);
                          });
                        },
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
                          onTap: () {
                            openLeaveDateBottomSheet(context, (dates) {
                              setState(() => _selectedDates = dates);
                            });
                          },
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
                        onPressed: () => _submitApplication(widget.staffId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0866FF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
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