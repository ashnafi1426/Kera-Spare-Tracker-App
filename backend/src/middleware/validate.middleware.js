import { ValidationError } from '../utils/errors.js';

export function validate(schema) {
  return (req, res, next) => {
    try {
      const parsed = schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });

      // Replace with sanitized & typed values
      if (parsed.body) req.body = parsed.body;
      if (parsed.query) req.query = parsed.query;
      if (parsed.params) req.params = parsed.params;

      next();
    } catch (err) {
      if (err.errors) {
        const details = err.errors.map((e) => ({
          field: e.path.join('.').replace(/^(body|query|params)\./, ''),
          message: e.message,
        }));
        return next(new ValidationError('Validation failed', details));
      }
      next(err);
    }
  };
}
