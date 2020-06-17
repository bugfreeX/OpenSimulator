//
//  Model.h
//  OpenSimulator
//
//  Created by SIHAO on 2020/6/12.
//  Copyright © 2020 XIEZHONGXI. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Model : NSObject
@end

@interface Application : NSObject
@property(nonatomic,copy) NSString *identifier;
@property(nonatomic,copy) NSString *name;
@property(nonatomic,copy) NSString *image;
@property(nonatomic,copy) NSString *sandBoxPath;
@end

@interface SimDeviceType : NSObject
@property(nonatomic,copy) NSString *device;
@property(nonatomic,copy) NSString *UUID;
@property(nonatomic,strong) NSArray <Application *>*applications;
@end



NS_ASSUME_NONNULL_END
