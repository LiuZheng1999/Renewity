# Privacy Policy

**Effective date: August 20, 2026**

Renewity (the “App”) is provided by the developer of the App (“we”, “us”, or “our”). This policy explains how the App handles information about you.

The App is designed so that **subscription records stay on your device by default**. We do not run a sign-in server for the App, and we do not collect personal information through the App for advertising or profiling.

A web copy matching the in-app text is published on GitHub Pages:  
**https://liuzheng1999.github.io/Renewity/privacy/**

Questions: **philiptrip1975@gmail.com**

## 1. What we do not collect through the App

Except as described below, we do not ask you to create an account with us, and we do not upload the following to servers we control:

- your name or email address (unless you email us);
- the subscription names, amounts, dates, categories, payment methods, and notes you enter;
- advertising identifiers or analytics SDK data used to track you across other apps or websites.

The App **does not include third-party ad SDKs, does not use App Tracking Transparency for cross-app tracking, and does not use analytics tools to build a marketing profile**. The App includes Apple’s required Privacy Manifest and declares that it does not track you.

## 2. Information stored on your device

Subscriptions, categories, payment methods, notes, icon choices, display currency, billing currency, appearance, notification settings, App Lock, and similar preferences are stored **on device** using Apple’s SwiftData / UserDefaults / system storage.

This information is used to:

- show and manage subscriptions in the App;
- estimate monthly and yearly spend and category totals using reference exchange rates;
- schedule several upcoming local notifications for renewal and trial reminders, based on the lead times you choose;

Uninstalling the App typically deletes data that exists only on the device and has not been saved somewhere you chose (such as the Files app or iCloud Drive).

## 3. iCloud sync and backup

If you are signed in to iCloud, the App can sync subscriptions, custom categories, payment methods, appearance, reminder time, display currency, and your profile photo through **CloudKit’s private database** (container `iCloud.Maoxia-Xiang.Renewity`) across your devices. Apple processes this under your Apple Account. We cannot sign in to read it.

If you have Pro and turn on iCloud backup, the App also writes a JSON copy to **your** iCloud Drive (same container) so you can restore manually. That file can include subscriptions, custom categories, payment methods, appearance, reminder time, and your profile photo.

- It is stored under your Apple Account and handled by Apple under Apple’s iCloud policies.
- We cannot sign in to your Apple Account to read that backup.
- You can turn off automatic backup in the App or manage iCloud in system settings.

You may also export a JSON backup to Files, a computer, or another location you choose. You are responsible for copies you export.

## 4. Notifications

Renewal and trial reminders use **local notifications**. Notification content is created on device from information you already stored locally (such as a name and amount). It is **not** uploaded to our servers in order to send the reminder.

The system limits how many pending local notifications an app may hold. The App schedules several future reminders in advance and refreshes that queue when you open the App. If you do not open the App for a long time, later reminders may stop until the App runs again. Delivery also depends on notification permission, Low Power Mode, Focus, and similar system settings.

## 5. Face ID, Touch ID, and passcode

If you enable App Lock, the App uses LocalAuthentication so that returning to the App requires you to authenticate. Biometric templates are stored by the operating system in the device’s secure area. **We do not collect or upload Face ID or fingerprint data.** If authentication fails, the App stays locked.

The system shows a purpose string: to unlock Renewity and protect your subscription data.

## 6. Purchases and Apple Account

Monthly, yearly, or lifetime Pro purchases go through StoreKit / the App Store. Apple processes payment and receipts. We may learn on device whether you have an active purchase (so Pro features can unlock). We **do not** receive your full card number or Apple Account password.

Refunds and cancellation of auto-renewing subscriptions follow Apple’s rules.

## 7. Network requests when you use certain features

The App may use the internet in the situations below. Your device talks to the relevant service **directly**, not to a user database we operate. Those providers may process technical logs (which can include IP address, time, and device/technical data) under their own policies.

### 7.1 Exchange-rate estimates

Overview totals and category totals may convert amounts from each subscription’s billing currency into your display currency using reference rates. The App may request USD-based rates from a public API (currently `open.er-api.com`). That figure is an estimate only, not an offer to exchange currency.

### 7.2 Service search and icons

When you search in “Choose a service”, the App may query:

- Apple’s App Store / iTunes Search API;
- public company-domain lookup services (such as Clearbit-related endpoints);
- third-party CDNs that serve public site icons (such as icon.horse, unavatar.io, or favicone.com, depending on what the App requests at the time).

**The keywords or domain names you type** may be sent to those services. Do not enter passwords, card numbers, or other sensitive personal data in the search field.

A third-party app or website appearing in results is not a review, endorsement, or affiliation. You decide whether to add it.

### 7.3 iCloud

When cloud backup is on, Apple syncs the file under Apple’s Privacy Policy.

## 8. Information you send us

If you use the in-app email links (bug report, support, feedback, or feature request), your message goes to **philiptrip1975@gmail.com**. You may include device or version details you choose to add. We use this only to respond and handle your request, and we delete it when it is no longer needed unless the law requires us to keep it.

## 9. Analytics, advertising, and tracking

- The App does not include third-party ads.
- The App does not use analytics SDKs to build a marketing profile from your subscription data.
- The App does not track you across other companies’ apps and does not request the “Allow Tracking” permission.

The operating system may send diagnostics or App Store statistics to Apple if you allow that. That is part of Apple’s products and is governed by Apple’s policies, not additional collection by us.

## 10. Children

The App is a personal finance recorder and is not directed at children under 13. We do not knowingly collect personal information from children under 13. If you believe we have received such information in error, contact us and we will delete what is within our control.

## 11. Retention, export, and deletion

- **On-device data:** deleted when you delete it in the App or uninstall (apart from ordinary system caches).
- **iCloud backup:** kept with your Apple Account until you overwrite it in the App, delete it in iCloud Drive, or turn off the relevant iCloud features.
- **Exported JSON:** retained wherever you saved it.

You can manage data by deleting subscriptions or custom categories, restoring a backup, exporting and then uninstalling, or deleting the iCloud backup file.

## 12. Security

We use safeguards that match this product: on-device storage by default, optional App Lock, and Apple’s purchase and iCloud channels for paid features and backup. No electronic or cloud storage is perfectly secure. Use a device passcode and protect your Apple Account.

## 13. Your rights

Depending on where you live (for example if GDPR, CCPA, or similar laws apply), you may have rights to access, correct, delete, export, restrict, or object to processing of personal information about you.

Because records mainly live on your device or in your iCloud, you can usually exercise these rights in the App or system settings. For email you sent to support, email us and we will respond within the time the law requires.

## 14. International processing

Exchange-rate, search, and icon requests may be handled in other countries. Apple processes purchases and iCloud under its policies. If you are in the EEA, the UK, or another region with cross-border rules, using those optional online features means you understand that related data may be processed accordingly.

## 15. Changes

We may update this policy. The new version will appear in the App and on the GitHub Pages site above, with a revised effective date. If a change materially affects your rights, we will provide a reasonable notice in the App. Continued use after the change means you are aware of the updated policy.

## 16. Contact

Privacy requests: **philiptrip1975@gmail.com**

Web: https://liuzheng1999.github.io/Renewity/privacy/

Please include “Privacy Policy” in the subject line.
