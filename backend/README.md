# Kera Spare Tracker - Backend API

Production-ready, multi-tenant RESTful API for **Kera Spare Tracker**, built with **Node.js 20 (ES Modules)**, **Express**, **Prisma ORM**, and **MySQL 8 (InnoDB, utf8mb4)**.

---

## 🚀 Beginner Quickstart: Running MySQL & Starting the API

### Step 1: Running MySQL on your PC

You have three easy options depending on what is installed on your computer:

#### Option A: Native Windows MySQL Service (Already on your PC!)
If you installed MySQL directly, the `MySQL96` service runs in the background on port `3306`.
1. Open PowerShell and verify:
   ```powershell
   Get-Service -Name MySQL96
   ```
2. Connect to MySQL with your root password:
   ```bash
   mysql -u root -p
   ```
3. Create the database:
   ```sql
   CREATE DATABASE kera_spare_tracker CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   EXIT;
   ```

#### Option B: Using Laragon (Recommended for Beginners)
1. Download **Laragon** from [laragon.org](https://laragon.org/download/).
2. Click **Start All** to launch MySQL on port `3306`.
3. Click **Database** (opens HeidiSQL) -> Right-click -> **Create new** -> **Database** -> Name: `kera_spare_tracker`.

#### Option C: Using XAMPP
1. Download **XAMPP** from [apachefriends.org](https://www.apachefriends.org/).
2. Open **XAMPP Control Panel** and click **Start** next to **MySQL**.
3. Open `http://localhost/phpmyadmin` in your browser.
4. Click **New**, enter database name `kera_spare_tracker`, collation `utf8mb4_unicode_ci`, and click **Create**.

---

### Step 2: Configure Environment Variables

1. Go to the `backend` folder:
   ```bash
   cd backend
   ```
2. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
3. Verify your `DATABASE_URL` in `.env`:
   - If MySQL has no password (default in Laragon / XAMPP):
     ```env
     DATABASE_URL="mysql://root:@localhost:3306/kera_spare_tracker"
     ```
   - If MySQL has a root password:
     ```env
     DATABASE_URL="mysql://root:YourPassword@localhost:3306/kera_spare_tracker"
     ```

---

### Step 3: Install Dependencies, Migrate & Seed

From the `backend` folder:

```bash
# 1. Install dependencies
npm install

# 2. Run Prisma migration (creates all InnoDB utf8mb4 tables & composite indexes)
npx prisma migrate dev --name init

# 3. Seed initial data (Admin user + Global Brands: CAT, Doosan, Develon, etc.)
npm run seed
```

---

### Step 4: Start the Server

```bash
# Start in development mode with auto-reload (port 7000)
npm run dev

# Or start in production mode
npm start
```

Open your browser:
- **API Health Check**: [http://localhost:7000/health](http://localhost:7000/health)
- **Interactive Swagger Documentation**: [http://localhost:7000/api-docs](http://localhost:7000/api-docs)

---

### Step 5: Run Automated Tests

```bash
# Runs Vitest and Supertest testing tenant isolation & RBAC
npm test
```

---

## 🔒 Security & Multi-Tenancy Architecture

### 1. Code-Enforced Data Access Layer
MySQL does not feature native Row Level Security (RLS). Privacy is enforced at the application code layer:
- **`ownerId` is ALWAYS extracted from the verified JWT on the server** (`req.user.id`).
- It is **NEVER** read from or trusted in `req.body`, `req.params`, or `req.query`.
- Every query in `src/services/` filters by `{ ownerId, deletedAt: null }`.
- If an owner attempts to read, edit, or delete another owner's item, the server returns **404 Not Found** (preventing ID enumeration).

### 2. Role-Based Access Control (RBAC)
- **`OWNER`**: Can only view and manage their private spare parts, stock ledger, sales, and custom brands.
- **`ADMIN`**: Can manage users (activate/suspend) and global brands. **Admins are strictly blocked from viewing or mutating owner inventory and sales.**
- **Suspended Accounts**: Any request made by a user with status `SUSPENDED` is immediately rejected with `403 Forbidden`.

### 3. Private Media Storage
- Spare part photos are uploaded via Multer to a folder partitioned per owner: `uploads/parts/{ownerId}/{filename}`.
- Uploads are **never served as public static files**.
- Photos can only be accessed via `GET /api/v1/parts/:id/photo`, which verifies the requesting user owns the part before streaming the file.

---

## 📁 Project Structure

```
backend/
├── prisma/
│   ├── schema.prisma           # MySQL schema with CHAR(36) UUIDs & composite indexes
│   ├── migrations/             # Database migrations
│   └── seed.js                 # Seed script (global brands & admin account)
├── src/
│   ├── config/                 # Environment, Prisma singleton, Winston, Swagger
│   ├── controllers/            # HTTP request/response handlers
│   ├── middleware/             # JWT auth, RBAC, Status, Error, Multer, Zod validation
│   ├── routes/                 # Express routers mounted under /api/v1
│   ├── services/               # Data access layer strictly filtering by ownerId
│   ├── utils/                  # Errors, JWT signing, bcrypt hashing
│   ├── validators/             # Zod input validation schemas
│   ├── app.js                  # Express app setup (Helmet, CORS, Rate Limit)
│   └── server.js               # Server entry point on port 7000
├── tests/                      # Automated Vitest + Supertest isolation tests
├── uploads/                    # Local private media storage (git-ignored)
├── .env.example
├── package.json
└── README.md
```
