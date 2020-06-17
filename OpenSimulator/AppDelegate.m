//
//  AppDelegate.m
//  OpenSandbox
//
//  Created by XIEZHONGXI on 2017/11/13.
//  Copyright © 2017年 XIEZHONGXI. All rights reserved.
//

#import "AppDelegate.h"
#import "Model.h"
@interface AppDelegate (){
    NSStatusItem * statusItem;
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
    [statusItem setToolTip:@"OpenSimulator"];
    
}

-(void)touchStatusItem:(id)sender{
    
    NSString * deviceSetPlistPath = [NSString stringWithFormat:@"%@/Library/Developer/CoreSimulator/Devices/device_set.plist",NSHomeDirectory()];
    NSDictionary * deviceSetDictionary = [NSDictionary dictionaryWithContentsOfFile:deviceSetPlistPath];
    NSDictionary *defaultDevices = [deviceSetDictionary objectForKey:@"DefaultDevices"];
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    for (NSString *device in defaultDevices.allKeys) {
        if ([device hasPrefix:@"com.apple"]) {
            NSString *version = [device componentsSeparatedByString:@"com.apple.CoreSimulator.SimRuntime."].lastObject;
            NSArray *set = [version componentsSeparatedByString:@"-"];
            NSString *setVersion = [NSString stringWithFormat:@"%@ %@.%@",set[0],set[1],set[2]];
            NSDictionary *simRuntime = defaultDevices[device];
            NSMutableArray *devices = [NSMutableArray array];
            for (NSString *deviceType in simRuntime.allKeys) {
                NSString *UUID = simRuntime[deviceType];
                NSString *simulatorPath = [deviceSetPlistPath.stringByDeletingLastPathComponent stringByAppendingPathComponent:UUID];
                NSString *containersPath = [[simulatorPath stringByAppendingPathComponent:@"data"] stringByAppendingPathComponent:@"Containers"];
                if ([[NSFileManager defaultManager] fileExistsAtPath:containersPath]) {
                    SimDeviceType *model = [[SimDeviceType alloc]init];
                    model.UUID = UUID;
                    model.device = [NSDictionary dictionaryWithContentsOfFile:[simulatorPath stringByAppendingPathComponent:@"device.plist"]][@"name"];
                    NSMutableArray *applications = [NSMutableArray array];
                    NSString *bundleApplicationPath = [[containersPath stringByAppendingPathComponent:@"Bundle"] stringByAppendingPathComponent:@"Application"];
                    NSArray *bundleApplications = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundleApplicationPath error:nil];
                    for (NSString *bundleApplicationUUID in bundleApplications) {
                        Application *application = [[Application alloc]init];
                        NSString *bundleApplicationUUIDPath = [bundleApplicationPath stringByAppendingPathComponent:bundleApplicationUUID];
                        NSArray *bundleApplicationUUIDFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundleApplicationUUIDPath error:nil];
                        for (NSString *bundleApplicationUUIDFile in bundleApplicationUUIDFiles) {
                            if ([bundleApplicationUUIDFile hasSuffix:@".app"]) {
                                NSString *appPath = [bundleApplicationUUIDPath stringByAppendingPathComponent:bundleApplicationUUIDFile];
                                NSDictionary *infoDictionary = [NSDictionary dictionaryWithContentsOfFile:[appPath stringByAppendingPathComponent:@"Info.plist"]];
                                NSString *identifier = infoDictionary[@"CFBundleIdentifier"];
                                NSString *displayName = infoDictionary[@"CFBundleDisplayName"];
                                if (displayName.length == 0) {
                                    displayName = infoDictionary[@"CFBundleName"];
                                }
                                application.identifier = identifier;
                                application.name = displayName;
                                application.image = [appPath stringByAppendingPathComponent:@"AppIcon40x40@2x.png"];
                                NSString *dataApplicationPath = [[containersPath stringByAppendingPathComponent:@"Data"] stringByAppendingPathComponent:@"Application"];
                                NSArray *dataApplications = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dataApplicationPath error:nil];
                                for (NSString *dataApplicationUUID in dataApplications) {
                                    NSString *dataApplicationUUIDPath = [dataApplicationPath stringByAppendingPathComponent:dataApplicationUUID];
                                    NSString *dataApplicationUUIDIdentifier = [NSDictionary dictionaryWithContentsOfFile:[dataApplicationUUIDPath stringByAppendingPathComponent:@".com.apple.mobile_container_manager.metadata.plist"]][@"MCMMetadataIdentifier"];
                                    if ([dataApplicationUUIDIdentifier isEqualToString:identifier]) {
                                        application.sandBoxPath = dataApplicationUUIDPath;
                                        break;
                                    }
                                }
                            }
                        }
                        if (application.name.length > 0) {
                            [applications addObject:application];
                        }
                    }
                    model.applications = applications;
                    if (model.applications > 0) {
                        [devices addObject:model];
                    }
                }
            }
            [dataDictionary setObject:devices forKey:setVersion];
        }
    }
    
    NSMenu * mainMenu = [[NSMenu alloc]init];
    for (NSString *version in dataDictionary.allKeys) {
        NSMenuItem * item = [[NSMenuItem alloc]init];
        [item setTitle:version];
        
        NSArray <SimDeviceType *>*devices = dataDictionary[version];
        if (devices.count > 0) {
            NSMenu * deviceMenu = [[NSMenu alloc]init];
            [item setSubmenu:deviceMenu];
            for (SimDeviceType *deviceType in devices) {
                NSMenuItem * deviceItem = [[NSMenuItem alloc]init];
                [deviceItem setTitle:deviceType.device];
                NSImage * icon = [[NSWorkspace sharedWorkspace] iconForFile:@"/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"];
                [icon setSize:CGSizeMake(25, 25)];
                [deviceItem setImage:icon];
                [deviceMenu addItem:deviceItem];
                
                if (deviceType.applications > 0) {
                    NSMenu * applicationMenu = [[NSMenu alloc]init];
                    [deviceItem setSubmenu:applicationMenu];
                    for (Application *application in deviceType.applications) {
                        NSMenuItem * applicationItem = [[NSMenuItem alloc]init];
                        [applicationItem setTitle:application.name];
                        [applicationItem setToolTip:application.sandBoxPath];
                        applicationItem.action = @selector(openSandBox:);
                        NSImage * applicationIcon = [[NSImage alloc]initWithContentsOfFile:application.image];
                        if (!applicationIcon) {
                            applicationIcon = [[NSWorkspace sharedWorkspace] iconForFile:application.image.stringByDeletingLastPathComponent];
                        }
                        [applicationIcon setSize:CGSizeMake(25, 25)];
                        [applicationItem setImage:applicationIcon];
                        [applicationMenu addItem:applicationItem];
                    }
                }else{
                    
                }
            }
        }
        [mainMenu addItem:item];
    }
    NSMenuItem* quit = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(exitApp:) keyEquivalent:@"Q"];
    [mainMenu addItem:quit];
    
    [statusItem popUpStatusItemMenu:mainMenu];
    
}

- (void) exitApp:(id)sender
{
    [[NSApplication sharedApplication] terminate:self];
}


-(void)openSandBox:(NSMenuItem *)item{
    NSLog(@"%@",item.toolTip);
    [[NSWorkspace sharedWorkspace] openFile:item.toolTip];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
