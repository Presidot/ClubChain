;; ClubChain - Social Club Member Governance System
;; Version: 1.0.0

;; Constants
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_MEASURE_EXISTS (err u101))
(define-constant ERR_MEASURE_NOT_FOUND (err u102))
(define-constant ERR_VOTING_ENDED (err u103))
(define-constant ERR_ALREADY_VOTED (err u104))
(define-constant ERR_INVALID_CHOICE (err u105))
(define-constant ERR_SELF_REPRESENTATION (err u106))
(define-constant ERR_REPRESENTATION_CYCLE (err u107))
(define-constant ERR_INVALID_INPUT (err u108))
(define-constant ERR_NOT_ENOUGH_MEMBERSHIP (err u109))
(define-constant ERR_INSUFFICIENT_SIGNATURES (err u110))

;; Data Variables
(define-data-var club-president principal tx-sender)
(define-data-var season-counter uint u0)

;; Maps
(define-map Measures
  { measure-id: uint }
  {
    title: (string-ascii 50),
    options: (list 10 (string-ascii 20)),
    deadline: uint,
    membership-total: uint
  })

(define-map MemberVotes
  { measure-id: uint, member: principal }
  { option: (string-ascii 20), membership: uint })

(define-map MembershipLevel
  { member: principal }
  { membership: uint })

(define-map Representatives
  { grantor: principal }
  { representative: principal })

;; Private Functions
(define-private (is-club-president)
  (is-eq tx-sender (var-get club-president)))

(define-private (check-measure-exists (measure-id uint))
  (is-some (map-get? Measures { measure-id: measure-id })))

(define-private (check-voting-open (measure-id uint))
  (match (map-get? Measures { measure-id: measure-id })
    measure-data (< (var-get season-counter) (get deadline measure-data))
    false))

(define-private (get-member-membership (member principal))
  (default-to u1 (get membership (map-get? MembershipLevel { member: member }))))

(define-private (update-membership-total (measure-id uint) (membership uint))
  (match (map-get? Measures { measure-id: measure-id })
    measure-data (map-set Measures
                 { measure-id: measure-id }
                (merge measure-data { membership-total: (+ (get membership-total measure-data) membership) }))
    false))

(define-private (validate-string (input (string-ascii 50)))
  (and (>= (len input) u1) (<= (len input) u50)))

(define-private (validate-options (options (list 10 (string-ascii 20))))
  (and 
    (>= (len options) u2)
    (<= (len options) u10)
    (fold and (map validate-string options) true)
  ))

(define-private (validate-membership-threshold (member principal))
  (> (get-member-membership member) u0))

;; Public Functions
(define-public (propose-measure (title (string-ascii 50)) (options (list 10 (string-ascii 20))) (duration uint))
  (begin
    (asserts! (is-club-president) ERR_UNAUTHORIZED)
    (asserts! (validate-string title) ERR_INVALID_INPUT)
    (asserts! (validate-options options) ERR_INVALID_INPUT)
    (asserts! (> duration u0) ERR_INVALID_INPUT)
    (let 
      (
        (measure-id (+ u1 (default-to u0 (get membership-total (map-get? Measures { measure-id: u0 })))))
        (current-season (var-get season-counter))
      )
      (asserts! (not (check-measure-exists measure-id)) ERR_MEASURE_EXISTS)
      (ok (map-set Measures
            { measure-id: measure-id }
            {
              title: title,
              options: options,
              deadline: (+ current-season duration),
              membership-total: u0
            }))
    )
  ))

(define-public (cast-member-vote (measure-id uint) (option (string-ascii 20)))
  (let 
    (
      (member-membership (get-member-membership tx-sender))
      (measure (unwrap! (map-get? Measures { measure-id: measure-id }) ERR_MEASURE_NOT_FOUND))
    )
    (asserts! (check-voting-open measure-id) ERR_VOTING_ENDED)
    (asserts! (is-some (index-of (get options measure) option)) ERR_INVALID_CHOICE)
    (asserts! (is-none (map-get? MemberVotes { measure-id: measure-id, member: tx-sender })) ERR_ALREADY_VOTED)
    (asserts! (validate-membership-threshold tx-sender) ERR_NOT_ENOUGH_MEMBERSHIP)
    (map-set MemberVotes
      { measure-id: measure-id, member: tx-sender }
      { option: option, membership: member-membership })
    (update-membership-total measure-id member-membership)
    (ok true)
  ))

(define-public (assign-representative (representative principal))
  (begin
    (asserts! (not (is-eq tx-sender representative)) ERR_SELF_REPRESENTATION)
    (asserts! (is-none (map-get? Representatives { grantor: representative })) ERR_REPRESENTATION_CYCLE)
    (map-set Representatives { grantor: tx-sender } { representative: representative })
    (map-set MembershipLevel
      { member: representative }
      { membership: (+ (get-member-membership representative) (get-member-membership tx-sender)) })
    (map-delete MembershipLevel { member: tx-sender })
    (ok true)
  ))

(define-public (close-measure (measure-id uint))
  (begin
    (asserts! (is-club-president) ERR_UNAUTHORIZED)
    (asserts! (check-measure-exists measure-id) ERR_MEASURE_NOT_FOUND)
    (let ((measure (unwrap! (map-get? Measures { measure-id: measure-id }) ERR_MEASURE_NOT_FOUND)))
      (ok (map-set Measures
            { measure-id: measure-id }
            (merge measure { deadline: (var-get season-counter) })))
    )
  ))

(define-public (advance-season)
  (begin
    (asserts! (is-club-president) ERR_UNAUTHORIZED)
    (ok (var-set season-counter (+ (var-get season-counter) u1)))
  ))

;; Read-Only Functions
(define-read-only (get-measure-membership-total (measure-id uint))
  (ok (get membership-total (unwrap! (map-get? Measures { measure-id: measure-id }) ERR_MEASURE_NOT_FOUND))))

(define-read-only (get-member-membership-level (member principal))
  (ok (get-member-membership member)))

(define-read-only (get-measure-status (measure-id uint))
  (let ((measure (unwrap! (map-get? Measures { measure-id: measure-id }) ERR_MEASURE_NOT_FOUND)))
    (ok (< (var-get season-counter) (get deadline measure)))
  ))

(define-read-only (get-current-season)
  (ok (var-get season-counter)))

(define-read-only (get-club-stats)
  {
    president: (var-get club-president),
    current-season: (var-get season-counter)
  })