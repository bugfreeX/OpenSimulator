//
//  AsyncTask.m
//  AsyncTask
//
//  Created by Zhongxi on 2017/1/10.
//  Copyright © 2017年 zhongxi. All rights reserved.
//

#import "AsyncTask.h"
#define errNo (*__error())
static NSTask * task;
@implementation AsyncTask
+(void)launchPath:(NSString *)launchPath currentDirectoryPath:(NSString *)currentDirectoryPath arguments:(NSArray *)arguments outputBlock:(void(^)(NSString * outString))outString errBlock:(void(^)(NSString *errString))errString onLaunch:(void(^)())launch onExit:(void(^)())exit{
    [task terminate];
    task = [[NSTask alloc]init];
    /* Set launch path. */
    [task setLaunchPath:[launchPath stringByStandardizingPath]];
    
    __block BOOL hasExecuted = NO;
    
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:[task launchPath]]) {
        @throw [NSException exceptionWithName:@"ASYNCTASK_INVALID_EXECUTABLE" reason:@"There is no executable at the path set." userInfo:nil];
        return;
    }
    
    /* Clean then set arguments. */
    for (id arg in arguments) {
        if ([arg class] != [NSString class]) {
            NSMutableArray * formatArgs = [NSMutableArray array];
            for (id arg in arguments) {
                [formatArgs addObject:[NSString stringWithFormat:@"%@",arg]];
            }
            arguments = formatArgs;
        }
    }
    [task setArguments:arguments];
    
    /* Setup pipes */
    NSPipe * inPipe = [NSPipe pipe];
    NSPipe * outPipe = [NSPipe pipe];
    NSPipe * errPipe = [NSPipe pipe];
    [task setStandardInput:inPipe];
    [task setStandardOutput:outPipe];
    [task setStandardError:errPipe];
    
    /* Set current directory, just pass on our actual CWD. */
    if (currentDirectoryPath) {
        [task setCurrentDirectoryPath:currentDirectoryPath];
    }else{
        [task setCurrentDirectoryPath:[[NSFileManager defaultManager] currentDirectoryPath]];
    }
    
    /* Ensure the pipes are non-blocking so GCD can read them correctly. */
    fcntl([outPipe fileHandleForReading].fileDescriptor, F_SETFL,O_NONBLOCK);
    fcntl([errPipe fileHandleForReading].fileDescriptor, F_SETFL,O_NONBLOCK);
    
    /* Setup a dispatch source for both descriptors. */
    dispatch_source_t outSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, [outPipe fileHandleForReading].fileDescriptor, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_t errSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, [errPipe fileHandleForReading].fileDescriptor, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    
    /* Set stdout source event handler to read data and send it out. */
    dispatch_source_set_event_handler(outSource, ^{
        void * buffer = malloc(4096);
        ssize_t bytesRead;
        do {
            errNo = 0;
            bytesRead = read([outPipe fileHandleForReading].fileDescriptor, buffer, 4096);
        } while (bytesRead == -1 && errNo == EINTR);
        
        if (bytesRead > 0) {
            /* Create before dispatch to prevent a race condition. */
            NSData * outData = [NSData dataWithBytes:buffer length:bytesRead];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!hasExecuted) {
                    if (launch) {
                        launch();
                    }
                    hasExecuted = YES;
                }
                if (outString) {
                    outString([[NSString alloc]initWithData:outData encoding:NSUTF8StringEncoding]);
                }
            });
        }
        if (errNo != 0 && bytesRead <= 0) {
            dispatch_source_cancel(outSource);
            if (exit) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    exit();
                });
            }
        }
        free(buffer);
    });
    
    /* Same thing for stderr. */
    dispatch_source_set_event_handler(errSource, ^{
        void * buffer = malloc(4096);
        ssize_t bytesRead;
        do {
            errNo = 0;
            bytesRead = read([errPipe fileHandleForReading].fileDescriptor, buffer, 4096);
        } while (bytesRead == -1 && errNo == EINTR);
        
        if (bytesRead > 0) {
            if (errString) {
                NSData * errData = [NSData dataWithBytes:buffer length:bytesRead];
                dispatch_async(dispatch_get_main_queue(), ^{
                    errString([[NSString alloc]initWithData:errData encoding:NSUTF8StringEncoding]);
                });
            }
        }
        if (errNo != 0 && bytesRead <= 0) {
            dispatch_source_cancel(errSource);
        }
        free(buffer);
    });
    
    dispatch_resume(outSource);
    dispatch_resume(errSource);
    task.terminationHandler = ^(NSTask * stask){
        dispatch_source_cancel(outSource);
        dispatch_source_cancel(errSource);
        if (exit) {
            dispatch_async(dispatch_get_main_queue(), ^{
                exit();
            });
        }
    };
    
    [task launch];
}


+(void)terminate{
    [task terminate];
}


@end
