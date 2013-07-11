// OCRSDKClient.m
//
// Copyright (c) 2013 Dmitry Obukhov (stel2k@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "OCRSDKClient.h"
#import "AFHTTPRequestOperation.h"
#import "XMLDictionary.h"

NSString * const OCRSDKTaskId = @"_id";
NSString * const OCRSDKTaskStatus = @"_status";
NSString * const OCRSDKTaskFilesCount = @"_filesCount";
NSString * const OCRSDKTaskCredits = @"_credits";
NSString * const OCRSDKTaskRegistrationTime = @"_registrationTime";
NSString * const OCRSDKTaskStatusChangeTime = @"_statusChangeTime";
NSString * const OCRSDKTaskEstimatedProcessingTime = @"_estimatedProcessingTime";
NSString * const OCRSDKTaskResultURL = @"_resultUrl";

NSString * const OCRSDKTaskStatusSubmitted = @"Submitted";
NSString * const OCRSDKTaskStatusQueued = @"Queued";
NSString * const OCRSDKTaskStatusInProgress = @"InProgress";
NSString * const OCRSDKTaskStatusCompleted = @"Completed";
NSString * const OCRSDKTaskStatusProcessingFailed = @"ProcessingFailed";
NSString * const OCRSDKTaskStatusDeleted = @"Deleted";
NSString * const OCRSDKTaskStatusNotEnoughCredits = @"NotEnoughCredits";

static NSString * const kOCRSDKBaseURLString = @"http://cloud.ocrsdk.com";
static NSString * const kOCRSDKInstallationId = @"com.abbyy.ocrsdk.installation-id";
static NSString * const kOCRSDKInstallationActivated = @"com.abbyy.ocrsdk.installation-activated";

@implementation OCRSDKClient

+ (instancetype)clientWithApplicationId:(NSString *)applicationId password:(NSString *)password
{
	return [[OCRSDKClient alloc] initWithApplicationId:applicationId password:password];
}

- (id)initWithApplicationId:(NSString *)applicationId password:(NSString *)password
{
	self = [self initWithBaseURL:[NSURL URLWithString:kOCRSDKBaseURLString]];
	
	if (self != nil) {
		_applicationId = applicationId;
		_password = password;
		
		[self updateAuthorizationHeader];
	}
	
	return self;
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
	
    if (self != nil) {
        [self registerHTTPOperationClass:[AFHTTPRequestOperation class]];
		[self setDefaultHeader:@"Accept" value:@"application/xml"];
    }
    
    return self;
}

#pragma mark -

- (void)activateInstallationWithDeviceId:(NSString *)deviceId
								 success:(void (^)(void))success
								 failure:(void (^)(NSError *error))failure
								   force:(BOOL)force
{
	NSParameterAssert(deviceId);
	
	BOOL installationActivated = [[NSUserDefaults standardUserDefaults] boolForKey:kOCRSDKInstallationActivated];
	
	if(!installationActivated || force) {
		[self setAuthorizationHeaderWithUsername:self.applicationId password:self.password];
		
		[self getPath:@"activateNewInstallation" parameters:@{@"deviceId": deviceId} success:^(AFHTTPRequestOperation *operation, id responseObject) {
			NSDictionary *responseDictionary = [NSDictionary dictionaryWithXMLData:responseObject];
			
			NSString *installationId = [responseDictionary valueForKey:@"authToken"];
			
			[[NSUserDefaults standardUserDefaults] setObject:installationId forKey:kOCRSDKInstallationId];
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kOCRSDKInstallationActivated];
			
			[self activateInstallationWithDeviceId:deviceId success:success failure:failure force:NO];
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			if (failure != nil) {
				failure(error);
			}
		}];
	} else {
		[self updateAuthorizationHeader];
		
		if (success != nil) {
			success();
		}
	}
}

- (void)startTaskWithImageData:(NSData *)imageData
					withParams:(NSDictionary *)processingParams
				 progressBlock:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progressBlock
					   success:(void (^)(NSDictionary *taskInfo))success
					   failure:(void (^)(NSError *error))failure
{
	NSParameterAssert(imageData);
	
	// Create a GET request to make AFHTTPClient set params to url
	NSMutableURLRequest *request = [self requestWithMethod:@"GET" path:@"processImage" parameters:processingParams];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"applicaton/octet-stream" forHTTPHeaderField:@"Content-Type"];
	[request setHTTPBody:imageData];
	
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		if (success != nil) {
			NSDictionary *responseDictionary = [NSDictionary dictionaryWithXMLData:responseObject];
			NSDictionary *taskInfo = [responseDictionary objectForKey:@"task"];
			
			success(taskInfo);
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (failure != nil) {
			failure(error);
		}
	}];
	   
	[operation setUploadProgressBlock:progressBlock];
	[self enqueueHTTPRequestOperation:operation];
}

- (void)getTaskInfo:(NSString *)taskId
			success:(void (^)(NSDictionary *taskInfo))success
			failure:(void (^)(NSError *error))failure
{
	NSParameterAssert(taskId);
	
	[self getPath:@"getTaskStatus" parameters:@{@"taskId": taskId} success:^(AFHTTPRequestOperation *operation, id responseObject) {
		if (success != nil) {
			NSDictionary *responseDictionary = [NSDictionary dictionaryWithXMLData:responseObject];
			NSDictionary *taskInfo = [responseDictionary objectForKey:@"task"];
			
			success(taskInfo);
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (failure != nil) {
			failure(error);
		}
	}];
}

- (void)downloadRecognizedData:(NSURL *)url
					   success:(void (^)(NSData *downloadedData))success
					   failure:(void (^)(NSError *error))failure
{
	NSParameterAssert(url);
	
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
		if (success != nil) {
			success(responseObject);
		}
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (failure != nil) {
			failure(error);
		}
	}];
	
	[self enqueueHTTPRequestOperation:operation];
}

#pragma mark -

- (void)setApplicationId:(NSString *)applicationId
{
	if (applicationId != self.applicationId) {
		_applicationId = applicationId;
		[self updateAuthorizationHeader];
	}
}

- (void)setPassword:(NSString *)password
{
	if (password != self.password) {
		_password = password;
		[self updateAuthorizationHeader];
	}
}

- (NSString *)installationId
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:kOCRSDKInstallationId];
}

- (void)updateAuthorizationHeader
{
	[self setAuthorizationHeaderWithUsername:self.installationId != nil ? [self.applicationId stringByAppendingString:self.installationId] : self.applicationId
									password:self.password];
}

@end
