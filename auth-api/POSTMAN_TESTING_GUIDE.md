# 🔐 Cryptography Visualizer Auth API - Postman Testing Guide

## ⚙️ Setup Instructions

### 1. Install Node.js
- Download from: https://nodejs.org/ (v14 or higher)
- Verify installation:
  ```bash
  node --version
  npm --version
  ```

### 2. Navigate to the API folder and Install Dependencies
```bash
cd auth-api
npm install
```

### 3. Create `.env` file
Copy the `.env.example` to `.env`:
```bash
cp .env.example .env
```

Or create manually with:
```
PORT=3000
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production
NODE_ENV=development
```

### 4. Start the Server
```bash
npm start
```

Or with auto-reload (requires nodemon):
```bash
npm run dev
```

You should see:
```
🚀 Server running at: http://localhost:3000
📝 Ready for Postman Testing!
```

---

## 🧪 Postman API Requests

### 1. ✅ Health Check (GET)
**Verify API is running**

```
GET http://localhost:3000/api/health
```

**Response:**
```json
{
  "status": "success",
  "message": "API is running",
  "timestamp": "2026-03-31T10:30:00.000Z"
}
```

---

### 2. 📝 Signup (POST)
**Register a new user**

```
POST http://localhost:3000/api/auth/signup
Content-Type: application/json
```

**Request Body:**
```json
{
  "fullName": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "confirmPassword": "password123"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Registration successful",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "fullName": "John Doe",
    "email": "john@example.com",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "createdAt": "2026-03-31T10:30:00.000Z"
  }
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "Email is already registered"
}
```

---

### 3. 🔑 Login (POST)
**Login with existing account**

```
POST http://localhost:3000/api/auth/login
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "fullName": "John Doe",
    "email": "john@example.com",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "lastSignIn": "2026-03-31T10:35:00.000Z"
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Incorrect password"
}
```

---

### 4. 👤 Get User Profile (GET)
**Retrieve logged-in user's profile (Protected)**

```
GET http://localhost:3000/api/auth/profile
Authorization: Bearer {TOKEN}
Content-Type: application/json
```

**Replace `{TOKEN}` with the token from login/signup response**

**Example:**
```
GET http://localhost:3000/api/auth/profile
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "fullName": "John Doe",
    "email": "john@example.com",
    "createdAt": "2026-03-31T10:30:00.000Z"
  }
}
```

---

### 5. ✏️ Update Profile (PUT)
**Update user profile information (Protected)**

```
PUT http://localhost:3000/api/auth/profile
Authorization: Bearer {TOKEN}
Content-Type: application/json
```

**Request Body:**
```json
{
  "fullName": "Jane Doe"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "data": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "fullName": "Jane Doe",
    "email": "john@example.com"
  }
}
```

---

### 6. 🚪 Logout (POST)
**Logout user (Optional)**

```
POST http://localhost:3000/api/auth/logout
Content-Type: application/json
```

**Response (200):**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

---

## 📋 Postman Quick Setup

### How to Import Entire Collection:

1. **Download the collection file:**
   - [POSTMAN_COLLECTION.json](./POSTMAN_COLLECTION.json)

2. **In Postman:**
   - Click **Import** (top-left)
   - Select the JSON file
   - All requests will be imported automatically

---

## 🧪 Test Scenarios

### Scenario 1: Complete User Flow
1. ✅ Health Check
2. 📝 Signup (new user)
3. 🔑 Login (with same user)
4. 👤 Get Profile (using token from login)
5. ✏️ Update Profile
6. 🚪 Logout

### Scenario 2: Error Handling
- Signup with existing email → Should fail (409)
- Signup with short password → Should fail (400)
- Login with wrong password → Should fail (401)
- Access protected route without token → Should fail (401)
- Access profile with invalid token → Should fail (403)

---

## 🔒 Security Features

✅ **Password Hashing** - Using bcryptjs (10 salt rounds)
✅ **JWT Authentication** - 7-day expiration
✅ **Email Validation** - Format checking
✅ **Token-Based Access** - Protected routes require Bearer token

---

## 📊 Database (In-Memory)

Currently using **in-memory storage** (data resets when server restarts).

For production, integrate:
- **MongoDB** (NoSQL)
- **PostgreSQL** (SQL)
- **Firebase Firestore**

---

## 🆘 Troubleshooting

### Port Already in Use
```bash
# Kill process on port 3000 (Windows)
netstat -ano | findstr :3000
taskkill /PID <PID> /F

# Or change PORT in .env file
PORT=3001
```

### Module Not Found
```bash
# Reinstall dependencies
rm -rf node_modules package-lock.json
npm install
```

### JWT Token Expired
- Tokens expire in 7 days
- Login again to get a fresh token

---

## 📞 API Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created (Signup) |
| 400 | Bad Request (Validation error) |
| 401 | Unauthorized (Invalid credentials) |
| 403 | Forbidden (Invalid token) |
| 404 | Not Found |
| 409 | Conflict (Email exists) |
| 500 | Server Error |

---

## 🎯 Next Steps

1. **Test all endpoints in Postman**
2. **Verify error responses**
3. **Integrate with Flutter app:**
   ```dart
   Future<void> loginWithCustomAPI(String email, String password) async {
     final response = await http.post(
       Uri.parse('http://localhost:3000/api/auth/login'),
       headers: {'Content-Type': 'application/json'},
       body: jsonEncode({'email': email, 'password': password}),
     );
     // Handle response...
   }
   ```

---

Happy Testing! 🚀
