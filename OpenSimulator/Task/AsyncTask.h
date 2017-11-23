//
//  AsyncTask.h
//  AsyncTask
//
//  Created by Zhongxi on 2017/1/10.
//  Copyright © 2017年 zhongxi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AsyncTask : NSObject

+(void)launchPath:(NSString *)launchPath currentDirectoryPath:(NSString *)currentDirectoryPath arguments:(NSArray *)arguments outputBlock:(void(^)(NSString * outString))outString errBlock:(void(^)(NSString *errString))errString onLaunch:(void(^)())launch onExit:(void(^)())exit;
+(void)terminate;
@end
