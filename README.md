# aquacatch

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Mobile email confirmation

Add `aquacatch://auth-callback` to Supabase **Authentication → URL Configuration
→ Redirect URLs**. Apply `supabase_email_confirmation_profile.sql` in the
Supabase SQL Editor so email-confirmed Buyer and Fisherman registrations get a
pending `public.users` profile for Port Admin review. Then rebuild and reinstall
the app so Android and iOS recognize the deep link. Web signups redirect to the
current web origin, which must also be included in Supabase's redirect allowlist.

Open a confirmation link created by a mobile signup on the mobile device. It
redirects through the `aquacatch://auth-callback` Android deep link and will not
render a page when opened in desktop Chrome. For browser signups, start the
Flutter web app first and open the email link in that browser; add its exact
origin (for example `http://localhost:8082`) to the Supabase redirect allowlist.
The app shows a **Verify Your Email** screen with a resend action, blocks
unconfirmed email accounts at login, and preserves the separate Port Admin
approval gate after email confirmation.

The login screen's **Forgot Password?** link sends a Supabase recovery email.
Recovery links return through the same web origin or mobile deep link and open
the in-app **Reset Password** screen.

## BFAR reminders

The fisherman catch form, buyer inventory, and Port Admin landing panel display
offline, informational BFAR reminders. The Super Admin dashboard provides a
static regulations reference. These screens do not determine legal compliance,
automatically flag catches, or replace current BFAR Fisheries Administrative
Orders and local guidance. The reference text is a general summary; verify
current rules with the appropriate authorities.

## Super Admin: inviting Port Admins

Run `supabase/port_admin_provisioning.sql` in the Supabase SQL Editor, then
deploy the `invite-port-admin` Edge Function with
`supabase functions deploy invite-port-admin`. The function requires the caller
to have a verified `Super_Admin` profile. It invites the new administrator by
email, creates an approved `Port_Admin` profile, and never handles or returns a
password. Configure Supabase Auth email delivery and the Site URL/redirect
settings so invitation links reach the intended AquaCatch web portal.

## Secure live auctions

Fish listing thumbnails use the optional `public.catch_logs.image_url` column.
Run `supabase/catch_image_support.sql` before populating image URLs. Listings
show a local placeholder when no image is available or an image cannot load.

Run `supabase/buyer_marketplace_read_policy.sql` and then
`supabase/buyer_retail_purchase_policy.sql` in the Supabase SQL Editor so
verified Buyer accounts can read Direct Selling marketplace rows and initiate
their own retail purchases under RLS. Retail `base_price` values are treated
as PHP per kg. Each retail order reserves its selected quantity; the remaining
quantity stays listed. The reservation expires after 30 minutes if payment is
still pending; the migration adds the `expired` payment status used to release
that reservation. Pending orders can also be cancelled by the Buyer or rejected
by Port Admin to release the reservation. Auction purchases remain whole-lot.
Then run `supabase/auction_management.sql` before using
the dedicated **Live Auctions** Port Admin tab. Deploy the Edge Functions
`submit-auction-bid`, `start-auction`, `resolve-auction`, and `stop-auction` from
`supabase/functions/`. Configure `AUCTION_BID_ENCRYPTION_KEY` as a Supabase
Edge Function secret containing the Base64 encoding of 32 cryptographically
random bytes; do not put this key in Flutter, SQL, or source control.

The Edge Function secret can be generated in a secure terminal, then configured
with `supabase secrets set AUCTION_BID_ENCRYPTION_KEY=<base64-secret>`. Never
paste the generated value into source code or chat. Existing auctions without
an `auction_ends_at` deadline are legacy auctions: restart them from the Live
Auctions panel to start a fresh 15-minute window. Legacy client-encrypted bids
are not accepted for winner selection. Winners are resolved server-side and receive a pending transaction; the buyer
chooses Cash, GCash, or Maya in Transactions before the payment appears in
Admin Payments for verification.
Run `supabase/payment_proofs_storage.sql` in the Supabase SQL Editor to create
the private bucket used for optional payment screenshots. The script is
idempotent and can be safely rerun.

The secure bid function updates the shared current-highest-bid value and the
three-minute inactivity timestamp after each accepted bid. Buyers and
Fishermen see the amount only; Port Admins also see bidder names. Port Admins
can stop an active auction immediately without a winner, or end it early and
declare the highest valid bid. Normal winner resolution still waits for the
inactivity window or the original 15-minute deadline.
