

app.use(express.urlencoded({ extended: true, limit: '1mb' }));


// 4. Rate Limiting (100 requests per 15 minutes window)
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: 'TOO_MANY_REQUESTS',
      message: 'Too many requests from this IP. Please try again after 15 minutes.',
    },
  },
});
app.use('/api/', limiter);

// 5. HTTP Request Logging with Winston
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info(`${req.method} ${req.originalUrl} ${res.statusCode} - ${duration}ms`);
  });
  next();
});

// 6. Swagger API Documentation (Non-production only)
setupSwagger(app);

// Static uploads serving (both at root and /api/v1 for reverse proxies and mobile apps)
const resolvedUploadDir = path.resolve(config.uploadDir);
app.use('/uploads', express.static(resolvedUploadDir));
app.use('/api/v1/uploads', express.static(resolvedUploadDir));

// 7. Health Check Route (Mounted at root and /api/v1)
app.use('/', healthRoutes);
app.use('/api/v1', healthRoutes);

// 8. Main API Router
app.use('/api/v1', apiRoutes);

// 9. Catch-all 404 for undefined routes
app.use((req, res, next) => {
  next(new NotFoundError(`Resource not found at ${req.method} ${req.originalUrl}`));
});

// 10. Centralized JSON Error Handler
app.use(errorHandler);

export default app;
