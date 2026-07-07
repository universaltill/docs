# POS Capability Acceptance Matrix (Epics 2–5)

_Last verified: 2026-07-07._

This matrix formalizes acceptance for the POS feature areas historically grouped as
**Epics 2–5** (catalog/inventory, sales/tender/receipt, offline/sync, and
plugins/permissions/settings). The original BMAD story files were removed in the docs
overhaul, so acceptance here is expressed as **capabilities mapped to the automated
tests that verify them** in `universal-till` — i.e. acceptance is grounded in the
green test suite, not in re-derived story text.

How to read it: each capability row is considered **accepted** when its listed tests
pass. Run `go test ./...` in `universal-till`; all packages below are green as of the
date above (12 test packages, 0 failures). Marketplace-side acceptance
(publish/validate/review/sign/download) is covered separately by `ut-market-place`
(18 test packages green) and by the live end-to-end proof in [STATUS](../STATUS.md).

---

## Epic 2 — Catalog & Inventory

| Capability | Verified by (tests) | Package |
|---|---|---|
| Create items with variants and barcodes | `TestCreateVariantAndBarcode`, `TestUpdateItemAndVariant` | `internal/pos` |
| Deactivate items/variants (soft) | `TestDeactivateItemAndVariants`, `TestDeactivateVariant` | `internal/pos` |
| Barcode integrity (XOR item/variant, no cross-assignment, reject inactive) | `TestAddBarcode_XORValidation`, `TestAddBarcode_CrossAssignmentBlocked`, `TestAddBarcode_InactiveItemFails` | `internal/pos` |
| Effective price resolution (history preferred, base fallback, future not yet active, variant-level history, inactive errors) | `TestResolveCurrentPrice_ItemHistoryPreferred`, `TestResolveCurrentPrice_FallbackToBase`, `TestResolveCurrentPrice_FuturePriceNotActive`, `TestResolveCurrentPrice_VariantHistoryPreferred`, `TestResolveCurrentPrice_InactiveErrors`, `TestResolveCurrentPrice_InactiveVariantErrors`, `TestResolveCurrentPrice_InvalidArgs` | `internal/pos` |
| Price-history append closes the previous period | `TestAppendPriceHistoryItem_AppendsAndEndsPrevious`, `TestAppendPriceHistoryVariant_AppendsAndEndsPrevious`, `TestAppendPriceHistoryItem_MultipleAppends` | `internal/pos` |
| Inventory aggregation (item/variant, no-record, item+variant mutual exclusion) | `TestAggregateInventory_ItemID`, `TestAggregateInventory_NoRecord`, `TestAggregateInventory_BothItemAndVariantError` | `internal/pos` |
| Stock movements (receive, adjust, reject zero-qty) | `TestRecordStockMovement_Receive`, `TestRecordStockMovement_Adjust`, `TestRecordStockMovement_ZeroQuantityError` | `internal/pos` |
| Negative-inventory guard + audited manager override (reason + actor required) | `TestCheckNegativeInventory_Sufficient/Insufficient/ZeroRequest/NegativeRequest`, `TestRecordNegativeInventoryOverride`, `TestRecordNegativeInventoryOverride_MissingReason`, `TestRecordNegativeInventoryOverride_MissingActorID` | `internal/pos` |
| Low-stock reporting + active-item search | `TestGetLowStockItems`, `TestSearchActiveItems_FiltersInactive`, `TestLookupActiveVariant` | `internal/pos` |
| Catalog/inventory UI (list filters inactive, create/deactivate, inventory + override + return forms, low-stock badge) | `TestCatalogPage_FiltersInactive`, `TestCatalogCreateAndDeactivate`, `TestInventoryFormRender`, `TestManagerOverrideForm`, `TestReturnFormRender`, `TestLowStockBadge` | `internal/pages`, `internal/pages/catalog` |
| Repository paging/order + input validation | `TestPOSRepo_SearchActiveItems_OrderAndPagination`, `TestSearchItemsForShortcuts_PaginationAndOrder`, `TestPOSRepo_LookupActiveVariant_ValidatesInput` | `internal/data` |

## Epic 3 — Sales, Tender & Receipt

