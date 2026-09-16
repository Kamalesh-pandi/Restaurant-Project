import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../config/theme.dart';

class ServerConfigDialog extends StatefulWidget {
  final VoidCallback? onSaved;

  const ServerConfigDialog({super.key, this.onSaved});

  static Future<void> show(BuildContext context, {VoidCallback? onSaved}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ServerConfigDialog(onSaved: onSaved),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;
  bool _testing = false;
  bool? _testSuccess;
  String? _testMessage;

  // Common quick presets
  final List<Map<String, String>> _presets = [
    {
      'label': 'Host Wi-Fi (Current)',
      'url': 'http://10.33.108.4:8080/api/v1',
      'desc': 'Direct Wi-Fi connection to host computer',
    },
    {
      'label': 'USB ADB Reverse',
      'url': 'http://127.0.0.1:8080/api/v1',
      'desc': 'Requires: adb reverse tcp:8080 tcp:8080',
    },
    {
      'label': 'Android Emulator',
      'url': 'http://10.0.2.2:8080/api/v1',
      'desc': 'Standard 10.0.2.2 alias for official emulator',
    },
  ];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiConfig.baseUrl);
    _runTest(ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _runTest(String url) async {
    setState(() {
      _testing = true;
      _testMessage = null;
    });

    final result = await ApiConfig.testConnection(url);
    if (!mounted) return;

    setState(() {
      _testing = false;
      _testSuccess = result['success'] == true;
      _testMessage = result['message']?.toString() ??
          (result['success'] == true ? 'Connected' : 'Connection failed');
    });
  }

  Future<void> _handleSave() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) return;

    await ApiConfig.setBaseUrl(newUrl);
    if (!mounted) return;

    widget.onSaved?.call();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Server endpoint saved: ${ApiConfig.baseUrl}'),
        backgroundColor: AppTheme.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.dns_rounded, color: AppTheme.primaryGold, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backend Server Config',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.titleHeading,
                        ),
                      ),
                      Text(
                        'Configure API base address for your device',
                        style: TextStyle(fontSize: 12, color: AppTheme.bodySecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Live Ping Status Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _testing
                    ? AppTheme.goldLight.withOpacity(0.12)
                    : (_testSuccess == true
                        ? AppTheme.statusSuccess.withOpacity(0.1)
                        : AppTheme.rose.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _testing
                      ? AppTheme.primaryGold
                      : (_testSuccess == true ? AppTheme.statusSuccess : AppTheme.rose),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  if (_testing) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Testing server connection...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.titleHeading),
                      ),
                    ),
                  ] else ...[
                    Icon(
                      _testSuccess == true ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: _testSuccess == true ? AppTheme.statusSuccess : AppTheme.rose,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _testMessage ?? 'Status unknown',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _testSuccess == true ? AppTheme.statusSuccess : AppTheme.rose,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _runTest(_urlController.text.trim()),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // URL Input Field
            const Text(
              'Server API Base URL',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.titleHeading),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'http://10.33.108.4:8080/api/v1',
                prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.primaryGold, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.play_circle_outline_rounded, color: AppTheme.primaryGold),
                  tooltip: 'Test this URL',
                  onPressed: () => _runTest(_urlController.text.trim()),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 16),

            // Presets
            const Text(
              'Quick Presets',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.titleHeading),
            ),
            const SizedBox(height: 8),
            ...List.generate(_presets.length, (index) {
              final p = _presets[index];
              final isSelected = _urlController.text.trim() == p['url'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    _urlController.text = p['url']!;
                    _runTest(p['url']!);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.goldLight.withOpacity(0.12) : AppTheme.surfaceSlate,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryGold : AppTheme.borderSlate,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          size: 18,
                          color: isSelected ? AppTheme.primaryGold : Colors.grey,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['label']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.titleHeading,
                                ),
                              ),
                              Text(
                                p['desc']!,
                                style: const TextStyle(fontSize: 11, color: AppTheme.bodySecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 8),

            // Tip banner
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If using USB cable, run "adb reverse tcp:8080 tcp:8080" in your computer terminal to use 127.0.0.1 without Wi-Fi.',
                      style: TextStyle(fontSize: 11, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppTheme.borderSlate),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      _urlController.text = ApiConfig.defaultBaseUrl;
                      _runTest(ApiConfig.defaultBaseUrl);
                    },
                    child: const Text(
                      'Reset Default',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.titleHeading),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: AppTheme.primaryGold,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _handleSave,
                    child: const Text(
                      'Save & Connect',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
