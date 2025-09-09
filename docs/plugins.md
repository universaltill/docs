# Plugins and Store

## What is a Plugin?
A plugin extends the Till with integrations, hardware support, or UI contributions.

- Runs as a separate process/microservice
- Declares a `manifest.yaml`
- Communicates via HTTP/gRPC with the Till runtime

## Store Submission
1. Create your plugin and manifest
2. Package as a container or binary
3. Submit to the Store `/api/plugins` with metadata
4. Pass automated validations (manifest schema, security checks)
5. Set pricing (one-time or subscription) and revenue share

## Revenue Share
- Configurable percentage for the platform owner from each sale or subscription

## Entitlements
- Runtime checks entitlement tokens with the Store before enabling plugin features
