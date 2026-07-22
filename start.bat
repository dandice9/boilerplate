@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

where docker >nul 2>nul
if errorlevel 1 (
  echo Error: 'docker' is required but not found on PATH.
  exit /b 1
)
where bun >nul 2>nul
if errorlevel 1 (
  echo Error: 'bun' is required but not found on PATH.
  exit /b 1
)

if not exist api\.env if exist api\.env.example (
  copy /y api\.env.example api\.env >nul
  echo Created api\.env from .env.example
)
if not exist database\.env if exist database\.env.example (
  copy /y database\.env.example database\.env >nul
  echo Created database\.env from .env.example
)

echo Starting Postgres (docker compose)...
docker compose up -d
if errorlevel 1 (
  echo Failed to start docker compose.
  exit /b 1
)

echo Waiting for Postgres to be healthy...
for /f "delims=" %%i in ('docker compose ps -q postgres') do set PG_CID=%%i

:wait_pg
set PG_HEALTH=
for /f "delims=" %%h in ('docker inspect -f "{{.State.Health.Status}}" %PG_CID% 2^>nul') do set PG_HEALTH=%%h
if not "%PG_HEALTH%"=="healthy" (
  timeout /t 1 >nul
  goto wait_pg
)
echo Postgres is ready.

echo Installing root workspace dependencies ^(api, database^)...
call bun install

echo Applying database schema...
pushd database
call bun run push
popd

echo Starting API server in a new window...
start "API Server" cmd /k "cd /d "%~dp0api" && bun run dev"

echo.
echo Select a frontend app to run:
echo   1^) management  ^(SvelteKit web, role: management^)
echo   2^) vendor      ^(SvelteKit web, role: vendor^)
echo   3^) customer_app ^(Flutter, role: customer^)
echo   4^) vendor_app   ^(Flutter, role: vendor^)
set /p CHOICE="Enter choice [1-4]: "

if "%CHOICE%"=="1" goto run_management
if "%CHOICE%"=="2" goto run_vendor
if "%CHOICE%"=="3" goto run_customer_app
if "%CHOICE%"=="4" goto run_vendor_app

echo Invalid choice: %CHOICE%
exit /b 1

:run_management
if not exist management\.env if exist management\.env.example (
  copy /y management\.env.example management\.env >nul
)
echo Installing management dependencies...
pushd management
call bun install
call bun run dev
popd
goto :eof

:run_vendor
if not exist vendor\.env if exist vendor\.env.example (
  copy /y vendor\.env.example vendor\.env >nul
)
echo Installing vendor dependencies...
pushd vendor
call bun install
call bun run dev
popd
goto :eof

:run_customer_app
where flutter >nul 2>nul
if errorlevel 1 (
  echo Error: 'flutter' is required but not found on PATH.
  exit /b 1
)
pushd customer_app
call flutter run
popd
goto :eof

:run_vendor_app
where flutter >nul 2>nul
if errorlevel 1 (
  echo Error: 'flutter' is required but not found on PATH.
  exit /b 1
)
pushd vendor_app
call flutter run
popd
goto :eof
