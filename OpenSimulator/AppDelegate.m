//
//  AppDelegate.m
//  OpenSandbox
//
//  Created by Nelson on 2017/11/13.
//  Copyright © 2017年 Nelson. All rights reserved.
//

#import "AppDelegate.h"
#import "Settings.h"
#import "ideviceinfoCommand.h"
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
        
        if ([windowOwner containsString:@"Simulator"] && ([windowName containsString:@"iOS"] || [windowName containsString:@"watchOS"] || [windowName containsString:@"tvOS"])){
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
                NSImage * subIcon = [[NSWorkspace sharedWorkspace] iconForFile:dictionary[APP_KEY]];
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
    
    [ideviceinfoCommand performCompletionHandler:^(NSDictionary *deviceinfo) {
        NSLog(@"%@",deviceinfo);
        if (deviceinfo) {
            NSString * deviceName = deviceinfo[@"DeviceName"];
            NSMenuItem * deviceItem = [[NSMenuItem alloc]init];
            [deviceItem setTitle:deviceName];
            NSMenu * deviceSubMenu = [[NSMenu alloc]init];
            [deviceSubMenu addItemWithTitle:@"Open Web Server" action:@selector(openWebServer:) keyEquivalent:@""];
            [deviceSubMenu addItemWithTitle:@"Usage" action:@selector(usageAction) keyEquivalent:@""];
            [deviceItem setSubmenu:deviceSubMenu];
            [mainMenu insertItem:deviceItem atIndex:mainMenu.numberOfItems - 3];
            [statusItem popUpStatusItemMenu:mainMenu];
        }else{
            [statusItem popUpStatusItemMenu:mainMenu];
        }
    }];
}

-(void)openWebServer:(NSMenuItem *)item{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.local:9090",item.parentItem.title]]];
}

-(void)usageAction{
    NSLog(@"%s",__func__);
    [[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"WebServer"]];
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
    NSString * version = [[windowName componentsSeparatedByString:@"iOS "] lastObject];
    NSString * platform = [[[[windowName componentsSeparatedByString:@"- "] lastObject] componentsSeparatedByString:@" "] firstObject];
    NSString * versionKey = [NSString stringWithFormat:@"com.apple.CoreSimulator.SimRuntime.%@",platform];
    for (NSString * string in [version componentsSeparatedByString:@"."]) {
        versionKey = [versionKey stringByAppendingFormat:@"-%@",string];
    }
    NSDictionary * simDictionary = DefaultDevices[versionKey];
    NSString * deviceName = [[[windowName componentsSeparatedByString:@" - "] firstObject] stringByReplacingOccurrencesOfString:@" " withString:@"-"];
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
