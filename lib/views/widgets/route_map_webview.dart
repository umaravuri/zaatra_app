import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/place_location_model.dart';
import '../../services/api_service.dart';
import '../../services/google_maps_service.dart';

class RouteMapWebView extends StatefulWidget {
  final String? pickup;
  final String? destination;
  final LocationPoint? pickupPoint;
  final LocationPoint? destPoint;
  final List<CandidateRoute> candidateRoutes;
  final String? rideId;
  final double height;
  final double borderRadius;
  final bool showNavigationOverlay;
  final bool interactive;
  final int selectedRouteIndex;
  final ValueChanged<int>? onRouteSelected;
  final VoidCallback? onTap;

  const RouteMapWebView({
    super.key,
    this.pickup,
    this.destination,
    this.pickupPoint,
    this.destPoint,
    this.candidateRoutes = const [],
    this.rideId,
    this.height = 200,
    this.borderRadius = 16,
    this.showNavigationOverlay = false,
    this.interactive = true,
    this.selectedRouteIndex = 0,
    this.onRouteSelected,
    this.onTap,
  });

  @override
  State<RouteMapWebView> createState() => _RouteMapWebViewState();
}

class _RouteMapWebViewState extends State<RouteMapWebView> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _currentUrl = '';

  @override
  void initState() {
    super.initState();
    _currentUrl = _buildMapUrl();
    _initWebView();
  }

  String _buildMapUrl() {
    const bypassParam = 'tunnel_skip_anti_phishing_page=true';
    if (widget.rideId != null && widget.rideId!.isNotEmpty) {
      return '${ApiService.baseUrl}/rides/${widget.rideId}/map-view?selectedRoute=${widget.selectedRouteIndex}&$bypassParam';
    }

    final p = widget.pickup?.trim() ?? 'Vijayawada';
    final d = widget.destination?.trim() ?? 'Hyderabad';

    return '${ApiService.baseUrl}/rides/map-view?pickup=${Uri.encodeComponent(p)}&destination=${Uri.encodeComponent(d)}&selectedRoute=${widget.selectedRouteIndex}&$bypassParam';
  }

  String _buildStaticMapUrl() {
    final p = widget.pickup?.trim() ?? 'Vijayawada';
    final d = widget.destination?.trim() ?? 'Hyderabad';
    final key = GoogleMapsService.apiKey;

    final activeRoute = (widget.candidateRoutes.isNotEmpty &&
            widget.selectedRouteIndex < widget.candidateRoutes.length)
        ? widget.candidateRoutes[widget.selectedRouteIndex]
        : (widget.candidateRoutes.isNotEmpty ? widget.candidateRoutes.first : null);

    final pathParam = (activeRoute != null && activeRoute.overviewPolyline.isNotEmpty)
        ? '&path=color:0x2563EBff%7Cweight:5%7Cenc:${Uri.encodeComponent(activeRoute.overviewPolyline)}'
        : '';

    return 'https://maps.googleapis.com/maps/api/staticmap?size=650x380&scale=2&maptype=roadmap&markers=color:0x10b981%7Clabel:A%7C${Uri.encodeComponent(p)}&markers=color:0xef4444%7Clabel:B%7C${Uri.encodeComponent(d)}$pathParam&key=$key';
  }

  String _generateLocalMapHtml() {
    final apiKey = GoogleMapsService.apiKey;
    final p = widget.pickup?.trim() ?? 'Pickup';
    final d = widget.destination?.trim() ?? 'Destination';
    final pLat = widget.pickupPoint?.latitude ?? 16.5062;
    final pLng = widget.pickupPoint?.longitude ?? 80.6480;
    final dLat = widget.destPoint?.latitude ?? 17.4065;
    final dLng = widget.destPoint?.longitude ?? 78.4772;

    final routesList = widget.candidateRoutes.map((r) => {
          'name': r.name,
          'summary': r.summary,
          'distance': r.distanceText,
          'duration': r.durationText,
          'polyline': r.overviewPolyline,
          'isRecommended': r.isRecommended,
        }).toList();

    final routesJson = jsonEncode(routesList);
    final activeIdx = widget.selectedRouteIndex;

    return '''<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Live Route Preview</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; overflow: hidden; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #e2e8f0; }
    #map { width: 100%; height: 100%; }
    .route-pill-wrapper {
      position: absolute;
      top: 12px;
      left: 12px;
      right: 12px;
      display: flex;
      justify-content: center;
      z-index: 10;
      pointer-events: none;
    }
    .route-pill {
      pointer-events: auto;
      max-width: 100%;
      background: rgba(255, 255, 255, 0.96);
      backdrop-filter: blur(8px);
      -webkit-backdrop-filter: blur(8px);
      padding: 6px 14px;
      border-radius: 999px;
      box-shadow: 0 4px 14px rgba(0, 0, 0, 0.16);
      border: 1.5px solid #dbeafe;
      display: flex;
      align-items: center;
      gap: 8px;
      user-select: none;
      -webkit-user-select: none;
      cursor: grab;
      overflow: hidden;
    }
    .route-pill:active {
      cursor: grabbing;
    }
    .route-pill-icon {
      flex-shrink: 0;
      font-size: 13px;
      display: inline-flex;
      align-items: center;
    }
    .route-pill-scroll {
      overflow-x: auto;
      overflow-y: hidden;
      white-space: nowrap;
      scrollbar-width: none;
      -ms-overflow-style: none;
      -webkit-overflow-scrolling: touch;
      touch-action: pan-x;
    }
    .route-pill-scroll::-webkit-scrollbar {
      display: none;
    }
    #routePillText {
      display: inline-block;
      font-size: 12px;
      font-weight: 700;
      color: #0f172a;
      white-space: nowrap;
    }
  </style>
</head>
<body>
  <div class="route-pill-wrapper">
    <div class="route-pill" id="routePill">
      <span class="route-pill-icon">🚘</span>
      <div class="route-pill-scroll" id="pillScroll">
        <span id="routePillText">Loading route...</span>
      </div>
    </div>
  </div>
  <div id="map"></div>

  <script src="https://maps.googleapis.com/maps/api/js?key=$apiKey&libraries=geometry"></script>
  <script>
    const candidateRoutes = $routesJson;
    let activeIndex = $activeIdx;

    const map = new google.maps.Map(document.getElementById('map'), {
      center: { lat: ($pLat + $dLat) / 2, lng: ($pLng + $dLng) / 2 },
      zoom: 12,
      disableDefaultUI: true,
      zoomControl: true,
      mapTypeId: 'roadmap',
      gestureHandling: 'greedy'
    });

    const bounds = new google.maps.LatLngBounds();
    bounds.extend(new google.maps.LatLng($pLat, $pLng));
    bounds.extend(new google.maps.LatLng($dLat, $dLng));

    // Point A (Green)
    new google.maps.Marker({
      position: { lat: $pLat, lng: $pLng },
      map: map,
      label: { text: 'A', color: '#ffffff', fontWeight: 'bold', fontSize: '11px' },
      icon: {
        path: google.maps.SymbolPath.CIRCLE,
        scale: 13,
        fillColor: '#10b981',
        fillOpacity: 1,
        strokeColor: '#ffffff',
        strokeWeight: 2.5
      },
      title: ${jsonEncode(p)}
    });

    // Point B (Red)
    new google.maps.Marker({
      position: { lat: $dLat, lng: $dLng },
      map: map,
      label: { text: 'B', color: '#ffffff', fontWeight: 'bold', fontSize: '11px' },
      icon: {
        path: google.maps.SymbolPath.CIRCLE,
        scale: 13,
        fillColor: '#ef4444',
        fillOpacity: 1,
        strokeColor: '#ffffff',
        strokeWeight: 2.5
      },
      title: ${jsonEncode(d)}
    });

    const polylineList = [];
    const casingList = [];

    candidateRoutes.forEach((route, idx) => {
      let path = [];
      if (route.polyline && window.google.maps.geometry) {
        path = google.maps.geometry.encoding.decodePath(route.polyline);
      }
      if (path.length > 0) {
        path.forEach(p => bounds.extend(p));
        const isSel = (idx === activeIndex);

        const casing = new google.maps.Polyline({
          path: path,
          geodesic: true,
          strokeColor: '#ffffff',
          strokeOpacity: isSel ? 0.95 : 0.0,
          strokeWeight: 9,
          zIndex: isSel ? 9 : 1,
          map: map
        });
        casingList.push(casing);

        const poly = new google.maps.Polyline({
          path: path,
          geodesic: true,
          strokeColor: isSel ? '#2563eb' : '#94a3b8',
          strokeOpacity: isSel ? 0.95 : 0.75,
          strokeWeight: isSel ? 6 : 4,
          zIndex: isSel ? 10 : 2,
          map: map
        });

        poly.addListener('click', () => {
          selectRoute(idx);
          if (window.FlutterMapChannel) {
            window.FlutterMapChannel.postMessage(String(idx));
          }
        });

        polylineList.push(poly);
      }
    });

    if (candidateRoutes.length === 0) {
      const directionsService = new google.maps.DirectionsService();
      const directionsRenderer = new google.maps.DirectionsRenderer({
        map: map,
        suppressMarkers: true,
        polylineOptions: {
          strokeColor: '#2563eb',
          strokeWeight: 6,
          strokeOpacity: 0.95
        }
      });

      const originReq = (${widget.pickupPoint != null} && $pLat && $pLng)
          ? { lat: $pLat, lng: $pLng }
          : ${jsonEncode(p)};
      const destReq = (${widget.destPoint != null} && $dLat && $dLng)
          ? { lat: $dLat, lng: $dLng }
          : ${jsonEncode(d)};

      directionsService.route({
        origin: originReq,
        destination: destReq,
        travelMode: google.maps.TravelMode.DRIVING
      }, (result, status) => {
        if (status === 'OK' && result && result.routes && result.routes.length > 0) {
          directionsRenderer.setDirections(result);
          const leg = result.routes[0].legs[0];
          const el = document.getElementById('routePillText');
          if (el && leg) {
            el.textContent = (leg.duration ? leg.duration.text + ' ' : '') + '(' + (leg.distance ? leg.distance.text : '') + ')';
          }
        } else {
          new google.maps.Polyline({
            path: [{ lat: $pLat, lng: $pLng }, { lat: $dLat, lng: $dLng }],
            strokeColor: '#2563eb',
            strokeOpacity: 0.85,
            strokeWeight: 5,
            geodesic: true,
            map: map
          });
          const el = document.getElementById('routePillText');
          if (el) el.textContent = ${jsonEncode(p)} + ' ➔ ' + ${jsonEncode(d)};
        }
      });
    }

    window.selectRoute = function(idx) {
      activeIndex = idx;
      polylineList.forEach((poly, i) => {
        const isSel = (i === idx);
        poly.setOptions({
          strokeColor: isSel ? '#2563eb' : '#94a3b8',
          strokeOpacity: isSel ? 0.95 : 0.75,
          strokeWeight: isSel ? 6 : 4,
          zIndex: isSel ? 10 : 2
        });
        if (casingList[i]) {
          casingList[i].setOptions({
            strokeOpacity: isSel ? 0.95 : 0.0,
            zIndex: isSel ? 9 : 1
          });
        }
      });

      const sel = candidateRoutes[idx];
      if (sel) {
        const el = document.getElementById('routePillText');
        if (el) el.textContent = (sel.summary ? sel.summary + ': ' : '') + sel.duration + ' (' + sel.distance + ')';
        const scrollEl = document.getElementById('pillScroll');
        if (scrollEl) scrollEl.scrollLeft = 0;
      }
    };

    const pillScroll = document.getElementById('pillScroll');
    if (pillScroll) {
      let isDown = false;
      let startX = 0;
      let scrollLeft = 0;
      pillScroll.addEventListener('mousedown', (e) => {
        isDown = true;
        startX = e.pageX - pillScroll.offsetLeft;
        scrollLeft = pillScroll.scrollLeft;
      });
      document.addEventListener('mouseup', () => isDown = false);
      pillScroll.addEventListener('mousemove', (e) => {
        if (!isDown) return;
        e.preventDefault();
        const x = e.pageX - pillScroll.offsetLeft;
        const walk = (x - startX) * 1.5;
        pillScroll.scrollLeft = scrollLeft - walk;
      });
    }

    selectRoute(activeIndex);
    map.fitBounds(bounds, { top: 50, right: 25, bottom: 25, left: 25 });
  </script>
</body>
</html>''';
  }

  void _initWebView() {
    if (kIsWeb) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFE8DEF8))
        ..addJavaScriptChannel(
          'FlutterMapChannel',
          onMessageReceived: (JavaScriptMessage message) {
            final idx = int.tryParse(message.message);
            if (idx != null && widget.onRouteSelected != null) {
              widget.onRouteSelected!(idx);
            }
          },
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (error.isForMainFrame ?? true) {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _hasError = true;
                  });
                }
              }
            },
          ),
        );

      // Primary: load fully self-contained Google Maps HTML locally (Zero DevTunnel calls)
      controller.loadHtmlString(_generateLocalMapHtml(), baseUrl: 'https://maps.googleapis.com');

      _controller = controller;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Widget _buildStaticMapWidget() {
    final staticUrl = _buildStaticMapUrl();
    final p = widget.pickup?.trim() ?? 'Origin';
    final d = widget.destination?.trim() ?? 'Destination';

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          staticUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              color: const Color(0xFFE8DEF8),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          },
          errorBuilder: (ctx, err, stack) => _buildFallbackCard(),
        ),
        // Floating Route Badge & Open in Google Maps action
        Positioned(
          top: 10,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(235),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_car_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            '$p ➔ $d',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  final extUrl = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(p)}&destination=${Uri.encodeComponent(d)}',
                  );
                  launchUrl(extUrl, mode: LaunchMode.externalApplication);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Maps', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackCard() {
    final p = widget.pickup?.trim() ?? 'Origin';
    final d = widget.destination?.trim() ?? 'Destination';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Vector road backdrop
        Container(
          color: const Color(0xFFF3EDF7),
          child: CustomPaint(
            painter: _RouteGridPainter(),
          ),
        ),

        // Route Information Overlay
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        p,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textMuted),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        d,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final extUrl = Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&origin=${Uri.encodeComponent(p)}&destination=${Uri.encodeComponent(d)}&travelmode=driving',
                      );
                      launchUrl(extUrl, mode: LaunchMode.externalApplication);
                    },
                    icon: const Icon(Icons.navigation_rounded, size: 14, color: Colors.white),
                    label: const Text('Start Navigation in Google Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void didUpdateWidget(covariant RouteMapWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.candidateRoutes.isNotEmpty) {
      if (oldWidget.candidateRoutes != widget.candidateRoutes) {
        _controller?.loadHtmlString(_generateLocalMapHtml(), baseUrl: 'https://maps.googleapis.com');
      } else if (oldWidget.selectedRouteIndex != widget.selectedRouteIndex) {
        _controller?.runJavaScript('if (window.selectRoute) { window.selectRoute(${widget.selectedRouteIndex}); }');
      }
      return;
    }

    if (oldWidget.pickup != widget.pickup ||
        oldWidget.destination != widget.destination ||
        oldWidget.selectedRouteIndex != widget.selectedRouteIndex) {
      _controller?.loadHtmlString(_generateLocalMapHtml(), baseUrl: 'https://maps.googleapis.com');
    }
  }

  @override
  Widget build(BuildContext context) {
    final useWebView = !kIsWeb && _controller != null && !_hasError;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFE8DEF8),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            // Map WebView on Mobile, or Google Static Map on Web/Error
            if (useWebView)
              Positioned.fill(
                child: WebViewWidget(
                  controller: _controller!,
                  gestureRecognizers: widget.interactive
                      ? {
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        }
                      : {},
                ),
              )
            else
              Positioned.fill(
                child: _buildStaticMapWidget(),
              ),

            // Loading Overlay for WebView
            if (useWebView && _isLoading)
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFF3EDF7).withAlpha(180),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading route map...',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Navigation Tap Overlay if requested
            if (widget.showNavigationOverlay)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(235),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me_rounded, size: 14, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Tap map to open Google Maps navigation',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Invisible Tap detector if onTap is provided and not interactive
            if (widget.onTap != null && !widget.interactive)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE5DCF6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double y = 20; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 30; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final routePaint = Paint()
      ..color = const Color(0xFF5B3AA8).withAlpha(160)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.15, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.25,
        size.width * 0.85,
        size.height * 0.35,
      );
    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
