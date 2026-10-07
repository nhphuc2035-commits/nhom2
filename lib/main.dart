import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuanLyXacThuc.khoiTao();
  runApp(const AppHotToc());
}

// Lớp quản lý trạng thái xác thực sinh trắc học bằng local_auth và SharedPreferences
class QuanLyXacThuc {
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyLinkedAccount = 'linked_account';

  static bool daKichHoatVanTay = false;
  static String taiKhoanLienKet = '';

  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Khởi tạo dữ liệu từ bộ nhớ máy (SharedPreferences)
  static Future<void> khoiTao() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      daKichHoatVanTay = prefs.getBool(keyBiometricEnabled) ?? false;
      taiKhoanLienKet = prefs.getString(keyLinkedAccount) ?? '';
    } catch (e) {
      debugPrint('Lỗi khởi tạo SharedPreferences: $e');
    }
  }

  /// Kiểm tra thiết bị có phần cứng sinh trắc học và đã cài vân tay hay chưa
  static Future<bool> kiemTraHoTroSinhTrac() async {
    try {
      final bool canCheck = await _localAuth.canCheckBiometrics;
      final bool isSupported = await _localAuth.isDeviceSupported();
      return canCheck || isSupported;
    } catch (e) {
      debugPrint('Lỗi kiểm tra phần cứng sinh trắc: $e');
      return false;
    }
  }

  /// Lưu trạng thái kích hoạt vào SharedPreferences
  static Future<void> luuTrangThai(bool enabled, String taiKhoan) async {
    daKichHoatVanTay = enabled;
    taiKhoanLienKet = taiKhoan;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyBiometricEnabled, enabled);
      await prefs.setString(keyLinkedAccount, taiKhoan);
    } catch (e) {
      debugPrint('Lỗi lưu SharedPreferences: $e');
    }
  }

  /// Gọi hộp thoại hệ thống quét vân tay thực tế từ phần cứng qua local_auth
  static Future<bool> xacThucVanTay({required String lyDo}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: lyDo,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Lỗi gọi authenticate sinh trắc học: $e');
      return false;
    }
  }
}

class LichHenItem {
  final String dichVu;
  final String ngay;
  final String gio;
  final String tho;

  LichHenItem({
    required this.dichVu,
    required this.ngay,
    required this.gio,
    required this.tho,
  });
}

class AppHotToc extends StatelessWidget {
  const AppHotToc({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Hớt Tóc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          primary: const Color(0xFF2563EB),
        ),
        useMaterial3: true,
      ),
      home: const DangNhapPage(),
    );
  }
}

class DangNhapPage extends StatefulWidget {
  const DangNhapPage({super.key});

  @override
  State<DangNhapPage> createState() => _DangNhapPageState();
}

class _DangNhapPageState extends State<DangNhapPage> {
  final TextEditingController _taiKhoanController = TextEditingController();
  final TextEditingController _matKhauController = TextEditingController();
  bool _anMatKhau = true;

  @override
  void initState() {
    super.initState();
    _dongBoTaiKhoanTuMemory();
  }

  void _dongBoTaiKhoanTuMemory() {
    if (QuanLyXacThuc.daKichHoatVanTay && QuanLyXacThuc.taiKhoanLienKet.isNotEmpty) {
      _taiKhoanController.text = QuanLyXacThuc.taiKhoanLienKet;
    }
  }

  void _dangNhap() {
    final taiKhoan = _taiKhoanController.text.trim();
    final matKhau = _matKhauController.text.trim();

    if (taiKhoan.isEmpty || matKhau.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tài khoản và mật khẩu!')),
      );
      return;
    }

