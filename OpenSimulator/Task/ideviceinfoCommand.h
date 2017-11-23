//
//  ideviceinfoCommand.h
//  OpenSimulator
//
//  Created by Nelson on 2017/11/21.
//  Copyright © 2017年 Nelson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ideviceinfoCommand : NSObject
+(void)performCompletionHandler:(void(^)(NSDictionary * deviceinfo))handler;
@end
