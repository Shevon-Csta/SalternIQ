@echo off
echo Starting SalternIQ...
echo.

:: Start FastAPI backend in a new terminal window
start "SalternIQ Backend" cmd /k "cd /d %~dp0backend && pip install -r requirements.txt -q && python -m uvicorn main:app --reload --port 8000"

:: Wait a moment for backend to boot
timeout /t 3 /nobreak > nul

:: Start React frontend in a new terminal window
start "SalternIQ Frontend" cmd /k "cd /d %~dp0frontend_web && npm run dev"

echo.
echo Both servers are starting:
echo   Backend:  http://localhost:8000
echo   Frontend: http://localhost:5173
echo.
echo Open http://localhost:5173 in your browser.
pause
