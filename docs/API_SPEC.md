# Infio Partner API

Backend contract for the Infio Partner mobile app — the business side of a hyperlocal service
marketplace operating in India.

A service professional registers through a four-step wizard, uploads work photos, clears Aadhaar
and video KYC, buys a membership plan, and then works a lead inbox against a monthly quota. The
marketplace charges a flat membership fee and takes **zero commission on bookings**, which is the
central product promise. A separate 10% commission figure appears on the service catalogue form;
see [Commission](#commission) for how the two reconcile.

This document is the human-readable reference. [`openapi.yaml`](./openapi.yaml) carries the same
endpoints in machine-readable form for Swagger UI, Postman, or server code generation. The two are
kept in sync.

---

## Contents

1. [Conventions](#conventions)
2. [Authentication](#authentication)
3. [Reference data](#reference-data)
4. [Onboarding](#onboarding)
5. [Partner profile](#partner-profile)
6. [Photos](#photos)
7. [KYC](#kyc)
8. [Plans and billing](#plans-and-billing)
9. [Leads](#leads)
10. [Services](#services)
11. [Dashboard](#dashboard)
12. [Growth](#growth)
13. [Referrals, reviews, notifications](#referrals-reviews-notifications)
14. [Enumerations](#enumerations)
15. [Push notifications](#push-notifications)
16. [Webhooks](#webhooks)
17. [Rate limits](#rate-limits)
18. [Out of scope](#out-of-scope)

---

## Conventions

**Base URL.** `https://api.infio.app/v1`

**Content type.** `application/json; charset=utf-8` on every endpoint except file uploads, which
use `multipart/form-data`.

**Field naming.** `snake_case` throughout. Timestamps are ISO 8601 with an explicit offset
(`2026-10-10T17:30:00+05:30`). Dates without a time are `YYYY-MM-DD`.

**Money.** Integer rupees for prices the partner sets and the customer sees. Decimal rupees to two
places only in checkout totals, where GST produces fractions. Never floats for a stored price.

**Success envelope.** Single resources and collections both nest under `data`. Collections add
`meta`.

```json
{
  "data": { "id": "ld_8924" }
}
```

```json
{
  "data": [ { "id": "ld_8924" } ],
  "meta": { "page": 1, "per_page": 20, "total": 48, "total_pages": 3 }
}
```

**Error envelope.** Always HTTP status plus a machine-readable `code`.

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Some fields need attention.",
    "field_errors": {
      "pincode": "Must be 6 digits",
      "business_name": "Required"
    }
  }
}
```

| Status | `code` | Meaning |
|---|---|---|
| 400 | `bad_request` | Malformed body or query |
| 401 | `unauthenticated` | Missing, expired, or invalid access token |
| 403 | `forbidden` | Authenticated but not permitted |
| 404 | `not_found` | No such resource |
| 409 | `conflict` | State conflict, e.g. accepting an expired lead |
| 422 | `validation_failed` | Body parsed but failed validation; see `field_errors` |
| 429 | `rate_limited` | Too many requests; see `Retry-After` |
| 500 | `internal_error` | Unhandled server fault |

**Pagination.** `?page=1&per_page=20`. Maximum `per_page` is 100.

**Idempotency.** Any `POST` that moves money or consumes quota accepts an `Idempotency-Key`
header. Replaying a key within 24 hours returns the original response rather than repeating the
side effect. Required on checkout payment and lead acceptance.

---

## Authentication

Bearer JWT. Send `Authorization: Bearer <access_token>` on every endpoint except the OTP exchange
and reference data.

Access tokens live 1 hour; refresh tokens live 60 days and rotate on each use.

Authentication is **OTP-first**. The partner enters a 10-digit Indian mobile number and chooses a
delivery channel, defaulting to WhatsApp. A second email-and-password path exists for partners who
set a password through support.

### `POST /auth/otp/request`

Unauthenticated. Sends a 6-digit code.

```json
{
  "phone": "+919849023114",
  "channel": "whatsapp"
}
```

`channel` is `whatsapp` or `sms`.

**200**

```json
{
  "data": {
    "challenge_id": "chl_01HQ3",
    "phone": "+919849023114",
    "channel": "whatsapp",
    "resend_after_seconds": 60,
    "code_length": 6
  }
}
```

The client renders a countdown from `resend_after_seconds` and disables both resend actions until
it reaches zero.

### `POST /auth/otp/resend`

```json
{ "challenge_id": "chl_01HQ3", "channel": "sms" }
```

The channel may differ from the original request — the UI offers "Resend via SMS" and
"Via WhatsApp" side by side. Returns the same shape as the request endpoint, with a fresh
cooldown. Returns **429** if called before the cooldown elapses.

### `POST /auth/otp/verify`

```json
{ "challenge_id": "chl_01HQ3", "code": "418203" }
```

**200**

```json
{
  "data": {
    "access_token": "eyJhbGciOi...",
    "refresh_token": "rt_01HQ3...",
    "expires_in": 3600,
    "partner_id": "ptr_1001",
    "is_new_partner": false
  }
}
```

`is_new_partner` routes the client: `true` goes to onboarding step 1, `false` to the dashboard.

Returns **422** with code `invalid_otp` on a wrong code, and **409** with code `otp_expired` once
the challenge is older than 10 minutes.

### `POST /auth/login/email`

```json
{ "email": "ramesh.apex@gmail.com", "password": "..." }
```

Same response as OTP verify. Returns **401** with code `invalid_credentials` on failure.

### `POST /auth/refresh`

```json
{ "refresh_token": "rt_01HQ3..." }
```

Returns a new token pair. The presented refresh token is invalidated.

### `POST /auth/logout`

Revokes the current refresh token. **204**, no body.

---

## Reference data

Unauthenticated, cacheable, and safe to serve from a CDN. Send `Cache-Control: public, max-age=3600`.

These power the onboarding dropdowns and the service form. The app ships a local copy as a
fallback, but the server is authoritative.

### `GET /ref/cities`

```json
{
  "data": [
    { "id": "hyderabad", "label": "Hyderabad & Secunderabad, Telangana" },
    { "id": "bengaluru", "label": "Bengaluru Urban, Karnataka" },
    { "id": "chennai",   "label": "Chennai Metropolitan, Tamil Nadu" },
    { "id": "pune",      "label": "Pune & PCMC, Maharashtra" }
  ]
}
```

### `GET /ref/categories`

The canonical trade taxonomy. `slug` is the stable key used everywhere else in the API;
`short_tag` is the compact label service cards render.

```json
{
  "data": [
    {
      "slug": "ac_repair",
      "label": "AC Repair & Maintenance",
      "short_tag": "AC Repair",
      "specializations": [
        "Split AC", "Window AC", "Gas Charging",
        "PCB Diagnostics", "Inverter Systems", "Jet Pump Wash"
      ]
    },
    {
      "slug": "plumbing",
      "label": "Plumbing Solutions",
      "short_tag": "Plumbing",
      "specializations": [
        "Pipe Leakage", "Sanitary Fitting", "Water Heater",
        "Motor & Pump", "Drain Cleaning"
      ]
    }
  ]
}
```

Remaining slugs: `electrical`, `deep_cleaning`, `appliance_care`, `painting`.

### `GET /ref/categories/{slug}/specializations`

Returns just the specialization array for one category, for clients that lazy-load.

### `GET /ref/enums`

One call returning the small fixed lists, so the client does not hardcode them.

```json
{
  "data": {
    "entity_types": [
      { "value": "sole_proprietor", "label": "Sole Proprietor" },
      { "value": "partnership_llp", "label": "Partnership / LLP" },
      { "value": "individual",      "label": "Individual Freelance" }
    ],
    "experience_bands": ["1-2 Years", "3-5 Years", "5+ Years"],
    "durations": ["30 mins", "45 mins", "1 hr", "2+ hrs"],
    "pricing_types": [
      { "value": "fixed",         "label": "Fixed Price" },
      { "value": "starting_from", "label": "Starting From" }
    ],
    "service_radius": { "min_km": 2, "max_km": 30, "default_km": 15 },
    "commission_percent": 10,
    "gst_percent": 18
  }
}
```

---

## Onboarding

A four-step wizard with server-side draft persistence, so "Save Draft & Exit" resumes on any
device.

| Step | Collects |
|---|---|
| 1 | Business name, owner name, entity type, phone, WhatsApp opt-in, email, city, referral code |
| 2 | Category, specializations, experience band, description, workshop address, map pin, radius |
| 3 | Cover photo and up to five portfolio photos |
| 4 | Membership plan selection |

Video KYC is a **separate flow**, not step 4. One of the source designs labelled step 4
"Bank & KYC"; the wizard itself is authoritative and step 4 is the plan.

### `GET /partners/me/onboarding`

Returns the saved draft, or an empty draft for a partner who has not started.

```json
{
  "data": {
    "business_name": "Apex Aircon Works",
    "owner_name": "Ramesh Kumar",
    "entity_type": "sole_proprietor",
    "phone": "+919849023114",
    "phone_verified": true,
    "whatsapp_alerts": true,
    "email": "ramesh.apex@gmail.com",
    "city_id": "hyderabad",
    "referral_code": "",
    "category_slug": "ac_repair",
    "specializations": ["Split AC", "Window AC", "Gas Charging", "PCB Diagnostics"],
    "experience_band": "3-5 Years",
    "service_description": "5+ years specializing in multi-brand inverter AC installation...",
    "shop_name": "Apex Aircon Works",
    "street": "Plot 28, Road No. 3, KPHB Phase 1",
    "landmark": "Opposite Metro Pillar 742",
    "pincode": "500072",
    "latitude": 17.4934,
    "longitude": 78.3995,
    "locality": "KPHB Colony, Kukatpally",
    "service_radius_km": 15,
    "cover_photo_id": "pho_a1",
    "portfolio_photo_ids": ["pho_b2", "pho_c3"],
    "selected_plan_id": null,
    "current_step": 3,
    "completed_steps": [1, 2]
  }
}
```

### `PATCH /partners/me/onboarding`

Partial update. Send only changed fields. The client calls this on every edit, debounced.
Returns the merged draft. Does **not** mark any step complete.

### `POST /partners/me/onboarding/steps/{step}`

`step` is 1-4. Validates everything that step requires and marks it complete.

**200** returns the updated draft with `completed_steps` extended and `current_step` advanced.

**422** when required fields are missing:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Complete the required fields to continue.",
    "field_errors": { "pincode": "Must be 6 digits" }
  }
}
```

Per-step required fields:

| Step | Required |
|---|---|
| 1 | `business_name`, `owner_name`, `phone` (verified), `city_id` |
| 2 | `category_slug`, `experience_band`, `shop_name`, `street`, `pincode` |
| 3 | `cover_photo_id` |
| 4 | `selected_plan_id` |

### `POST /partners/me/onboarding/complete`

Finalizes registration, creates the partner record, and queues it for admin review. Sets
verification status to `pending_admin_approval`. **409** if any step is incomplete.

### `POST /partners/me/location/reverse-geocode`

Backs the "Auto-Detect Address via GPS" button and the draggable pin.

```json
{ "latitude": 17.4934, "longitude": 78.3995 }
```

**200**

```json
{
  "data": {
    "locality": "KPHB Colony, Kukatpally",
    "street": "Road No. 3, KPHB Phase 1",
    "city": "Hyderabad",
    "pincode": "500072",
    "formatted": "KPHB Colony, Kukatpally, Hyderabad 500072"
  }
}
```

---

## Partner profile

### `GET /partners/me`

```json
{
  "data": {
    "id": "ptr_1001",
    "owner_name": "Ramesh Kumar",
    "business_name": "Apex Aircon Works",
    "phone": "+919849023114",
    "email": "ramesh.apex@gmail.com",
    "entity_type": "sole_proprietor",
    "city_id": "hyderabad",
    "city_label": "Hyderabad & Secunderabad, Telangana",
    "address": {
      "shop_name": "Apex Aircon Works",
      "street": "Plot 28, Road No. 3, KPHB Phase 1",
      "landmark": "Opposite Metro Pillar 742",
      "pincode": "500072",
      "locality": "KPHB Colony, Kukatpally",
      "city": "Hyderabad",
      "latitude": 17.4934,
      "longitude": 78.3995,
      "service_radius_km": 15
    },
    "category_slug": "ac_repair",
    "specializations": ["Split AC", "Window AC", "Gas Charging", "PCB Diagnostics"],
    "experience_band": "3-5 Years",
    "service_description": "5+ years specializing in multi-brand inverter AC installation...",
    "rating": 4.9,
    "review_count": 142,
    "completion_rate": 98,
    "member_since": "2023-05-01",
    "verification_status": "verified",
    "phone_verified": true,
    "is_online": true,
    "whatsapp_alerts": true,
    "photo_count": 8,
    "active_service_count": 4,
    "referral_credits": 500,
    "language": "English (India)",
    "onboarding": {
      "current_step": 2,
      "completed_steps": [1],
      "total_steps": 4
    }
  }
}
```

`completion_rate` is the percentage of accepted jobs marked complete. `rating` is a one-decimal
average over `review_count` reviews.

### `PATCH /partners/me`

Partial update of any writable field above. Changing `phone` requires a fresh OTP challenge and
returns **409** with code `phone_change_requires_otp` if the number is unverified.

### `PATCH /partners/me/availability`

Backs the Online/Offline pill in the dashboard header. While offline the partner receives no new
lead dispatches.

```json
{ "is_online": false }
```

### `GET` / `PATCH /partners/me/preferences`

```json
{
  "data": {
    "lead_notifications": true,
    "lead_sound": "loud_chime",
    "whatsapp_alerts": true,
    "language": "en-IN"
  }
}
```

---

## Photos

Business photos. One cover and at most five portfolio images, matching the five-slot grid.

### `POST /partners/me/photos`

`multipart/form-data`.

| Field | Type | Notes |
|---|---|---|
| `file` | binary | JPEG, PNG or WebP. Max 5 MB. |
| `kind` | string | `cover` or `portfolio` |
| `slot` | integer | 1-5, portfolio only |
| `caption` | string | Optional, e.g. "AC Unit Repair" |

**201**

```json
{
  "data": {
    "id": "pho_a1",
    "kind": "cover",
    "slot": null,
    "caption": null,
    "url": "https://cdn.infio.app/partners/ptr_1001/pho_a1.jpg",
    "width": 1920,
    "height": 1080,
    "bytes": 2516582,
    "content_type": "image/jpeg",
    "uploaded_at": "2026-10-10T12:04:00+05:30"
  }
}
```

Uploading `kind=cover` when a cover exists replaces it. Uploading to an occupied portfolio slot
replaces that slot. **422** with code `portfolio_full` when all five slots are taken and no slot
is named.

### `GET /partners/me/photos`

Returns the cover and portfolio arrays separately.

### `DELETE /partners/me/photos/{id}`

**204**. Deleting the cover leaves onboarding step 3 incomplete.

---

## KYC

Two independent artefacts, tracked as tasks so the UI can show "0/2 Completed". A live video call
is an alternative to the self-recorded clip.

### `GET /partners/me/kyc`

```json
{
  "data": {
    "status": "in_progress",
    "tasks": [
      { "kind": "aadhaar",        "completed": true,  "submitted_at": "2026-10-10T11:02:00+05:30" },
      { "kind": "business_video", "completed": false, "submitted_at": null }
    ],
    "review_eta": "Usually reviewed within 2 hours by the InFio team",
    "scheduled_call_at": null,
    "rejection_reason": null
  }
}
```

### `POST /partners/me/kyc/aadhaar`

`multipart/form-data` with `front` and `back` binary parts. Both required in one call. Max 5 MB
each. Stored encrypted at rest; never returned in any response body.

### `POST /partners/me/kyc/video`

`multipart/form-data` with a `file` part. MP4 or MOV, maximum 15 seconds, maximum 50 MB. **422**
with code `clip_too_long` beyond the limit.

### `POST /partners/me/kyc/submit`

Moves status to `pending_review`. **409** with code `kyc_incomplete` unless both tasks are done.

### `POST /partners/me/kyc/schedule-call`

```json
{ "preferred_at": "2026-10-12T15:00:00+05:30" }
```

Books the live alternative. Returns the KYC state with `scheduled_call_at` set.

---

## Plans and billing

### Commission

Two different percentages appear in the product and they describe different things.

- **Zero commission on bookings.** The marketplace takes no cut of a completed job. This is the
  headline promise on the landing and plan screens, and it is what `0% Commission` means.
- **10% platform fee on catalogue listings.** The add-service form shows
  `InFio partner commission: 10%` with a live take-home figure. This is the legacy listing fee and
  applies only to jobs booked directly through the in-app catalogue, not to leads the partner
  converts themselves.

Both numbers come from `GET /ref/enums` so the split stays server-controlled.

### `GET /plans`

The catalogue is server-driven. Clients render whatever comes back and never hardcode tiers.

```json
{
  "data": [
    {
      "id": "plan_basic",
      "name": "Basic Starter",
      "eyebrow": "Free Tier",
      "tagline": "Standard profile with basic visibility",
      "monthly_price": 0,
      "annual_monthly_price": 0,
      "is_free": true,
      "is_recommended": false,
      "ribbon_label": null,
      "lead_quota": 5,
      "features": [
        { "text": "customer leads / month", "bold_prefix": "5", "included": true },
        { "text": "Standard directory profile listing", "included": true },
        { "text": "Verified Pro Badge", "included": false }
      ]
    },
    {
      "id": "plan_growth_pro",
      "name": "Growth Pro",
      "eyebrow": "Signature Tier",
      "tagline": "Recommended for solo service pros",
      "monthly_price": 999,
      "annual_monthly_price": 799,
      "is_free": false,
      "is_recommended": true,
      "ribbon_label": "Most Popular",
      "lead_quota": null,
      "features": [
        { "text": "direct customer lead inquiries", "bold_prefix": "Unlimited", "included": true },
        {
          "text": "Verified Pro Trust Badge on search profile",
          "included": true,
          "highlighted": true,
          "badge": "PRO"
        },
        { "text": "on all completed bookings", "bold_prefix": "0% Commission", "included": true }
      ]
    }
  ]
}
```

`lead_quota` of `null` means unlimited. `highlighted` renders the feature in its own tinted row;
`badge` adds a trailing tier chip.

### `GET /partners/me/membership`

```json
{
  "data": {
    "plan_id": "plan_growth_pro",
    "plan_name": "Growth Pro",
    "cycle": "monthly",
    "leads_used": 12,
    "lead_quota": 20,
    "leads_remaining": 8,
    "renews_on": "2026-11-15",
    "is_active": true
  }
}
```

### `POST /checkout/preview`

Returns server-computed totals. **The client never derives these.** Quoting, discounting and GST
all happen here so pricing stays consistent and auditable.

```json
{
  "plan_id": "plan_growth_pro",
  "cycle": "annual",
  "promo_code": "WELCOMEPRO"
}
```

**200**

```json
{
  "data": {
    "plan_id": "plan_growth_pro",
    "cycle": "annual",
    "promo": { "code": "WELCOMEPRO", "discount": 200.00, "description": "Welcome offer" },
    "lines": [
      { "label": "Growth Pro (Annual Access)", "amount": 999.00, "is_discount": false },
      { "label": "Promo Discount",             "amount": -200.00, "is_discount": true },
      { "label": "Statutory GST (18%)",        "amount": 143.82, "is_discount": false }
    ],
    "tax_percent": 18,
    "total": 942.82,
    "currency": "INR"
  }
}
```

GST applies to the post-discount subtotal: `(999 − 200) × 0.18 = 143.82`, giving `942.82`.

### `POST /promo/validate`

```json
{ "code": "WELCOMEPRO" }
```

**200** returns the promo, or `{ "data": null }` when the code is unknown or expired.

### `POST /checkout/orders`

Requires `Idempotency-Key`. Creates a pending order and returns the gateway handoff.

```json
{
  "plan_id": "plan_growth_pro",
  "cycle": "annual",
  "promo_code": "WELCOMEPRO",
  "payment_method": "upi"
}
```

**201**

```json
{
  "data": {
    "order_id": "ord_01HQ8",
    "status": "pending",
    "total": 942.82,
    "currency": "INR",
    "gateway": {
      "provider": "razorpay",
      "order_ref": "order_Nq8vT2",
      "checkout_token": "..."
    }
  }
}
```

### `POST /checkout/orders/{id}/confirm`

Called after the gateway SDK returns. The server verifies the signature with the provider before
activating anything — a client-reported success is never trusted on its own.

```json
{ "gateway_payment_id": "pay_Nq8vT9", "gateway_signature": "9f86d08..." }
```

**200** returns the activated membership. **402** with code `payment_failed` if verification fails.

---

## Leads

The core of the product. A lead is a customer enquiry routed to nearby matching partners.

Leads **expire**. `expires_at` drives the `mm:ss` countdown on the inbox card; once it passes, the
lead moves to `missed` and can no longer be accepted.

The customer's phone number is **withheld until the lead is accepted**. Until then
`customer_phone` is `null` and `contact_revealed` is `false`. The customer's surname is abbreviated
server-side, so the API returns `"John D."` rather than a full name.

### `GET /leads`

| Query | Type | Notes |
|---|---|---|
| `status` | enum | `new`, `contacted`, `missed`, `accepted`, `declined`, `quoted` |
| `urgency` | enum | `urgent`, `standard`, `immediate` |
| `page`, `per_page` | integer | Pagination |

```json
{
  "data": [
    {
      "id": "ld_8924",
      "reference": "LD-8924",
      "customer_name": "John D.",
      "customer_verified": true,
      "customer_phone": null,
      "contact_revealed": false,
      "service_name": "Split AC Repair & Maintenance",
      "category_slug": "ac_repair",
      "description": "Split AC not cooling, need gas refill and filter clean today.",
      "locality": "Kukatpally, Hyderabad",
      "full_address": null,
      "distance_km": 2.3,
      "drive_time": "Approx. 15 mins drive",
      "budget_min": 1200,
      "budget_max": 1200,
      "budget_is_fixed": true,
      "suggested_quote": 1200,
      "preferred_slot": "Today, Evening (5:00 PM - 7:00 PM)",
      "status": "new",
      "urgency": "urgent",
      "created_at": "2026-10-10T17:15:00+05:30",
      "expires_at": "2026-10-10T18:00:00+05:30",
      "photos": [],
      "viewed_by_other_pros": 3,
      "match_rate": "High Match Rate",
      "quoted_amount": null
    }
  ],
  "meta": { "page": 1, "per_page": 20, "total": 12, "total_pages": 1 }
}
```

`full_address` and `photos` are omitted in the list and populated on the detail endpoint, keeping
the list payload small.

### `GET /leads/{id}`

The full record, adding `full_address` and the customer's attached photos.

```json
{
  "data": {
    "id": "ld_8924",
    "full_address": "Kukatpally Housing Board Colony, Phase 2, Hyderabad",
    "photos": [
      { "id": "lph_1", "caption": "Unit 1", "url": "https://cdn.infio.app/leads/ld_8924/1.jpg" },
      { "id": "lph_2", "caption": "Unit 2", "url": "https://cdn.infio.app/leads/ld_8924/2.jpg" }
    ]
  }
}
```

### `GET /leads/summary`

Powers the inbox banner and the filter tab counts.

```json
{
  "data": {
    "today_count": 12,
    "urgent_count": 3,
    "average_response": "4 mins",
    "match_rate": "98%",
    "counts": { "new": 12, "contacted": 5, "missed": 2 }
  }
}
```

### `POST /leads/{id}/accept`

Requires `Idempotency-Key`. Consumes one unit of the monthly quota and reveals the contact number.

**200**

```json
{
  "data": {
    "id": "ld_8924",
    "status": "accepted",
    "contact_revealed": true,
    "customer_phone": "+919876543210"
  }
}
```

| Status | `code` | When |
|---|---|---|
| 409 | `lead_expired` | `expires_at` has passed |
| 409 | `lead_taken` | Another partner has already been assigned |
| 402 | `quota_exhausted` | Monthly lead quota is spent; prompt an upgrade |

### `POST /leads/{id}/decline`

```json
{ "reason": "out_of_area" }
```

`reason` is optional and free-form. Declining does not consume quota.

### `POST /leads/{id}/quote`

```json
{
  "amount": 1200,
  "note": "Can visit by 5:30 PM with genuine refrigerant gas"
}
```

`amount` is in whole rupees with a floor of 100. **422** with code `quote_below_minimum` otherwise.
Moves the lead to `quoted`.

---

## Services

The partner's catalogue.

### `GET /partners/me/services`

Query by `category_slug`, `status`, or a free-text `q`.

```json
{
  "data": [
    {
      "id": "svc_1",
      "name": "Split AC Deep Cleaning / Jet Wash",
      "description": "High-pressure chemical jet wash for indoor & outdoor unit.",
      "category_slug": "ac_repair",
      "category_tag": "AC Repair",
      "sub_type": "Split AC",
      "price": 499,
      "pricing_type": "starting_from",
      "status": "active",
      "commission_percent": 10,
      "duration": "45 mins",
      "turnaround": null,
      "image_url": null,
      "created_at": "2026-08-01T10:00:00+05:30"
    }
  ],
  "meta": { "page": 1, "per_page": 20, "total": 4, "total_pages": 1 }
}
```

### `POST /partners/me/services`

Required: `name`, `category_slug`, `price`, `description`. Optional: `sub_type`, `pricing_type`
(defaults `fixed`), `duration`, `turnaround`, `status` (defaults `active`), `image_url`.

`description` is capped at 500 characters.

### `PATCH /partners/me/services/{id}`

Partial update of any field above.

### `PATCH /partners/me/services/{id}/status`

```json
{ "status": "paused" }
```

Backs the per-card toggle and the "Resume Listing" action.

### `DELETE /partners/me/services/{id}`

**204**. Services referenced by an in-flight booking are soft-deleted.

### `GET` / `PATCH /partners/me/catalog-visibility`

The master switch above the catalogue. Turning it off hides every service at once without
changing individual statuses.

```json
{ "data": { "visible": true } }
```

---

## Dashboard

### `GET /partners/me/dashboard`

One aggregate call so the home screen is a single round trip.

```json
{
  "data": {
    "partner": { "id": "ptr_1001", "owner_name": "Ramesh Kumar", "...": "abbreviated" },
    "membership": {
      "plan_name": "Growth Pro",
      "renews_on": "2026-11-15",
      "leads_used": 12,
      "lead_quota": 20,
      "leads_remaining": 8
    },
    "headline_metrics": {
      "new_leads": 12,
      "new_leads_delta": "+3 today",
      "rating": 4.9
    },
    "quick_actions": {
      "active_service_count": 4,
      "profile_views_delta": "+15% views",
      "review_count": 142
    },
    "recent_leads": [ { "id": "ld_8928", "...": "two most recent new leads" } ]
  }
}
```

---

## Growth

### `GET /partners/me/stats`

`?range=today|this_week|this_month|last_3_months`, defaulting to `this_month`.

```json
{
  "data": {
    "range": "this_month",
    "metrics": [
      { "key": "total_leads",    "label": "Total Leads",    "value": "142", "delta": "+12%" },
      { "key": "profile_views",  "label": "Profile Views",  "value": "890", "delta": "+5%" },
      { "key": "customer_calls", "label": "Customer Calls", "value": "34",  "delta": "92% conn." },
      { "key": "avg_rating",     "label": "Avg Rating",     "value": "4.8", "delta": "Top Rated",
        "suffix": "(142)" }
    ],
    "velocity": {
      "points": [
        { "label": "M", "value": 5,  "is_peak": false },
        { "label": "T", "value": 9,  "is_peak": false },
        { "label": "W", "value": 7,  "is_peak": false },
        { "label": "T", "value": 12, "is_peak": false },
        { "label": "F", "value": 16, "is_peak": true  },
        { "label": "S", "value": 10, "is_peak": false },
        { "label": "S", "value": 6,  "is_peak": false }
      ],
      "total": 65,
      "peak_label": "Peak on Fri",
      "delta_label": "+18%",
      "daily_average": "Avg 9.3 leads/day"
    },
    "activity": [
      {
        "id": "act_1",
        "type": "new_lead",
        "title": "New Lead: John Doe",
        "subtitle": "Plumbing & Leakage Repair",
        "occurred_at": "2026-10-10T15:30:00+05:30"
      }
    ]
  }
}
```

`metrics[].value` and `delta` arrive **pre-formatted as display strings**. The server owns
rounding and unit choice so every client renders identically.

### `GET /partners/me/activity`

The paginated full feed behind "View All Activity". Event types: `new_lead`, `quote_accepted`,
`review_received`.

---

## Referrals, reviews, notifications

### `POST /referrals/validate`

Backs the Apply button beside a referral code, validating before submit rather than at save time.

```json
{ "code": "RAM500" }
```

```json
{
  "data": { "valid": true, "bonus_amount": 500, "message": "₹500 bonus applied" }
}
```

### `GET /partners/me/referrals`

Referral code, credits earned, and the list of referred partners with their status.

### `GET /partners/me/reviews`

Paginated customer reviews: `rating`, `comment`, `customer_name`, `service_name`, `created_at`.

### `GET /notifications`

Paginated, with `?unread_only=true`. Each entry carries `type`, `title`, `body`, `read`,
`created_at`, and a `deep_link` such as `infio://leads/ld_8924`.

### `POST /notifications/{id}/read` and `POST /notifications/read-all`

Marks notifications read. **204**.

---

## Enumerations

The complete vocabulary. Clients should treat unknown values as a safe default rather than
crashing, since the server may add members.

| Enum | Values |
|---|---|
| `otp_channel` | `whatsapp`, `sms` |
| `entity_type` | `sole_proprietor`, `partnership_llp`, `individual` |
| `verification_status` | `unverified`, `pending_admin_approval`, `verified`, `rejected` |
| `kyc_status` | `not_started`, `in_progress`, `pending_review`, `verified`, `rejected` |
| `kyc_task_kind` | `aadhaar`, `business_video` |
| `photo_kind` | `cover`, `portfolio` |
| `lead_status` | `new`, `contacted`, `missed`, `accepted`, `declined`, `quoted` |
| `lead_urgency` | `urgent`, `standard`, `immediate` |
| `service_status` | `active`, `paused`, `draft` |
| `pricing_type` | `fixed`, `starting_from` |
| `billing_cycle` | `monthly`, `annual` |
| `payment_method` | `upi`, `card`, `netbanking_wallet` |
| `order_status` | `pending`, `paid`, `failed`, `refunded` |
| `stats_range` | `today`, `this_week`, `this_month`, `last_3_months` |
| `activity_type` | `new_lead`, `quote_accepted`, `review_received` |

---

## Push notifications

Lead delivery is push-first. A partner who is online should see a new lead within seconds, which
is what the plan's "15-min priority lead dispatch" promises against.

### `POST /devices`

```json
{
  "fcm_token": "dXy...",
  "platform": "ios",
  "app_version": "1.0.0"
}
```

### `DELETE /devices/{fcm_token}`

Unregisters on logout, so a signed-out device stops receiving leads.

### Payloads

Every push carries a `type` and a `deep_link`.

```json
{
  "type": "new_lead",
  "lead_id": "ld_8924",
  "title": "New urgent lead, 2.3 km away",
  "body": "Split AC Repair & Maintenance · ₹1,200",
  "expires_at": "2026-10-10T18:00:00+05:30",
  "deep_link": "infio://leads/ld_8924"
}
```

Other types: `lead_expiring` (fired two minutes before expiry), `quote_accepted`,
`kyc_approved`, `kyc_rejected`, `membership_expiring`, `review_received`.

---

## Webhooks

Inbound, from the payment gateway to Infio. Not called by the mobile app, documented here because
they complete the checkout flow.

### `POST /webhooks/payments`

Verify the provider signature before processing, and treat delivery as at-least-once — handlers
must be idempotent on `gateway_payment_id`.

```json
{
  "event": "payment.captured",
  "order_id": "ord_01HQ8",
  "gateway_payment_id": "pay_Nq8vT9",
  "amount": 942.82,
  "currency": "INR",
  "captured_at": "2026-10-10T12:31:00+05:30"
}
```

Events: `payment.captured`, `payment.failed`, `refund.processed`.

---

## Rate limits

Returned on every response as `X-RateLimit-Limit`, `X-RateLimit-Remaining` and
`X-RateLimit-Reset`. Exceeding a limit returns **429** with `Retry-After` in seconds.

| Scope | Limit |
|---|---|
| `POST /auth/otp/request` | 5 per phone number per hour |
| `POST /auth/otp/resend` | 1 per 60 seconds per challenge, 5 per challenge total |
| `POST /auth/otp/verify` | 10 attempts per challenge, then the challenge is burned |
| `POST /promo/validate` | 20 per minute |
| Uploads (photos, KYC) | 30 per hour |
| Everything else | 120 per minute per partner |

---

## Out of scope

The design folder contains one consumer-side screen, the **InFio SEARCH** signup. It belongs to
the customer-facing app, not the partner one, and its endpoints live in a separate consumer
service that this document does not cover. The partner app ships the screen only as a navigational
stub.

Likewise, admin review tooling (approving KYC, moderating catalogues) is a back-office concern and
is not part of this contract.
