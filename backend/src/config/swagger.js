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
        responses: {
          200: {
            description: 'API and database are healthy',
          },
        },
      },
    },
    '/auth/register': {
      post: {
        summary: 'Register new Spare Part Business Owner',
        responses: {
          201: { description: 'Owner registered successfully' },
        },
      },
    },
    '/auth/login': {
      post: {
        summary: 'Authenticate user and get JWT token',
        responses: {
          200: { description: 'Login successful' },
        },
      },
    },
    '/parts': {
      get: {
        summary: 'List private spare parts for authenticated owner',
        responses: {
          200: { description: 'Array of parts' },
        },
      },
      post: {
        summary: 'Create a new spare part',
        responses: {
          201: { description: 'Spare part created' },
        },
      },
    },
  },
};

export function setupSwagger(app) {
  if (process.env.NODE_ENV !== 'production') {
    app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));
  }
}
