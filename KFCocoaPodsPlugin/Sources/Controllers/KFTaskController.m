//
//  KFTaskController.m
//  KFCocoaPodsPlugin
//
//  Created by rick on 05.09.13.
//  Copyright (c) 2013 KF Interactive. All rights reserved.
//

#import "KFTaskController.h"

@implementation KFTaskController


- (void)runShellCommand:(NSString *)command withArguments:(NSArray *)arguments directory:(NSString *)directory progress:(KFTaskControllerProgressBlock)progressBlock completion:(KFTaskControllerCompletionBlock)completionBlock
{
    NSTask *task = [NSTask new];
    
    task.currentDirectoryPath = directory;
    task.launchPath = command;
    task.arguments  = arguments;
    task.standardOutput = [NSPipe pipe];
    task.standardError  = [NSPipe pipe];
    
    __block NSMutableData *outputData = [NSMutableData new];
    __block NSMutableData *errorData = [NSMutableData new];
    

    [[task.standardOutput fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file)
    {
        NSData *availableData = [file availableData];
        [outputData appendData:availableData];
        if (progressBlock != nil)
        {
            progressBlock(task, [[NSString alloc] initWithData:availableData encoding:NSUTF8StringEncoding], nil);
        }
    }];
    
    [[task.standardError fileHandleForReading] setReadabilityHandler:^(NSFileHandle *file)
    {
        NSData *availableData = [file availableData];
        [errorData appendData:availableData];
        if (progressBlock != nil)
        {
            progressBlock(task, nil, [[NSString alloc] initWithData:availableData encoding:NSUTF8StringEncoding]);
        }
    }];
    
    [task setTerminationHandler:^(NSTask *task)
    {
        [task.standardOutput fileHandleForReading].readabilityHandler = nil;
        [task.standardError fileHandleForReading].readabilityHandler  = nil;

    }];
    
    @try
    {
        [task launch];
        [task waitUntilExit];
    }
    @catch (NSException *exception)
    {
        completionBlock(task, NO, [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding], exception);
    }
    @finally
    {
        completionBlock(task, YES, [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding], nil);
    }
}


@end
