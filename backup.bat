@echo off
rem Expects PGPASSWORD to be set in the window (the password is never stored in this file)
for /f %%i in ('powershell -command "Get-Date -Format yyyy-MM-dd"') do set D=%%i
if not exist C:\capstone\backups mkdir C:\capstone\backups
"C:\Program Files\PostgreSQL\18\bin\pg_dump.exe" -U postgres -Fc -f C:\capstone\backups\capstone_%D%.dump capstone
echo Backup written to C:\capstone\backups\capstone_%D%.dump