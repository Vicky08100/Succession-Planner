;; EternalLegacy: Multi-Tiered Endowment Fund with Succession Planning
;; A comprehensive smart contract that enables users to create endowment funds with:
;; - Multi-tiered succession planning (up to 3 levels of successors)
;; - Time-locked inheritance triggers based on inactivity periods
;; - Percentage-based fund distribution to successors
;; - Endowment support voting system
;; - Returns calculation and distribution mechanisms

;; Error Constants
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-INSUFFICIENT-FUNDS (err u101))
(define-constant ERR-INVALID-ENDOWMENT-DATA (err u102))
(define-constant ERR-ALREADY-VOTED (err u103))
(define-constant ERR-TRANSACTION-FAILED (err u104))
(define-constant ERR-INVALID-TIER-LEVEL (err u105))
(define-constant ERR-SUCCESSOR-NOT-REGISTERED (err u106))
(define-constant ERR-NOT-DESIGNATED-SUCCESSOR (err u107))
(define-constant ERR-TIMELOCK-ACTIVE (err u108))

;; Contract Constants
(define-constant contract-admin tx-sender)

;; Fund Data Variables
(define-data-var fund-total-balance uint u0)
(define-data-var fund-generated-returns uint u0)
(define-data-var fund-last-activity-timestamp uint u0)

;; Data Maps
(define-map user-deposits principal uint)
(define-map registered-endowments 
  {endowment-name: (string-ascii 64)} 
  {beneficiary-address: principal, vote-count: uint}
)
(define-map endowment-voter-registry 
  {endowment-name: (string-ascii 64), voter-address: principal} 
  bool
)
(define-map inheritance-configuration 
  {owner-address: principal, tier-level: uint} 
  {inactivity-period: uint, heir-address: principal, allocation-percentage: uint, notification-timestamp: uint}
)
(define-map heir-notification-registry 
  {heir-address: principal, owner-address: principal} 
  {tier-level: uint, inheritance-activation-time: uint, notification-sent: bool}
)

;; Private Helper Functions
(define-private (transfer-funds-to-recipient (recipient-address principal) (transfer-amount uint))
  (match (as-contract (stx-transfer? transfer-amount tx-sender recipient-address))
    success-response (ok transfer-amount)
    error-code (err ERR-TRANSACTION-FAILED)
  )
)

(define-private (update-activity-timestamp)
  (var-set fund-last-activity-timestamp block-height)
)

;; Public Fund Management Functions
(define-public (deposit-funds)
  (let ((deposit-amount (stx-get-balance tx-sender)))
    (try! (stx-transfer? deposit-amount tx-sender (as-contract tx-sender)))
    (map-set user-deposits tx-sender (+ (default-to u0 (map-get? user-deposits tx-sender)) deposit-amount))
    (var-set fund-total-balance (+ (var-get fund-total-balance) deposit-amount))
    (update-activity-timestamp)
    (ok deposit-amount)
  )
)

(define-public (compute-fund-returns)
  (let (
    (periodic-returns (/ (* (var-get fund-total-balance) u5) u100)) ;; 5% return simulation
  )
    (var-set fund-generated-returns (+ (var-get fund-generated-returns) periodic-returns))
    (update-activity-timestamp)
    (ok periodic-returns)
  )
)

(define-public (send-returns-to-endowment (endowment-name (string-ascii 64)))
  (let (
    (endowment-record (unwrap! (map-get? registered-endowments {endowment-name: endowment-name}) 
                      (err ERR-INVALID-ENDOWMENT-DATA)))
    (available-returns (var-get fund-generated-returns))
  )
    (match (transfer-funds-to-recipient (get beneficiary-address endowment-record) available-returns)
      success-transfer (begin
        (var-set fund-generated-returns u0)
        (update-activity-timestamp)
        (ok available-returns)
      )
      failure-code (err ERR-TRANSACTION-FAILED)
    )
  )
)

;; Fund Information Functions
(define-read-only (get-fund-status)
  (ok {
    total-assets: (var-get fund-total-balance),
    undistributed-returns: (var-get fund-generated-returns)
  })
)

