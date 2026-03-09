//
//  p12_password_check.hpp
//  feather
//
//  Created by HAHALOSAH on 8/6/24.
//

#import <Foundation/Foundation.h>

// Return codes for p12_change_password_data
#define P12_CHANGE_SUCCESS       0
#define P12_CHANGE_DECODE_ERROR  1   // Failed to parse PKCS#12 (corrupted or not a valid file)
#define P12_CHANGE_AUTH_ERROR    2   // Wrong password
#define P12_CHANGE_EXPORT_ERROR  3   // Failed to re-encrypt with new password

#ifdef __cplusplus
extern "C" {
#endif
bool p12_password_check(NSString *file, NSString *pass);
void password_check_fix_WHAT_THE_FUCK(NSString *path);
void password_check_fix_WHAT_THE_FUCK_free(NSString *path);

/// Changes the password of a PKCS#12 blob entirely in memory using OpenSSL.
/// Returns a P12_CHANGE_* status code. On success, *outputData contains the re-encrypted PKCS#12 data.
int p12_change_password_data(NSData *p12Data, NSString *oldPassword, NSString *newPassword, NSData * _Nullable * _Nonnull outputData);
#ifdef __cplusplus
}
#endif
