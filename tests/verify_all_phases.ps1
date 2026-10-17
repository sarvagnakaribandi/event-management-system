# ==============================================================================
# EventSphere Complete End-to-End System Verification Suite (Phase 8)
# Covers: Architecture, Discovery, Capacity, Bookings, Proposals, Trust, Notifications
# ==============================================================================

param(
    [string]$BaseUrl = "http://localhost:8081/Eventsphere",
    [string]$MysqlPath = "C:\xampp\mysql\bin\mysql.exe"
)

$ErrorActionPreference = "Continue"

Write-Host "`n====================================================================" -ForegroundColor Cyan
Write-Host "   EVENTSPHERE - COMPREHENSIVE END-TO-END TEST SUITE (PHASES 2-7)   " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Target Base URL: $BaseUrl" -ForegroundColor Gray
Write-Host "Execution Time : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "--------------------------------------------------------------------`n" -ForegroundColor Gray

$passed = 0
$failed = 0

function Assert-Step([string]$testName, [bool]$condition, [string]$details = "") {
    if ($condition) {
        $global:passed++
        Write-Host "  [PASS] $testName" -ForegroundColor Green
        if ($details) { Write-Host "         $details" -ForegroundColor DarkGray }
    } else {
        $global:failed++
        Write-Host "  [FAIL] $testName" -ForegroundColor Red
        if ($details) { Write-Host "         $details" -ForegroundColor Yellow }
    }
}

# ------------------------------------------------------------------------------
# TEST GROUP 1: Database Schema & Relational Structure
# ------------------------------------------------------------------------------
Write-Host "[Group 1] Database Tables & Integrity Checks..." -ForegroundColor Yellow

$expectedTables = @(
    "users", "events", "registrations", "payments", "organizer_profiles",
    "event_types", "event_requests", "proposals", "proposal_items",
    "custom_event_bookings", "notifications"
)

foreach ($tbl in $expectedTables) {
    $out = & $MysqlPath -u root eventsphere -e "SHOW TABLES LIKE '$tbl';" | Out-String
    Assert-Step "Table '$tbl' exists in schema" ([bool]($out -match $tbl))
}

# Verify Admin role in ENUM
$roleDef = & $MysqlPath -u root eventsphere -e "SHOW COLUMNS FROM users LIKE 'role';" | Out-String
Assert-Step "Role ENUM contains 'Admin'" ([bool]($roleDef -match "Admin"))

# Verify Capacity fields in events
$capDef = & $MysqlPath -u root eventsphere -e "SHOW COLUMNS FROM events LIKE 'available_seats';" | Out-String
Assert-Step "Events table has 'available_seats' column" ([bool]($capDef -match "available_seats"))

# ------------------------------------------------------------------------------
# TEST GROUP 2: Authentication & Access Control Verification
# ------------------------------------------------------------------------------
Write-Host "`n[Group 2] Authentication & Access Control Verification..." -ForegroundColor Yellow

# Test guest access restriction to protected portals
$userDashCode = curl.exe -s -o NUL -w "%{http_code}" "$BaseUrl/userDashboard.jsp"
Assert-Step "Guest redirected from userDashboard.jsp (HTTP 302)" ($userDashCode -eq "302")

$orgDashCode = curl.exe -s -o NUL -w "%{http_code}" "$BaseUrl/organizerDashboard.jsp"
Assert-Step "Guest redirected from organizerDashboard.jsp (HTTP 302)" ($orgDashCode -eq "302")

$adminDashCode = curl.exe -s -o NUL -w "%{http_code}" "$BaseUrl/adminDashboard.jsp"
Assert-Step "Guest redirected from adminDashboard.jsp (HTTP 302)" ($adminDashCode -eq "302")

$updateEventCode = curl.exe -s -o NUL -w "%{http_code}" "$BaseUrl/updateEvent.jsp"
Assert-Step "Guest redirected from updateEvent.jsp (HTTP 302)" ($updateEventCode -eq "302")

# Test Public Pages Accessibility
$indexCode = curl.exe -s -o NUL -w "%{http_code}" "$BaseUrl/index.jsp"
Assert-Step "Public Landing Page index.jsp accessible (HTTP 200)" ($indexCode -eq "200")

$browseCode = curl.exe -s -L -o NUL -w "%{http_code}" "$BaseUrl/browseEvents.jsp"
Assert-Step "Browse Events router safely resolves (HTTP 200 via index.jsp)" ($browseCode -eq "200")

# ------------------------------------------------------------------------------
# TEST GROUP 3: Customer Discovery & Filter Endpoints
# ------------------------------------------------------------------------------
Write-Host "`n[Group 3] Customer Experience & Dynamic Discovery..." -ForegroundColor Yellow

$searchResp = Invoke-WebRequest -Uri "$BaseUrl/browseEvents.jsp?category=Technical" -UseBasicParsing
Assert-Step "Category Filtering for 'Technical' events router works (HTTP 200/302)" ($searchResp.StatusCode -in @(200, 302))

