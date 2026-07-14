import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  server: { port: 5190, host: '127.0.0.1', strictPort: false, open: '/' },
  build: {
    rollupOptions: {
      input: {
        hub: resolve(__dirname, 'index.html'),
        buoyancy: resolve(__dirname, 'buoyancy.html'),
        halbach: resolve(__dirname, 'halbach.html'),
        elevatorDual: resolve(__dirname, 'elevator-dual.html'),
        elevatorVariable: resolve(__dirname, 'elevator-variable.html'),
      },
    },
  },
});
