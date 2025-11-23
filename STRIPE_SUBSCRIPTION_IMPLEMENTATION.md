# Stripe Subscription Implementation Guide

## Overview
This document describes the Stripe payment integration for vet/sitter subscriptions in the iOS app. The implementation follows the scenario where owners must pay $30/month to become vets or sitters, with email verification required after payment.

## Implementation Summary

### 1. **Subscription Models** (`SubscriptionModels.swift`)
- `Subscription` model with status, dates, and Stripe IDs
- `SubscriptionStatus` enum (active, canceled, expired, pending, none)
- Request/Response models for API communication

### 2. **Services Created**

#### `SubscriptionService.swift`
Handles all subscription-related API calls:
- `createSubscription(role:accessToken:)` - Creates a new subscription
- `getSubscription(accessToken:)` - Gets user's current subscription
- `cancelSubscription(accessToken:)` - Cancels subscription (at period end)
- `reactivateSubscription(accessToken:)` - Reactivates canceled subscription
- `checkSubscriptionStatus(_:)` - Checks subscription validity

#### `StripeService.swift`
Placeholder for Stripe SDK integration (to be completed when Stripe SDK is added)

### 3. **User Model Updates**
- Added `subscription: Subscription?` field to `AppUser`
- Updated encoding/decoding to handle subscription data
- Updated `mergedUser` in `SessionManager` to preserve subscription info

### 4. **Payment Flow**

#### `PaymentView.swift`
- Displays subscription pricing ($30/month)
- Shows benefits of subscribing
- Processes payment through backend
- Shows success/error messages

#### Integration in Join Views
- `JoinVetView` and `JoinPetSitterView` now show payment screen before conversion
- Payment is required for existing users converting to vet/sitter
- After payment, form submission proceeds normally

### 5. **Email Verification Integration**
- After email verification, subscription is activated (via backend webhook)
- `SessionManager.verifyEmail()` now checks for pending subscriptions
- User role is upgraded after verification

### 6. **Subscription Management**

#### `SubscriptionManagementView.swift`
- View subscription status and details
- Cancel subscription (with confirmation)
- Reactivate canceled subscription
- Renew expired subscription
- Shows expiration warnings

#### Profile Integration
- Added "Subscription" option in ProfileView settings (for vets/sitters only)
- Links to `SubscriptionManagementView`

### 7. **Expiration Handling**

#### `SubscriptionManager.swift`
- Periodic subscription status checking (every hour)
- Alerts when subscription is expiring soon (within 7 days)
- Alerts when subscription has expired
- Auto-downgrades role when subscription expires

## Backend API Requirements

The backend must implement the following endpoints:

### 1. **POST /subscriptions**
Creates a new subscription for the user.

**Request:**
```json
{
  "role": "vet" | "sitter",
  "paymentMethodId": "pm_xxx" // Optional for test mode
}
```

**Response:**
```json
{
  "subscription": {
    "id": "sub_xxx",
    "userId": "user_xxx",
    "role": "vet",
    "status": "pending",
    "stripeSubscriptionId": "sub_xxx",
    "stripeCustomerId": "cus_xxx",
    "currentPeriodStart": "2025-01-01T00:00:00Z",
    "currentPeriodEnd": "2025-02-01T00:00:00Z",
    "cancelAtPeriodEnd": false,
    "createdAt": "2025-01-01T00:00:00Z",
    "updatedAt": "2025-01-01T00:00:00Z"
  },
  "clientSecret": "pi_xxx_secret_xxx", // For Stripe PaymentSheet (optional)
  "message": "Subscription created successfully"
}
```

**Notes:**
- In test mode, you can create subscription without actual payment
- Set status to "pending" initially
- After email verification, activate subscription (status = "active")
- Create Stripe customer and subscription on backend

### 2. **GET /subscriptions/me**
Gets the current user's subscription.

**Response:**
```json
{
  "id": "sub_xxx",
  "userId": "user_xxx",
  "role": "vet",
  "status": "active",
  "stripeSubscriptionId": "sub_xxx",
  "stripeCustomerId": "cus_xxx",
  "currentPeriodStart": "2025-01-01T00:00:00Z",
  "currentPeriodEnd": "2025-02-01T00:00:00Z",
  "cancelAtPeriodEnd": false,
  "createdAt": "2025-01-01T00:00:00Z",
  "updatedAt": "2025-01-01T00:00:00Z"
}
```

### 3. **POST /subscriptions/cancel**
Cancels the user's subscription (at period end).