| Capability | Verified by (tests) | Package |
|---|---|---|
| Complete a sale, writing sale/line/payment rows | `TestCompleteSale_SucceedsAndWritesRows` | `internal/pos` |
| Tender correctness: reject underpayment, allow change across payments, reject invalid change | `TestCompleteSale_RejectsUnderpayment`, `TestCompleteSale_AllowsChangeAcrossPayments`, `TestCompleteSale_RejectsInvalidChange` | `internal/pos` |
| Tax: inclusive tax not double-counted; basis-point tax; line/quantity amounts | `TestCompleteSale_InclusiveTaxNoDoubleCount`, `TestComputeTaxBasisPoints`, `TestAmountForQuantity`, `TestServiceUpdateLine` | `internal/pos` |
| Atomicity: roll back the sale on payment failure; record the failure for retry | `TestCompleteSale_RollsBackOnPaymentFailure`, `TestRecordPaymentFailure_PersistsAuditLog` | `internal/pos` |
| Void / park a sale | `TestUpdateSaleStatus_Void`, `TestStatusEndpoint_ParkAndVoid` | `internal/pos`, `internal/pages` |
| Scanning: quantity accumulation, weighed-item cache refresh, cache reset/remove, basket totals | `TestScanQty_DuplicateScanUsesInMemoryLine`, `TestScanQty_CacheRefreshesWeighedFlag`, `TestScanCacheClearsOnReset`, `TestScanCacheClearsOnRemove`, `TestScanHandlerUpdatesBasketTotals` | `internal/pos`, `internal/pages` |
| Promotions via barcode (DB-driven, percent, customer-match required) | `TestPromoBarcodeSetsDiscount_FromDB`, `TestPromoBarcodeSetsDiscount_Percent`, `TestPromoBarcodeRequiresCustomerMatch` | `internal/pages` |
| Split payments + printer fallback with legal text | `TestPOSTenderSplitPayments`, `TestPOSTender_PrinterFallbackAndLegalText` | `internal/pages` |
| Receipt rendering (discount shown, legal text present/absent) | `TestRenderReceipt_DiscountShown`, `TestRenderReceipt_LegalText`, `TestRenderReceipt_NoLegalText` | `internal/pages` |
| Unique receipt numbers under concurrency | `TestReceiptNoGenerator_Concurrency` | `internal/pos` |
| Shifts / cash drawer: open (reject duplicate register), close, expected-cash, cash adjustments (reject on closed shift) | `TestOpenShift`, `TestOpenShift_DuplicateRegister`, `TestCloseShift`, `TestComputeExpectedCash`, `TestRecordCashAdjustment`, `TestRecordCashAdjustment_ClosedShift` | `internal/pos` |

## Epic 4 — Offline-first & Sync

| Capability | Verified by (tests) | Package |
|---|---|---|
| A sale completes offline: sync flags set + plugin audit emitted | `TestCompleteSale_OfflineSyncFlagsAndAuditPlugins` | `internal/pos` |
| Offline tender updates the journal | `TestOfflineTenderUpdatesJournal` | `internal/pages` |
| Queued sales list + sync-attempt backoff bookkeeping | `TestPOSRepo_ListQueuedSales`, `TestPOSRepo_BumpSaleSyncAttempt` | `internal/data` |
| Checkout stays responsive (latency/perf budgets that guard the offline-first promise) | `TestSalePerformanceThresholds`, `TestMicroInteractionLatency`, `TestScanTotalsLatency`, `TestBenchmarkThresholdConfiguration` | `internal/pos` |

## Epic 5 — Plugins, Permissions & Settings

