#!/usr/bin/env python3
"""Write PrayerGuide.xcodeproj, the shared PrayerGuide scheme, and the widget target."""

from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SHARED_SOURCES = [
    "PrayerGuide/PrayerTimes/PrayerTimeEngine.swift",
    "PrayerGuide/Data/City.swift",
    "PrayerGuide/Theme/Palette.swift",
    "PrayerGuide/Shared/SharedPreferences.swift",
    "PrayerGuide/Shared/PrayerSnapshot.swift",
]
APP_ONLY_SOURCES = [
    "PrayerGuide/App/PrayerGuideApp.swift",
    "PrayerGuide/Views/TodayView.swift",
    "PrayerGuide/Views/CitySearchView.swift",
    "PrayerGuide/Views/SettingsScreen.swift",
    "PrayerGuide/Data/CityCatalog.swift",
    "PrayerGuide/Services/SettingsStore.swift",
    "PrayerGuide/Services/LocationService.swift",
    "PrayerGuide/Services/NotificationScheduler.swift",
    "PrayerGuide/Services/TodayModel.swift",
    "PrayerGuide/Shared/PrayerAlertPlan.swift",
    "PrayerGuide/Intents/MyFiveIntents.swift",
]
WIDGET_ONLY_SOURCES = [
    "MyFiveWidgets/MyFiveWidgetBundle.swift",
    "MyFiveWidgets/NextPrayerWidget.swift",
    "MyFiveWidgets/TodayPrayersWidget.swift",
]
APP_SOURCES = APP_ONLY_SOURCES + SHARED_SOURCES
WIDGET_SOURCES = WIDGET_ONLY_SOURCES + SHARED_SOURCES
APP_RESOURCES = [
    "PrayerGuide/Resources/Assets.xcassets",
    "PrayerGuide/Resources/PrivacyInfo.xcprivacy",
    "PrayerGuide/Data/cities.json",
]
WIDGET_RESOURCES = [
    "MyFiveWidgets/Assets.xcassets",
    "MyFiveWidgets/PrivacyInfo.xcprivacy",
]
SUPPORTING = [
    "PrayerGuide/Resources/PrayerGuide.entitlements",
    "MyFiveWidgets/MyFiveWidgets.entitlements",
    "MyFiveWidgets/Info.plist",
]
TEST_SOURCES = [
    "PrayerGuideTests/PrayerTimeEngineTests.swift",
    "PrayerGuideTests/CityCatalogTests.swift",
    "PrayerGuideTests/PrayerAlertPlanTests.swift",
]


def hid(seed: str) -> str:
    return hashlib.sha1(seed.encode()).hexdigest()[:24].upper()


def file_type(path: Path) -> str:
    return {
        ".swift": "sourcecode.swift",
        ".json": "text.json",
        ".xcprivacy": "text.xml",
        ".xcassets": "folder.assetcatalog",
        ".entitlements": "text.plist.entitlements",
        ".plist": "text.plist.xml",
    }.get(path.suffix, "text")


