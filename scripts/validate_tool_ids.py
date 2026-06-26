# scripts/validate_tool_ids.py
import re
import os
import sys

# Import tool definitions from generator script
sys.path.append(os.path.dirname(__file__))
from generate_tool_maps import tool_definitions

COUNTRY_SCREEN_PATHS = {
    "usa": "lib/features/usa/usa_screen.dart",
    "canada": "lib/features/canada/canada_screen.dart",
    "uk": "lib/features/uk/uk_screen.dart",
    "australia": "lib/features/australia/australia_screen.dart",
    "nz": "lib/features/newzealand/nz_screen.dart",
    "europe": "lib/features/europe/europe_screen.dart",
    "india": "lib/features/india/india_screen.dart",
}

def validate():
    errors = []
    
    # 1. Verify every defined tool ID is implemented in its country screen
    print("--- Verifying defined Tool IDs exist in target country screens ---")
    for tool_id, info in tool_definitions.items():
        country = info["country"]
        if country not in COUNTRY_SCREEN_PATHS:
            print(f"Skipping unknown country: '{country}' for tool ID: '{tool_id}'")
            continue
        
        path = COUNTRY_SCREEN_PATHS[country]
        if not os.path.exists(path):
            errors.append(f"Target country screen file does not exist: {path}")
            continue
            
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Check if the tool_id string is present in the screen code
        if tool_id not in content:
            errors.append(f"Tool ID '{tool_id}' is defined but NOT found in country screen file: '{path}'")
            
    # 2. Check for tool ID usages in country screens that aren't defined in generate_tool_maps.py
    print("--- Verifying country screen wrappers use valid Tool IDs ---")
    for country, path in COUNTRY_SCREEN_PATHS.items():
        if not os.path.exists(path):
            continue
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Find all DeepLinkHighlightWrapper toolId assignments
        # e.g., toolId: 'usa_loan_fha'
        found_ids = re.findall(r"toolId:\s*['\"]([^'\"]+)['\"]", content)
        for found_id in found_ids:
            if found_id not in tool_definitions:
                errors.append(f"Country screen '{path}' uses undefined toolId: '{found_id}'")

    # 3. Check navigateToTool calls in home and global screens
    print("--- Verifying navigateToTool calls use valid Tool IDs ---")
    caller_files = [
        "lib/features/home/home_screen.dart",
        "lib/features/global/global_screen.dart",
    ]
    for path in caller_files:
        if not os.path.exists(path):
            continue
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Find navigateToTool(context, 'country', 'tool_id')
        calls = re.findall(r"navigateToTool\(\s*context\s*,\s*['\"][^'\"]+['\"]\s*,\s*['\"]([^'\"]+)['\"]", content)
        for call_id in calls:
            if call_id not in tool_definitions:
                errors.append(f"File '{path}' calls navigateToTool with undefined tool ID: '{call_id}'")

    # Output results
    if errors:
      print("\nVALIDATION FAILED with the following errors:")
      for err in errors:
        print(f"  - {err}")
      sys.exit(1)
    else:
      print("\nVALIDATION SUCCESS: All tool IDs are properly defined, mapped, and linked!")
      sys.exit(0)

if __name__ == "__main__":
    validate()
