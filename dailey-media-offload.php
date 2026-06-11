<?php
/**
 * Dailey OS media offload (mu-plugin).
 *
 * Auto-configures humanmade/S3-Uploads from the platform-injected S3_PUBLIC_*
 * env: uploads go to the public R2 bucket and serve from the platform CDN
 * (assets.dailey.cloud) instead of the pod volume.
 *
 * - NO-OPS when public storage isn't enabled on the project (no S3_PUBLIC_*).
 * - Kill switch: set env WP_OFFLOAD_MEDIA=false (dailey env set).
 * - Credentials are the platform's prefix-scoped temp creds (rotated daily
 *   with a pod roll), passed via the client-params filter because they
 *   include a session token.
 */

if ( ! getenv( 'S3_PUBLIC_BUCKET_NAME' ) || getenv( 'WP_OFFLOAD_MEDIA' ) === 'false' ) {
	return;
}

$dailey_prefix = trim( (string) getenv( 'S3_PUBLIC_KEY_PREFIX' ), '/' );
// S3-Uploads accepts "bucket/key-prefix" in the bucket constant.
define( 'S3_UPLOADS_BUCKET', getenv( 'S3_PUBLIC_BUCKET_NAME' ) . ( $dailey_prefix !== '' ? '/' . $dailey_prefix : '' ) . '/uploads' );
define( 'S3_UPLOADS_REGION', getenv( 'S3_REGION' ) ?: 'auto' );
define( 'S3_UPLOADS_KEY', getenv( 'S3_PUBLIC_ACCESS_KEY_ID' ) );
define( 'S3_UPLOADS_SECRET', getenv( 'S3_PUBLIC_SECRET_ACCESS_KEY' ) );
define( 'S3_UPLOADS_AUTOENABLE', true );

// Public URL base: must include the full path prefix through "/uploads" so
// that S3-Uploads' str_replace( s3://bucket/key-prefix, BUCKET_URL, path )
// produces the correct public URL (e.g. https://assets.dailey.cloud/<proj>/uploads/y/m/file.png).
// S3_PUBLIC_URL is already https://assets.dailey.cloud/<projectId>, so we
// append the same prefix path we put in S3_UPLOADS_BUCKET after the bucket name.
$dailey_public = rtrim( (string) getenv( 'S3_PUBLIC_URL' ), '/' );
if ( $dailey_public !== '' ) {
	$dailey_bucket_url = $dailey_public . ( $dailey_prefix !== '' ? '/' . $dailey_prefix : '' ) . '/uploads';
	define( 'S3_UPLOADS_BUCKET_URL', $dailey_bucket_url );
}

// R2 specifics: custom endpoint, path-style, session token (temp creds),
// and when_required checksums (newer AWS SDKs default to modes R2 rejects).
add_filter( 's3_uploads_s3_client_params', function ( $params ) {
	$params['endpoint']                = getenv( 'S3_ENDPOINT' );
	$params['use_path_style_endpoint'] = true;
	$params['credentials']             = [
		'key'    => getenv( 'S3_PUBLIC_ACCESS_KEY_ID' ),
		'secret' => getenv( 'S3_PUBLIC_SECRET_ACCESS_KEY' ),
		'token'  => getenv( 'S3_PUBLIC_SESSION_TOKEN' ),
	];
	$params['request_checksum_calculation'] = 'when_required';
	$params['response_checksum_validation'] = 'when_required';
	return $params;
} );

require_once '/var/www/dailey-mu-plugins/s3-uploads/s3-uploads.php';
