// lib/core/navigation/tool_navigation.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'tool_id_map.dart';

/// Universal navigation function for deep linking to specific calculator cards.
void navigateToTool(BuildContext context, String countryId, String? toolId) {
  final normalizedCountry = countryId.toLowerCase().trim();
  
  if (toolId == null || toolId.isEmpty) {
    // Standard country screen navigation
    context.push('/$normalizedCountry');
    return;
  }

  // Validate if toolId exists in the canonical map
  if (!toolIdMap.containsKey(toolId)) {
    // Log the bad toolId to console/analytics
    debugPrint('WARNING: Invalid or stale toolId navigated: "$toolId" (Country: "$countryId")');
    
    // Navigate with fallback parameter to show warning banner
    context.push('/$normalizedCountry?fallback=true');
    return;
  }

  // Valid tool ID navigation
  context.push('/$normalizedCountry?toolId=$toolId');
}
