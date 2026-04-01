import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import 'dart:math';

// Enum to manage connection states
enum ConnectionStatus { disconnected, connecting, connected }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuantumTunnel VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple, // Modern Material 3 theme with deepPurple seed
        brightness: Brightness.dark, // Dark theme
        useMaterial3: true,
      ),
      home: const VPNPrankApp(),
    );
  }
}

class VPNPrankApp extends StatefulWidget {
  const VPNPrankApp({super.key});

  @override
  State<VPNPrankApp> createState() => _VPNPrankAppState();
}

class _VPNPrankAppState extends State<VPNPrankApp> with SingleTickerProviderStateMixin {
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String _ping = '--';
  String _download = '--';
  String _upload = '--';
  final Random _random = Random();
  Timer? _statsTimer;
  Timer? _connectionTimer;

  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  late VideoPlayerController _videoController;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _videoController = VideoPlayerController.asset('resources/video.mkv');
    _initializeVideoPlayerFuture = _videoController.initialize();
    _videoController.setLooping(true);
  }

  @override
  void dispose() {
    _statsTimer?.cancel();
    _connectionTimer?.cancel();
    _pulseAnimationController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _toggleConnection() {
    if (_connectionStatus == ConnectionStatus.disconnected) {
      setState(() {
        _connectionStatus = ConnectionStatus.connecting;
        _ping = '--';
        _download = '--';
        _upload = '--';
      });

      _pulseAnimationController.stop(); // Stop the pulse animation when connecting

      // Start updating fake stats periodically
      _statsTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        setState(() {
          _ping = '${_random.nextInt(31) + 15} ms'; // Random ping between 15-45 ms
          _download = '${_random.nextInt(51) + 50} Mbps'; // Random download between 50-100 Mbps
          _upload = '${_random.nextInt(31) + 20} Mbps'; // Random upload between 20-50 Mbps
        });
      });

      // Simulate connection duration (3-5 seconds)
      final int connectionDuration = _random.nextInt(3) + 3; // Random duration: 3, 4, or 5 seconds
      _connectionTimer = Timer(Duration(seconds: connectionDuration), () {
        _statsTimer?.cancel(); // Stop the stats updates after connection
        setState(() {
          _connectionStatus = ConnectionStatus.connected;
          // Set final stable stats
          _ping = '${_random.nextInt(11) + 10} ms'; // Final ping 10-20 ms
          _download = '${_random.nextInt(21) + 80} Mbps'; // Final download 80-100 Mbps
          _upload = '${_random.nextInt(11) + 40} Mbps'; // Final upload 40-50 Mbps
        });
        _videoController.play();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_connectionStatus == ConnectionStatus.connected) {
      return Scaffold(
        body: Center(
          child: FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return AspectRatio(
                  aspectRatio: _videoController.value.aspectRatio,
                  child: VideoPlayer(_videoController),
                );
              } else {
                return const CircularProgressIndicator();
              }
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _videoController.pause();
              _connectionStatus = ConnectionStatus.disconnected;
              _pulseAnimationController.repeat(reverse: true);
            });
          },
          child: const Icon(Icons.close),
        ),
      );
    }

    // Determine colors and text based on connection status
    final Color connectionColor = _connectionStatus == ConnectionStatus.connecting
            ? Colors.orange // Orange for connecting
            : Colors.grey; // Grey for disconnected

    final String connectionText = _connectionStatus == ConnectionStatus.connecting
            ? 'Connecting...'
            : 'Disconnected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('QuantumTunnel VPN'),
        centerTitle: true,
        backgroundColor: Colors.transparent, // Transparent app bar for sleek look
        elevation: 0, // No shadow
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Header
            Text(
              'VPN: $connectionText',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: connectionColor,
              ),
            ),
            const SizedBox(height: 40),

            // Central Connection Button
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: _connectionStatus == ConnectionStatus.disconnected
                      ? _toggleConnection // Only tapable when disconnected
                      : null,
                  child: ScaleTransition(
                    // Apply pulse animation only when disconnected
                    scale: _connectionStatus == ConnectionStatus.disconnected
                        ? _pulseAnimation
                        : const AlwaysStoppedAnimation(1.0), // No pulse when connecting/connected
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: connectionColor.withOpacity(0.2), // Subtle background color
                        border: Border.all(
                          color: connectionColor,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: connectionColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _connectionStatus == ConnectionStatus.connecting
                            ? const SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  strokeWidth: 6,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                Icons.power_settings_new, // Power icon
                                size: 100,
                                color: connectionColor,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Server Selection Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Theme.of(context).colorScheme.secondary),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Optimal Server',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Frankfurt - DE',
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Ping', _ping),
                _buildStatItem('Download', _download),
                _buildStatItem('Upload', _upload),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper widget to build individual stat items
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