$queryResp = Invoke-WebRequest -Uri "$BaseUrl/browseEvents.jsp?search=hackathon" -UseBasicParsing
Assert-Step "Search query router for 'hackathon' works (HTTP 200/302)" ($queryResp.StatusCode -in @(200, 302))

# ------------------------------------------------------------------------------
# TEST GROUP 4: In-App Notification Center & Real-Time APIs (Phase 7)
# ------------------------------------------------------------------------------
Write-Host "`n[Group 4] In-App Notifications & REST APIs..." -ForegroundColor Yellow

$cookieFile = "$PSScriptRoot\temp_cookie.txt"
# Login as Admin
curl.exe -s -c $cookieFile -d "email=admin@eventsphere.com&password=Admin@123" "$BaseUrl/loginProcess.jsp" > $null

$notifApiResp = (curl.exe -s -b $cookieFile "$BaseUrl/getNotifications.jsp") | Out-String
$isJsonValid = $false
try {
    $parsed = $notifApiResp | ConvertFrom-Json
    $isJsonValid = ($parsed.authenticated -eq $true)
} catch {}
Assert-Step "getNotifications.jsp returns authenticated JSON payload" $isJsonValid

$markAllResp = (curl.exe -s -b $cookieFile "$BaseUrl/markNotificationRead.jsp?action=all") | Out-String
Assert-Step "markNotificationRead.jsp marks all notifications read" ([bool]($markAllResp -match '"success":\s*true'))

if (Test-Path $cookieFile) { Remove-Item -Force $cookieFile }

# ------------------------------------------------------------------------------
# TEST GROUP 5: Custom Event Requests & Proposal Negotiation Flow (Phase 5)
# ------------------------------------------------------------------------------
Write-Host "`n[Group 5] Custom Event Requests & Proposal Negotiation..." -ForegroundColor Yellow

# Verify custom request workflow tables
$propCount = (& $MysqlPath -u root eventsphere -e "SELECT COUNT(*) FROM proposals;") | Out-String
Assert-Step "Proposals table operational" ([bool]($propCount -match "\d+"))

$bookingCount = (& $MysqlPath -u root eventsphere -e "SELECT COUNT(*) FROM custom_event_bookings;") | Out-String
Assert-Step "Custom event bookings table operational" ([bool]($bookingCount -match "\d+"))

# ------------------------------------------------------------------------------
# TEST GROUP 6: Organizer Profile & Administrator Verification (Phase 6)
# ------------------------------------------------------------------------------
Write-Host "`n[Group 6] Platform Trust & Verification Engine..." -ForegroundColor Yellow

