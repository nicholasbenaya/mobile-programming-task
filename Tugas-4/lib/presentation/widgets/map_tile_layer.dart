import 'package:flutter_map/flutter_map.dart';

import '../../core/constants/app_constants.dart';

TileLayer buildTileLayer() => TileLayer(
      urlTemplate: AppConstants.mapTileUrl,
      userAgentPackageName: AppConstants.mapUserAgent,
    );
