//
//  p12_password_check.cpp
//  feather
//
//  Created by HAHALOSAH on 8/6/24.
//

#include "openssl_tools.hpp"
#include "common.h"

#include <openssl/pem.h>
#include <openssl/cms.h>
#include <openssl/err.h>
#include <openssl/provider.h>
#include <openssl/pkcs12.h>
#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/x509.h>

#include <string>

using namespace std;

bool p12_password_check(NSString *file, NSString *pass) {
	const std::string strFile = [file cStringUsingEncoding:NSUTF8StringEncoding];
	const std::string strPass = [pass cStringUsingEncoding:NSUTF8StringEncoding];
	
	BIO *bio = BIO_new_file(strFile.c_str(), "rb");
	if (!bio) {
		NSLog(@"Failed to open .p12 file");
		return false;
	}
	
	OSSL_PROVIDER_load(NULL, "legacy");
	
	PKCS12 *p12 = d2i_PKCS12_bio(bio, NULL);
	BIO_free(bio);
	
	if (!p12) {
		NSLog(@"Failed to parse PKCS12");
		return false;
	}
	
	if( PKCS12_verify_mac(p12, NULL, 0) ) {
		return true;
	} else if( PKCS12_verify_mac(p12, strPass.c_str(), -1) ) {
		return true;
	} else {
		return false;
	}
	
	PKCS12_free(p12);
	return false;
}

// This is fucking bullshit IMO.
//
// In total, I probably wasted a total of 1.5 hours on this
// Feel free to increment the counter until someone finds a proper fix
//
// hours_wasted = 1.5
//
// TODO: FIX
void password_check_fix_WHAT_THE_FUCK(NSString *path) {
	string strProvisionFile = [path cStringUsingEncoding:NSUTF8StringEncoding];
	string strProvisionData;
	ZFile::ReadFile(strProvisionFile.c_str(), strProvisionData);
	
	BIO *in = BIO_new(BIO_s_mem());
	OPENSSL_assert((size_t)BIO_write(in, strProvisionData.data(), (int)strProvisionData.size()) == strProvisionData.size());
	d2i_CMS_bio(in, NULL);
}

int p12_change_password_data(NSData *p12Data, NSString *oldPassword, NSString *newPassword, NSData **outputData) {
	*outputData = nil;

	const char *oldPass = ([oldPassword length] > 0) ? [oldPassword cStringUsingEncoding:NSUTF8StringEncoding] : NULL;
	const char *newPass = ([newPassword length] > 0) ? [newPassword cStringUsingEncoding:NSUTF8StringEncoding] : NULL;

	const uint8_t *bytes = (const uint8_t *)[p12Data bytes];

	BIO *bio = BIO_new_mem_buf(bytes, (int)[p12Data length]);
	if (!bio) return P12_CHANGE_DECODE_ERROR;

	OSSL_PROVIDER_load(NULL, "legacy");

	PKCS12 *p12 = d2i_PKCS12_bio(bio, NULL);
	BIO_free(bio);

	if (!p12) return P12_CHANGE_DECODE_ERROR;

	// Verify the old password by checking the MAC.
	// PKCS12_verify_mac returns 1 on success, 0 on wrong password, -1 if no MAC.
	// Check the provided password first (the most common case), then fall back to empty/no password.
	bool macWithPass = (oldPass != NULL && PKCS12_verify_mac(p12, oldPass, -1) == 1);
	bool macNoPass = !macWithPass && (PKCS12_verify_mac(p12, NULL, 0) == 1);

	if (!macNoPass && !macWithPass) {
		// No MAC match — try a full parse to distinguish wrong-password from missing MAC
		EVP_PKEY *pkey = NULL;
		X509 *cert = NULL;
		STACK_OF(X509) *ca = NULL;
		int parsed = PKCS12_parse(p12, oldPass, &pkey, &cert, &ca);
		if (pkey) EVP_PKEY_free(pkey);
		if (cert) X509_free(cert);
		if (ca) sk_X509_pop_free(ca, X509_free);

		if (!parsed) {
			PKCS12_free(p12);
			return P12_CHANGE_AUTH_ERROR;
		}
	}

	// Re-encrypt the PKCS#12 container with the new password.
	// Pass the password that was actually accepted by verify_mac.
	const char *effectiveOldPass = macNoPass ? NULL : oldPass;
	if (!PKCS12_newpass(p12, effectiveOldPass, newPass)) {
		PKCS12_free(p12);
		return P12_CHANGE_EXPORT_ERROR;
	}

	// Serialize the modified PKCS#12 back to DER bytes.
	BIO *out = BIO_new(BIO_s_mem());
	if (!out) {
		PKCS12_free(p12);
		return P12_CHANGE_EXPORT_ERROR;
	}

	if (!i2d_PKCS12_bio(out, p12)) {
		PKCS12_free(p12);
		BIO_free(out);
		return P12_CHANGE_EXPORT_ERROR;
	}

	PKCS12_free(p12);

	BUF_MEM *bptr = NULL;
	BIO_get_mem_ptr(out, &bptr);

	if (!bptr || bptr->length == 0) {
		BIO_free(out);
		return P12_CHANGE_EXPORT_ERROR;
	}

	*outputData = [NSData dataWithBytes:bptr->data length:bptr->length];
	BIO_free(out);

	return P12_CHANGE_SUCCESS;
}

void password_check_fix_WHAT_THE_FUCK_free(NSString *path) {
	string strProvisionFile = [path cStringUsingEncoding:NSUTF8StringEncoding];
	string strProvisionData;
	ZFile::ReadFile(strProvisionFile.c_str(), strProvisionData);
	
	BIO *in = BIO_new(BIO_s_mem());
	if (!in) return;
	
	if ((size_t)BIO_write(in, strProvisionData.data(), (int)strProvisionData.size()) != strProvisionData.size()) {
		BIO_free(in);
		return;
	}
	
	CMS_ContentInfo *cms = d2i_CMS_bio(in, NULL);
	if (cms) CMS_ContentInfo_free(cms);
	// free my boy
	BIO_free(in);
}