def main() -> None:
    ids = {
        "project": hid("project"),
        "root": hid("root"),
        "products": hid("products"),
        "app_group": hid("app_group"),
        "tests_group": hid("tests_group"),
        "widget_group": hid("widget_group"),
        "app_target": hid("app_target"),
        "tests_target": hid("tests_target"),
        "widget_target": hid("widget_target"),
        "app_product": hid("app_product"),
        "tests_product": hid("tests_product"),
        "widget_product": hid("widget_product"),
        "app_sources": hid("app_sources"),
        "app_resources": hid("app_resources"),
        "app_frameworks": hid("app_frameworks"),
        "app_embed": hid("app_embed"),
        "tests_sources": hid("tests_sources"),
        "tests_frameworks": hid("tests_frameworks"),
        "widget_sources": hid("widget_sources"),
        "widget_resources": hid("widget_resources"),
        "widget_frameworks": hid("widget_frameworks"),
        "proxy": hid("proxy"),
        "dependency": hid("dependency"),
        "widget_proxy": hid("widget_proxy"),
        "widget_dependency": hid("widget_dependency"),
        "embed_build": hid("embed_build"),
        "proj_configs": hid("proj_configs"),
        "app_configs": hid("app_configs"),
        "tests_configs": hid("tests_configs"),
        "widget_configs": hid("widget_configs"),
        "proj_debug": hid("proj_debug"),
        "proj_release": hid("proj_release"),
        "app_debug": hid("app_debug"),
        "app_release": hid("app_release"),
        "tests_debug": hid("tests_debug"),
        "tests_release": hid("tests_release"),
        "widget_debug": hid("widget_debug"),
        "widget_release": hid("widget_release"),
    }

    all_paths = APP_SOURCES + WIDGET_ONLY_SOURCES + APP_RESOURCES + WIDGET_RESOURCES + SUPPORTING + TEST_SOURCES
    file_refs = {rel: hid(f"ref:{rel}") for rel in all_paths}

    def build_id(target: str, rel: str) -> str:
        return hid(f"build:{target}:{rel}")

    groups: dict[str, list[str]] = {}
    for rel in all_paths:
        groups.setdefault(str(Path(rel).parent), []).append(rel)
    group_ids = {folder: hid(f"group:{folder}") for folder in groups}

    def ref_block(rel: str) -> str:
        path = Path(rel)
        return (
            f"\t\t{file_refs[rel]} /* {path.name} */ = {{"
            f"isa = PBXFileReference; lastKnownFileType = {file_type(path)}; "
            f"path = {path.name}; sourceTree = \"<group>\"; }};"
        )

    def build_block(target: str, rel: str, phase: str) -> str:
        name = Path(rel).name
        extra = ""
        if phase == "Embed Foundation Extensions":
            extra = " settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); };"
        return (
            f"\t\t{build_id(target, rel)} /* {name} in {phase} */ = {{"
            f"isa = PBXBuildFile; fileRef = {file_refs[rel]} /* {name} */;{extra} }};"
        )

    pbx_build = "\n".join(
        [build_block("app", rel, "Sources") for rel in APP_SOURCES]
        + [build_block("app", rel, "Resources") for rel in APP_RESOURCES]
        + [build_block("widget", rel, "Sources") for rel in WIDGET_SOURCES]
        + [build_block("widget", rel, "Resources") for rel in WIDGET_RESOURCES]
        + [build_block("tests", rel, "Sources") for rel in TEST_SOURCES]
        + [
            (
                f"\t\t{ids['embed_build']} /* MyFiveWidgets.appex in Embed Foundation Extensions */ = {{"
                f"isa = PBXBuildFile; fileRef = {ids['widget_product']} /* MyFiveWidgets.appex */; "
                f"settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};"
            )
        ]
    )

    pbx_refs = "\n".join(ref_block(rel) for rel in all_paths)
    pbx_refs += (
        f"\n\t\t{ids['app_product']} /* PrayerGuide.app */ = {{isa = PBXFileReference; "
        f"explicitFileType = wrapper.application; includeInIndex = 0; path = PrayerGuide.app; "
        f"sourceTree = BUILT_PRODUCTS_DIR; }};"
        f"\n\t\t{ids['tests_product']} /* PrayerGuideTests.xctest */ = {{isa = PBXFileReference; "
        f"explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = PrayerGuideTests.xctest; "
        f"sourceTree = BUILT_PRODUCTS_DIR; }};"
        f"\n\t\t{ids['widget_product']} /* MyFiveWidgets.appex */ = {{isa = PBXFileReference; "
        f"explicitFileType = \"wrapper.app-extension\"; includeInIndex = 0; path = MyFiveWidgets.appex; "
        f"sourceTree = BUILT_PRODUCTS_DIR; }};"
    )

    def children(folder: str) -> str:
        refs = ", ".join(f"{file_refs[rel]} /* {Path(rel).name} */" for rel in sorted(groups[folder]))
        name = Path(folder).name
        return (
            f"\t\t{group_ids[folder]} /* {name} */ = {{\n"
            f"\t\t\tisa = PBXGroup;\n"
            f"\t\t\tchildren = (\n"
            f"\t\t\t\t{refs},\n"
            f"\t\t\t);\n"
            f"\t\t\tpath = {name};\n"
            f"\t\t\tsourceTree = \"<group>\";\n"
            f"\t\t}};"
        )

    pbx_groups = "\n".join(children(folder) for folder in sorted(groups))

    app_group_children = ", ".join(
        f"{group_ids[folder]} /* {Path(folder).name} */"
        for folder in sorted(groups)
        if folder.startswith("PrayerGuide/")
    )
    widget_folder_id = group_ids["MyFiveWidgets"]
    test_group_children = ", ".join(f"{file_refs[rel]} /* {Path(rel).name} */" for rel in TEST_SOURCES)

    pbx_groups += f"""
		{ids['root']} = {{
			isa = PBXGroup;
			children = (
				{ids['app_group']} /* PrayerGuide */,
				{widget_folder_id} /* MyFiveWidgets */,
				{ids['tests_group']} /* PrayerGuideTests */,
				{ids['products']} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{ids['products']} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{ids['app_product']} /* PrayerGuide.app */,
				{ids['widget_product']} /* MyFiveWidgets.appex */,
				{ids['tests_product']} /* PrayerGuideTests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
		{ids['app_group']} /* PrayerGuide */ = {{
			isa = PBXGroup;
			children = (
				{app_group_children},
			);
			path = PrayerGuide;
			sourceTree = "<group>";
		}};
		{ids['tests_group']} /* PrayerGuideTests */ = {{
			isa = PBXGroup;
			children = (
				{test_group_children},
			);
			path = PrayerGuideTests;
			sourceTree = "<group>";
		}};
"""

    app_source_files = ",\n".join(
        f"\t\t\t\t{build_id('app', rel)} /* {Path(rel).name} in Sources */" for rel in APP_SOURCES
    )
    app_resource_files = ",\n".join(
        f"\t\t\t\t{build_id('app', rel)} /* {Path(rel).name} in Resources */" for rel in APP_RESOURCES
    )
    widget_source_files = ",\n".join(
        f"\t\t\t\t{build_id('widget', rel)} /* {Path(rel).name} in Sources */" for rel in WIDGET_SOURCES
    )
    widget_resource_files = ",\n".join(
        f"\t\t\t\t{build_id('widget', rel)} /* {Path(rel).name} in Resources */" for rel in WIDGET_RESOURCES
    )
    test_files = ",\n".join(
        f"\t\t\t\t{build_id('tests', rel)} /* {Path(rel).name} in Sources */" for rel in TEST_SOURCES
    )

    location_usage = (
        "My Five uses your location only to calculate salah times for where you are. "
        "Times are worked out on this iPhone and are never sent anywhere. "
        "You can refuse and pick a city instead."
    )

    common_debug = project_debug_settings()
    common_release = project_release_settings()

    pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{pbx_build}
