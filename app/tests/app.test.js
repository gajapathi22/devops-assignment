// app/tests/app.test.js
const request = require('supertest');
const { app, server } = require('../app');

describe('DevOps Assignment API', () => {
  afterAll(async () => {
    if (server) {
      server.close();
    }
  });

  describe('GET /', () => {
    it('should return welcome message', async () => {
      const response = await request(app).get('/');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('message');
      expect(response.body).toHaveProperty('version');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body.message).toBe('DevOps Assignment - Node.js App');
    });
  });

  describe('GET /health', () => {
    it('should return health status', async () => {
      const response = await request(app).get('/health');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'healthy');
      expect(response.body).toHaveProperty('uptime');
      expect(response.body).toHaveProperty('timestamp');
      expect(response.body).toHaveProperty('environment');
      expect(typeof response.body.uptime).toBe('number');
    });
  });

  describe('GET /status', () => {
    it('should return service status', async () => {
      const response = await request(app).get('/status');
      
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('status', 'ok');
      expect(response.body).toHaveProperty('service', 'devops-assignment-api');
      expect(response.body).toHaveProperty('version', '1.0.0');
    });
  });

  describe('GET /nonexistent', () => {
    it('should return 404 for non-existent routes', async () => {
      const response = await request(app).get('/nonexistent');
      
      expect(response.status).toBe(404);
      expect(response.body).toHaveProperty('error', 'Route not found');
    });
  });
});

// Additional utility tests
describe('Application Configuration', () => {
  it('should have correct port configuration', () => {
    const port = process.env.PORT || 3000;
    expect(typeof port).toBe('number' || 'string');
  });

  it('should handle JSON requests', async () => {
    const response = await request(app)
      .post('/')
      .send({ test: 'data' });
    
    // Should handle JSON even if route doesn't exist for POST
    expect(response.status).toBe(404);
  });
});