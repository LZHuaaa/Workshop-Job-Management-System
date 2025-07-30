# Firestore Security Rules Template

## 🔒 Current Production Rules (Copy to Firebase Console)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // USER PROFILES - Users can only access their own profile
    match /user_profiles/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // EXISTING APP COLLECTIONS - All authenticated users can read/write
    match /vehicles/{document} {
      allow read, write: if request.auth != null;
    }
    match /inventory/{document} {
      allow read, write: if request.auth != null;
    }
    match /inventory_usage/{document} {
      allow read, write: if request.auth != null;
    }
    match /customers/{document} {
      allow read, write: if request.auth != null;
    }
    match /service_records/{document} {
      allow read, write: if request.auth != null;
    }
    match /job_appointments/{document} {
      allow read, write: if request.auth != null;
    }
    match /appointments/{document} {
      allow read, write: if request.auth != null;
    }
    match /invoices/{document} {
      allow read, write: if request.auth != null;
    }
    match /order_requests/{document} {
      allow read, write: if request.auth != null;
    }
    
    // FUTURE COLLECTIONS - Add new collections here
    // match /new_collection_name/{document} {
    //   allow read, write: if request.auth != null;
    // }
    
    // FALLBACK RULE - For any collections not explicitly defined above
    // This allows authenticated users to access any collection
    // Remove this if you want stricter control
    match /{document=**} {
      allow read: if request.auth != null;
      // Uncomment the line below to allow write access to all collections
      // allow write: if request.auth != null;
    }
  }
}
```

## 📋 When to Update Rules

### **✅ Always Update Rules When:**
1. Adding a new collection to your app
2. Changing access patterns (who can read/write)
3. Adding user-specific data that needs privacy protection
4. Implementing admin-only collections

### **⚠️ Rule Update Process:**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **pinkdrive-21122**
3. Navigate to **Firestore Database > Rules**
4. Update the rules with new collection patterns
5. Click **"Publish"** to apply changes
6. Test the new collection access in your app

## 🔐 Security Best Practices

### **Collection-Specific Rules (Recommended):**
```javascript
// Example: Admin-only collection
match /admin_settings/{document} {
  allow read, write: if request.auth != null && 
    request.auth.token.admin == true;
}

// Example: User-specific data
match /user_data/{userId} {
  allow read, write: if request.auth != null && 
    request.auth.uid == userId;
}

// Example: Read-only reference data
match /reference_data/{document} {
  allow read: if request.auth != null;
  allow write: if false; // No one can write
}
```

### **Common Rule Patterns:**

#### **1. Public Read, Auth Write:**
```javascript
match /public_data/{document} {
  allow read: if true;
  allow write: if request.auth != null;
}
```

#### **2. Owner-Only Access:**
```javascript
match /private_data/{document} {
  allow read, write: if request.auth != null && 
    request.auth.uid == resource.data.ownerId;
}
```

#### **3. Role-Based Access:**
```javascript
match /admin_data/{document} {
  allow read, write: if request.auth != null && 
    request.auth.token.role == 'admin';
}
```

## 🚨 Important Notes

### **Rule Priority:**
- More specific rules take precedence over general rules
- Rules are NOT filters - they're permissions
- If any rule allows access, the operation succeeds

### **Testing Rules:**
1. Use Firebase Console Rules Playground
2. Test with different user authentication states
3. Verify both read and write operations
4. Test edge cases (unauthenticated users, etc.)

### **Common Mistakes to Avoid:**
- ❌ Forgetting to add rules for new collections
- ❌ Using overly permissive wildcard rules
- ❌ Not testing rules after updates
- ❌ Mixing up `resource.data` vs `request.resource.data`

## 📝 Rule Update Checklist

When adding a new collection:

- [ ] Identify the collection name
- [ ] Determine who should have read access
- [ ] Determine who should have write access
- [ ] Add specific rule to Firestore Rules
- [ ] Test the rule in Firebase Console
- [ ] Publish the updated rules
- [ ] Test in your app
- [ ] Document the new collection in this file

## 🔄 Quick Reference

### **Current Collections in Your App:**
- `user_profiles` - User-specific access only
- `vehicles` - All authenticated users
- `inventory` - All authenticated users  
- `inventory_usage` - All authenticated users
- `customers` - All authenticated users
- `service_records` - All authenticated users
- `job_appointments` - All authenticated users
- `appointments` - All authenticated users
- `invoices` - All authenticated users
- `order_requests` - All authenticated users

### **To Add New Collection:**
1. Copy this template rule:
```javascript
match /YOUR_COLLECTION_NAME/{document} {
  allow read, write: if request.auth != null;
}
```
2. Replace `YOUR_COLLECTION_NAME` with actual name
3. Adjust permissions as needed
4. Add to Firebase Console Rules
5. Publish changes
