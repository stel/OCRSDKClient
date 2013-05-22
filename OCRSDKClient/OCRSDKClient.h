// OCRSDKClient.h
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

#import "AFHTTPClient.h"

/**
 `OCRSDKClient` is an `AFHTTPClient` subclass for interacting with the ABBYY Cloud OCR SDK webservice API (http://ocrsdk.com).
 
 See ABBYY Cloud OCR SDK API Reference on http://ocrsdk.com/documentation/apireference.
 */
@interface OCRSDKClient : AFHTTPClient

/// @name Accessing HTTP Client Properties

/**
 Your ABBYY Cloud OCR SDK application ID.
 */
@property (nonatomic, readonly) NSString *applicationId;

/**
 Your ABBYY Cloud OCR SDK application password.
 */
@property (nonatomic, readonly) NSString *password;

/**
 Your ABBYY Cloud OCR SDK application installation ID for current device.
 
 @discussion By default `installationId` is nil, you must call `activateInstallation:success:failure:` to setup its value.
 */
@property (nonatomic, readonly) NSString *installationId;

/// @name Creating and Initializing ABBYY Cloud OCR SDK Client

/**
 Creates and initializes an `OCRSDKClient` object with specified credentials.
 
 @param applicationId Your application ID.
 @param password Your application password.
 
 @return The newly-initialized ABBYY Cloud OCR SDK client.
 */
+ (instancetype)clientWithApplicationId:(NSString *)applicationId password:(NSString *)password;

/**
 Initializes and returns a newly allocated `OCRSDKClient` object with specified credentials.
 
 @param applicationId Your application ID.
 @param password Your application password.
 
 @return The newly-initialized ABBYY Cloud OCR SDK client.
 */
- (id)initWithApplicationId:(NSString *)applicationId password:(NSString *)password;

/// @name Activation Application Installation

/**
 Activates your application installation on current device.
 
 @param deviceId An unique identifier of the current device.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and no arguments.
 @param failure A block object to be executed when the request operation finishes unsuccessfully. This block has no return value and takes a single argument: the `NSError` object describing error that occurred.
 
 @param force If YES or installation hasn't already been activated on current device asks server for installation ID, otherwise takes installation ID from user defaults.
 
 @discussion You should call this method before performing any image processing operations.
 */
- (void)activateInstallationWithDeviceId:(NSString *)deviceId
								 success:(void (^)(void))success
								 failure:(void (^)(NSError *error))failure
								   force:(BOOL)force;

/// @name Performing Image Processing Operations

/**
 Uploads image data to server and starts image processing.
 
 @param imageData An `NSData` object with image data.
 @param processingParams Image processing params.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the `NSDictionary` object with new image processing task task info.

 @param failure A block object to be executed when the request operation finishes unsuccessfully. This block has no return value and takes a single argument: the `NSError` object describing error that occurred.
 */
- (void)startTaskWithImageData:(NSData *)imageData
					withParams:(NSDictionary *)processingParams
					   success:(void (^)(NSDictionary *taskInfo))success
					   failure:(void (^)(NSError *error))failure;

/**
 Retrives the image processing task info.
 
 @param taskId The ID of image processing task.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the `NSDictionary` object with image processing task task info.
 
 @param failure A block object to be executed when the request operation finishes unsuccessfully. This block has no return value and takes a single argument: the `NSError` object describing error that occurred.
 */
- (void)getTaskInfo:(NSString *)taskId
			success:(void (^)(NSDictionary *taskInfo))success
			failure:(void (^)(NSError *error))failure;

/**
 Downloads the recognized data.
 
 @param url URL to download.
 @param success A block object to be executed when the request operation finishes successfully. This block has no return value and takes a single argument: the `NSData` object with recognized string data.
 
 @param failure A block object to be executed when the request operation finishes unsuccessfully. This block has no return value and takes a single argument: the `NSError` object describing error that occurred.
 */
- (void)downloadRecognizedData:(NSURL *)url
					   success:(void (^)(NSData *downloadedData))success
					   failure:(void (^)(NSError *error))failure;

@end

/// @name Constants

/**
 ### Processing task info dictionary keys

 The following constants describes the keys in processing task info dictionary
 */
extern NSString * const OCRSDKTaskId;
extern NSString * const OCRSDKTaskStatus;
extern NSString * const OCRSDKTaskFilesCount;
extern NSString * const OCRSDKTaskCredits;
extern NSString * const OCRSDKTaskRegistrationTime;
extern NSString * const OCRSDKTaskStatusChangeTime;
extern NSString * const OCRSDKTaskEstimatedProcessingTime;
extern NSString * const OCRSDKTaskResultURL;

/**
 ### Processing task status
 */
extern NSString * const OCRSDKTaskStatusSubmitted;
extern NSString * const OCRSDKTaskStatusQueued;
extern NSString * const OCRSDKTaskStatusInProgress;
extern NSString * const OCRSDKTaskStatusCompleted;
extern NSString * const OCRSDKTaskStatusProcessingFailed;
extern NSString * const OCRSDKTaskStatusDeleted;
extern NSString * const OCRSDKTaskStatusNotEnoughCredits;
