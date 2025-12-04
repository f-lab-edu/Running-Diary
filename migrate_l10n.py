#!/usr/bin/env python3
"""
L10n Refactoring Script
Converts nested L10n enum structure to flat structure across all Swift files
"""

import re
import sys
from pathlib import Path

# Mapping of old nested paths to new flat names
MIGRATION_MAP = {
    "L10n.Error.generic": "L10n.errorGeneric",
    "L10n.Format.yearMonth": "L10n.formatYearMonth",
    "L10n.Format.totalKm": "L10n.formatTotalKm",
    "L10n.Format.viewDiaryDate": "L10n.formatViewDiaryDate",
    "L10n.Format.km": "L10n.formatKm",
    "L10n.Healthkit.Data.empty": "L10n.healthkitDataEmpty",
    "L10n.Healthkit.Data.loading": "L10n.healthkitDataLoading",
    "L10n.Healthkit.Data.permissionMessage": "L10n.healthkitDataPermissionMessage",
    "L10n.Healthkit.Error.authorizationFailed": "L10n.healthkitErrorAuthorizationFailed",
    "L10n.Healthkit.Error.dataNotFound": "L10n.healthkitErrorDataNotFound",
    "L10n.Healthkit.Error.fetchContext": "L10n.healthkitErrorFetchContext",
    "L10n.Healthkit.Error.notAvailable": "L10n.healthkitErrorNotAvailable",
    "L10n.Healthkit.fetchFailedTitle": "L10n.healthkitFetchFailedTitle",
    "L10n.Record.add": "L10n.recordAdd",
    "L10n.Record.addButton": "L10n.recordAddButton",
    "L10n.Record.edit": "L10n.recordEdit",
    "L10n.Record.empty": "L10n.recordEmpty",
    "L10n.Record.fitnessData": "L10n.recordFitnessData",
    "L10n.Record.writeDiaryButton": "L10n.recordWriteDiaryButton",
    "L10n.Record.Error.fetchContext": "L10n.recordErrorFetchContext",
    "L10n.Record.Error.saveContext": "L10n.recordErrorSaveContext",
    "L10n.Record.Field.alcoholLabel": "L10n.recordFieldAlcoholLabel",
    "L10n.Record.Field.cadence": "L10n.recordFieldCadence",
    "L10n.Record.Field.condition": "L10n.recordFieldCondition",
    "L10n.Record.Field.distance": "L10n.recordFieldDistance",
    "L10n.Record.Field.duration": "L10n.recordFieldDuration",
    "L10n.Record.Field.hasMeal": "L10n.recordFieldHasMeal",
    "L10n.Record.Field.heartRate": "L10n.recordFieldHeartRate",
    "L10n.Record.Field.intensity": "L10n.recordFieldIntensity",
    "L10n.Record.Field.intensityPlaceholder": "L10n.recordFieldIntensityPlaceholder",
    "L10n.Record.Field.map": "L10n.recordFieldMap",
    "L10n.Record.Field.mealLabel": "L10n.recordFieldMealLabel",
    "L10n.Record.Field.memo": "L10n.recordFieldMemo",
    "L10n.Record.Field.memoPlaceholder": "L10n.recordFieldMemoPlaceholder",
    "L10n.Record.Field.pace": "L10n.recordFieldPace",
    "L10n.Record.Field.painAreas": "L10n.recordFieldPainAreas",
    "L10n.Record.Field.runningStyle": "L10n.recordFieldRunningStyle",
    "L10n.Record.Field.runningStyleLabel": "L10n.recordFieldRunningStyleLabel",
    "L10n.Record.Field.runningStylePlaceholder": "L10n.recordFieldRunningStylePlaceholder",
    "L10n.Record.Field.shoes": "L10n.recordFieldShoes",
    "L10n.Record.Field.shoesLabel": "L10n.recordFieldShoesLabel",
    "L10n.Record.Field.shoesPlaceholder": "L10n.recordFieldShoesPlaceholder",
    "L10n.Record.Field.sleepDuration": "L10n.recordFieldSleepDuration",
    "L10n.Record.Field.sleepLabel": "L10n.recordFieldSleepLabel",
    "L10n.Record.Field.time": "L10n.recordFieldTime",
    "L10n.Record.Field.wasDrinking": "L10n.recordFieldWasDrinking",
    "L10n.Repository.Error.deleteFailed": "L10n.repositoryErrorDeleteFailed",
    "L10n.Repository.Error.notFound": "L10n.repositoryErrorNotFound",
    "L10n.Repository.Error.saveFailed": "L10n.repositoryErrorSaveFailed",
    "L10n.Repository.Error.updateFailed": "L10n.repositoryErrorUpdateFailed",
    "L10n.Shoe.Error.fetchContext": "L10n.shoeErrorFetchContext",
    "L10n.Shoe.Error.fetchFailed": "L10n.shoeErrorFetchFailed",
    "L10n.UI.back": "L10n.uiBack",
    "L10n.UI.cancel": "L10n.uiCancel",
    "L10n.UI.done": "L10n.uiDone",
    "L10n.UI.edit": "L10n.uiEdit",
    "L10n.UI.goToSettings": "L10n.uiGoToSettings",
    "L10n.UI.save": "L10n.uiSave",
    "L10n.UI.today": "L10n.uiToday",
    "L10n.UI.viewDetails": "L10n.uiViewDetails",
    "L10n.Unit.bpm": "L10n.unitBpm",
    "L10n.Unit.hours": "L10n.unitHours",
    "L10n.Unit.km": "L10n.unitKm",
    "L10n.Unit.spm": "L10n.unitSpm",
    "L10n.Weather.noData": "L10n.weatherNoData",
    "L10n.Weather.Error.apiKeyMissing": "L10n.weatherErrorApiKeyMissing",
    "L10n.Weather.Error.dataUnavailable": "L10n.weatherErrorDataUnavailable",
    "L10n.Weather.Error.invalidResponse": "L10n.weatherErrorInvalidResponse",
    "L10n.Weather.Error.locationRequired": "L10n.weatherErrorLocationRequired",
    "L10n.Weather.Error.networkError": "L10n.weatherErrorNetworkError",
    "L10n.Weather.Field.temperature": "L10n.weatherFieldTemperature",
    "L10n.Weather.Field.humidity": "L10n.weatherFieldHumidity",
    "L10n.Weather.Field.windSpeed": "L10n.weatherFieldWindSpeed",
}