;; Endowment Management Functions
(define-public (create-endowment (endowment-name (string-ascii 64)) (beneficiary-address principal))
  (begin
    (asserts! (is-eq tx-sender contract-admin) ERR-UNAUTHORIZED-ACCESS)
    (map-set registered-endowments {endowment-name: endowment-name} 
             {beneficiary-address: beneficiary-address, vote-count: u0})
    (update-activity-timestamp)
    (ok true)
  )
)

(define-public (vote-for-endowment (endowment-name (string-ascii 64)))
  (let (
    (has-voted-before (default-to false (map-get? endowment-voter-registry 
                                        {endowment-name: endowment-name, voter-address: tx-sender})))
    (current-votes (get vote-count (unwrap! (map-get? registered-endowments {endowment-name: endowment-name}) 
                                 ERR-INVALID-ENDOWMENT-DATA)))
  )
    (asserts! (not has-voted-before) ERR-ALREADY-VOTED)
    (map-set endowment-voter-registry {endowment-name: endowment-name, voter-address: tx-sender} true)
    (map-set registered-endowments {endowment-name: endowment-name} 
      (merge (unwrap! (map-get? registered-endowments {endowment-name: endowment-name}) ERR-INVALID-ENDOWMENT-DATA)
             {vote-count: (+ u1 current-votes)}))
    (update-activity-timestamp)
    (ok true)
  )
)

;; Succession Planning Functions
(define-public (configure-succession-tier (tier-level uint) (inactivity-period uint) 
                                         (heir-address principal) (allocation-percentage uint))
  (begin
    (asserts! (and (>= tier-level u1) (<= tier-level u3)) ERR-INVALID-TIER-LEVEL)
    (asserts! (<= allocation-percentage u100) ERR-INVALID-TIER-LEVEL)
    (map-set inheritance-configuration {owner-address: tx-sender, tier-level: tier-level} 
      {inactivity-period: inactivity-period, heir-address: heir-address, 
       allocation-percentage: allocation-percentage, notification-timestamp: u0})
    (update-activity-timestamp)
    (ok true)
  )
)

(define-public (delete-succession-tier (tier-level uint))
  (begin
    (asserts! (and (>= tier-level u1) (<= tier-level u3)) ERR-INVALID-TIER-LEVEL)
    (map-delete inheritance-configuration {owner-address: tx-sender, tier-level: tier-level})
    (update-activity-timestamp)
    (ok true)
  )
)

(define-read-only (view-succession-tier (owner-address principal) (tier-level uint))
  (match (map-get? inheritance-configuration {owner-address: owner-address, tier-level: tier-level})
    tier-details (ok tier-details)
    (err ERR-SUCCESSOR-NOT-REGISTERED)
  )
)

(define-private (process-succession (owner-address principal) (heir-address principal) 
                                   (allocation-percentage uint) (owner-balance uint))
  (let (
    (inheritance-amount (/ (* owner-balance allocation-percentage) u100))
  )
    (match (as-contract (stx-transfer? inheritance-amount tx-sender heir-address))
      success-response (begin
        (var-set fund-total-balance (- owner-balance inheritance-amount))
        (map-delete user-deposits owner-address)
        (map-delete inheritance-configuration {owner-address: owner-address, tier-level: u1})
        (map-delete inheritance-configuration {owner-address: owner-address, tier-level: u2})
        (map-delete inheritance-configuration {owner-address: owner-address, tier-level: u3})
        (map-delete heir-notification-registry {heir-address: heir-address, owner-address: owner-address})
        (ok inheritance-amount)
      )
      error-code (err ERR-TRANSACTION-FAILED)
    )
  )
)

;; Succession Alert Functions
(define-public (verify-succession-eligibility)
  (let (
    (current-block-height block-height)
    (last-user-activity (var-get fund-last-activity-timestamp))
  )
    (map-set heir-notification-registry 
      {heir-address: tx-sender, owner-address: contract-admin}
      (merge 
        (default-to 
          {tier-level: u0, inheritance-activation-time: u0, notification-sent: false}
          (map-get? heir-notification-registry {heir-address: tx-sender, owner-address: contract-admin})
        )
        {
          tier-level: (determine-eligible-tier-level tx-sender contract-admin current-block-height last-user-activity),
          inheritance-activation-time: (+ last-user-activity (get-tier-inactivity-period tx-sender contract-admin)),
          notification-sent: true
        }
      )
    )
    (ok true)
  )
)

