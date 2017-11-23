//
//  ideviceinfoCommand.m
//  OpenSimulator
//
//  Created by Nelson on 2017/11/21.
//  Copyright © 2017年 Nelson. All rights reserved.
//

#import "ideviceinfoCommand.h"
#import "AsyncTask.h"
@implementation ideviceinfoCommand
+(void)performCompletionHandler:(void(^)(NSDictionary * deviceinfo))handler{
    NSMutableString * deviceString = [NSMutableString string];
    [AsyncTask launchPath:[[NSBundle mainBundle] pathForResource:@"ideviceinfo" ofType:nil] currentDirectoryPath:nil arguments:@[@"-s"] outputBlock:^(NSString *outString) {
        [deviceString appendString:outString];
//        NSLog(@"output:%@",outString);
    } errBlock:^(NSString *errString) {
        NSLog(@"errString:%@",errString);
    } onLaunch:^{
//        NSLog(@"onLaunch");
    } onExit:^{
//        NSLog(@"ideviceinfo:%@",deviceString);
        if ([deviceString containsString:@"No device found"]) {
            handler(nil);
            return;
        }
        NSArray * devices = [deviceString componentsSeparatedByString:@"\n"];
        NSMutableDictionary * infoDictionary = [NSMutableDictionary dictionary];
        for (NSString * info in devices) {
            NSArray * objects = [info componentsSeparatedByString:@": "];
            NSString * key = objects.firstObject;
            NSString * value = objects.lastObject;
            if (key.length > 0 && value.length >0) {
                [infoDictionary setValue:value forKey:key];
            }
        }
        handler(infoDictionary);
        
        //        CFPropertyListRef list = CFPropertyListCreateFromXMLData(kCFAllocatorDefault, (__bridge CFDataRef)[deviceString dataUsingEncoding:NSUTF8StringEncoding], kCFPropertyListImmutable, NULL);
        //        NSDictionary * deviceInfo = (__bridge NSDictionary *)list;
        //        if (handler) {
        //            handler(deviceInfo);
        //        }
        //        CFRelease(list);
    }];
}
@end
