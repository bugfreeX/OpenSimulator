//
//  AppDelegate.m
//  OpenSandbox
//
//  Created by Nelson on 2017/11/13.
//  Copyright © 2017年 Nelson. All rights reserved.
//

#import "AppDelegate.h"
#import "Settings.h"
//#import "ideviceinfoCommand.h"
static NSString * APP_KEY = @"app";
static NSString * IDENTIFIER_KEY = @"identifier";
static NSString * NAME_KEY = @"name";
static NSString * SANDBOX_KEY = @"sandBox";
@interface AppDelegate (){
    NSStatusItem * statusItem;
    NSDictionary * windowDictionary;
}

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSImage * icon = [NSImage imageNamed:@"simulators"];
    [icon setSize:CGSizeMake(20, 20)];
    [statusItem.button setImage:[NSImage imageNamed:@"simulators"]];
    statusItem.action = @selector(touchStatusItem:);
    [statusItem setToolTip:@"Open current sandBox"];
    
}

-(void)touchStatusItem:(id)item{

    NSMenu * mainMenu = [[NSMenu alloc]init];
    NSArray* windows = (NSArray *)CFBridgingRelease(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    for(NSDictionary *window in windows){
        NSString* windowOwner = [window objectForKey:(NSString *)kCGWindowOwnerName];
        NSString* windowName = [window objectForKey:(NSString *)kCGWindowName];
        
        if ([windowOwner containsString:@"Simulator"] && ([windowName containsString:@"iOS"] || [windowName containsString:@"watchOS"] || [windowName containsString:@"tvOS"] || [windowName containsString:@"iPhone"] || [windowName containsString:@"iPad"] || [windowName containsString:@"iPod"])){
            NSString * deviceName = [[windowName componentsSeparatedByString:@" - "] firstObject];
            NSArray * applications = [self installedAppsOnSimulatorWithWindowName:windowName];
            NSMenuItem * item = [[NSMenuItem alloc]init];
            [item setTitle:deviceName];
            NSImage * icon = [[NSWorkspace sharedWorkspace] iconForFile:@"/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"];
            [icon setSize:CGSizeMake(25, 25)];
            [item setImage:icon];
            
            NSMenu * menu = [[NSMenu alloc]init];
            [item setSubmenu:menu];
            for (NSDictionary * dictionary in applications) {
                NSMenuItem * subItem = [[NSMenuItem alloc]init];
                [subItem setTitle:dictionary[NAME_KEY]];
                [subItem setToolTip:dictionary[SANDBOX_KEY]];
//                NSImage * subIcon = [[NSWorkspace sharedWorkspace] iconForFile:dictionary[APP_KEY]];
                NSImage * subIcon = [[NSImage alloc]initWithContentsOfFile:[dictionary[APP_KEY] stringByAppendingPathComponent:@"AppIcon40x40@2x.png"]];
//                if (!subIcon) {
//                    NSLog(@"---%@",dictionary[NAME_KEY]);
//                }
                [subIcon setSize:CGSizeMake(30, 30)];
                [subItem setImage:subIcon];
                subItem.action = @selector(openSandBox:);
                [menu addItem:subItem];
            }
            [mainMenu addItem:item];
        }
    }
    [mainMenu addItem:[NSMenuItem separatorItem]];
    
    //Start at Login
    NSMenuItem* startAtLogin =
    [[NSMenuItem alloc] initWithTitle:@"Start at Login" action:@selector(handleStartAtLogin:) keyEquivalent:@""];
    
    BOOL isStartAtLoginEnabled = [Settings isStartAtLoginEnabled];
    if (isStartAtLoginEnabled){
        [startAtLogin setState:NSOnState];
    }else{
        [startAtLogin setState:NSOffState];
    }
    [startAtLogin setRepresentedObject:@(isStartAtLoginEnabled)];
    [mainMenu addItem:startAtLogin];
    
    //Quit
    NSMenuItem* quit = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(exitApp:) keyEquivalent:@"Q"];
    [mainMenu addItem:quit];
    
    [statusItem popUpStatusItemMenu:mainMenu];

}

- (void) exitApp:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}

- (void) handleStartAtLogin:(id)sender{
    BOOL isEnabled = [[sender representedObject] boolValue];
    
    [Settings setStartAtLoginEnabled:!isEnabled];
    
    [sender setRepresentedObject:@(!isEnabled)];
    
    if (isEnabled){
        [sender setState:NSOffState];
    }else{
        [sender setState:NSOnState];
    }
}

-(void)openSandBox:(NSMenuItem *)item{
    NSLog(@"%@",item.toolTip);
    [[NSWorkspace sharedWorkspace] openFile:item.toolTip];
}