(define-private (determine-eligible-tier-level (heir-address principal) (owner-address principal) 
                                              (current-time uint) (last-activity uint))
  (let (
    (tier-one (default-to {inactivity-period: u0, heir-address: 'SP000000000000000000002Q6VF78, 
                           allocation-percentage: u0, notification-timestamp: u0} 
                (map-get? inheritance-configuration {owner-address: owner-address, tier-level: u1})))
    (tier-two (default-to {inactivity-period: u0, heir-address: 'SP000000000000000000002Q6VF78, 
                          allocation-percentage: u0, notification-timestamp: u0} 
                (map-get? inheritance-configuration {owner-address: owner-address, tier-level: u2})))
    (tier-three (default-to {inactivity-period: u0, heir-address: 'SP000000000000000000002Q6VF78, 
                            allocation-percentage: u0, notification-timestamp: u0} 
                  (map-get? inheritance-configuration {owner-address: owner-address, tier-level: u3})))
  )
    (if (and (is-eq heir-address (get heir-address tier-three)) 
             (>= (- current-time last-activity) (get inactivity-period tier-three)))
      u3
      (if (and (is-eq heir-address (get heir-address tier-two)) 
               (>= (- current-time last-activity) (get inactivity-period tier-two)))
        u2
        (if (and (is-eq heir-address (get heir-address tier-one)) 
                 (>= (- current-time last-activity) (get inactivity-period tier-one)))
          u1
          u0
        )
      )
    )
  )
)

(define-private (get-tier-inactivity-period (heir-address principal) (owner-address principal))
  (let (
    (tier-one (default-to {inactivity-period: u0, heir-address: 'SP000000000000000000002Q6VF78, 
                          allocation-percentage: u0, notification-timestamp: u0} 
                (map-get? inheritance-configuration {owner-address: owner-address, tier-level: u1})))
    (tier-two (default-to {inactivity-period: u0, heir-address: 'SP000000000000000000002Q6VF78, 
                          allocation-percentage: u0, notification-timestamp: u0} 
                (map-get? inheritance-configuration {owner-address: owner-address, tier-level: u2})))
    (tier-three (default-to {inactivity-period: u0, heir-address: 'SP000000000000000000002Q6VF78, 
                            allocation-percentage: u0, notification-timestamp: u0} 
                  (map-get? inheritance-configuration {owner-address: owner-address, tier-level: u3})))
  )
    (if (is-eq heir-address (get heir-address tier-three))
      (get inactivity-period tier-three)
      (if (is-eq heir-address (get heir-address tier-two))
        (get inactivity-period tier-two)
        (if (is-eq heir-address (get heir-address tier-one))
          (get inactivity-period tier-one)
          u0
        )
      )
    )
  )
)

;; Read-only Information Functions
(define-read-only (get-user-deposit (user-address principal))
  (ok (default-to u0 (map-get? user-deposits user-address)))
)

(define-read-only (get-endowment-details (endowment-name (string-ascii 64)))
  (ok (unwrap! (map-get? registered-endowments {endowment-name: endowment-name}) ERR-INVALID-ENDOWMENT-DATA))
)

(define-read-only (get-total-fund-assets)
  (ok (var-get fund-total-balance))
)

(define-read-only (get-undistributed-returns)
  (ok (var-get fund-generated-returns))
)

(define-read-only (get-last-activity-timestamp)
  (ok (var-get fund-last-activity-timestamp))
)

(define-read-only (get-heir-notification-status (heir-address principal) (owner-address principal))
  (ok (unwrap! (map-get? heir-notification-registry {heir-address: heir-address, owner-address: owner-address}) 
              ERR-NOT-DESIGNATED-SUCCESSOR))
)