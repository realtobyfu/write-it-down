# App Store Connect Setup Guide for Ecrivez-local (Write-It-Down)

## Prerequisites
- [ ] Apple Developer Account ($99/year)
- [ ] App Bundle ID: `com.tobiasfu.write-it-down`
- [ ] Xcode with valid signing certificates
- [ ] App icons in all required sizes
- [ ] Screenshots for all supported devices

## Step 1: Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform**: iOS
   - **App Name**: Write-It-Down (or your preferred name)
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: Select `com.tobiasfu.write-it-down`
   - **SKU**: `WRITEITDOWN001` (or similar unique identifier)
   - **User Access**: Full Access

## Step 2: App Information

### General Information
- **Category**: 
  - Primary: Productivity
  - Secondary: Lifestyle
- **Content Rights**: Check if you own all rights
- **Age Rating**: Complete questionnaire
  - No objectionable content
  - No unrestricted web access
  - No gambling
  - Result: 4+

### Privacy Policy
- **Privacy Policy URL**: Required (host on your website)
- **Privacy Choices URL**: Optional (if you collect data)

Example Privacy Policy should cover:
- What data is collected (notes, location, email for auth)
- How data is used (sync, authentication)
- Data storage (local Core Data, Supabase cloud)
- User rights (deletion, export)

## Step 3: Pricing and Availability

1. **Price**: Free (since you have in-app purchases)
2. **Availability**: Select all countries/regions
3. **Pre-Orders**: Not available (optional)

## Step 4: In-App Purchases Setup

### Create Subscription Group
1. Go to "In-App Purchases" → "Manage"
2. Create Subscription Group: "Premium Features"

### Add Subscriptions
1. **Monthly Premium**
   - Reference Name: Premium Monthly
   - Product ID: `com.tobiasfu.write-it-down.premium.monthly`
   - Duration: 1 Month
   - Price: $4.99 (Tier 5)

2. **Yearly Premium**  
   - Reference Name: Premium Yearly
   - Product ID: `com.tobiasfu.write-it-down.premium.yearly`
   - Duration: 1 Year
   - Price: $39.99 (Tier 40)
   - Free Trial: 7 days (optional)

### Add Non-Consumables
1. **Lifetime Pro**
   - Reference Name: Lifetime Pro
   - Product ID: `com.tobiasfu.write-it-down.lifetime`
   - Price: $99.99 (Tier 100)

### Localization for Each IAP
- Display Name
- Description
- Add review screenshot (1024x1024)

## Step 5: App Version Information

### Version Information
- **Version Number**: 1.0.0
- **Copyright**: © 2024 Tobias Fu
- **Trade Representative Contact**: Your contact info

### Description
```
Write-It-Down is a beautiful, intuitive note-taking app that combines rich text editing with location-based memories. 

Key Features:
• Rich text formatting with images
• Location tagging for your memories
• Weather tracking
• Public note sharing
• Anonymous posting option
• Beautiful, customizable themes
• Secure cloud sync
• Categories for organization
```

### Keywords
```
notes,journal,diary,location,memories,writing,sync,private,markdown,rich text
```

### Support Information
- **Support URL**: Your website/support page
- **Marketing URL**: Optional

## Step 6: Screenshots & App Preview

### Required Screenshots
Upload for these device sizes:
- **6.9" Display** (iPhone 16 Pro Max): 1320 x 2868 pixels
- **6.5" Display** (iPhone 11 Pro Max): 1284 x 2778 pixels  
- **5.5" Display** (iPhone 8 Plus): 1242 x 2208 pixels
- **12.9" Display** (iPad Pro): 2048 x 2732 pixels

### Screenshot Guidelines
1. Show app in actual use
2. Include captions highlighting features
3. Show premium features
4. Include diverse content examples

### App Preview Video (Optional)
- 15-30 seconds
- Show key features in action
- No outside graphics/text

## Step 7: Test Information

### Test Account
Provide for App Review:
- Email: test@example.com
- Password: [secure password]
- Demo content pre-loaded

### Review Notes
```
This app requires authentication for public note sharing features.
Test credentials are provided above.
Location permissions are optional but enhance the experience.
Premium features can be tested with sandbox account.
```

## Step 8: App Review Preparation

### Before Submission
- [ ] Test on all device sizes
- [ ] Verify all IAPs work in sandbox
- [ ] Check for crashes
- [ ] Remove any test/debug code
- [ ] Update version/build numbers
- [ ] Archive and validate in Xcode

### Common Rejection Reasons to Avoid
1. **Crashes**: Test thoroughly
2. **Broken features**: Ensure all features work
3. **IAP issues**: Clear value proposition for premium
4. **Privacy**: Must have privacy policy
5. **Sign in with Apple**: Required if you have other auth
6. **Placeholder content**: Remove Lorem Ipsum

## Step 9: Submit for Review

1. Click "Submit for Review"
2. Answer export compliance (usually No)
3. Select manual or automatic release
4. Submit

### Review Timeline
- Initial review: 24-48 hours typically
- If rejected: Address issues and resubmit
- Appeals: Use Resolution Center if needed

## Step 10: Post-Launch

### After Approval
1. **Monitor**:
   - Crash reports in Xcode
   - Customer reviews
   - Analytics

2. **Respond**:
   - Reply to reviews
   - Fix critical bugs quickly
   - Plan feature updates

3. **Marketing**:
   - Update website
   - Social media announcement
   - Press kit if needed

### Version Updates
- Bug fixes: 1.0.1, 1.0.2
- Minor features: 1.1.0, 1.2.0
- Major updates: 2.0.0

## App Store Optimization (ASO)

### Tips for Better Visibility
1. Use all keyword characters (100)
2. Include keywords in title/subtitle
3. Get positive reviews (4.5+ rating)
4. Regular updates (monthly)
5. Localize for major markets

### Monitoring Tools
- App Store Connect Analytics
- Third-party ASO tools
- Competitor analysis

## Revenue Tracking

### Financial Reports
- Check monthly in App Store Connect
- Track subscriber retention
- Monitor conversion rates
- Plan promotional offers

### Tax Information
- Complete all tax forms
- Set up banking information
- Understand regional requirements

## Important Links

- [App Store Connect](https://appstoreconnect.apple.com)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)

## Checklist Summary

- [ ] Create app record
- [ ] Set up IAPs
- [ ] Upload screenshots
- [ ] Write descriptions
- [ ] Add keywords
- [ ] Privacy policy URL
- [ ] Test account info
- [ ] Build and archive
- [ ] Submit for review
- [ ] Monitor and respond

Remember: Take your time with each step. A well-prepared submission is more likely to be approved on the first try.