**Response:**
```json
{
  "subscription": { /* updated subscription */ },
  "message": "Subscription will be canceled at period end"
}
```

**Notes:**
- Set `cancelAtPeriodEnd: true`
- Subscription remains active until `currentPeriodEnd`
- After period ends, downgrade role to "owner" and set status to "canceled"

### 4. **POST /subscriptions/reactivate**
Reactivates a canceled subscription.

**Response:**
```json
{
  "id": "sub_xxx",
  "status": "active",
  "cancelAtPeriodEnd": false,
  /* ... other fields ... */
}
```

### 5. **Webhook Endpoints** (Stripe)
The backend must handle these Stripe webhooks:

- `customer.subscription.created` - Set subscription status to "active"
- `customer.subscription.updated` - Update subscription details
- `customer.subscription.deleted` - Set status to "expired", downgrade role to "owner"
- `invoice.payment_succeeded` - Ensure subscription remains active
- `invoice.payment_failed` - Handle payment failures

## Flow Diagram

### Subscription Flow
1. User clicks "Join as Vet/Sitter"
2. User fills form
3. **Payment Screen** appears (for existing users)
4. User pays $30/month (test mode)
5. Subscription created with status "pending"
6. User receives email verification
7. User verifies email
8. **Backend activates subscription** (status = "active")
9. User role upgraded to "vet" or "sitter"
10. User appears in discover list and map

### Cancellation Flow
1. User goes to Profile → Subscription
2. User clicks "Cancel Subscription"
3. Confirmation dialog appears
4. User confirms
5. Backend sets `cancelAtPeriodEnd: true`
6. Subscription remains active until period end
7. At period end, backend:
   - Sets status to "canceled"
   - Downgrades role to "owner"
   - User disappears from discover list/map

### Expiration Flow
1. Subscription expires (currentPeriodEnd passed)
2. Backend webhook or scheduled job:
   - Sets status to "expired"
   - Downgrades role to "owner"
   - User disappears from discover list/map
3. App shows expiration alert
4. User can renew subscription

### Renewal Alert Flow
1. Subscription expiring soon (within 7 days)
2. App checks subscription status periodically
3. Alert shown: "Your subscription expires in X days"
4. User can renew immediately

## Testing Checklist

### Test Mode Setup
1. Use Stripe test API keys
2. Use test card numbers (e.g., `4242 4242 4242 4242`)
3. Verify no real charges are made

### Test Scenarios
- [ ] New user joins as vet (payment → verification → activation)
- [ ] Existing owner converts to vet (payment → verification → activation)
- [ ] User cancels subscription (remains active until period end)
- [ ] User reactivates canceled subscription
- [ ] Subscription expires (role downgrades automatically)
- [ ] Expiration alert appears (within 7 days)
- [ ] User renews expired subscription
- [ ] Subscription appears in ProfileView for vets/sitters
- [ ] User disappears from discover list after cancellation/expiration
- [ ] User reappears after renewal

## Next Steps

1. **Add Stripe SDK** (when ready for production):
   - Add Stripe iOS SDK via Swift Package Manager
   - Update `StripeService.swift` to use PaymentSheet
   - Update `PaymentView.swift` to present PaymentSheet

2. **Backend Implementation**:
   - Implement all subscription endpoints
   - Set up Stripe webhooks
   - Handle subscription lifecycle (create, activate, cancel, expire)
   - Update user role based on subscription status

3. **Testing**:
   - Test all flows in test mode
   - Verify email verification activates subscription
   - Test expiration and cancellation
   - Test role downgrade/upgrade

## Important Notes

- **Test Mode**: Currently, payment is simulated. Real Stripe integration requires adding Stripe SDK.
- **Email Verification**: Subscription activation happens after email verification (backend webhook).
- **Role Management**: Backend must handle role upgrades/downgrades based on subscription status.
- **Visibility**: Users with active subscriptions appear in discover list/map. Canceled/expired users do not.
- **Period End**: Cancellations take effect at period end, not immediately.

## API Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/subscriptions` | Create subscription |
| GET | `/subscriptions/me` | Get user's subscription |
| POST | `/subscriptions/cancel` | Cancel subscription |
| POST | `/subscriptions/reactivate` | Reactivate subscription |

## Environment Variables

For test mode, ensure backend uses Stripe test keys:
- `STRIPE_SECRET_KEY_TEST`
- `STRIPE_PUBLISHABLE_KEY_TEST`

For production:
- `STRIPE_SECRET_KEY`
- `STRIPE_PUBLISHABLE_KEY`