-(NSArray *)installedAppsOnSimulatorWithWindowName:(NSString *)windowName{
    NSString * filePath = [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/device_set.plist",NSHomeDirectory()];
    NSDictionary * deviceDictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
    NSDictionary * DefaultDevices = deviceDictionary[@"DefaultDevices"];
    NSString * system;
    if ([windowName containsString:@"iPhone"] || [windowName containsString:@"iPod"] || [windowName containsString:@"iPad"]) {
        system = @"iOS";
    }
    NSString * platform = [[NSString stringWithFormat:@"%@.%@",system,[windowName componentsSeparatedByString:@" "].lastObject] stringByReplacingOccurrencesOfString:@"." withString:@"-"];
    NSString * versionKey = [NSString stringWithFormat:@"com.apple.CoreSimulator.SimRuntime.%@",platform];
    NSDictionary * simDictionary = DefaultDevices[versionKey];
    if (simDictionary == nil) {
        NSLog(@"Can't find %@", versionKey);
        // 修正一下最小的子版本号有时候不在配置中的情况
        NSArray *platformParts = [platform componentsSeparatedByString:@"-"];
        NSMutableString *platform2 = [[NSMutableString alloc] initWithCapacity:platform.length];
        if (platformParts.count > 0) {
            for (NSUInteger i=0; i<platformParts.count-1; i++) {
                [platform2 appendString:platformParts[i]];
                if (i != platformParts.count-2) {
                    [platform2 appendString:@"-"];
                }
            }
            platform = platform2;
        }
        versionKey = [NSString stringWithFormat:@"com.apple.CoreSimulator.SimRuntime.%@",platform];
        simDictionary = DefaultDevices[versionKey];
    }
    //?
    NSString *deviceName;
    if ([windowName containsString:@" — "]) {
        deviceName = [[[windowName componentsSeparatedByString:@" — "] firstObject] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    }else{
        deviceName = [[[windowName componentsSeparatedByString:@" - "] firstObject] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
    }
    deviceName = [deviceName stringByReplacingOccurrencesOfString:@"Xs" withString:@"XS"];
    deviceName = [deviceName stringByReplacingOccurrencesOfString:@"Xʀ" withString:@"XR"];
    
    NSString * deviceTypeKey = [NSString stringWithFormat:@"com.apple.CoreSimulator.SimDeviceType.%@",deviceName];
    NSString * deviceUDID = simDictionary[deviceTypeKey];
    NSString * devicePath = [[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:deviceUDID];
    
    NSString * sandPath = [NSString stringWithFormat:@"%@/data/Containers/Data/Application",devicePath];
    
    NSArray * udids = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:sandPath error:nil];
    NSMutableDictionary * sandBoxDictionary = [NSMutableDictionary dictionary];
    for (NSString * udid in udids) {
        if (![udid isEqualToString:@".DS_Store"]) {
            NSString * metadataPlistPath = [[sandPath stringByAppendingPathComponent:udid] stringByAppendingPathComponent:@".com.apple.mobile_container_manager.metadata.plist"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:metadataPlistPath]) {
                NSDictionary * metadataDictionary = [NSDictionary dictionaryWithContentsOfFile:metadataPlistPath];
                NSString * identifier = metadataDictionary[@"MCMMetadataIdentifier"];
                if (![identifier hasPrefix:@"com.apple"]) {
                    [sandBoxDictionary setValue:[sandPath stringByAppendingPathComponent:udid] forKey:identifier];
                }
            }
        }
    }
    
    NSString * applicationPath = [NSString stringWithFormat:@"%@/data/Containers/Bundle/Application",devicePath];
    NSArray * files = [[NSFileManager defaultManager] subpathsAtPath:applicationPath];
    NSMutableArray * applications = [NSMutableArray array];
    for (NSString * file in files) {
        if ([file hasSuffix:@".app"]) {
            NSDictionary * infoDictionary = [NSDictionary dictionaryWithContentsOfFile:[[applicationPath stringByAppendingPathComponent:file] stringByAppendingPathComponent:@"Info.plist"]];
            NSString * identifier = infoDictionary[@"CFBundleIdentifier"];
            NSString * displayName = infoDictionary[@"CFBundleDisplayName"];
            if (displayName.length == 0) {
                displayName = infoDictionary[@"CFBundleName"];
            }
            NSMutableDictionary * applicationDictionary = [NSMutableDictionary dictionary];
            [applicationDictionary setValue:identifier forKey:IDENTIFIER_KEY];
            [applicationDictionary setValue:displayName forKey:NAME_KEY];
            [applicationDictionary setValue:sandBoxDictionary[identifier] forKey:SANDBOX_KEY];
            [applicationDictionary setValue:[applicationPath stringByAppendingPathComponent:file] forKey:APP_KEY];
            [applications addObject:applicationDictionary];
        }
    }
    return applications;
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
