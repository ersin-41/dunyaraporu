import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  List<dynamic> _news = [];
  Map<String, dynamic>? _selectedScenario;
  bool _isLoadingNews = false;
  bool _isLoadingScenario = false;
  bool _isLoadingAudio = false;
  bool _isLoadingRender = false;
  String? _selectedNewsTitle;
  String? _lastAudioPath;
  String? _lastVideoPath;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoadingNews = true);
    try {
      final news = await _apiService.fetchLatestNews();
      setState(() => _news = news);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Haberler y\u00fcklenemedi: $e')),
      );
    } finally {
      setState(() => _isLoadingNews = false);
    }
  }

  Future<void> _generateScenario(String newsTitle) async {
    setState(() {
      _isLoadingScenario = true;
      _selectedNewsTitle = newsTitle;
      _selectedScenario = null;
      _lastAudioPath = null;
      _lastVideoPath = null;
    });
    try {
      final scenario = await _apiService.generateScenario(newsTitle);
      setState(() => _selectedScenario = scenario);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Senaryo olu\u015fturulamad\u0131: $e')),
      );
    } finally {
      setState(() => _isLoadingScenario = false);
    }
  }

  Future<void> _generateAudio() async {
    if (_selectedScenario == null || _selectedNewsTitle == null) return;
    
    setState(() => _isLoadingAudio = true);
    try {
      final projectName = _selectedNewsTitle!.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final path = await _apiService.generateAudio(
        _selectedScenario!['script'],
        projectName,
      );
      setState(() => _lastAudioPath = path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ses Ba\u015far\u0131yla Olu\u015fturuldu: $path'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ses \u00fcretilemedi: $e')),
      );
    } finally {
      setState(() => _isLoadingAudio = false);
    }
  }

  Future<void> _renderVideo() async {
    if (_selectedScenario == null || _selectedNewsTitle == null || _lastAudioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('L\u00fctfen \u00f6nce sesi olu\u015fturun.')),
      );
      return;
    }

    setState(() => _isLoadingRender = true);
    try {
      final projectName = _selectedNewsTitle!.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final path = await _apiService.renderVideo(
        _selectedScenario!,
        _lastAudioPath!,
        projectName,
      );
      setState(() => _lastVideoPath = path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Video Ba\u015far\u0131yla Olu\u015fturuldu!'),
          backgroundColor: Colors.blueAccent,
          duration: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video render edilemedi: $e')),
      );
    } finally {
      setState(() => _isLoadingRender = false);
    }
  }

  Future<void> _saveVideo() async {
    if (_lastVideoPath == null) return;
    try {
      final url = _apiService.getFullUrl(_lastVideoPath!);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\u0130ndirme ba\u015flat\u0131lamad\u0131: $e')),
      );
    }
  }

  void _shareVideo() {
    if (_lastVideoPath == null) return;
    final url = _apiService.getFullUrl(_lastVideoPath!);
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Video linki kopyaland\u0131!'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'A\u00c7',
          textColor: Colors.white,
          onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        ),
      ),
    );
  }

  void _handleLogout() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'D\u00dcNYA RAPORU - OPERASYON MERKEZ\u0130',
              style: TextStyle(
                color: Color(0xFFFFD700),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            if (_currentUser?.email != null)
              Text(
                'Yetkili: ${_currentUser!.email}',
                style: TextStyle(color: Colors.white54, fontSize: 10),
              ),
          ],
        ),
        backgroundColor: Colors.black,
        elevation: 10,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFFFFD700)),
            onPressed: _loadNews,
            tooltip: 'Haberleri Yenile',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _handleLogout,
            tooltip: 'G\u00fcvenli \u00c7\u0131k\u0131\u015f',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.white12)),
              ),
              child: _isLoadingNews
                  ? Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                  : ListView.builder(
                      itemCount: _news.length,
                      itemBuilder: (context, index) {
                        final item = _news[index];
                        final isSelected = _selectedNewsTitle == item['title'];
                        return Card(
                          color: isSelected ? Color(0xFF2A2A2A) : Colors.black,
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: isSelected ? Color(0xFFFFD700) : Colors.transparent,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text(
                              item['title'],
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            subtitle: Text(
                              'Lojistik Raporu',
                              style: TextStyle(color: Color(0xFFFFD700), fontSize: 11),
                            ),
                            onTap: () => _generateScenario(item['title']),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(24),
              child: _isLoadingScenario
                  ? Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                  : _selectedScenario == null
                      ? Center(
                          child: Text(
                            'Ba\u015flamak i\u00e7in bir haber se\u00e7in.',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TIKTOK SENARYO ANAL\u0130Z\u0130',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedScenario!['hook'] ?? 'Ba\u015fl\u0131k Yok',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Divider(color: Colors.white10, height: 32),
                                    Text(
                                      _selectedScenario!['script'] ?? 'Senaryo Yok',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24),
                              Text(
                                'G\u00d6RSEL OPERASYON PLANI',
                                style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              ...(_selectedScenario!['scenes'] as List? ?? []).map((scene) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.movie, color: Colors.white38, size: 16),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          scene,
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ).toList(),
                              SizedBox(height: 100),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedScenario != null ? Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_lastVideoPath != null) ...[
            FloatingActionButton(
              mini: true,
              heroTag: 'share',
              onPressed: _shareVideo,
              backgroundColor: Colors.green,
              child: Icon(Icons.share, color: Colors.white),
            ),
            SizedBox(width: 8),
            FloatingActionButton(
              mini: true,
              heroTag: 'save',
              onPressed: _saveVideo,
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.download, color: Colors.white),
            ),
            SizedBox(width: 8),
          ],
          FloatingActionButton.extended(
            heroTag: 'audio',
            onPressed: _isLoadingAudio ? null : _generateAudio,
            backgroundColor: Colors.black.withOpacity(0.8),
            icon: _isLoadingAudio 
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(Icons.mic, color: Colors.white),
            label: Text(_isLoadingAudio ? 'Olu\u015fturuluyor...' : 'Sesi Olu\u015ftur', style: TextStyle(color: Colors.white)),
          ),
          SizedBox(width: 12),
          FloatingActionButton.extended(
            heroTag: 'render',
            onPressed: (_isLoadingAudio || _isLoadingRender) ? null : _renderVideo,
            backgroundColor: Color(0xFFFFD700),
            icon: _isLoadingRender 
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Icon(Icons.video_settings, color: Colors.black),
            label: Text(_isLoadingRender ? 'Render Ediliyor...' : 'V\u0130DEOYU HAZIRLA', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ) : null,
    );
  }
}
