# UniPay React Frontend

This folder is the React.js conversion of the Flutter `Mobile/lib` page flow.

## Run

```bash
cd Frontend
npm install
npm run dev
```

The app uses `VITE_API_BASE_URL` to link to the ASP.NET server. By default it points to:

```text
https://fyp-1-izlh.onrender.com
```

For local server development, create `.env`:

```bash
VITE_API_BASE_URL=http://localhost:5000
```

## Build

```bash
npm run build
```

The production build is written to `Frontend/dist`. To serve it from the ASP.NET app, copy the contents of `Frontend/dist` into `Server/ApiApp/wwwroot`.