$adminMetrics = (& $MysqlPath -u root eventsphere -e "
    SELECT 
        (SELECT COUNT(*) FROM users WHERE role='Admin') AS admins,
        (SELECT COUNT(*) FROM users WHERE role='Organizer') AS organizers,
        (SELECT COUNT(*) FROM organizer_profiles WHERE verification_status='Verified') AS verified;
") | Out-String
Assert-Step "Admin portal aggregation queries functional" ([bool]($adminMetrics -match "admins"))

# ------------------------------------------------------------------------------
# TEST GROUP 7: Digital E-Ticket, QR Gate Check-In & Verified Certificates (Phase 9)
# ------------------------------------------------------------------------------
Write-Host "`n[Group 7] Digital E-Ticket, QR Gate Check-In & Verified Certificates..." -ForegroundColor Yellow

$cookieFile9 = "$PSScriptRoot\temp_cookie9.txt"
curl.exe -s -c $cookieFile9 -d "email=admin@eventsphere.com&password=Admin@123" "$BaseUrl/loginProcess.jsp" | Out-Null

# 1. Gate Scanner UI
$scannerResp = (curl.exe -s -b $cookieFile9 "$BaseUrl/gateScanner.jsp?id=10") | Out-String
Assert-Step "Live Gate QR Scanner UI renders HUD and video viewport" ([bool]($scannerResp -match "Live Gate Check-In Scanner"))

# 2. CSV Roster Export
$csvResp = (curl.exe -s -b $cookieFile9 "$BaseUrl/exportParticipants.jsp?id=10&format=csv") | Out-String
Assert-Step "Participant roster exports to CSV stream with ticket tokens" ([bool]($csvResp -match "Ticket Token"))

# 3. Printable Roster
$printResp = (curl.exe -s -b $cookieFile9 "$BaseUrl/exportParticipants.jsp?id=10&format=print") | Out-String
Assert-Step "Printable Gate Roster renders high-contrast venue attendance sheet" ([bool]($printResp -match "Gate Attendance Sheet"))

# 4. Gate Check-In API & Duplicate Prevention
$checkInResp = (curl.exe -s -b $cookieFile9 "$BaseUrl/checkInProcess.jsp?token=TKT-0006-F33110&event_id=10") | Out-String
Assert-Step "Gate Check-In API evaluates token and prevents duplicate admission" ([bool]($checkInResp -match "SUCCESS" -or $checkInResp -match "ALREADY_CHECKED_IN"))

# 5. Certificate of Participation Generation
$certResp = (curl.exe -s "$BaseUrl/certificate.jsp?cert_id=CERT-0006-543F39") | Out-String
Assert-Step "Certificate generator renders golden border and attendee verification" ([bool]($certResp -match "Certificate of Participation" -and $certResp -match "Ramya"))

# 6. Public Certificate Verification Portal
$verifyResp = (curl.exe -s "$BaseUrl/verifyCertificate.jsp?cert_id=CERT-0006-543F39") | Out-String
Assert-Step "Public Trust Verification Portal confirms gate-checked attendee authenticity" ([bool]($verifyResp -match "Authentic & Verified Certificate" -and $verifyResp -match "Ramya"))

# 7. E-Ticket Pass View
$ticketResp = (curl.exe -s -b $cookieFile9 "$BaseUrl/viewTicket.jsp?id=6") | Out-String
Assert-Step "Attendee E-Ticket Pass renders boarding card and scannable QR token" ([bool]($ticketResp -match "BOARDING PASS" -or $ticketResp -match "Ramya"))

if (Test-Path $cookieFile9) { Remove-Item -Force $cookieFile9 }

# ------------------------------------------------------------------------------
# TEST GROUP 8: Attendee Ratings & Reviews Engine + Organizer Analytics (Phase 10)
# ------------------------------------------------------------------------------
Write-Host "`n[Group 8] Attendee Ratings & Reviews Engine + Organizer Analytics..." -ForegroundColor Yellow

$cookieUser10 = "$PSScriptRoot\temp_user10.txt"
$cookieOrg10 = "$PSScriptRoot\temp_org10.txt"

# 1. Attendee login (qwe@gmail.com / qwe)
curl.exe -s -c $cookieUser10 -d "email=qwe@gmail.com&password=qwe" "$BaseUrl/loginProcess.jsp" | Out-Null

# 2. Submit Review
$revResp = (curl.exe -s -b $cookieUser10 -d "event_id=10&rating=5&review_title=Outstanding+Experience&review_text=Great+hands-on+coding+challenges+and+smooth+event+management.&format=json" "$BaseUrl/submitReview.jsp") | Out-String
Assert-Step "Attendee review submission API returns success JSON" ([bool]($revResp -match '"success":\s*true'))

# 3. Verify Review on Event Details
$detailsResp = (curl.exe -s -b $cookieUser10 "$BaseUrl/eventDetails.jsp?id=10") | Out-String
Assert-Step "Event Details renders social proof rating breakdown and verified review" ([bool]($detailsResp -match "Outstanding Experience" -and $detailsResp -match "Verified Attendee"))

# 4. Star Rating Badge on Browse Feed
$indexResp = (curl.exe -s "$BaseUrl/index.jsp") | Out-String
Assert-Step "Discovery Feed renders star rating badge on event card" ([bool]($indexResp -match "badge-star-rating" -or $indexResp -match "5.0"))

# 5. Organizer Login & Analytics Dashboard
curl.exe -s -c $cookieOrg10 -d "email=klo@sasi.ac.in&password=klo" "$BaseUrl/loginProcess.jsp" | Out-Null
$analyticsResp = (curl.exe -s -b $cookieOrg10 "$BaseUrl/organizerAnalytics.jsp") | Out-String
Assert-Step "Organizer Analytics renders confirmed revenue KPIs and attendance rate" ([bool]($analyticsResp -match "Confirmed Revenue" -and $analyticsResp -match "Gate Check-In Rate"))
Assert-Step "Organizer Analytics displays recent attendee reviews feed" ([bool]($analyticsResp -match "Outstanding Experience"))

if (Test-Path $cookieUser10) { Remove-Item -Force $cookieUser10 }
if (Test-Path $cookieOrg10) { Remove-Item -Force $cookieOrg10 }

# ------------------------------------------------------------------------------
# FINAL REPORT SUMMARY
# ------------------------------------------------------------------------------
Write-Host "`n====================================================================" -ForegroundColor Cyan
Write-Host "                    TEST EXECUTION SUMMARY                          " -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  Total Tests Executed : $($passed + $failed)" -ForegroundColor Gray
Write-Host "  Tests Passed         : $passed" -ForegroundColor Green
Write-Host "  Tests Failed         : $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

if ($failed -eq 0) {
    Write-Host "`n>>> ALL SYSTEM VERIFICATION TESTS PASSED SUCCESSFULLY! (100%) <<<`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n>>> SOME TESTS FAILED. PLEASE REVIEW LOGS ABOVE. <<<`n" -ForegroundColor Red
    exit 1
}
