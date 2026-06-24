// vite.config.js
import { defineConfig } from "file:///sessions/vibrant-bold-edison/mnt/FYP/saltern_app/frontend_web/node_modules/vite/dist/node/index.js";
import react from "file:///sessions/vibrant-bold-edison/mnt/FYP/saltern_app/frontend_web/node_modules/@vitejs/plugin-react/dist/index.js";
var vite_config_default = defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/auth": "http://localhost:8000",
      "/predict": "http://localhost:8000",
      "/history": "http://localhost:8000",
      "/dashboard": "http://localhost:8000",
      "/admin": "http://localhost:8000"
    }
  }
});
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcuanMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCIvc2Vzc2lvbnMvdmlicmFudC1ib2xkLWVkaXNvbi9tbnQvRllQL3NhbHRlcm5fYXBwL2Zyb250ZW5kX3dlYlwiO2NvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9maWxlbmFtZSA9IFwiL3Nlc3Npb25zL3ZpYnJhbnQtYm9sZC1lZGlzb24vbW50L0ZZUC9zYWx0ZXJuX2FwcC9mcm9udGVuZF93ZWIvdml0ZS5jb25maWcuanNcIjtjb25zdCBfX3ZpdGVfaW5qZWN0ZWRfb3JpZ2luYWxfaW1wb3J0X21ldGFfdXJsID0gXCJmaWxlOi8vL3Nlc3Npb25zL3ZpYnJhbnQtYm9sZC1lZGlzb24vbW50L0ZZUC9zYWx0ZXJuX2FwcC9mcm9udGVuZF93ZWIvdml0ZS5jb25maWcuanNcIjtpbXBvcnQgeyBkZWZpbmVDb25maWcgfSBmcm9tICd2aXRlJ1xuaW1wb3J0IHJlYWN0IGZyb20gJ0B2aXRlanMvcGx1Z2luLXJlYWN0J1xuXG5leHBvcnQgZGVmYXVsdCBkZWZpbmVDb25maWcoe1xuICBwbHVnaW5zOiBbcmVhY3QoKV0sXG4gIHNlcnZlcjoge1xuICAgIHBvcnQ6IDUxNzMsXG4gICAgcHJveHk6IHtcbiAgICAgICcvYXV0aCc6ICdodHRwOi8vbG9jYWxob3N0OjgwMDAnLFxuICAgICAgJy9wcmVkaWN0JzogJ2h0dHA6Ly9sb2NhbGhvc3Q6ODAwMCcsXG4gICAgICAnL2hpc3RvcnknOiAnaHR0cDovL2xvY2FsaG9zdDo4MDAwJyxcbiAgICAgICcvZGFzaGJvYXJkJzogJ2h0dHA6Ly9sb2NhbGhvc3Q6ODAwMCcsXG4gICAgICAnL2FkbWluJzogJ2h0dHA6Ly9sb2NhbGhvc3Q6ODAwMCcsXG4gICAgfVxuICB9XG59KVxuIl0sCiAgIm1hcHBpbmdzIjogIjtBQUE0VyxTQUFTLG9CQUFvQjtBQUN6WSxPQUFPLFdBQVc7QUFFbEIsSUFBTyxzQkFBUSxhQUFhO0FBQUEsRUFDMUIsU0FBUyxDQUFDLE1BQU0sQ0FBQztBQUFBLEVBQ2pCLFFBQVE7QUFBQSxJQUNOLE1BQU07QUFBQSxJQUNOLE9BQU87QUFBQSxNQUNMLFNBQVM7QUFBQSxNQUNULFlBQVk7QUFBQSxNQUNaLFlBQVk7QUFBQSxNQUNaLGNBQWM7QUFBQSxNQUNkLFVBQVU7QUFBQSxJQUNaO0FBQUEsRUFDRjtBQUNGLENBQUM7IiwKICAibmFtZXMiOiBbXQp9Cg==