    // Nếu tài khoản này đã kích hoạt vân tay trước đó -> Vào thẳng màn hình chính
    if (QuanLyXacThuc.daKichHoatVanTay && QuanLyXacThuc.taiKhoanLienKet.toLowerCase() == taiKhoan.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập thành công!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TrangChinhPage(tenNguoiDung: taiKhoan),
        ),
      );
      return;
    }

    // Nếu chưa kích hoạt vân tay cho tài khoản này -> Hiển thị hộp thoại hỏi người dùng
    final scaffold = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF2563EB), size: 24),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Kích hoạt vân tay',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            'Đăng nhập mật khẩu thành công! Bạn có muốn kích hoạt tính năng đăng nhập nhanh bằng vân tay cho tài khoản "$taiKhoan" vào các lần sau không?',
            style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nav.pop();
                nav.pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => TrangChinhPage(tenNguoiDung: taiKhoan),
                  ),
                );
              },
              child: const Text('Để sau', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                nav.pop();
                final bool hoTro = await QuanLyXacThuc.kiemTraHoTroSinhTrac();
                if (hoTro) {
                  final bool xacThucThanhCong = await QuanLyXacThuc.xacThucVanTay(
                    lyDo: 'Xác nhận vân tay để kích hoạt đăng nhập nhanh cho tài khoản $taiKhoan',
                  );
                  if (xacThucThanhCong) {
                    await QuanLyXacThuc.luuTrangThai(true, taiKhoan);
                    if (mounted) {
                      scaffold.showSnackBar(
                        const SnackBar(
                          content: Text('Kích hoạt đăng nhập vân tay thành công!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    if (mounted) {
                      scaffold.showSnackBar(
                        const SnackBar(content: Text('Chưa hoàn tất xác thực vân tay.')),
                      );
                    }
                  }
                } else {
                  // Thiết bị không có cảm biến -> vẫn lưu trạng thái nếu máy ảo
                  await QuanLyXacThuc.luuTrangThai(true, taiKhoan);
                }

                if (mounted) {
                  nav.pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => TrangChinhPage(tenNguoiDung: taiKhoan),
                    ),
                  );
                }
              },
              child: const Text('Kích hoạt ngay', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _quetVanTay() async {
    // Kiểm tra quy tắc: Chưa kích hoạt thì không cho vào
    if (!QuanLyXacThuc.daKichHoatVanTay || QuanLyXacThuc.taiKhoanLienKet.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Chưa kích hoạt vân tay',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Để đảm bảo an toàn, bạn cần đăng nhập bằng Số điện thoại/Tài khoản và Mật khẩu trước một lần. Hệ thống sẽ hỏi bạn có muốn kích hoạt vân tay cho các lần sau hay không.',
              style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Đã hiểu', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
      return;
    }

    final bool hoTro = await QuanLyXacThuc.kiemTraHoTroSinhTrac();
    if (!hoTro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thiết bị không hỗ trợ vân tay hoặc chưa cài đặt vân tay trong máy.')),
      );
      return;
    }

    // Quét vân tay phần cứng thực tế qua local_auth
    final bool thanhCong = await QuanLyXacThuc.xacThucVanTay(
      lyDo: 'Quét vân tay để đăng nhập nhanh vào App Hớt Tóc cho tài khoản: ${QuanLyXacThuc.taiKhoanLienKet}',
    );

    if (thanhCong && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xác thực vân tay thành công! Chào ${QuanLyXacThuc.taiKhoanLienKet}'),
          backgroundColor: Colors.green[700],
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TrangChinhPage(tenNguoiDung: QuanLyXacThuc.taiKhoanLienKet),
        ),
      );
    }
  }

  @override
  void dispose() {
    _taiKhoanController.dispose();
    _matKhauController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool daKichHoat = QuanLyXacThuc.daKichHoatVanTay && QuanLyXacThuc.taiKhoanLienKet.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF6FF),
              Color(0xFFF8FAFC),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.35, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tiêu đề: Đăng Nhập
                  const Center(
                    child: Text(
                      'Đăng Nhập',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Chào mừng bạn trở lại! Vui lòng đăng nhập để tiếp tục.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Khung thẻ Form đăng nhập
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0F0F172A),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label & Input Tài khoản
                        const Text(
                          'Tài khoản / Số điện thoại',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _taiKhoanController,
                          decoration: InputDecoration(
                            hintText: 'Nhập số điện thoại hoặc email',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF2563EB)),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Label & Input Mật khẩu
                        const Text(
                          'Mật khẩu',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _matKhauController,
                          obscureText: _anMatKhau,
                          decoration: InputDecoration(
                            hintText: 'Nhập mật khẩu của bạn',
                            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF2563EB)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _anMatKhau ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF64748B),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _anMatKhau = !_anMatKhau;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Quên mật khẩu
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng liên hệ hotline quán để được hỗ trợ đặt lại mật khẩu!'),
                                ),
                              );
                            },
                            child: const Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Hàng nút: Đăng Nhập + Nút Quét Vân Tay vuông kế bên phải
                        Row(
                          children: [
                            // Nút Đăng nhập chính
                            Expanded(
                              child: Container(
                                height: 54,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x592563EB),
                                      blurRadius: 16,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _dangNhap,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Đăng Nhập',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Nút Quét Vân Tay bo vuông kế bên phải
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _quetVanTay,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.fingerprint_rounded,
                                    color: daKichHoat ? const Color(0xFF2196F3) : const Color(0xFF93C5FD),
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TrangChinhPage extends StatefulWidget {
  final String tenNguoiDung;

  const TrangChinhPage({super.key, this.tenNguoiDung = 'Hoài An'});

  @override
  State<TrangChinhPage> createState() => _TrangChinhPageState();
}

class _TrangChinhPageState extends State<TrangChinhPage> {
  int _tabHienTai = 0;
  final List<LichHenItem> _danhSachLichHen = [];
  final List<String> _danhSachTho = [
    'Thợ Phúc',
    'Thợ An',
    'Thợ Quân',
    'Thợ Mạnh',
    'Thợ Trí'
  ];

  Future<void> _moHopThoaiChonLich(String tenDichVu) async {
    // 1. Chọn ngày
    final DateTime? ngayChon = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (ngayChon == null || !mounted) return;

    // 2. Chọn giờ
    final TimeOfDay? gioChon = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (gioChon == null || !mounted) return;

    // 3. Chọn thợ
    final String? thoChon = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text('Chọn thợ cắt tóc cho: $tenDichVu'),
          children: _danhSachTho.map((tho) {
            return SimpleDialogOption(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              onPressed: () => Navigator.pop(context, tho),
              child: Text(tho, style: const TextStyle(fontSize: 16)),
            );
          }).toList(),
        );
      },
    );

    if (thoChon == null || !mounted) return;

    final String ngayStr = '${ngayChon.day.toString().padLeft(2, '0')}/${ngayChon.month.toString().padLeft(2, '0')}/${ngayChon.year}';
    final String gioStr = '${gioChon.hour.toString().padLeft(2, '0')}:${gioChon.minute.toString().padLeft(2, '0')}';

    setState(() {
      _danhSachLichHen.add(LichHenItem(
        dichVu: tenDichVu,
        ngay: ngayStr,
        gio: gioStr,
        tho: thoChon,
      ));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tuyệt vời! Đã đặt lịch ($ngayStr $gioStr) với $thoChon!'),
        backgroundColor: Colors.green[700],
      ),
    );
  }

  void _hienThiDanhSachLichHen() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('📅 Danh sách lịch hẹn đã đặt'),
          content: _danhSachLichHen.isEmpty
              ? const Text('Bạn chưa đặt lịch hẹn nào.\nHãy nhấn "Đặt lịch ngay" hoặc chọn dịch vụ để đặt!')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _danhSachLichHen.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = _danhSachLichHen[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          child: Icon(Icons.content_cut),
                        ),
                        title: Text(item.dichVu, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('⏰ ${item.gio} - ${item.ngay}\n✂️ ${item.tho}'),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _hienThiThongTinTaiKhoan() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('👤 Thông tin tài khoản'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tài khoản: ${widget.tenNguoiDung}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Trạng thái: Đã xác thực', style: TextStyle(color: Colors.green)),
                  const SizedBox(height: 8),
                  const Text('Vai trò: Khách hàng thân thiết'),
                  const SizedBox(height: 8),
                  Text(
                    'Đăng nhập vân tay: ${QuanLyXacThuc.daKichHoatVanTay ? "Đã kích hoạt (${QuanLyXacThuc.taiKhoanLienKet})" : "Chưa kích hoạt"}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: QuanLyXacThuc.daKichHoatVanTay ? const Color(0xFF1976D2) : Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (QuanLyXacThuc.daKichHoatVanTay) {
                      await QuanLyXacThuc.luuTrangThai(false, '');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã tắt đăng nhập vân tay')),
                        );
                      }
                    } else {
                      await QuanLyXacThuc.luuTrangThai(true, widget.tenNguoiDung);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã bật đăng nhập vân tay cho ${widget.tenNguoiDung}')),
                        );
                      }
                    }
                    setDialogState(() {});
                    setState(() {});
                  },
                  child: Text(QuanLyXacThuc.daKichHoatVanTay ? 'Tắt vân tay' : 'Bật vân tay'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const DangNhapPage()),
                    );
                  },
                  child: const Text('Đăng xuất'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lời chào người dùng
              Text(
                'Chào, ${widget.tenNguoiDung} 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1D),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hôm nay bạn muốn cắt kiểu gì?',
                style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
              ),
              const SizedBox(height: 24),

              // Banner Khuyến mãi / Đặt lịch nhanh
              Card(
                color: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Combo Cắt Gội Tỏa Sáng',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Giảm 20% cho lần đặt lịch đầu tiên qua app',
                        style: TextStyle(fontSize: 14, color: Color(0xFFE3F2FD)),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _moHopThoaiChonLich('Combo Cắt Gội Tỏa Sáng'),
                        child: const Text('Đặt lịch ngay'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                'Dịch vụ nổi bật',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1D1D),
                ),
              ),
              const SizedBox(height: 16),

              // Danh sách dịch vụ dạng lưới 2 cột
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _moHopThoaiChonLich('Cắt tạo kiểu Mohican Fade'),
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const SizedBox(
                          height: 120,
                          child: Center(
                            child: Text(
                              'Cắt tạo kiểu\nMohican Fade',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1D1D),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _moHopThoaiChonLich('Uốn/Nhuộm'),
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const SizedBox(
                          height: 120,
                          child: Center(
                            child: Text(
                              'Uốn/Nhuộm',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1D1D),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabHienTai,
        selectedItemColor: const Color(0xFF1976D2),
        onTap: (index) {
          setState(() {
            _tabHienTai = index;
          });
          if (index == 0) {
            // Trang chủ
          } else if (index == 1) {
            _hienThiDanhSachLichHen();
          } else if (index == 2) {
            _hienThiThongTinTaiKhoan();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Lịch hẹn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}