| Capability | Verified by (tests) | Package |
|---|---|---|
| Install a plugin (success, checksum mismatch, missing binary, default trust) | `TestInstallPlugin_Success`, `TestInstallPlugin_ChecksumMismatch`, `TestInstallPlugin_MissingBinary`, `TestInstallPlugin_DefaultTrustLevel` | `internal/plugins` |
| Uninstall + trust-level management (valid levels, reject invalid) | `TestUninstallPlugin`, `TestUpdatePluginTrustLevel`, `TestUpdatePluginTrustLevel_AllValidLevels`, `TestUpdatePluginTrustLevel_InvalidLevel` | `internal/plugins` |
| Manifest parse + validation + persistence; checksum util | `TestParseManifest_Valid`, `TestParseManifest_MissingRequiredFields`, `TestParseManifest_DefaultRuntime`, `TestPersistManifest`, `TestPersistManifest_Update`, `TestComputeSHA256`, `TestComputeSHA256_NonExistentFile` | `internal/plugins` |
| Marketplace install: Ed25519 verify (accept valid, reject wrong key/bad sig), reject checksum mismatch / tampered payload / missing integrity, normalize entrypoint | `TestMarketplaceSignatureVerifies`, `TestMarketplaceSignatureRejectedByWrongKey`, `TestMarketplaceInstallerInstallSuccess`, `TestMarketplaceInstallerRejectsBadSignature`, `TestMarketplaceInstallerRejectsChecksumMismatch`, `TestMarketplaceInstallerRejectsTamperedBundlePayload`, `TestMarketplaceInstallerRejectsMissingIntegrityMetadata`, `TestMarketplaceInstallerNormalizesEntrypointFromExecutable` | `internal/plugins` |
| Install-state reporting + error classification | `TestMarketplaceReporterReports`, `TestMarketplaceReporterDisabledAndNoop`, `TestClassifyInstallError`, `TestInstallStatusStoreRoundTrip` | `internal/plugins` |
| Permission model (grant/revoke/check, multiple/any, list) + not-declared vs not-granted | `TestCheckPermission_Granted/NotGranted/NotDeclared`, `TestGrantPermission`, `TestGrantPermission_NotFound`, `TestRevokePermission`, `TestListPluginPermissions`, `TestCheckMultiplePermissions`, `TestHasAnyPermission` | `internal/plugins` |
| Plugin event bus (permissioned publish, non-blocking audit, blocking rollback, crash isolation, unsubscribe/ack) | `TestEventBus_SubscribePublish`, `TestEventBus_PublishWithoutPermission`, `TestEventBus_NonBlockingAuditsAndContinues`, `TestEventBus_BlockingRollsBackOnError`, `TestEventBus_Unsubscribe`, `TestEventBus_AcknowledgeError`, `TestEventBus_MultipleSubscribers`, `TestEventBus_SubscribeWithoutHook` | `internal/plugins` |
| Plugin supervisor lifecycle (start/stop, already-running, list, shutdown, process info) + IPC | `TestSupervisor_StartStopPlugin`, `TestSupervisor_StartAlreadyRunning`, `TestSupervisor_ListRunning`, `TestSupervisor_Shutdown`, `TestSupervisor_GetProcessInfo_NotRunning`, `TestSupervisor_StopPlugin_NotRunning`, `TestPluginIPC_Ack` | `internal/plugins` |
| Cross-cutting integration: permission-denial audit, menu filtering by permission, crash isolation, IPC round-trip, marketplace checksum rejection | `TestIntegration_PermissionDenialAudit`, `TestIntegration_MenuFilteringByPermissions`, `TestIntegration_EventDispatchCrashIsolation`, `TestIntegration_IPCEventRoundTrip`, `TestIntegration_MarketplaceChecksumRejection` | `internal/plugins` |
| Marketplace OAuth token client (success, cache, missing creds, clear) | `TestTokenClient_GetToken_Success`, `TestTokenClient_GetToken_UsesCache`, `TestTokenClient_GetToken_MissingCredentials`, `TestTokenClient_ClearCache` | `internal/plugins/oauth` |
| Settings persistence + plugin menu entries filtered by grant/active | `TestSettingsRepo_SetAndGet`, `TestPluginRepo_ListMenuEntries_FiltersUngranted`, `TestPluginRepo_ListInstalledPlugins_ActiveOnly` | `internal/data` |
| Plugins UI surfaces lifecycle status + operator-visible install failures | `TestPluginsPageEmbedsLifecycleStatusAndRetryData`, `TestInstallFromMarketplaceFailurePersistsOperatorVisibleStatus` | `internal/pages` |

---

## Gaps / not yet accepted here

These are **not** covered by this matrix and remain open (see [STATUS](../STATUS.md)):

- **POS UI MVP (epic 1-4)** — presentation-layer polish/flows beyond the rendered-form
  tests above; greenfield, needs a design decision.
- **Offline export/import bundles (epic 1-1 AC3)** — no implementation yet; greenfield,
  needs a format decision.
- Any capability whose only evidence is manual/live (e.g. printer hardware) rather than
  an automated test.
