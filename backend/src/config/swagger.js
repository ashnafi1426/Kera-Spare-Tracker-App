import swaggerUi from 'swagger-ui-express';

const swaggerDocument = {
  openapi: '3.0.0',
  info: {
    title: 'Kera Spare Tracker API',
    version: '1.0.0',
    description: 'Production Node.js, Express & MySQL Multi-Tenant API for Kera Spare Tracker',
  },
  servers: [
    {
      url: '/api/v1',
      description: 'API v1 Base URL',
    },
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
      },
    },
  },
  security: [
    {
      bearerAuth: [],
    },
  ],
  paths: {
    '/health': {
      get: {
        summary: 'System Health Check',
        responses: { 200: { description: 'API and database are healthy' } },
      },
    },
    '/auth/register': {
      post: {
        summary: 'Register new Spare Part Business Owner',
        responses: { 201: { description: 'Owner registered successfully' } },
      },
    },
    '/auth/login': {
      post: {
        summary: 'Authenticate user and get JWT token',
        responses: { 200: { description: 'Login successful' } },
      },
    },
    '/auth/admin/login': {
      post: {
        summary: 'Strict administrator authentication (rate limited)',
        responses: { 200: { description: 'Admin login successful' } },
      },
    },
    '/admin/dashboard': {
      get: {
        tags: ['Admin'],
        summary: 'Admin Telemetry & Aggregated Dashboard Metrics',
        responses: { 200: { description: 'Dashboard stats and counts' } },
      },
    },
    '/admin/users': {
      get: {
        tags: ['Admin'],
        summary: 'List & search registered owner accounts with filters and pagination',
        responses: { 200: { description: 'Paginated user list' } },
      },
    },
    '/admin/users/{id}': {
      get: {
        tags: ['Admin'],
        summary: 'Get owner details, item/sales counts, and last 20 audit entries',
        responses: { 200: { description: 'User account details' } },
      },
      patch: {
        tags: ['Admin'],
        summary: 'Update basic owner details (businessName, phone)',
        responses: { 200: { description: 'User updated' } },
      },
      delete: {
        tags: ['Admin'],
        summary: 'Soft-disable an owner account (requires exact phone confirmation)',
        responses: { 200: { description: 'User disabled' } },
      },
    },
    '/admin/users/{id}/suspend': {
      patch: {
        tags: ['Admin'],
        summary: 'Suspend an owner account and immediately revoke tokens',
        responses: { 200: { description: 'User suspended' } },
      },
    },
    '/admin/users/{id}/reactivate': {
      patch: {
        tags: ['Admin'],
        summary: 'Reactivate a suspended owner account',
        responses: { 200: { description: 'User reactivated' } },
      },
    },
    '/admin/users/{id}/reset-password': {
      post: {
        tags: ['Admin'],
        summary: 'Generate temporary password, revoke tokens, and set mustChangePassword',
        responses: { 200: { description: 'Temporary password returned once' } },
      },
    },
    '/admin/brands': {
      get: {
        tags: ['Admin - Catalog'],
        summary: 'List global brands',
        responses: { 200: { description: 'Global brands list' } },
      },
      post: {
        tags: ['Admin - Catalog'],
        summary: 'Create a new global brand',
        responses: { 201: { description: 'Global brand created' } },
      },
    },
    '/admin/brands/{id}': {
      patch: {
        tags: ['Admin - Catalog'],
        summary: 'Update global brand name or active status',
        responses: { 200: { description: 'Brand updated' } },
      },
      delete: {
        tags: ['Admin - Catalog'],
        summary: 'Deactivate / soft-delete global brand',
        responses: { 200: { description: 'Brand deactivated' } },
      },
    },
    '/admin/categories': {
      get: {
        tags: ['Admin - Catalog'],
        summary: 'List global categories',
        responses: { 200: { description: 'Global categories list' } },
      },
      post: {
        tags: ['Admin - Catalog'],
        summary: 'Create a new global category',
        responses: { 201: { description: 'Global category created' } },
      },
    },
    '/admin/categories/{id}': {
      patch: {
        tags: ['Admin - Catalog'],
        summary: 'Update global category name or active status',
        responses: { 200: { description: 'Category updated' } },
      },
      delete: {
        tags: ['Admin - Catalog'],
        summary: 'Deactivate / soft-delete global category',
        responses: { 200: { description: 'Category deactivated' } },
      },
    },
    '/admin/units': {
      get: {
        tags: ['Admin - Catalog'],
        summary: 'List global units',
        responses: { 200: { description: 'Global units list' } },
      },
      post: {
        tags: ['Admin - Catalog'],
        summary: 'Create a new global unit',
        responses: { 201: { description: 'Global unit created' } },
      },
    },
    '/admin/units/{id}': {
      patch: {
        tags: ['Admin - Catalog'],
        summary: 'Update global unit name or active status',
        responses: { 200: { description: 'Unit updated' } },
      },
      delete: {
        tags: ['Admin - Catalog'],
        summary: 'Deactivate / soft-delete global unit',
        responses: { 200: { description: 'Unit deactivated' } },
      },
    },
    '/admin/settings/min-app-version': {
      get: {
        tags: ['Admin - Settings'],
        summary: 'Get minimum required app version',
        responses: { 200: { description: 'Min app version setting' } },
      },
      put: {
        tags: ['Admin - Settings'],
        summary: 'Update minimum required app version',
        responses: { 200: { description: 'Setting updated' } },
      },
    },
    '/admin/settings/announcement': {
      get: {
        tags: ['Admin - Settings'],
        summary: 'Get active system announcement',
        responses: { 200: { description: 'Announcement setting' } },
      },
      put: {
        tags: ['Admin - Settings'],
        summary: 'Update system announcement',
        responses: { 200: { description: 'Setting updated' } },
      },
    },
    '/admin/settings/maintenance': {
      get: {
        tags: ['Admin - Settings'],
        summary: 'Get maintenance mode configuration',
        responses: { 200: { description: 'Maintenance setting' } },
      },
      put: {
        tags: ['Admin - Settings'],
        summary: 'Update maintenance mode configuration',
        responses: { 200: { description: 'Setting updated' } },
      },
    },
    '/admin/audit-logs': {
      get: {
        tags: ['Admin'],
        summary: 'Query immutable audit logs with filters and pagination',
        responses: { 200: { description: 'Audit logs array' } },
      },
    },
    '/parts': {
      get: {
        summary: 'List private spare parts for authenticated owner',
        responses: { 200: { description: 'Array of parts' } },
      },
      post: {
        summary: 'Create a new spare part',
        responses: { 201: { description: 'Spare part created' } },
      },
    },
  },
};

export function setupSwagger(app) {
  if (process.env.NODE_ENV !== 'production') {
    app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
  }
}