/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		{ids['proxy']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {ids['project']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {ids['app_target']};
			remoteInfo = PrayerGuide;
		}};
		{ids['widget_proxy']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {ids['project']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {ids['widget_target']};
			remoteInfo = MyFiveWidgets;
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXCopyFilesBuildPhase section */
		{ids['app_embed']} /* Embed Foundation Extensions */ = {{
			isa = PBXCopyFilesBuildPhase;
			buildActionMask = 2147483647;
			dstPath = "";
			dstSubfolderSpec = 13;
			files = (
				{ids['embed_build']} /* MyFiveWidgets.appex in Embed Foundation Extensions */,
			);
			name = "Embed Foundation Extensions";
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXCopyFilesBuildPhase section */

/* Begin PBXFileReference section */
{pbx_refs}
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{ids['app_frameworks']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['tests_frameworks']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['widget_frameworks']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
{pbx_groups}
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{ids['app_target']} /* PrayerGuide */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {ids['app_configs']} /* Build configuration list for PBXNativeTarget "PrayerGuide" */;
			buildPhases = (
				{ids['app_sources']} /* Sources */,
				{ids['app_frameworks']} /* Frameworks */,
				{ids['app_resources']} /* Resources */,
				{ids['app_embed']} /* Embed Foundation Extensions */,
			);
			buildRules = (
			);
			dependencies = (
				{ids['widget_dependency']} /* PBXTargetDependency */,
			);
			name = PrayerGuide;
			productName = PrayerGuide;
			productReference = {ids['app_product']} /* PrayerGuide.app */;
			productType = "com.apple.product-type.application";
		}};
		{ids['tests_target']} /* PrayerGuideTests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {ids['tests_configs']} /* Build configuration list for PBXNativeTarget "PrayerGuideTests" */;
			buildPhases = (
				{ids['tests_sources']} /* Sources */,
				{ids['tests_frameworks']} /* Frameworks */,
			);
			buildRules = (
			);
			dependencies = (
				{ids['dependency']} /* PBXTargetDependency */,
			);
			name = PrayerGuideTests;
			productName = PrayerGuideTests;
			productReference = {ids['tests_product']} /* PrayerGuideTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		}};
		{ids['widget_target']} /* MyFiveWidgets */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {ids['widget_configs']} /* Build configuration list for PBXNativeTarget "MyFiveWidgets" */;
			buildPhases = (
				{ids['widget_sources']} /* Sources */,
				{ids['widget_frameworks']} /* Frameworks */,
				{ids['widget_resources']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = MyFiveWidgets;
			productName = MyFiveWidgets;
			productReference = {ids['widget_product']} /* MyFiveWidgets.appex */;
			productType = "com.apple.product-type.app-extension";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{ids['project']} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{ids['app_target']} = {{
						CreatedOnToolsVersion = 15.0;
					}};
					{ids['tests_target']} = {{
						CreatedOnToolsVersion = 15.0;
						TestTargetID = {ids['app_target']};
					}};
					{ids['widget_target']} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {ids['proj_configs']} /* Build configuration list for PBXProject "PrayerGuide" */;
			compatibilityVersion = "Xcode 15.0";
			developmentRegion = "en-GB";
			hasScannedForEncodings = 0;
			knownRegions = (
				"en-GB",
				en,
				Base,
			);
			mainGroup = {ids['root']};
			productRefGroup = {ids['products']} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{ids['app_target']} /* PrayerGuide */,
				{ids['widget_target']} /* MyFiveWidgets */,
				{ids['tests_target']} /* PrayerGuideTests */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{ids['app_resources']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{app_resource_files},
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['widget_resources']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{widget_resource_files},
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{ids['app_sources']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{app_source_files},
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['widget_sources']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{widget_source_files},
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['tests_sources']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{test_files},
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		{ids['dependency']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {ids['app_target']} /* PrayerGuide */;
			targetProxy = {ids['proxy']} /* PBXContainerItemProxy */;
		}};
		{ids['widget_dependency']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {ids['widget_target']} /* MyFiveWidgets */;
			targetProxy = {ids['widget_proxy']} /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		{ids['proj_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{common_debug}}};
			name = Debug;
		}};
		{ids['proj_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{common_release}}};
			name = Release;
		}};
		{ids['app_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{app_settings(location_usage)}}};
			name = Debug;
		}};
		{ids['app_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{app_settings(location_usage)}}};
			name = Release;
		}};
		{ids['tests_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{test_settings()}}};
			name = Debug;
		}};
		{ids['tests_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{test_settings()}}};
			name = Release;
		}};
		{ids['widget_debug']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{widget_settings()}}};
			name = Debug;
		}};
		{ids['widget_release']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{{widget_settings()}}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{ids['proj_configs']} /* Build configuration list for PBXProject "PrayerGuide" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['proj_debug']} /* Debug */,
				{ids['proj_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{ids['app_configs']} /* Build configuration list for PBXNativeTarget "PrayerGuide" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['app_debug']} /* Debug */,
				{ids['app_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{ids['tests_configs']} /* Build configuration list for PBXNativeTarget "PrayerGuideTests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['tests_debug']} /* Debug */,
				{ids['tests_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{ids['widget_configs']} /* Build configuration list for PBXNativeTarget "MyFiveWidgets" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['widget_debug']} /* Debug */,
				{ids['widget_release']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {ids['project']} /* Project object */;
}}
"""

    proj_dir = ROOT / "PrayerGuide.xcodeproj"
    (proj_dir / "project.xcworkspace").mkdir(parents=True, exist_ok=True)
    (proj_dir / "xcshareddata" / "xcschemes").mkdir(parents=True, exist_ok=True)
    (proj_dir / "project.pbxproj").write_text(pbx, encoding="utf-8")
    (proj_dir / "project.xcworkspace" / "contents.xcworkspacedata").write_text(
        """<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
""",
        encoding="utf-8",
    )

    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "1500"
   version = "1.7">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ids['app_target']}"
               BuildableName = "PrayerGuide.app"
               BlueprintName = "PrayerGuide"
               ReferencedContainer = "container:PrayerGuide.xcodeproj">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES">
      <Testables>
         <TestableReference
            skipped = "NO"
            parallelizable = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "{ids['tests_target']}"
               BuildableName = "PrayerGuideTests.xctest"
               BlueprintName = "PrayerGuideTests"
               ReferencedContainer = "container:PrayerGuide.xcodeproj">
            </BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction
      buildConfiguration = "Debug"
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      debugServiceExtension = "internal"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{ids['app_target']}"
            BuildableName = "PrayerGuide.app"
            BlueprintName = "PrayerGuide"
            ReferencedContainer = "container:PrayerGuide.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction
      buildConfiguration = "Release"
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "{ids['app_target']}"
            BuildableName = "PrayerGuide.app"
            BlueprintName = "PrayerGuide"
            ReferencedContainer = "container:PrayerGuide.xcodeproj">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "Debug">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "Release"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
"""
    (proj_dir / "xcshareddata" / "xcschemes" / "PrayerGuide.xcscheme").write_text(scheme, encoding="utf-8")
    print(f"Wrote {proj_dir}")
    print(f"App target id {ids['app_target']}")
    print(f"Widget target id {ids['widget_target']}")


def settings_block(pairs: dict[str, str]) -> str:
    lines = [""]
    for key, value in pairs.items():
        lines.append(f"\t\t\t\t{key} = {value};")
    lines.append("\t\t\t")
    return "\n".join(lines)


def project_debug_settings() -> str:
    return settings_block(
        {
            "ALWAYS_SEARCH_USER_PATHS": "NO",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "CLANG_ANALYZER_NONNULL": "YES",
            "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
            "CLANG_CXX_LANGUAGE_STANDARD": '"gnu++20"',
            "CLANG_ENABLE_MODULES": "YES",
            "CLANG_ENABLE_OBJC_ARC": "YES",
            "CLANG_ENABLE_OBJC_WEAK": "YES",
            "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
            "CLANG_WARN_BOOL_CONVERSION": "YES",
            "CLANG_WARN_COMMA": "YES",
            "CLANG_WARN_CONSTANT_CONVERSION": "YES",
            "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
            "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
            "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
            "CLANG_WARN_EMPTY_BODY": "YES",
            "CLANG_WARN_ENUM_CONVERSION": "YES",
            "CLANG_WARN_INFINITE_RECURSION": "YES",
            "CLANG_WARN_INT_CONVERSION": "YES",
            "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
            "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
            "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
            "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
            "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
            "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
            "CLANG_WARN_STRICT_PROTOTYPES": "YES",
            "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
            "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
            "CLANG_WARN_UNREACHABLE_CODE": "YES",
            "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
            "COPY_PHASE_STRIP": "NO",
            "DEBUG_INFORMATION_FORMAT": "dwarf",
            "ENABLE_STRICT_OBJC_MSGSEND": "YES",
            "ENABLE_TESTABILITY": "YES",
            "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
            "GCC_C_LANGUAGE_STANDARD": "gnu17",
            "GCC_DYNAMIC_NO_PIC": "NO",
            "GCC_NO_COMMON_BLOCKS": "YES",
            "GCC_OPTIMIZATION_LEVEL": "0",
            "GCC_PREPROCESSOR_DEFINITIONS": '("DEBUG=1", "$(inherited)", )',
            "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
            "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
            "GCC_WARN_UNDECLARED_SELECTOR": "YES",
            "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
            "GCC_WARN_UNUSED_FUNCTION": "YES",
            "GCC_WARN_UNUSED_VARIABLE": "YES",
            "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
            "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
            "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
            "MTL_FAST_MATH": "YES",
            "ONLY_ACTIVE_ARCH": "YES",
            "SDKROOT": "iphoneos",
            "SWIFT_ACTIVE_COMPILATION_CONDITIONS": '"DEBUG $(inherited)"',
            "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"',
            "SWIFT_STRICT_CONCURRENCY": "targeted",
        }
    )


def project_release_settings() -> str:
    return settings_block(
        {
            "ALWAYS_SEARCH_USER_PATHS": "NO",
            "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
            "CLANG_ANALYZER_NONNULL": "YES",
            "CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION": "YES_AGGRESSIVE",
            "CLANG_CXX_LANGUAGE_STANDARD": '"gnu++20"',
            "CLANG_ENABLE_MODULES": "YES",
            "CLANG_ENABLE_OBJC_ARC": "YES",
            "CLANG_ENABLE_OBJC_WEAK": "YES",
            "CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING": "YES",
            "CLANG_WARN_BOOL_CONVERSION": "YES",
            "CLANG_WARN_COMMA": "YES",
            "CLANG_WARN_CONSTANT_CONVERSION": "YES",
            "CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS": "YES",
            "CLANG_WARN_DIRECT_OBJC_ISA_USAGE": "YES_ERROR",
            "CLANG_WARN_DOCUMENTATION_COMMENTS": "YES",
            "CLANG_WARN_EMPTY_BODY": "YES",
            "CLANG_WARN_ENUM_CONVERSION": "YES",
            "CLANG_WARN_INFINITE_RECURSION": "YES",
            "CLANG_WARN_INT_CONVERSION": "YES",
            "CLANG_WARN_NON_LITERAL_NULL_CONVERSION": "YES",
            "CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF": "YES",
            "CLANG_WARN_OBJC_LITERAL_CONVERSION": "YES",
            "CLANG_WARN_OBJC_ROOT_CLASS": "YES_ERROR",
            "CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER": "YES",
            "CLANG_WARN_RANGE_LOOP_ANALYSIS": "YES",
            "CLANG_WARN_STRICT_PROTOTYPES": "YES",
            "CLANG_WARN_SUSPICIOUS_MOVE": "YES",
            "CLANG_WARN_UNGUARDED_AVAILABILITY": "YES_AGGRESSIVE",
            "CLANG_WARN_UNREACHABLE_CODE": "YES",
            "CLANG_WARN__DUPLICATE_METHOD_MATCH": "YES",
            "COPY_PHASE_STRIP": "NO",
            "DEBUG_INFORMATION_FORMAT": '"dwarf-with-dsym"',
            "ENABLE_NS_ASSERTIONS": "NO",
            "ENABLE_STRICT_OBJC_MSGSEND": "YES",
            "ENABLE_USER_SCRIPT_SANDBOXING": "YES",
            "GCC_C_LANGUAGE_STANDARD": "gnu17",
            "GCC_NO_COMMON_BLOCKS": "YES",
            "GCC_WARN_64_TO_32_BIT_CONVERSION": "YES",
            "GCC_WARN_ABOUT_RETURN_TYPE": "YES_ERROR",
            "GCC_WARN_UNDECLARED_SELECTOR": "YES",
            "GCC_WARN_UNINITIALIZED_AUTOS": "YES_AGGRESSIVE",
            "GCC_WARN_UNUSED_FUNCTION": "YES",
            "GCC_WARN_UNUSED_VARIABLE": "YES",
            "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
            "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
            "MTL_ENABLE_DEBUG_INFO": "NO",
            "MTL_FAST_MATH": "YES",
            "SDKROOT": "iphoneos",
            "SWIFT_COMPILATION_MODE": "wholemodule",
            "SWIFT_STRICT_CONCURRENCY": "targeted",
            "VALIDATE_PRODUCT": "YES",
        }
    )


def app_settings(location_usage: str) -> str:
    quoted = location_usage.replace('"', '\\"')
    return settings_block(
        {
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
            "CODE_SIGN_ENTITLEMENTS": "PrayerGuide/Resources/PrayerGuide.entitlements",
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "3",
            "DEVELOPMENT_TEAM": '""',
            "ENABLE_PREVIEWS": "YES",
            "GENERATE_INFOPLIST_FILE": "YES",
            "INFOPLIST_KEY_CFBundleDisplayName": '"My Five"',
            "INFOPLIST_KEY_ITSAppUsesNonExemptEncryption": "NO",
            "INFOPLIST_KEY_LSApplicationCategoryType": '"public.app-category.lifestyle"',
            "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription": f'"{quoted}"',
            "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
            "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
            "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
            "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
            "LD_RUNPATH_SEARCH_PATHS": '("$(inherited)", "@executable_path/Frameworks", )',
            "MARKETING_VERSION": "1.0",
            "PRODUCT_BUNDLE_IDENTIFIER": "ai.desklink.prayerguide",
            "PRODUCT_NAME": "PrayerGuide",
            "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"',
            "SUPPORTS_MACCATALYST": "NO",
            "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
            "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "SWIFT_VERSION": "5.0",
            "TARGETED_DEVICE_FAMILY": "1",
        }
    )


def test_settings() -> str:
    return settings_block(
        {
            "BUNDLE_LOADER": '"$(TEST_HOST)"',
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "3",
            "DEVELOPMENT_TEAM": '""',
            "GENERATE_INFOPLIST_FILE": "YES",
            "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
            "MARKETING_VERSION": "1.0",
            "PRODUCT_BUNDLE_IDENTIFIER": "ai.desklink.prayerguide.tests",
            "PRODUCT_NAME": '"$(TARGET_NAME)"',
            "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"',
            "SWIFT_EMIT_LOC_STRINGS": "NO",
            "SWIFT_VERSION": "5.0",
            "TARGETED_DEVICE_FAMILY": "1",
            "TEST_HOST": '"$(BUILT_PRODUCTS_DIR)/PrayerGuide.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/PrayerGuide"',
        }
    )


def widget_settings() -> str:
    return settings_block(
        {
            "APPLICATION_EXTENSION_API_ONLY": "YES",
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
            "CODE_SIGN_ENTITLEMENTS": "MyFiveWidgets/MyFiveWidgets.entitlements",
            "CODE_SIGN_STYLE": "Automatic",
            "CURRENT_PROJECT_VERSION": "3",
            "DEVELOPMENT_TEAM": '""',
            "GENERATE_INFOPLIST_FILE": "YES",
            "INFOPLIST_FILE": "MyFiveWidgets/Info.plist",
            "INFOPLIST_KEY_CFBundleDisplayName": '"My Five"',
            "INFOPLIST_KEY_NSHumanReadableCopyright": '""',
            "LD_RUNPATH_SEARCH_PATHS": '("$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks", )',
            "MARKETING_VERSION": "1.0",
            "PRODUCT_BUNDLE_IDENTIFIER": "ai.desklink.prayerguide.widgets",
            "PRODUCT_NAME": "MyFiveWidgets",
            "SKIP_INSTALL": "YES",
            "SUPPORTED_PLATFORMS": '"iphoneos iphonesimulator"',
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "SWIFT_VERSION": "5.0",
            "TARGETED_DEVICE_FAMILY": "1",
        }
    )


if __name__ == "__main__":
    main()