def migrate_file(file_path: Path) -> tuple[int, int]:
    """
    Migrate a single Swift file from nested to flat L10n structure.
    Returns (lines_changed, replacements_made)
    """
    content = file_path.read_text(encoding='utf-8')
    original_content = content
    replacements = 0

    # Sort by length (longest first) to avoid partial replacements
    sorted_mappings = sorted(MIGRATION_MAP.items(), key=lambda x: len(x[0]), reverse=True)

    for old_path, new_path in sorted_mappings:
        if old_path in content:
            count = content.count(old_path)
            content = content.replace(old_path, new_path)
            replacements += count
            print(f"  {old_path} -> {new_path} ({count} replacements)")

    if content != original_content:
        file_path.write_text(content, encoding='utf-8')
        return 1, replacements

    return 0, 0

def main():
    # Find all Swift files that use L10n (excluding L10n.swift itself initially)
    project_root = Path("/Users/kimhyeji/RunDiary")
    swift_files = list(project_root.rglob("*.swift"))

    # Filter to files that contain L10n references
    l10n_files = []
    for file_path in swift_files:
        if "Generated/L10n.swift" in str(file_path):
            continue  # Skip the L10n.swift file for now
        try:
            content = file_path.read_text(encoding='utf-8')
            if "L10n." in content:
                l10n_files.append(file_path)
        except:
            continue

    print(f"Found {len(l10n_files)} files using L10n")
    print("\nMigrating files...\n")

    total_replacements = 0
    files_changed = 0
    for file_path in l10n_files:
        print(f"Migrating: {file_path.relative_to(project_root)}")
        lines, replacements = migrate_file(file_path)
        total_replacements += replacements
        files_changed += lines
        if replacements == 0:
            print("  No changes needed")
        print()

    print(f"\n{'='*60}")
    print(f"Migration complete!")
    print(f"Files changed: {files_changed}/{len(l10n_files)}")
    print(f"Total replacements: {total_replacements}")
    print(f"{'='*60}")
    print("\nNext steps:")
    print("1. Update L10n.swift with the new flat structure")
    print("2. Run tests to verify everything works")
    print("3. Review changes with git diff")

if __name__ == "__main__":
    main()
