const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'your_super_secret_jwt_key';

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ======================== In-Memory Database (For Testing) ========================
// In production, use a real database like MongoDB, PostgreSQL, etc.
const users = {};

// ======================== Health Check Endpoint ========================
app.get('/api/health', (req, res) => {
  res.json({
    status: 'success',
    message: 'API is running',
    timestamp: new Date().toISOString(),
  });
});

// ======================== SIGNUP ENDPOINT ========================
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { fullName, email, password, confirmPassword } = req.body;

    // Validation
    if (!fullName || !email || !password || !confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'All fields are required',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters',
      });
    }

    if (password !== confirmPassword) {
      return res.status(400).json({
        success: false,
        message: 'Passwords do not match',
      });
    }

    // Email validation
    if (!isValidEmail(email)) {
      return res.status(400).json({
        success: false,
        message: 'Please enter a valid email address',
      });
    }

    // Check if user already exists
    if (users[email]) {
      return res.status(409).json({
        success: false,
        message: 'Email is already registered',
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user
    const userId = uuidv4();
    users[email] = {
      id: userId,
      fullName,
      email,
      password: hashedPassword,
      createdAt: new Date().toISOString(),
    };

    // Generate JWT token
    const token = jwt.sign(
      { id: userId, email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        id: userId,
        fullName,
        email,
        token,
        createdAt: users[email].createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error during signup',
      error: error.message,
    });
  }
});

// ======================== LOGIN ENDPOINT ========================
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required',
      });
    }

    // Check if user exists
    const user = users[email];
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'No account found with this email',
      });
    }

    // Compare password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Incorrect password',
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { id: user.id, email: user.email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        token,
        lastSignIn: new Date().toISOString(),
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error during login',
      error: error.message,
    });
  }
});

// ======================== GET USER PROFILE (Protected Route) ========================
app.get('/api/auth/profile', authenticateToken, (req, res) => {
  try {
    const userEmail = req.user.email;
    const user = users[userEmail];

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Profile retrieved successfully',
      data: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
});

// ======================== UPDATE PROFILE ========================
app.put('/api/auth/profile', authenticateToken, async (req, res) => {
  try {
    const { fullName } = req.body;
    const userEmail = req.user.email;
    const user = users[userEmail];

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    if (fullName) {
      user.fullName = fullName;
    }

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Server error',
      error: error.message,
    });
  }
});

// ======================== LOGOUT (Optional - mainly for frontend) ========================
app.post('/api/auth/logout', (req, res) => {
  res.json({
    success: true,
    message: 'Logout successful',
  });
});

// ======================== Middleware: Verify JWT Token ========================
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    return res.status(401).json({
      success: false,
      message: 'Access token is missing',
    });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({
        success: false,
        message: 'Invalid or expired token',
      });
    }
    req.user = user;
    next();
  });
}

// ======================== Helper Functions ========================
function isValidEmail(email) {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

// ======================== Error Handling - 404 ========================
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
    path: req.path,
  });
});

// ======================== Start Server ========================
app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║  🔐 Cryptography Visualizer Auth API                       ║
║  🚀 Server running at: http://localhost:${PORT}                ║
║  📝 Ready for Postman Testing!                              ║
╚════════════════════════════════════════════════════════════╝

Available Endpoints:
├─ GET  /api/health                (Check API status)
├─ POST /api/auth/signup           (Register new user)
├─ POST /api/auth/login            (Login user)
├─ GET  /api/auth/profile          (Get user profile - requires token)
├─ PUT  /api/auth/profile          (Update profile - requires token)
└─ POST /api/auth/logout           (Logout)
  `);
});
